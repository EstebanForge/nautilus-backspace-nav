#!/usr/bin/env bash
# install.sh - One-liner installer for nautilus-backspace-nav
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/EstebanForge/nautilus-backspace-nav/main/install.sh | bash
# Or run directly:
#   ./install.sh
#
# What it does:
#   1. Detects your distro / package manager
#   2. Checks Python 3 and Nautilus 4.x are present
#   3. Installs the nautilus-python bridge if missing (asks for sudo)
#   4. Drops backspace-nav.py into ~/.local/share/nautilus-python/extensions/
#   5. Restarts Nautilus
set -euo pipefail

# --- helpers -----------------------------------------------------------------
ansi_red()    { printf '\033[31m'; }
ansi_green()  { printf '\033[32m'; }
ansi_yellow() { printf '\033[33m'; }
ansi_blue()   { printf '\033[34m'; }
ansi_bold()   { printf '\033[1m'; }
ansi_reset()  { printf '\033[0m'; }

log()    { printf '%s\n' "$*"; }
info()   { printf '%s==>%s %s\n'  "$(ansi_blue)"   "$(ansi_reset)" "$*"; }
ok()     { printf '%sOK%s %s\n'   "$(ansi_green)"  "$(ansi_reset)" "$*"; }
warn()   { printf '%s!!%s %s\n'   "$(ansi_yellow)" "$(ansi_reset)" "$*"; }
die()    { printf '%sERR%s %s\n'  "$(ansi_red)"    "$(ansi_reset)" "$*" >&2; exit 1; }

confirm() {
  # confirm "Prompt" -> 0=yes, 1=no. Auto-yes when stdin is not a TTY (pipe mode).
  local prompt="$1"
  if [[ ! -t 0 ]]; then
    return 0
  fi
  local reply
  read -r -p "$(ansi_bold)$prompt [y/N]$(ansi_reset) " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# --- 1. distro / package manager ---------------------------------------------
detect_pkg_manager() {
  if   command -v dnf    >/dev/null 2>&1; then echo "dnf:nautilus-python"
  elif command -v apt    >/dev/null 2>&1; then echo "apt:python3-nautilus"
  elif command -v pacman >/dev/null 2>&1; then echo "pacman:nautilus-python"
  elif command -v zypper >/dev/null 2>&1; then echo "zypper:python-nautilus"
  elif command -v emerge >/dev/null 2>&1; then echo "emerge:dev-python/nautilus-python"
  else echo "none:none"
  fi
}

# Companion PyGObject package (provides `import gi`) per backend. The nautilus-python
# bridge package does NOT always pull it in (notably on Fedora 44), so install explicitly.
gi_pkg_for() {
  case "$1" in
    dnf)    echo "python3-gobject" ;;
    apt)    echo "python3-gi" ;;
    pacman) echo "python-gobject" ;;
    zypper) echo "python3-gobject" ;;
    emerge) echo "dev-python/pygobject" ;;
    *)      echo "" ;;
  esac
}

# nautilus-python embeds the interpreter it was compiled against -- the SYSTEM python,
# not whatever happens to be first on PATH (pyenv/conda/linuxbrew/uv/asdf shadow it).
# Probe /usr/bin/python3 first, fall back to bare python3.
system_python() {
  if [[ -x /usr/bin/python3 ]]; then echo "/usr/bin/python3"
  else echo "python3"
  fi
}

PY3="$(system_python)"

# Probe the installed Nautilus GIR typelib version (Nautilus-4.0.typelib vs 4.1.typelib
# vs ...). Nautilus 50 bumped the API minor to 4.1, so hardcoding '4.0' fails on current
# GNOME. Returns the highest installed version, or empty if none.
nautilus_gir_version() {
  "$PY3" -c 'import gi; vs=gi.Repository.get_default().enumerate_versions("Nautilus"); print(vs[-1] if vs else "")' 2>/dev/null
}

