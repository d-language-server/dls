# D Language Server

### LSP compliance: `3.7.0`

_This is a work in progress..._

DLS implements the server side of the [Language Server Protocol (LSP)](https://microsoft.github.io/language-server-protocol/) for the [D programming language](https://dlang.org). It does not contain any language feature itself (yet), but uses existing components and provides an interface to work with the LSP.
It currently provides:
- Code completion using [DCD](https://github.com/dlang-community/DCD)
- Go to definition using [DCD](https://github.com/dlang-community/DCD)
- Error checking using [D-Scanner](https://github.com/dlang-community/D-Scanner)
- Formatting using [DFMT](https://github.com/dlang-community/dfmt)

## Client side configuration

All these keys should be formatted as `d.dls.[section].[key]` (e.g. `d.dls.format.endOfLine`).

|Section: `symbol`|Type      |Default value|
|-----------------|----------|-------------|
|`importPaths`    |`string[]`|`[]`         |

|Section: `analysis`|Type    |Default value   |
|-------------------|--------|----------------|
|`configFile`       |`string`|`"dscanner.ini"`|

|Section: `format`                  |Type                                    |Default value|
|-----------------------------------|----------------------------------------|-------------|
|`endOfLine`                        |`"lf"` or `"cr"` or `"crlf"`            |`"lf"`       |
|`maxLineLength`                    |`number`                                |`120`        |
|`dfmtBraceStyle`                   |`"allman"` or `"otbs"` or `"stroustrup"`|`"allman"`   |
|`dfmtSoftMaxLineLength`            |`number`                                |`80`         |
|`dfmtAlignSwitchStatements`        |`boolean`                               |`true`       |
|`dfmtOutdentAttributes`            |`boolean`                               |`true`       |
|`dfmtSplitOperatorAtLineEnd`       |`boolean`                               |`false`      |
|`dfmtSpaceAfterCast`               |`boolean`                               |`true`       |
|`dfmtSpaceAfterKeywords`           |`boolean`                               |`true`       |
|`dfmtSpaceBeforeFunctionParameters`|`boolean`                               |`false`      |
|`dfmtSelectiveImportSpace`         |`boolean`                               |`true`       |
|`dfmtCompactLabeledStatements`     |`boolean`                               |`true`       |

## The `find` subpackage and the update system

In order to simplify the process of updating DLS, an update system is implemented.
However, the extension will need to locate a first version of DLS; this is where `dls:find` comes in.
The steps are:
- `dub fetch dls` will fetch the latest version of DLS
- `dub run --quiet dls:find` will output the directory to its parent DLS package
- `dub build --build=release` launched in the just acquired DLS directory will build DLS (notifying the user before and after the build might be a good idea, as it can take several minutes)
- The `dls` executable will now be right under the same directory

__IMPORTANT__: when building DLS on Windows, `--arch=x86_mscoff` must be added to the arguments for the build to succeed.

After this, the Language Client has to listen to the `dls/updatedPath` notification.
This notification, sent by the server after every update, will be the path to the new DLS executable.
Otherwise nothing specific is required on the client's part regarding updates: the server will send notifications to the user when an update is available, and build its next version in parallel to responding to requests.

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

As support for messages regarding workspace folders are not yet supported in Visual Studio Code (used for testing the server), dls also lacks support for multiple workspace folders for now.

## Example usage

I made a VSCode extension and an atom package using DLS:
- https://github.com/LaurentTreguier/vscode-dls
- https://github.com/LaurentTreguier/ide-dlang
