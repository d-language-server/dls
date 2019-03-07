# D Language Server

[![GitHub](https://img.shields.io/github/license/d-language-server/dls.svg?style=social)](https://www.gnu.org/licenses/gpl.html)

|DUB|Travis|AppVeyor|
|---|------|--------|
|[![DUB](https://img.shields.io/dub/v/dls.svg?style=flat-square)](https://code.dlang.org/packages/dls)|[![Travis](https://img.shields.io/travis/d-language-server/dls.svg?style=flat-square)](https://travis-ci.org/d-language-server/dls)|[![AppVeyor](https://img.shields.io/appveyor/ci/dlanguageserver/dls.svg?style=flat-square)](https://ci.appveyor.com/project/dlanguageserver/dls)

__LSP compliance: `3.14`__

_This is still a work in progress; there might still be bugs and crashes_

DLS implements the server side of the [Language Server Protocol (LSP)](https://microsoft.github.io/language-server-protocol) for the [D programming language](https://dlang.org).
It doesn't do much itself (yet), and rather uses already available components, and provides an interface to work with the LSP.
Current features include:

- Code completion
- Going to symbol definition
- Finding references
- Symbol renaming
- Error checking
- Code formatting (document, range and on-type)
- Symbol listing (current document and workspace-wide)
- Symbol highlighting
- Documentation on hover
- Random, frustrating crashes

Packages used (the stuff doing the actual hard work):

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

### Installation

If you are using VSCode, Visual Studio or Atom, you can [skip this step](#some-common-editors) and install the corresponding extension.

Simply run:
```shell
dub fetch dls
dub run dls:bootstrap
```
to install to download and install the latest binary release.
The second command will output the executable's path.
DLS will automatically update itself whenever a new version is out.

### Some common editors

- Visual Studio Code: [install the extension](https://marketplace.visualstudio.com/items?itemName=LaurentTreguier.vscode-dls)
- Visual Studio: [install the extension](https://marketplace.visualstudio.com/items?itemName=LaurentTreguier.visual-studio-dlang)
- Atom: [install the package](https://atom.io/packages/ide-dlang)
- Sublime Text (using [tomv654's LSP client](https://github.com/tomv564/LSP)):
    ```json
    {
        "clients": {
            "dls": {
                "command": ["<PATH TO DLS EXECUTABLE>"],
                "enabled": true,
                "languageId": "d",
                "scopes": ["source.d"],
                "syntaxes": ["Packages/D/D.sublime-syntax"]
            }
        }
    }
    ```
- Vim/Neovim (using [autozimu's LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim)):
    ```vim
    let g:LanguageClient_serverCommands = {
        \ 'd': ['<PATH TO DLS EXECUTABLE>']
        \ }
    ```
- Emacs (using [d-mode](https://github.com/Emacs-D-Mode-Maintainers/Emacs-D-Mode) and [lsp-mode](https://github.com/emacs-lsp/lsp-mode)):
    ```elisp
    (require 'lsp)
    (add-hook 'd-mode-hook #'lsp)
    (lsp-register-client
        (make-lsp-client
            :new-connection (lsp-stdio-connection '("<PATH TO DLS EXECUTABLE>"))
            :major-modes '(d-mode)
            :server-id 'dls))
    ```

If it's not working with your editor of choice, [submit an issue](https://github.com/d-language-server/dls/issues/new)!

### Notes about FreeBSD

DLS is usable using FreeBSD's Linux binary compatibility system.
The main steps to enable Linux binary compatibility are:
- Adding `enable_linux="YES"` to `/etc/rc.conf`
- Running `kldload linux` (only the 32bit binaries will be used; the 64bit Linux binaries crash on FreeBSD)
- Running `pkg install emulators/linux_base-c7` (or `emulators/linux_base-c6`)
- Running `pkg install ftp/linux-c7-curl` (or `ftp/linux-c6-curl`)
- Adding the following lines to `/etc/fstab`:
    ```
    linprocfs	/compat/linux/proc		linprocfs	rw				0	0
    linsysfs	/compat/linux/sys		linsysfs	rw				0	0
    tmpfs		/compat/linux/dev/shm	tmpfs		rw,mode=1777	0	0
    ```
- Running:
    ```shell
    mount /compat/linux/proc
    mount /compat/linux/sys
    mount /compat/linux/dev/shm
    ```

More detailed information can be found in the [FreeBSD documentation](https://www.freebsd.org/doc/handbook/linuxemu-lbc-install.html).

### Command line options

Some command line options exist to control the behavior of DLS:
- `--stdio`: use standard input and output streams for communication (default behavior)
- `--socket=<PORT>` or `--tcp=<PORT>`: use a socket to connect on the specified port for communication

## Client side configuration

All these keys should be formatted as `d.dls.[section].[key]` (e.g. `d.dls.format.endOfLine`).

|Section: `symbol`|Type      |Default value|
|-----------------|----------|-------------|
|`importPaths`    |`string[]`|`[]`         |
|`listAllSymbols` |`boolean` |`false`      |

|Section: `analysis`|Type    |Default value   |
|-------------------|----------|----------------|
|`configFile`       |`string`  |`"dscanner.ini"`|
|`filePatterns`     |`string[]`|`[]`            |

|Section: `format`                   |Type                                    |Default value|Builtin|DFMT|
|------------------------------------|----------------------------------------|-------------|-------|----|
|`engine`                            |`"dfmt"` or `"indent"`                  |`"dfmt"`     |       |    |
|`endOfLine`                         |`"lf"` or `"cr"` or `"crlf"`            |`"lf"`       |       |✔   |
|`insertFinalNewline`                |`boolean`                               |`true`       |       |✔   |
|`trimTrailingWhitespace`            |`boolean`                               |`true`       |✔      |    |
|`maxLineLength`                     |`number`                                |`120`        |       |✔   |
|`softMaxLineLength`                 |`number`                                |`80`         |       |✔   |
|`braceStyle`                        |`"allman"` or `"otbs"` or `"stroustrup"`|`"allman"`   |       |✔   |
|`spaceAfterCasts`                   |`boolean`                               |`true`       |       |✔   |
|`spaceAfterKeywords`                |`boolean`                               |`true`       |✔      |    |
|`spaceBeforeAAColons`               |`boolean`                               |`false`      |✔      |    |
|`spaceBeforeFunctionParameters`     |`boolean`                               |`false`      |✔      |✔   |
|`spaceBeforeSelectiveImportColons`  |`boolean`                               |`true`       |✔      |✔   |
|`alignSwitchStatements`             |`boolean`                               |`true`       |       |    |
|`compactLabeledStatements`          |`boolean`                               |`true`       |       |✔   |
|`outdentAttributes`                 |`boolean`                               |`true`       |       |    |
|`splitOperatorsAtLineEnd`           |`boolean`                               |`false`      |       |✔   |
|`templateConstraintsStyle`          |`"conditionalNewlineIndent"` or `"conditionalNewline"` or `"alwaysNewline"` or `"alwaysNewlineIndent"`|`"conditionalNewlineIndent"`| |✔|
|`templateConstraintsSingleIndent`   |`boolean`                               |`false`      |       |✔   |

## Server initialization options

DLS supports a few custom initialization options in the `InitializeParams.initializationOptions` object sent with the `initialize` request:

```typescript
interface InitializationOptions: {
    autoUpdate?: boolean = true;        // Enable auto-updating
    preReleaseBuilds?: boolean = false; // Enable pre-release updates
    safeMode?: boolean = false;         // Disable processing multiple requests in parallel
    catchErrors?: boolean = false;      // Catch and ignore errors (WARNING: UNSAFE)
    logFile?: string = "";              // Path to a file to log DLS operations
    capabilities?: {
        hover?: boolean = true;                     // Enable hover
        completion?: boolean = true;                // Enable completion
        definition?: boolean = true;                // Enable go-to-definition
        typeDefinition?: boolean = true;            // Enable go-to-type-definition
        references?: boolean = true;                // Enable references search
        documentHighlight?: boolean = true;         // Enable symbol highlighting
        documentSymbol?: boolean = true;            // Enable document symbol search
        workspaceSymbol?: boolean = true;           // Enable workspace symbol search
        codeAction?: boolean = true;                // Enable code actions
        documentFormatting?: boolean = true;        // Enable formatting
        documentRangeFormatting?: boolean = true;   // Enable range formatting
        documentOnTypeFormatting?: boolean = true;  // Enable on type formatting
        rename?: boolean = true;                    // Enable renaming
    },
    symbol?: {
        autoImports?: boolean = true;   // Automatically import projects and their dependencies
    }
}
```

## Caveats

The server may delegate a few operations to the client-side extension depending on the language client's capabilities.
The client should watch these files for the server to work properly:

- `dub.selections.json`
- `dub.json`
- `dub.sdl`
- `.gitmodules`
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
Adding new strings is straightforward, simply add new entries in the `message` objects with the locale identifier as key and the translated string as value.

### Which branch should be targeted by pull requests ?

Is it work on a new feature ? Then the `master` branch should be targeted.
Is it a fix ? Then the latest `release/v<MAJOR>.<MINOR>.x` branch should be targeted.

## Other links

- https://github.com/Pure-D/code-d: a D extension for VSCode
- https://github.com/Pure-D/serve-d: a language server based on [workspace-d](https://github.com/Pure-D/workspace-d)
- https://github.com/dlang/visuald: an extension seamlessly integrating into Visual Studio
