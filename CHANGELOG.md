# Changelog

This changlelog tracks meaningful changes. Various improvements and fixes are omitted.

Breaking changes will be in bold.

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
