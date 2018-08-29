# D Language Server

[![GitHub](https://img.shields.io/github/license/d-language-server/dls.svg?style=social)](https://www.gnu.org/licenses/gpl.html)

|DUB|Travis|AppVeyor|
|---|------|--------|
|[![DUB](https://img.shields.io/dub/v/dls.svg?style=flat-square)](https://code.dlang.org/packages/dls)|[![Travis](https://img.shields.io/travis/d-language-server/dls.svg?style=flat-square)](https://travis-ci.org/d-language-server/dls)|[![AppVeyor](https://img.shields.io/appveyor/ci/dlanguageserver/dls.svg?style=flat-square)](https://ci.appveyor.com/project/dlanguageserver/dls)

### LSP compliance: `3.12`

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
- Symbol renaming at module level (not accross entire projects)
- Random, frustrating crashes

Dub packages used (the stuff doing the actual hard work):

- [dcd](http://dcd.dub.pm)
- [dfmt](http://dfmt.dub.pm)
- [dscanner](http://dscanner.dub.pm)
- [dsymbol](http://dsymbol.dub.pm)
- [dub](http://dub.dub.pm)
- [emsi_containers](http://emsi_containers.dub.pm)
- [inifiled](http://inifiled.dub.pm)
- [libddoc](http://libddoc.dub.pm)
- [libdparse](http://libdparse.dub.pm)
- [msgpack-d](http://msgpack-d.dub.pm)
- [stdx-allocator](http://stdx-allocator.dub.pm)

## Usage

Some editors may need DLS to be [installed manually](#installing) (don't worry, it's easy).

- Visual Studio Code: [install the extension](https://marketplace.visualstudio.com/items?itemName=LaurentTreguier.vscode-dls)
- Atom: [install the package](https://atom.io/packages/ide-dlang)
- Sublime Text (using [tomv654's LSP client](https://github.com/tomv564/LSP)):
    ```json
    "clients":
    {
        "dls":
        {
            "command":
            [
                "[path to dls executable]"
            ],
            "enabled": true,
            "languageId": "d",
            "scopes":
            [
                "source.d"
            ],
            "syntaxes":
            [
                "Packages/D/D.sublime-syntax"
            ]
        }
    }
    ```

DLS should work with other editors, but it may have some quirks.
If it's not working with your editor of choice, [submit an issue](https://github.com/d-language-server/dls/issues/new)!

## Installing

You can run `dub fetch dls` and then `dub run dls:bootstrap` to install dls.
The second command will output a path that will always point to the latest DLS executable.
DLS will automatically update itself whenever a new version is out.

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

## Server initialization options

DLS supports a few custom initialization options in the `InitializeParams.initializationOptions` object sent with the `initialize` request:

```typescript
interface InitializationOptions: {
    autoUpdate?: boolean;
    capabilities?: {
        hover?: boolean;
        completion?: boolean;
        definition?: boolean;
        documentHighlight?: boolean;
        documentSymbol?: boolean;
        workspaceSymbol?: boolean;
        documentFormatting?: boolean;
        rename?: boolean;
    }
}
```

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
If `dub.json` and `dub.sdl` are also watched, `dub.selections.json` can be regenerated on demand.
Watching `*.ini` allows DLS to monitor D-Scanner config files, even if the name is changed in the config and isn't `dscanner.ini`.

## Custom messages

Since the LSP defines messages with methods starting in `$/` to be implementation dependant, DLS uses `$/dls` as a prefix for custom messages.

|Message                                |Type        |Parameters            |Description                                                                |
|---------------------------------------|------------|----------------------|---------------------------------------------------------------------------|
|`$/dls/upgradeDls/didStart`            |Notification|`TranslationParams`   |Sent when the upgrade process starts                                       |
|`$/dls/upgradeDls/didStop`             |Notification|`null`                |Sent when the upgrade process stops                                        |
|`$/dls/upgradeDls/didChangeTotalSize`  |Notification|`DlsUpgradeSizeParams`|Sent during the download, with the total size of the upgrade download      |
|`$/dls/upgradeDls/didChangeCurrentSize`|Notification|`DlsUpgradeSizeParams`|Sent during the download, with the current size of the upgrade download    |
|`$/dls/upgradeDls/didExtract`          |Notification|`TranslationParams`   |Sent when the download is finished and the contents are written on the disk|
|`$/dls/upgradeSelections/didStart`     |Notification|`TranslationParams`   |Sent when DLS starts upgrading dub.selections.json                         |
|`$/dls/upgradeSelections/didStop`      |Notification|`null`                |Sent when DLS has finished upgrading dub.selections.json                   |

```typescript
interface TranslationParams {
    tr: string;
}

interface DlsUpgradeSizeParams extends TranslationParams {
    size: number;
}
```

## Contributing

### Translations

The file `i18n/data/translations.json` contains localization strings.
Adding new strings is straightforward, simply add new entries in the `title` objects with the locale identifier as key and the translated string as value.
