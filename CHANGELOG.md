# Changelog

This changlelog tracks meaningful changes. Various improvements and fixes are omitted.

Breaking changes will be in bold.

#### 0.5.3
- Added libcurl.dll to the Windows zip archive

#### 0.5.2
- Fixed symlinks not being created on Windows 

#### 0.5.1
- Fixed constant update nagging when DLS is already at the latest version

### 0.5.0
- __Removed `telemetry/event` notification usage__
- Added support for upgrades using automatic binary builds

#### 0.4.1
- __Removed dls:find subpackage__
- Attempt to work around problems in updating on Windows

### 0.4.0
- Added symbol highlighting support
- Added completion documentation support
- Added workspace and document symbols searching support
- Added documentation on hover support
- Added dls:bootstrap to supercede dls:find
- Enhanced resilience on server exceptions (dls will only crash on errors and never on exceptions)
- Fixed (really, for good this time) the updater by pining dependency versions

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
