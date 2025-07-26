#!/usr/bin/env bash
# scripts/provision_env.sh
# Hardened, professional-grade environment provisioner for BrakeFlasher PRO
# Supports: Linux (Ubuntu/WSL2), macOS (brew), Windows via WSL2 only
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assigned
# Version: 1.1.1

set -Eeuo pipefail
trap 'echo "[ERROR] Line $LINENO failed. Exiting." >&2; exit 1' ERR
IFS=$'\n\t'

PYTHON_VERSION="${1:-3.10.12}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_NAME="brakeflash-env"

log()    { printf "[INFO]  %s\n" "$1"; }
warn()   { printf "[WARN]  %s\n" "$1"; }
error()  { printf "[ERROR] %s\n" "$1" >&2; exit 1; }
success(){ printf "[ OK ]  %s\n" "$1"; }

detect_platform() {
  case "$(uname -s)" in
    Linux*)  echo "linux" ;;
    Darwin*) echo "macos" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) error "Unsupported OS: $(uname -s)" ;;
  esac
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || error "Missing required command: $1"
}

install_pyenv() {
  if command -v pyenv >/dev/null 2>&1; then
    success "pyenv already installed"
  else
    log "Installing pyenv..."
    curl https://pyenv.run | bash
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
  fi
}

install_tk_deps_linux() {
  log "Installing Linux GUI dependencies..."
  sudo apt update -y
  sudo apt install -y \
    tk-dev libtk8.6 libx11-dev libxext-dev libxrender-dev \
    libxcb1 libxfixes-dev build-essential zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl llvm \
    libncursesw5-dev xz-utils libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
}

install_tk_deps_macos() {
  log "Installing macOS Tcl/Tk..."
  require_command brew
  brew install tcl-tk || true
  export CPPFLAGS="-I$(brew --prefix tcl-tk)/include"
  export LDFLAGS="-L$(brew --prefix tcl-tk)/lib"
  export PKG_CONFIG_PATH="$(brew --prefix tcl-tk)/lib/pkgconfig"
}

install_tk_deps() {
  case "$1" in
    linux)  install_tk_deps_linux ;;
    macos)  install_tk_deps_macos ;;
    windows)
      warn "Native Windows is not supported. Use WSL2 or install Python manually with Tkinter."
      exit 0 ;;
    *) error "Unknown platform: $1" ;;
  esac
}

build_python_with_tkinter() {
  log "Installing Python $PYTHON_VERSION with GUI support via pyenv..."
  pyenv uninstall -f "$PYTHON_VERSION" >/dev/null 2>&1 || true
  env PYTHON_CONFIGURE_OPTS="--with-tcltk" pyenv install "$PYTHON_VERSION"
  pyenv global "$PYTHON_VERSION"
}

verify_tkinter_import() {
  if python -c "import tkinter" &>/dev/null; then
    success "Tkinter module is functional"
  else
    error "Tkinter module still missing after build"
  fi
}

create_virtualenv() {
  log "Creating virtualenv: $VENV_NAME"
  pyenv virtualenv -f "$PYTHON_VERSION" "$VENV_NAME"
  pyenv activate "$VENV_NAME"
}

install_project_requirements() {
  log "Installing Python requirements"
  if [[ ! -f "$ROOT_DIR/requirements.txt" ]]; then
    warn "requirements.txt missing – creating fallback"
    echo "pyyaml" > "$ROOT_DIR/requirements.txt"
    echo "jsonschema" >> "$ROOT_DIR/requirements.txt"
  fi
  pip install --upgrade pip setuptools
  pip install -r "$ROOT_DIR/requirements.txt"
}

main() {
  PLATFORM="$(detect_platform)"
  log "Platform detected: $PLATFORM"

  install_pyenv
  install_tk_deps "$PLATFORM"
  build_python_with_tkinter
  verify_tkinter_import
  create_virtualenv
  install_project_requirements

  echo "--------------------------------------------------"
  echo " Environment provision complete"
  echo " Python        : $(python --version)"
  echo " Virtualenv    : $VENV_NAME"
  echo " Project root  : $ROOT_DIR"
  echo "--------------------------------------------------"
}

main "$@"
