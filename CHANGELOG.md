# Changelog

All notable changes to this project are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Fixed

- **Installer now supports Nautilus 50+ (Nautilus 4.1 typelib).**
  Nautilus 50 ships `Nautilus-4.1.typelib`, not `Nautilus-4.0.typelib`. The
  installer's bridge check and the extension both hardcoded
  `gi.require_version("Nautilus", "4.0")`, which failed on current GNOME with
  `ValueError: Namespace Nautilus not available for version 4.0`. The extension
  and the installer now auto-detect the installed version via
  `gi.Repository.get_default().enumerate_versions("Nautilus")` and use the
  highest one. Survives future minor version bumps within the 4.x line.
  ([#43bfcb8](https://github.com/EstebanForge/nautilus-backspace-nav/commit/43bfcb8))

- **Installer now probes the system Python, not bare `python3` on PATH.**
  On machines with a shadow Python (Homebrew/Linuxbrew, pyenv, conda, uv, asdf),
  `python3` resolves to an interpreter that lacks the `gi` module — Fedora's
  `python3-gobject` RPM only installs into the system site-packages. This caused
  a false-negative bridge check on such machines, even though the extension
  worked fine (nautilus-python embeds the system interpreter it was compiled
  against). The installer now uses `/usr/bin/python3` when present.
  ([#bf031e6](https://github.com/EstebanForge/nautilus-backspace-nav/commit/bf031e6))

- **Installer installs PyGObject (`python3-gobject`) alongside `nautilus-python`.**
  The `nautilus-python` package does not always pull PyGObject as a dependency
  (notably on Fedora 44). The installer now installs the companion `gi` package
  explicitly per backend: `python3-gobject` (dnf), `python3-gi` (apt),
  `python-gobject` (pacman), `python3-gobject` (zypper),
  `dev-python/pygobject` (emerge).
  ([#f977ea3](https://github.com/EstebanForge/nautilus-backspace-nav/commit/f977ea3))

- **Installer surfaces the real Python exception instead of a generic message.**
  The bridge check used `2>&1` and swallowed the actual `ValueError` /
  `ModuleNotFoundError`, then printed a generic "check your distro package".
  It now prints the raw traceback and classifies it: missing `gi` vs. missing
  Nautilus typelib vs. shadow-Python PATH issue.
  ([#2e123c7](https://github.com/EstebanForge/nautilus-backspace-nav/commit/2e123c7))

### Added

- `.gitignore` for `__pycache__/`.
