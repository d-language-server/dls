# D Language Server

_This is a work in progress..._

DLS implements the server side of the [Language Server Protocol (LSP)](https://microsoft.github.io/language-server-protocol/) for the [D programming language](https://dlang.org). It does not contain any language feature itself (yet), but uses existing components and provides an interface to work with the LSP.
It currently provides:
- formatting using [DFMT](https://github.com/dlang-community/dfmt)
- code completion using [DCD](https://github.com/dlang-community/DCD)

## Client side configuration

All these keys should be formatted as `d.dls.[section].[key]` (e.g. `d.dls.formatter.endOfLine`).

|Section: `general`|Type      |Default value|
|------------------|----------|-------------|
|`importPaths`     |`string[]`|`[]`         |

|Section: `formatter`               |Type                                    |Default value|
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

## Caveats

The server may delegate a few operations to the client-side extension dpending on the language client's capabilities.
The client should watch these files for the server to work properly:
- `dub.selections.json`
- `dub.json`
- `dub.sdl`

If the client supports dynamic registration of the `workspace/didChangeWatchedFiles` method, then the server will automatically register file watching.
If the client doesn't support dynamic registration however, the client-side extension will need to manually do it.
The server needs to know at least when `dub.selections.json` files change to properly provide completion support.
If `dub.json` and `dub.sdl` are also watched, `dub.selections.json` will automatically be regenerated and then it will be used for completion support.

As support for messages regarding workspace folders are not yet supported in Visual Studio Code (used for testing the server), dls also lacks support for multiple workspace folders for now.

## Example usage

Below is the code of a minimal Visual Studio Code extension using a hardcoded path to the dls binary:

```typescript
'use strict';

import * as vscode from 'vscode';
import * as lc from 'vscode-languageclient';

export function activate(context: vscode.ExtensionContext) {
    const serverOptions: lc.ServerOptions = {
        command: 'path/to/the/dls/binary'
    };
    const clientOptions: lc.LanguageClientOptions = {
        documentSelector: [{ scheme: 'file', language: 'd' }],
        synchronize: {
            configurationSection: 'd.dls'
        }
    };
    const client = new lc.LanguageClient('vscode-dls', 'D Language', serverOptions, clientOptions);
    context.subscriptions.push(client.start());
}

export function deactivate() {
}
```

Extract from the `properties` section of the `package.json` file:

```json
{
    "title": "D",
    "properties": {
        "d.dls.general.importPaths": {
            "type": "array",
            "default": []
        },
        "d.dls.formatter.endOfLine": {
            "enum": [
                "lf",
                "cr",
                "crlf"
            ],
            "default": "lf"
        },
        "d.dls.formatter.maxLineLength": {
            "type": "number",
            "default": 120
        },
        "d.dls.formatter.dfmtBraceStyle": {
            "enum": [
                "allman",
                "otbs",
                "stroustrup"
            ],
            "default": "allman"
        },
        "d.dls.formatter.dfmtSoftMaxLineLength": {
            "type": "number",
            "default": 80
        },
        "d.dls.formatter.dfmtAlignSwitchStatements": {
            "type": "boolean",
            "default": true
        },
        "d.dls.formatter.dfmtOutdentAttributes": {
            "type": "boolean",
            "default": true
        },
        "d.dls.formatter.dfmtSplitOperatorAtLineEnd": {
            "type": "boolean",
            "default": false
        },
        "d.dls.formatter.dfmtSpaceAfterCast": {
            "type": "boolean",
            "default": true
        },
        "d.dls.formatter.dfmtSpaceAfterKeywords": {
            "type": "boolean",
            "default": true
        },
        "d.dls.formatter.dfmtSpaceBeforeFunctionParameters": {
            "type": "boolean",
            "default": false
        },
        "d.dls.formatter.dfmtSelectiveImportSpace": {
            "type": "boolean",
            "default": true
        },
        "d.dls.formatter.dfmtCompactLabeledStatements": {
            "type": "boolean",
            "default": true
        }
    }
}
```