# Show the real exception and classify it. Never swallow the error, never guess from
# the Python version alone (that misclassified a missing-gi as the namespace bug).
show_nautilus_python_error() {
  local err py_ver nautilus_ver gir_ver sys_err
  gir_ver="$(nautilus_gir_version)"
  err="$("$PY3" -c "import gi; gi.require_version('Nautilus', '${gir_ver:-4.0}'); from gi.repository import Nautilus" 2>&1 >/dev/null || true)"
  py_ver="$("$PY3" -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null || echo unknown)"
  nautilus_ver="${nautilus_version:-unknown}"
  warn "Raw diagnostics from $PY3:"
  printf '%s\n' "$err" >&2
  warn "Detected: python=${py_ver} nautilus=${nautilus_ver} gir_version=${gir_ver:-none}"
  case "$err" in
    *"No module named 'gi'"*)
      # Common cause: a shadow python (pyenv/conda/linuxbrew/uv) on PATH hides system gi.
      # Distinguish that from a genuinely missing package by checking /usr/bin/python3 too.
      if [[ "$PY3" != "/usr/bin/python3" && -x /usr/bin/python3 ]]; then
        sys_err="$(/usr/bin/python3 -c 'import gi' 2>&1 || true)"
        if [[ -z "$sys_err" ]]; then
          die "PyGObject (gi) is installed for the system Python (/usr/bin/python3), but your PATH resolves '$PY3' first, and that interpreter lacks gi. nautilus-python uses the system interpreter anyway, so the extension should still work. If not, fix PATH or 'hash -r' and re-run."
        fi
      fi
      die "PyGObject (the python 'gi' module) is missing. Install it (dnf: python3-gobject, apt: python3-gi, pacman: python-gobject) and re-run." ;;
    *"Namespace Nautilus not available"*)
      die "Nautilus GIR typelib not found. Install nautilus-extensions (or equivalent) for your Nautilus version and re-run." ;;
    *)
      die "nautilus-python is installed but not importable. See the error above." ;;
  esac
}

# is the nautilus-python bridge importable? (silent check, uses system python + detected GIR version)
has_nautilus_python() {
  local gir_ver
  gir_ver="$(nautilus_gir_version)"
  [[ -n "$gir_ver" ]] || return 1
  "$PY3" -c "import gi; gi.require_version('Nautilus', '$gir_ver'); from gi.repository import Nautilus" >/dev/null 2>&1
}

# --- 2. preflight: python3 ----------------------------------------------------
command -v python3 >/dev/null 2>&1 || die "Python 3 is required but not found. Install it first."

# --- 3. nautilus presence + version ------------------------------------------
if ! command -v nautilus >/dev/null 2>&1; then
  die "nautilus executable not found. Install GNOME Files (nautilus) first."
fi

nautilus_version="$(nautilus --version 2>/dev/null | awk '{print $3}')" || nautilus_version=""
[[ -n "$nautilus_version" ]] || die "Could not determine Nautilus version."

nautilus_major="${nautilus_version%%.*}"
if [[ "$nautilus_major" -lt 42 ]]; then
  die "Nautilus ${nautilus_version} detected. This extension requires Nautilus 42+ (libnautilus-extension-4)."
fi
ok "Nautilus ${nautilus_version} detected."

# --- 4. nautilus-python bridge -----------------------------------------------
if has_nautilus_python; then
  ok "nautilus-python bridge already importable."
else
  IFS=: read -r pm pkg <<<"$(detect_pkg_manager)"
  if [[ "$pm" == "none" ]]; then
    die "nautilus-python is missing and no supported package manager (dnf/apt/pacman/zypper/emerge) was found."
  fi
  gi_pkg="$(gi_pkg_for "$pm")"
  info "nautilus-python bridge is missing (would install: $pkg${gi_pkg:+ and $gi_pkg} via $pm)."
  confirm "Install it now (requires sudo)?" || die "Cannot continue without nautilus-python. Aborting."

  case "$pm" in
    dnf)    sudo dnf install -y "$pkg" $gi_pkg ;;
    apt)    sudo apt update && sudo apt install -y "$pkg" $gi_pkg ;;
    pacman) sudo pacman -S --noconfirm "$pkg" $gi_pkg ;;
    zypper) sudo zypper --non-interactive install "$pkg" $gi_pkg ;;
    emerge) sudo emerge -av "$pkg" $gi_pkg ;;
  esac

  has_nautilus_python || { show_nautilus_python_error; }
  ok "nautilus-python bridge installed."
fi

# --- 5. locate backspace-nav.py (next to this script or via download) --------
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
src="$script_dir/backspace-nav.py"
if [[ ! -f "$src" ]]; then
  info "backspace-nav.py not found alongside installer. Downloading latest from GitHub..."
  tmp="$(mktemp -d)"
  src="$tmp/backspace-nav.py"
  curl -fsSL "https://raw.githubusercontent.com/EstebanForge/nautilus-backspace-nav/main/backspace-nav.py" -o "$src" \
    || die "Failed to download backspace-nav.py"
fi

# --- 6. install ---------------------------------------------------------------
dest_dir="$HOME/.local/share/nautilus-python/extensions"
mkdir -p "$dest_dir"
cp -f "$src" "$dest_dir/backspace-nav.py"
chmod 644 "$dest_dir/backspace-nav.py"
ok "Installed to $dest_dir/backspace-nav.py"

# --- 7. restart nautilus ------------------------------------------------------
if confirm "Restart Nautilus now (any open windows will close)?"; then
  nautilus -q 2>/dev/null || true
  ok "Nautilus restarted."
fi

printf '\n%sDone.%s Open Nautilus and press %sBackspace%s to go up one directory.\n' \
  "$(ansi_green)" "$(ansi_reset)" "$(ansi_bold)" "$(ansi_reset)"
