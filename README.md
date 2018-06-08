# D Language Server

[![DUB Package](https://img.shields.io/dub/v/dls.svg)](https://code.dlang.org/packages/dls)
[![Build Status](https://travis-ci.org/LaurentTreguier/dls.svg?branch=master)](https://travis-ci.org/LaurentTreguier/dls)
[![Build status](https://ci.appveyor.com/api/projects/status/apmr87v3yvkxb5dm/branch/master?svg=true)](https://ci.appveyor.com/project/LaurentTreguier/dls)

### LSP compliance: `3.7.0`

_This is a work in progress. There ~~might~~ will be bugs and crashes..._

DLS implements the server side of the [Language Server Protocol (LSP)](https://microsoft.github.io/language-server-protocol/) for the [D programming language](https://dlang.org).
It does not contain any language feature itself (yet), but uses already available components, and provides an interface to work with the LSP.
Current features include:
- Code completion
- Go to definition
- Error checking
- Formatting
- Symbol searching
- Symbol highlighting
- Documentation on hover
- Random crashes

Libraries used (the stuff doing the actual hard work):
- [arsd](http://arsd.dub.pm)
- [DCD](http://dcd.dub.pm)
- [DFMT](http://dfmt.dub.pm)
- [D-Scanner](http://dscanner.dub.pm)
- [DSymbol](http://dsymbol.dub.pm)
- [Dub](http://dub.dub.pm)
- [emsi_containers](http://emsi_containers.dub.pm)
- [inifiled](http://inifiled.dub.pm)
- [libddoc](http://libddoc.dub.pm)
- [libdparse](http://libdparse.dub.pm)
- [msgpack-d](http://msgpack-d.dub.pm)
- [stdx-allocator](http://stdx-allocator.dub.pm)

## Installing
You can run `dub fetch dls` and then `dub run dls:bootstrap` to install dls.
The second command will output a path to a symbolic link that will always point to the latest DLS executable.
DLS will propose updates as they come, and update the symbolic link upon upgrading.

## Client side configuration

All these keys should be formatted as `d.dls.[section].[key]` (e.g. `d.dls.format.endOfLine`).

|Section: `symbol`|Type      |Default value|
|-----------------|----------|-------------|
|`importPaths`    |`string[]`|`[]`         |

|Section: `analysis`|Type    |Default value   |
|-------------------|--------|----------------|
|`configFile`       |`string`|`"dscanner.ini"`|

|Section: `format`                   |Type                                    |Default value|
|------------------------------------|----------------------------------------|-------------|
|`endOfLine`                         |`"lf"` or `"cr"` or `"crlf"`            |`"lf"`       |
|`maxLineLength`                     |`number`                                |`120`        |
|`dfmtAlignSwitchStatements`         |`boolean`                               |`true`       |
|`dfmtBraceStyle`                    |`"allman"` or `"otbs"` or `"stroustrup"`|`"allman"`   |
|`dfmtOutdentAttributes`             |`boolean`                               |`true`       |
|`dfmtSoftMaxLineLength`             |`number`                                |`80`         |
|`dfmtSpaceAfterCast`                |`boolean`                               |`true`       |
|`dfmtSpaceAfterKeywords`            |`boolean`                               |`true`       |
|`dfmtSpaceBeforeFunctionParameters` |`boolean`                               |`false`      |
|`dfmtSplitOperatorAtLineEnd`        |`boolean`                               |`false`      |
|`dfmtSelectiveImportSpace`          |`boolean`                               |`true`       |
|`dfmtCompactLabeledStatements`      |`boolean`                               |`true`       |
|`dfmtTemplateConstraintStyle`       |`"conditionalNewlineIndent"` or `"conditionalNewline"` or `"alwaysNewline"` or `"alwaysNewlineIndent"`|`"conditionalNewlineIndent"`|
|`dfmtSingleTemplateConstraintIndent`|`boolean`                               |`false`      |

## The `bootstrap` subpackage and the update system

In order to simplify the process of updating DLS, an update system is implemented.
However, the extension will need to locate a first version of DLS; this is where `dls:bootstrap` comes in.
The steps are:
- `dub fetch dls` will fetch the latest version of DLS
- `dub run --quiet dls:bootstrap` will output the path to a symlink pointing to the latest DLS executable

Nothing specific is required on the client's part regarding updates: the server will send notifications to the user when an update is available, and download/build the new version (in parallel to responding to requests).
Binary downloads are available and should be picked up automatically for Windows, macOS and Linux in both x86 and x86_64 flavors.

## Caveats

The server may delegate a few operations to the client-side extension depending on the language client's capabilities.
The client should watch these files for the server to work properly:
- `dub.selections.json`
- `dub.json`
- `dub.sdl`
- `*.ini`

If the client supports dynamic registration of the `workspace/didChangeWatchedFiles` method, then the server will automatically register file watching.
If the client doesn't support dynamic registration however, the client-side extension will need to manually do it.
The server needs to know at least when `dub.selections.json` files change to properly provide completion support.
If `dub.json` and `dub.sdl` are also watched, `dub.selections.json` will automatically be regenerated and then it will be used for completion support.
Watching `*.ini` allows DLS to monitor D-Scanner config files, even if the name is changed in the config and isn't precisly `dscanner.ini`.

## Custom messages
The LSP defines messages with methods starting in `$/` to be implementation dependant.
DLS uses `$/dls` as a prefix for some custom messages.

|Message                        |Type        |Parameter|Description                                                                |
|-------------------------------|------------|---------|---------------------------------------------------------------------------|
|`$/dls.upgradeDls.start`       |Notification|`null`   |Sent when the upgrade process starts                                       |
|`$/dls.upgradeDls.stop`        |Notification|`null`   |Sent when the upgrade process stops                                        |
|`$/dls.upgradeDls.totalSize`   |Notification|`number` |Sent during the download, with the total size of the upgrade download      |
|`$/dls.upgradeDls.chunkSize`   |Notification|`number` |Sent during the download, with the size of a chunk that was just downloaded|
|`$/dls.upgradeDls.extract`     |Notification|`null`   |Sent when the download is finished and the contents are written on the disk|
|`$/dls.upgradeSelections.start`|Notification|`number` |Sent when DLS starts upgrading dub.selections.json                         |
|`$/dls.upgradeSelections.stop` |Notification|`null`   |Sent when DLS has finished upgrading dub.selections.json                   |

## Example usage

I made a VSCode extension and an Atom package using DLS:
- https://github.com/LaurentTreguier/vscode-dls
- https://github.com/LaurentTreguier/ide-dlang
