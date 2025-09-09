#!/bin/sh

# ==============================================================================
#      System-wide oh-my-zsh installer
# ==============================================================================

# --- 1. Check for root privileges ---
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ This script must be run as root." >&2
  exit 1
fi

# --- 2. Check for supported Linux distributions ---
if [ -f /etc/os-release ]; then
  # Source the /etc/os-release file to get the ID variable.
  . /etc/os-release
else
  echo "❌ Could not determine OS version. (/etc/os-release not found)" >&2
  exit 1
fi

case "$ID" in
  ubuntu|debian|rocky)
    # If the OS is supported, continue
    echo "✅ Supported operating system ($ID) detected."
    ;;
  *)
    # If the OS is not supported, print a message and exit
    echo "❌ This script only supports Ubuntu, Debian, and Rocky Linux." >&2
    echo "   (Detected OS: $ID)" >&2
    exit 1
    ;;
esac


# --- Start Installation ---
# Do not run if already installed
if [ -d /oh-my-zsh ]; then
  echo "ℹ️ Oh My Zsh is already installed in /oh-my-zsh. Exiting."
  exit 0
fi

# URL for fetching files from GitHub
GH="https://raw.githubusercontent.com/KREONET/ohmyzsh/refs/heads/main/"

# Check for package manager and install dependencies
echo "Installing dependencies (git, wget)..."
if [ -x "$(which apt-get)" ]; then
  apt-get update && apt-get -y install git wget
elif [ -x "$(which dnf)" ]; then
  dnf -y install git wget
else
  echo "❌ Could not find apt-get or dnf package manager." >&2
  exit 1
fi

# Install oh-my-zsh and plugins
echo "Cloning Oh My Zsh and plugins..."
git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh /oh-my-zsh
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions /oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting /oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# Download custom configuration files
echo "Downloading custom theme and zshrc template..."
wget ${GH}/custom/zshrc.zsh-template -O /oh-my-zsh/custom/zshrc.zsh-template
wget ${GH}/custom/themes/dallas.zsh-theme -O /oh-my-zsh/custom/themes/dallas.zsh-theme

# --- 3. Confirm before applying user settings ---
echo "" # Newline for formatting
read -p "❓ Apply zsh settings for all users and change their default shell to zsh? [y/N] " confirm
echo "" # Newline for formatting

case "$confirm" in
  [yY]*)
    echo "Applying user configurations..."
    if [ -d /home ]; then
      for H in /home/*; do
        if [ -d "$H" ]; then # Check if the item in /home is a directory
          U="$(basename "$H")"
          echo "  -> Applying .zshrc for user $U"
          cp /oh-my-zsh/custom/zshrc.zsh-template "$H/.zshrc"
          chown "$U:$U" "$H/.zshrc"
        fi
      done
    fi

    echo "Changing default shells to zsh..."
    # Safely replace /bin/bash with /bin/zsh
    sed -i 's|/bin/bash|/bin/zsh|g' /etc/passwd
    sed -i 's#SHELL=.*#SHELL=/bin/zsh#g' /etc/default/useradd;
    echo "✅ All tasks completed successfully."
    ;;
  *)
    echo "ℹ️ Aborted by user. Only the Oh My Zsh installation is complete; user settings were not applied."
    exit 0
    ;;
esac
