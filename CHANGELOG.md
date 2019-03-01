# Changelog

This changlelog tracks meaningful changes. Various improvements and fixes are omitted.

Breaking changes will be in bold.

#### 0.22.5
- Fixed non-ascii characters handling ([#33](https://github.com/d-language-server/dls/issues/33))

#### 0.22.4
- Fixed broken stdio communication (yet again)

#### 0.22.3
- Fixed DLS waiting for input with `--help` or `--version`

#### 0.22.2
- Fixed D-Scanner config files not always being picked up ([#30](https://github.com/d-language-server/dls/issues/30))
- Fixed potentially wrong text insertion in code actions

#### 0.22.1
- Removed a test temporarily (see https://github.com/dlang/dmd/pull/9380)

### 0.22.0
- Added help message for command line options
- Added command line options for initialization options ([#28](https://github.com/d-language-server/dls/issues/28))
- Added back inlining to releases
- Fixed references not found for one-letter long symbols

#### 0.21.12
- Fixed crash on diagnostics associated to no line/column pair ([#25](https://github.com/d-language-server/dls/issues/25))
- Updated libraries:
    - `libdparse`: `0.10.12` => `0.10.13`
    - `msgpack-d`: `1.0.0-beta.7` => `1.0.0-beta.8`

#### 0.21.11
- Enhanced GNOME Builder compatibility

#### 0.21.10
- Added `autoImports` init option to disable automatically importing projects and their dependencies ([#24](https://github.com/d-language-server/dls/issues/24))

#### 0.21.9
- Fixed crash on `importPaths` configuration set to relative paths ([#23](https://github.com/d-language-server/dls/issues/23))

#### 0.21.8
- Fixed broken stdio communication

#### 0.21.7
- Fixed stdio communication on Windows hanging by applying a [fix from serve-d](https://github.com/Pure-D/serve-d/commit/eeb4c0875049be2bd7bd1f00019071413bee93ca)

#### 0.21.6
- Fixed document contents not being saved internally ([#22](https://github.com/d-language-server/dls/issues/22))
- Updated libraries:
    - `dub`: `1.12.1` => `1.13.0`

#### 0.21.5
- Fixed memory leaked on cross-platform cancellation support with stdio communication

#### 0.21.4
- Removed cross-platform cancellation support temporarily to fix a memory leak

#### 0.21.3
- Fixed error about missing `vcruntime140.dll` on some Windows systems by using Microsoft's linker for Windows releases

#### 0.21.2
- Removed inlining from releases

#### 0.21.1
- Fixed stdio communication getting stuck in an infinite loop, preventing DLS from shutting down

### 0.21.0
- Enhanced stdio communication to support cancelling long running operations on Windows
- Enhanced file analysis to ignore folders whose name starts with a dot
- Enhanced `dls:bootstrap` backwards compatibility back to DMD `2.067`
- Updated libraries:
    - `dcd`: `0.9.13` => `0.10.2`
    - `dfmt`: `0.8.3` => `0.9.0`
    - `dscanner`: `0.8.3` => `0.9.0`
    - `dsymbol`: `0.4.8` => `0.5.7`
    - `libddoc`: `0.4.0` => `0.5.1`
    - `libdparse`: `0.9.10` => `0.10.12`

#### 0.20.2
- Fixed relative import paths not being handled ([#19](https://github.com/d-language-server/dls/issues/19))

#### 0.20.1
- Enhanced socket communication by setting the `TCP_NODELAY` flag

### 0.20.0
- Added support for druntime + phobos installations in ~/dlang on Posix systems
- Added limited support for FreeBSD using binary releases using the Linux compatibility module
- Added option to list all symbols from a document, including local variables and parameters
- Added support for cancelling long running operations
- Fixed formatting only using `.editorconfig` files present at a project root

#### 0.19.2
- Fixed `dls:bootstrap` not printing a newline after DLS' path ([#18](https://github.com/d-language-server/dls/issues/18))

#### 0.19.1
- Fixed data possibly being sent in socket multiple times
- Fixed symbol list being empty when encountering an anonymous symbol
- Fixed symbol list sometimes containing garbage instead of correct names

### 0.19.0
- Added ability to ignore pre-release builds unless the pre-release init option is set
- Added ability to automatically import git submodules in non-dub projects
- Enhanced range formatting to apply edits affecting the range and not the line containing the range
- Enhanced Linux builds by upgrading the Travis image from trusty to Xenial
- Enhanced file logging by ensuring its parent directory is created at startup
- Fixed socket communication quickly going awry

#### 0.18.3
- Fixed import paths being cleared when removed from a project even if another still used it

#### 0.18.2
- Updated libraries:
    - `dub`: `1.12.0` => `1.12.1-rc.1` ([#17](https://github.com/d-language-server/dls/issues/17))

#### 0.18.1
- Fixed dub dependency for the BuilKite CI ([#17](https://github.com/d-language-server/dls/issues/17))
- Fixed completions when the cursor is at the very end of a source file

### 0.18.0
- Added test suite skeleton to start fighting against regressions
- Fixed diagnostics being sent before responding to the initialization request
- Fixed some initialization properties assumed to not be unspecified, potentially leading to crashes
- Fixed exit code always being one even if exiting without a shutdown request
- Fixed some wrong error codes
- Fixed possible crash upon receiving an invalid worksapce URI

#### 0.17.1
- Fixed logger not cleaning up the log file before writing to it
- Fixed directories not being cleared from DCD's cache after being deleted

### 0.17.0
- Added ability to use DLS with sockets instead of stdio
- Enhanced unknown custom notification handling to ignore them instead of producing an error
- Enhanced diagnostic publishing to pick up `.dscanner.ini` files automatically
- Fixed comment handling with multiple `@suppress()`
- Updated libraries:
    - `emsi_containers`: `0.8.0-alpha.10` => `0.8.0-alpha.11`

#### 0.16.4
- Fixed crash for workspaces containing directories ending in `.d` ([#16](https://github.com/d-language-server/dls/issues/16))

#### 0.16.3
- Fixed buggy import paths clearing

#### 0.16.2
- Fixed unneeded import paths not being cleared

#### 0.16.1
- Fixed Travis build for dlang/ci ([#15](https://github.com/d-language-server/dls/issues/15))

### 0.16.0
- Added option to log operations to a file
- Enhanced out-of-source-tree diagnostic handling
- Enhanced Linux x86 binary release by using LDC instead of DMD
- Enhanced error messages to show full stacktrace

#### 0.15.5
- Fixed non-dub project directories not being imported

#### 0.15.4
- Fixed non-project files being scanned when they change
- Fixed truncated symbol name when preparing a rename
- Fixed duplicate ranges when looking for references causing errors during certains renames

#### 0.15.3
- Fixed crash with document symbols
- Updated libraries:
    - `dub`: `1.11.0` => `1.12.0`

#### 0.15.2
- Updated libraries:
    - `dfmt`: `0.8.2` => `0.8.3`
    - `emsi_containers`: `0.8.0-alpha.9` => `0.8.0-alpha.10`

#### 0.15.1
- Fixed Travis build for dlang/ci

### 0.15.0
- Added better code action support for editors complying to older LSP specs
- Fixed missing completions for compiler-generated symbols
- Updated libraries:
    - `dcd`: `0.9.10` => `0.9.13`
    - `dscanner`: `0.5.8` => `0.5.11`
    - `dsymbol`: `0.3.8` => `0.4.8`
    - `libddoc`: `0.3.0-beta.1` => `0.4.0`
    - `libdparse`: `0.8.8` => `0.9.10`

#### 0.14.3
- Added option to forcefully ignore errors ([#12](https://github.com/d-language-server/dls/issues/12))

#### 0.14.2
- Fixed code action messages overflowing Atom's buttons

#### 0.14.1
- Fixed diagnostics for opened documents not being updated with editors that don't support file watching

### 0.14.0
- Added code action for project-wide warning disabling
- Added code action for line-specific warning disabling
- Updated libraries:
    - `stdx-allocator`: `2.77.2` => `2.77.4`

#### 0.13.3
- Fixed potential crash on go to type definition

#### 0.13.2
- Fixed diagnostics not being updated for unopened files

#### 0.13.1
- Fixed crash on non-D or bad D files outside of project source paths

### 0.13.0
- Added range formatting support
- Added on type formatting support
- Enhanced diagnostics to show errors and warnings on whole projects instead of only open documents
- Enhanced handling of non-dub projects ([#11](https://github.com/d-language-server/dls/issues/11))

#### 0.12.3
- Fixed manual path importing ([#10](https://github.com/d-language-server/dls/issues/10))
- Fixed changelog URL

#### 0.12.2
- Fixed error on go to definition

#### 0.12.1
- Fixed error on symbol highlighting

### 0.12.0
- __Removed custom message using old naming__
- Added support for automatically picking up `.editorconfig` files when formatting
- Added go to type definition support
- Enhanced formatting to only edit specific portions of documents instead of replacing the whole buffer
- Enhanced go to definition, find references and highlighting to work with overloaded methods and such

#### 0.11.2
- Fixed crash on file diagnostics generation

#### 0.11.1
- Fixed position validation error shown on completion at the end of a line

### 0.11.0
- Added find references support
- Added project-wide renaming support
- Enhanced dub selections upgrade to show a message on error

#### 0.10.4
- Fixed potential crash with document symbols

#### 0.10.3
- Fixed crash on garbage collection (for good this time)
- Fixed rename feature activation not taken into account

#### 0.10.2
- Fixed module constructors/destructors missing in symbol search

#### 0.10.1
- Fixed crashes with document symbols

### 0.10.0
- Added hierarchical symbols support
- Enhanced updating to be automatic
- Enhanced `Upgrade selections` message to be shown only when dependencies actually changed
- Fixed wrong position when searching for invariants in symbol search

### 0.9.0
- __Changed custom message naming, old messages will stop being sent in a future version__
- Added license file to distributed archives
- Enhanced `dls:bootstrap` to not require admin rights on Windows

#### 0.8.3
- Fixed potential error when creating symlink on Windows if the path contains a space

#### 0.8.2
- Fixed inability to run `dls:bootstrap` on Windows when LDC is in the PATH

#### 0.8.1
- Fixed crash happening on garbage collection

### 0.8.0
- Added module-level renaming support
- Enhanced document symbols to be generated using document buffers instead of DCD's cache
- Fixed duplicate workspace symbols

#### 0.7.2
- Enhanced druntime/phobos paths search on macOS

#### 0.7.1
- Updated libraries:
    - `dcd`: `0.9.9` => `0.9.10`
    - `dscanner`: `0.5.7` => `0.5.8`

### 0.7.0
- __Changed license to GPLv3 to comply with DCD being itself under GPLv3__
- Added system locale detection
- Added French locale
- Fixed `Upgrade selections` message being shown when removing `dub.json`/`dub.sdl`
- Updated libraries:
    - `dsymbol`: `0.3.10` => `0.3.12`

#### 0.6.11
- Fixed `dls:bootstrap` exiting before symlink was created on Windows
- Fixed selections upgrade message being show upon deleting `dub.selections.json`
- Updated libraries:
    - `libdparse`: `0.8.7` => `0.8.8`

#### 0.6.10
- Fixed crash when importing dependencies

#### 0.6.9
- Enhanced binary releases by compressing them with UPX on Posix platforms
- Fixed issues with dependency handling ([#5](https://github.com/d-language-server/dls/issues/5))
- Updated libraries:
    - `dub`: `1.9.0` => `1.10.0`

#### 0.6.8
- Enhanced binary releases by using LDC for most builds
- Enhanced non-dub project handling
- Fixed log messages not being properly aligned

#### 0.6.7
- Fixed 1 hour margin handling problems with UTC offsets

#### 0.6.6
- Stopped removing older `dls` dub packages as binaries are now used
- Fixed `Upgrade selections` popup appearing when building
- Fixed subpackages missing completions from libraries ([#4](https://github.com/d-language-server/dls/issues/4))

#### 0.6.5
- Fixed instant crash at server startup

#### 0.6.4
- Fixed compatibility with Sublime Text
- Updated libraries:
    - `emsi_containers`: `0.8.0-alpha.7` => `0.8.0-alpha.9`

#### 0.6.3
- `dls:bootstrap` should now apply the same more-than-an-hour policy regarding the version it's installing as the update system
- Updated libraries:
    - `dfmt`: `0.8.1` => `0.8.2`
    - `libdparse`: `0.8.6` => `0.8.7`

#### 0.6.2
- Fixed issue with subpackages importing other subpackages

#### 0.6.1
- Fixed error when trying to fetch completions right after a parenthesis ([#2](https://github.com/d-language-server/dls/issues/2))
- Updated libraries:
    - `dcd`: `0.9.8` => `0.9.9`
    - `dscanner`: `0.5.6` => `0.5.7`
    - `dsymbol`: `0.3.9` => `0.3.10`

### 0.6.0
- Fixed updater detecting `v0.5.9` as superior to `v0.5.10`
- Updated libraries:
    - `dsymbol`: `0.3.8` => `0.3.9`

#### 0.5.10
- Added ability for clients to disable features with server init options
- Fixed symbol searching being case sensitive
- Fixed server crashing with Intellij Idea

#### 0.5.9
- Fixed issues with files containing an UTF BOM

#### 0.5.8
- Added `$/dls.upgradeSelections.*` custom notifications
- Updated libraries:
    - `dfmt`: `0.8.0` => `0.8.1`

#### 0.5.7
- Removed libcurl.dll from the Windows archive, DMD's libcurl.dll is now used

#### 0.5.6
- Fixed older DLS binaries not being removed when upgrading
- Fixed `$/dls.upgradeDls.chunkSize` notifications being spammed
- Fixed `dls:bootstrap` not necessarily using the correct libcurl.dll

#### 0.5.5
- Enhanced message logging by using LSP logging instead of stderr
- Fixed `dls:bootstrap` building DLS if the latest release was still in the process of building binaries
- Updated libraries:
    - `dscanner`: `0.5.5` => `0.5.6`
    - `dsymbol`: `0.3.7` => `0.3.8`
    - `msgpack-d`: `1.0.0-beta.6` => `1.0.0-beta.7`

#### 0.5.4
- Added symlink to libcurl.dll in `.bin` directory
- Added custom notifications documentation in README
- Updated libraries:
    - `dfmt`: `0.7.0` => `0.8.0`

#### 0.5.3
- Added libcurl.dll to the Windows zip archive

#### 0.5.2
- Fixed symlinks not being created on Windows 

#### 0.5.1
- Fixed constant update nagging when DLS is already at the latest version

### 0.5.0
- __Removed `dls/didUpdatePath` notification usage__
- __Removed `telemetry/event` notification usage__
- Added support for upgrades using automatic binary builds
- Added custom `$/dls.upgradeDls.*` notifications
- Updated libraries:
    - `dcd`: `0.9.6` => `0.9.8`
    - `dscanner`: `0.5.3` => `0.5.5`
    - `dsymbol`: `0.3.6` => `0.3.7`
    - `libdparse`: `0.8.4` => `0.8.6`
    - `stdx-allocator`: `2.77.1` => `2.77.2`

#### 0.4.1
- __Removed `dls:find` subpackage__
- Attempt to work around problems in updating on Windows

### 0.4.0
- Added symbol highlighting support
- Added completion documentation support
- Added workspace and document symbols searching support
- Added documentation on hover support
- Added `dls:bootstrap` to supercede `dls:find`
- Enhanced resilience on server exceptions (DLS will only crash on errors and never on exceptions)
- Fixed (really, for good this time) the updater by pining dependency versions
- Updated libraries:
    - `arsd-official`: `none` => `2.0.0`
    - `dcd`: `0.9.2` => `0.9.6`
    - `dscanner`: `0.5.1` => `0.5.3`
    - `dsymbol`: `0.3.0` => `0.3.6`
    - `dub`: `1.8.0` => `1.9.0`
    - `emsi_containers`: `0.6.0` => `0.8.0-alpha.7`
    - `inifiled`: `1.3.0` => `1.3.1`
    - `libdparse`: `0.8.0` => `0.8.4`
    - `stdx-allocator`: `2.77.0` => `2.77.1`

#### 0.3.1
- Added missing DFMT options
- Fixed (hopefully for good this time) the updater by using the system installed dub to build next versions of DLS
- Fixed crashes with DFMT due to the missing options

### 0.3.0
- Added linting support on file save, along with support for workspace-local D-Scanner config files
- Enhanced go to definition: the range of the symbol is now used instead of the whole line
- Enhanced automatic druntime/phobos path detection:
    - On Windows, import paths should be detected regardless of DMD's install location
    - On Linux, DLS will now also try to import paths from the DMD snap package
- Fixed server crash on exit notification
- Updated libraries:
    - `dscanner`: `none` => `0.5.1`
    - `inifiled`: `none` => `1.3.0`
    - `libddoc`: `none` => `0.3.0-beta.1`
    - `libdparse`: `0.8.0-beta.5` => `0.8.0`

#### 0.2.1
- Fixed "See what's new" button being activated even if not clicked
- Fixed dfmtSelectiveImportSpace not being respected

### 0.2.0
- __Changed the naming convention of the tools' configuration for consistency__
- __Changed from `telemetry/event` to custom `dls/didUpdatePath` notification__
- Added go to definition support
- Added guard to prevent debug builds to update
- Added "See what's new" button to message shown when a new version of DLS has been built
- Added CHANGELOG file
- Fixed potential issues with object initialization resulting in inpredictable behavior
- Fixed dependencies imports not actually working
- Updated libraries:
    - `dsymbol`: `0.3.0-beta.3` => `0.3.0`

#### 0.1.5
- Fixed crash if the client didn't send an initial `workspace/didConfigurationChange` notification
- Fixed `dub fetch` operation being done in the main thread, blocking the whole program in case of a connection problem

#### 0.1.4
- Fixed updater sending a path to a directory instead of an executable

#### 0.1.3
- Fixed `find` subpackage not being declared

#### 0.1.2
- Added `find` subpackage and the update system

#### 0.1.1
- Added dynamic file watchers registering if the client supports it
- Added README file

#### 0.1.0
- Added the base JSON-RPC messages loop and classes to implement the LSP
- Added formatting support
- Added autocompletion support
- Updated libraries:
    - `dcd`: `none` => `0.9.2`
    - `dfmt`: `none` => `0.7.0`
    - `dsymbol`: `none` => `0.3.0-beta.3`
    - `dub`: `none` => `1.8.0`
    - `emsi_containers`: `none` => `0.6.0`
    - `libdparse`: `none` => `0.8.0-beta.5`
    - `msgpack-d`: `none` => `1.0.0-beta.6`
    - `stdx-allocator`: `none` => `2.77.0`
