/*
 *Copyright (C) 2018 Laurent Tréguier
 *
 *This file is part of DLS.
 *
 *DLS is free software: you can redistribute it and/or modify
 *it under the terms of the GNU General Public License as published by
 *the Free Software Foundation, either version 3 of the License, or
 *(at your option) any later version.
 *
 *DLS is distributed in the hope that it will be useful,
 *but WITHOUT ANY WARRANTY; without even the implied warranty of
 *MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *GNU General Public License for more details.
 *
 *You should have received a copy of the GNU General Public License
 *along with DLS.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

module dls.updater;

import std.format : format;

private enum descriptionJson = import("description.json");
private immutable changelogUrl = format!"https://github.com/d-language-server/dls/blob/v%s/CHANGELOG.md"(
        currentVersion);

void cleanup()
{
    import dls.bootstrap : dubBinDir;
    import dub.semver : compareVersions;
    import std.file : FileException, SpanMode, dirEntries, isSymlink, remove,
        rmdirRecurse;
    import std.path : baseName;
    import std.regex : matchFirst;

    foreach (string entry; dirEntries(dubBinDir, SpanMode.shallow))
    {
        const match = entry.baseName.matchFirst(`dls-v([\d.]+)`);

        if (match)
        {
            if (compareVersions(currentVersion, match[1]) > 0)
            {
                try
                {
                    rmdirRecurse(entry);
                }
                catch (FileException e)
                {
                }
            }
        }
        else if (isSymlink(entry))
        {
            try
            {
                version (Windows)
                {
                    import std.file : isDir, rmdir;
                    import std.stdio : File;

                    if (isDir(entry))
                    {
                        try
                        {
                            dirEntries(entry, SpanMode.shallow);
                        }
                        catch (FileException e)
                        {
                            rmdir(entry);
                        }
                    }
                    else
                    {
                        try
                        {
                            File(entry, "rb");
                        }
                        catch (Exception e)
                        {
                            remove(entry);
                        }
                    }
                }
                else version (Posix)
                {
                    import std.file : exists, readLink;

                    if (!exists(readLink(entry)))
                    {
                        remove(entry);
                    }
                }
            }
            catch (Exception e)
            {
            }
        }
    }
}

void update(bool autoUpdate)
{
    import core.time : hours;
    import dls.bootstrap : UpgradeFailedException, apiEndpoint, buildDls,
        canDownloadDls, downloadDls, linkDls;
    static import dls.protocol.jsonrpc;
    import dls.protocol.interfaces.dls : DlsUpgradeSizeParams,
        TranslationParams;
    import dls.protocol.messages.methods : Dls;
    import dls.protocol.messages.window : Util;
    import dls.util.constants : Tr;
    import dls.util.logger : logger;
    import dls.util.path : normalized;
    import dub.dependency : Dependency;
    import dub.dub : Dub, FetchOptions;
    import dub.semver : compareVersions;
    import std.algorithm : stripLeft;
    import std.concurrency : ownerTid, receiveOnly, register, send, thisTid;
    import std.datetime : Clock, SysTime;
    import std.json : parseJSON;
    import std.net.curl : get;

    const latestRelease = parseJSON(get(format!apiEndpoint("releases/latest")));
    const latestVersion = latestRelease["tag_name"].str.stripLeft('v');
    const releaseTime = SysTime.fromISOExtString(latestRelease["published_at"].str);

    if (latestVersion.length == 0 || compareVersions(currentVersion,
            latestVersion) >= 0 || (Clock.currTime.toUTC() - releaseTime < 1.hours))
    {
        return;
    }

    if (!autoUpdate)
    {
        auto id = Util.sendMessageRequest(Tr.app_upgradeDls,
                [Tr.app_upgradeDls_upgrade], [latestVersion, currentVersion]);
        const threadName = "updater";
        register(threadName, thisTid());
        send(ownerTid(), Util.ThreadMessageData(id, Tr.app_upgradeDls, threadName));

        const shouldUpgrade = receiveOnly!bool();

        if (!shouldUpgrade)
        {
            return;
        }
    }

    dls.protocol.jsonrpc.send(Dls.Compat.upgradeDls_start,
            new TranslationParams(Tr.app_upgradeDls_upgrading));
    dls.protocol.jsonrpc.send(Dls.UpgradeDls.didStart,
            new TranslationParams(Tr.app_upgradeDls_upgrading));

    scope (exit)
    {
        dls.protocol.jsonrpc.send(Dls.Compat.upgradeDls_stop);
        dls.protocol.jsonrpc.send(Dls.UpgradeDls.didStop);
    }

    bool upgradeSuccessful;

    if (canDownloadDls)
    {
        try
        {
            enum totalSizeCallback = (size_t size) {
                dls.protocol.jsonrpc.send(Dls.Compat.upgradeDls_totalSize,
                        new DlsUpgradeSizeParams(Tr.app_upgradeDls_downloading, [], size));
                dls.protocol.jsonrpc.send(Dls.UpgradeDls.didChangeTotalSize,
                        new DlsUpgradeSizeParams(Tr.app_upgradeDls_downloading, [], size));
            };
            enum chunkSizeCallback = (size_t size) {
                dls.protocol.jsonrpc.send(Dls.Compat.upgradeDls_currentSize,
                        new DlsUpgradeSizeParams(Tr.app_upgradeDls_downloading, [], size));
                dls.protocol.jsonrpc.send(Dls.UpgradeDls.didChangeCurrentSize,
                        new DlsUpgradeSizeParams(Tr.app_upgradeDls_downloading, [], size));
            };
            enum extractCallback = () {
                dls.protocol.jsonrpc.send(Dls.Compat.upgradeDls_extract,
                        new TranslationParams(Tr.app_upgradeDls_extracting));
                dls.protocol.jsonrpc.send(Dls.UpgradeDls.didExtract,
                        new TranslationParams(Tr.app_upgradeDls_extracting));
            };

            downloadDls(totalSizeCallback, chunkSizeCallback, extractCallback);
            upgradeSuccessful = true;
        }
        catch (Exception e)
        {
            logger.errorf("Could not download DLS: %s", e.message);
        }
    }

    if (!upgradeSuccessful)
    {
        auto dub = new Dub();
        FetchOptions fetchOpts;
        fetchOpts |= FetchOptions.forceBranchUpgrade;
        const pack = dub.fetch("dls", Dependency(">=0.0.0"),
                dub.defaultPlacementLocation, fetchOpts);

        int i;
        const additionalArgs = [[], ["--force"]];

        do
        {
            try
            {
                buildDls(pack.path.toString().normalized, additionalArgs[i]);
                upgradeSuccessful = true;
            }
            catch (UpgradeFailedException e)
            {
                ++i;
            }
        }
        while (i < additionalArgs.length && !upgradeSuccessful);

        if (!upgradeSuccessful)
        {
            Util.sendMessage(Tr.app_buildError);
            return;
        }
    }

    try
    {
        linkDls();
        auto id = Util.sendMessageRequest(Tr.app_showChangelog,
                [Tr.app_showChangelog_show], [latestVersion]);
        send(ownerTid(), Util.ThreadMessageData(id, Tr.app_showChangelog, changelogUrl));
    }
    catch (UpgradeFailedException e)
    {
        Util.sendMessage(Tr.app_linkError);
    }
}

@property private string currentVersion()
{
    import std.algorithm : find;
    import std.json : parseJSON;

    const desc = parseJSON(descriptionJson);
    return desc["packages"].array.find!(p => p["name"] == desc["rootPackage"])[0]["version"].str;
}
