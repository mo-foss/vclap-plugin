# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
* Demonstration of plugin GUI using raw XCB calls.
  The GUI is currently totally non-functional.

## [0.1.3] - 2024-01-24
### Changed
* Plugin version is now source from V mod file.
* CLAP plugin functions are directly V plugin structs methods (closures).

## [0.1.2] - 2024-01-20
### Changed
* Using proper struct casting for event header when processing.
* Less copying in the example audio buffer processing.

### Added
* Logging.
* Build target for generating intermediary C form.
* Extended DEBUG flag for tracing all calls.

## [0.1.1] - 2024-01-17

### Changed
- Aligned the minimal plugin example with the template from CLAP repository.
