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

import dls.util.communicator : Communicator;
import std.json : JSONValue;

private enum MessageFileType : string
{
    order = "txt",
    input = "in.json",
    output = "out.json",
    reference = "ref.json"
}

private struct Message
{
    private string name;
    private char[] content;
}

private class TestCommunicator : Communicator
{
    string[] testedWorkspaces;
    private Message[][string] _workspacesMessages;
    private string _workspace;
    private string _lastReadMessageName;
    private string _currentOutput;
    private JSONValue[] _outputMessages;

    this()
    {
        import std.algorithm : filter;
        import std.file : SpanMode, dirEntries, getcwd, isDir;
        import std.path : buildPath;

        foreach (workspace; dirEntries(buildPath(getcwd(), "tests"), SpanMode.shallow).filter!(
                entry => isDir(entry.name)))
        {
            _workspacesMessages[workspace] = [];

            if (_workspace.length == 0)
            {
                _workspace = workspace;
            }
        }

        fillWorkspaceMessages();
    }

    bool hasData()
    {
        return _workspacesMessages.keys.length > 0;
    }

    char[] read(size_t size)
    {
        auto currentMessage = _workspacesMessages[_workspace][0];
        auto result = currentMessage.content[0 .. size];

        if (currentMessage.content.length > size)
        {
            _workspacesMessages[_workspace][0].content = currentMessage.content[size .. $];
        }
        else
        {
            _lastReadMessageName = currentMessage.name;
            _outputMessages = [];

            if (_workspacesMessages[_workspace].length > 1)
            {
                _workspacesMessages[_workspace] = _workspacesMessages[_workspace][1 .. $];
            }
            else
            {
                testedWorkspaces ~= _workspace;
                _workspacesMessages.remove(_workspace);

                if (_workspacesMessages.keys.length > 0)
                {
                    _workspace = _workspacesMessages.keys[0];
                    fillWorkspaceMessages();
                }
            }
        }

        return result;
    }

    void write(in char[] buffer)
    {
        _currentOutput ~= buffer;
    }

    void flush()
    {
        import std.algorithm : findSkip;
        import std.file : write;
        import std.json : JSONOptions, parseJSON;

        _currentOutput.findSkip("\r\n\r\n");
        _outputMessages ~= parseJSON(_currentOutput);
        const outputPath = getMessagePath(_workspace, _lastReadMessageName,
                MessageFileType.output);
        write(outputPath, JSONValue(_outputMessages)
                .toPrettyString(JSONOptions.doNotEscapeSlashes));
        _currentOutput = "";
    }

    private void fillWorkspaceMessages()
    {
        import std.file : readText;
        import std.format : format;

        foreach (line; getOrderedMessageNames(_workspace))
        {
            const inputPath = getMessagePath(_workspace, line, MessageFileType.input);
            auto input = readText!(char[])(inputPath).expandTestUris(_workspace);
            auto message = Message(line);
            message.content ~= format("Content-Length: %s\r\n\r\n%s", input.length, input);
            _workspacesMessages[_workspace] ~= message;
        }
    }
}

int main()
{
    import dls.server : Server;
    import dls.util.communicator : communicator;

    auto testCommunicator = new TestCommunicator();
    communicator = testCommunicator;
    Server.loop();
    return checkResults(testCommunicator.testedWorkspaces);
}

private int checkResults(in string[] workspaces)
{
    import std.algorithm : reduce;
    import std.array : array;
    import std.json : JSONOptions;
    import std.range : repeat;
    import std.stdio : stderr;

    size_t diffCount;

    foreach (workspace; workspaces)
    {
        stderr.writefln("#### Workspace %s", workspace);

        auto orderedMessageNames = getOrderedMessageNames(workspace).array;
        const maxNameLength = reduce!((a, b) => a.length > b.length ? a : b)("",
                orderedMessageNames).length;

        foreach (name; orderedMessageNames)
        {
            auto output = getJSON(workspace, name, MessageFileType.output);
            auto reference = getJSON(workspace, name, MessageFileType.reference);
            stderr.writef("     Message %s%s: ", name, repeat(' ', maxNameLength - name.length));

            if (output != reference)
            {
                ++diffCount;
                stderr.writefln("FAIL");
                stderr.writeln(">>>> expected result:");
                stderr.writeln(reference.toPrettyString(JSONOptions.doNotEscapeSlashes));
                stderr.writeln(">>>> actual result:");
                stderr.writeln(output.toPrettyString(JSONOptions.doNotEscapeSlashes));
            }
            else
            {
                stderr.writefln("SUCCESS");
            }
        }
    }

    return diffCount > 0 ? 1 : 0;
}

private auto getOrderedMessageNames(in string workspace)
{
    import std.algorithm : map;
    import std.stdio : File;
    import std.string : strip;

    return File(getMessagePath(workspace, "_order", MessageFileType.order), "r")
        .byLineCopy.map!strip;
}

private JSONValue getJSON(in string workspace, in string name, in MessageFileType type)
{
    import std.json : parseJSON;
    import std.file : exists, readText;

    const path = getMessagePath(workspace, name, type);
    return parseJSON(exists(path) ? readText(path).expandTestUris(workspace) : "[]");
}

private string getMessagePath(in string workspace, in string name, in MessageFileType type)
{
    import std.path : buildPath;

    return buildPath(workspace, "messages", name ~ "." ~ type);
}

private inout(char[]) expandTestUris(inout(char[]) text, in string workspace)
{
    import dls.util.uri : Uri;
    import std.array : replace;

    return text.replace("testFile://", Uri.fromPath(workspace).toString());
}
