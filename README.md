# Nautilus Backspace Navigation Extension

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Nautilus 4.0](https://img.shields.io/badge/Nautilus-4.0-blue)
![GTK 4.0](https://img.shields.io/badge/GTK-4.0-green)

A Nautilus extension that enables (restores) backspace key navigation to go up one directory level, similar to other popular file managers.

## Why?

Because the backspace key is, for better or worse, a common way to navigate up a directory in many file managers across different OSes. Muscle memory is a powerful thing, and it can be frustrating to have to use the mouse or a two-handed keyboard shortcut to achieve the same result in modern Nautilus.

And I'm old enough to take care of myself and decide how I want to use my computer. Default options are OK, but developers shouldn't forget about users of an OS that promotes freedom of choice (and customization). Simple hidden options (gsettings) would be enough for "power users". And would be highly appreciated. 

Anyhow...

I did find other extensions online that do this, but they were either outdated (Gnome 46 and earlier) or not working properly (couldn't use the backspace key in text fields). So I decided to create my own.

This extension is designed to be simple and effective, using the native Nautilus navigation actions to ensure compatibility with all features of the file manager.

## Features

- Press backspace to navigate to parent directory
- Preserves normal backspace behavior in text fields
- Compatible with file renaming, search, and path bar operations
- Uses native Nautilus navigation actions
- Automatically attaches to new and existing windows

## Requirements

- Nautilus 4.0
- GTK 4.0
- Python 3
- nautilus-python package

Tested only on Fedora 41 with latest Gnome 47.5

## Installation

### 1. Install the required dependency:

For Fedora 41

   ```bash
   sudo dnf install nautilus-python
   ```

For Ubuntu 24.10

   ```bash
   sudo apt install python3-nautilus
   ```

For Arch Linux

   ```bash
   sudo pacman -S python-nautilus
   ```

### 2. Download and install the extension:

   ```bash
   mkdir -p ~/.local/share/nautilus-python/extensions/
   cd ~/.local/share/nautilus-python/extensions/
   wget https://raw.githubusercontent.com/EstebanForge/nautilus-backspace-nav/main/backspace-nav.py
   ```

Or you can download the script manually and put it into:

`~/.local/share/nautilus-python/extensions/`

### 3. Restart Nautilus:

   ```bash
   nautilus -q
   ```

Alternatively, log out and log back into your session.

## Usage

Simply press the Backspace key while in any Nautilus window to navigate up one directory level. The extension preserves normal backspace functionality when:

- Renaming files
- Using the search feature
- Typing in the path bar
- Any other text editing operation

## License

MIT License - See LICENSE file for details
