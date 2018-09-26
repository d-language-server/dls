# Changelog

This changlelog tracks meaningful changes. Various improvements and fixes are omitted.

Breaking changes will be in bold.

#### 0.13.1
- Fixed crash on non-D or bad D files outside of project source paths

### 0.13.0
- Added range formatting support
- Added on type formatting support
- Enhanced diagnostics to show errors and warnings on whole projects instead of only open documents
- Enhanced handling on non-dub projects

#### 0.12.3
- Fixed manual path importing (#10)
- Fixed changelog URL

#### 0.12.2
- Fixed error on go-to-definition

#### 0.12.1
- Fixed error on symbol highlighting

### 0.12.0
- __Removed custom message using old naming__
- Added support for automatically picking up `.editorconfig` files when formatting
- Enhanced formatting to only edit specific portions of documents instead of replacing the whole buffer
- Enhanced go-to-definition, find references and highlighting to work with overloaded methods and such

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
- Fixed issues with dependency handling (#5)
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
- Fixed subpackages missing completions from libraries (#4)

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
- Fixed error when trying to fetch completions right after a parenthesis (#2)
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
- Fixed older dls binaries not being removed when upgrading
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
- Enhanced resilience on server exceptions (dls will only crash on errors and never on exceptions)
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
- Enhanced go-to-definition: the range of the symbol is now used instead of the whole line
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
- Added go-to-definition support
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
