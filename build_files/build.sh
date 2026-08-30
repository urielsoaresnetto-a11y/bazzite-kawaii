#!/bin/bash

set -ouex pipefail

#############################################
# bazzite-kawaii build script
#
# Adds a Hyprland (Wayland) session + tooling on top of
# bazzite-nvidia-open, WITHOUT removing KDE Plasma.
# KDE stays as the safety-net session (choose it at the SDDM login).
#
# Strategy:
#   - CORE (hyprland + portal) is installed strictly: if it fails, the
#     build fails (we need the compositor).
#   - Everything else is installed best-effort via install_optional():
#     a missing package name in a given repo logs a warning but does NOT
#     abort the build. This keeps the image usable and lets us refine
#     package names iteratively without losing a whole build.
#############################################

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

# Best-effort installer: tries each package individually; warns on failure.
install_optional() {
    for pkg in "$@"; do
        if dnf5 -y install "$pkg"; then
            echo "OK: installed $pkg"
        else
            echo "WARN: could not install '$pkg' (skipping)"
        fi
    done
}

### -------------------------------------------------------------
### 1. CORE: Hyprland compositor + portal (COPR: ashbuk/Hyprland-Fedora)
###    Strict install — the build MUST fail if this doesn't work.
### -------------------------------------------------------------
dnf5 -y copr enable ashbuk/Hyprland-Fedora

# hyprland pulls in hyprlock + hypridle as subpackages per the COPR.
# xdg-desktop-portal-hyprland is REQUIRED for Wayland screen sharing / file pickers.
dnf5 -y install \
    hyprland \
    xdg-desktop-portal-hyprland

### -------------------------------------------------------------
### 2. Wayland session components (bar, launcher, notifications, logout)
###    Best-effort so one missing name never kills the build.
### -------------------------------------------------------------
install_optional \
    waybar \
    wofi \
    mako \
    wlogout

# Wallpaper daemon: try hyprpaper first, then swww; either is fine.
# (Availability varies by repo; a wallpaper tool can also be added later
#  per-user in the dotfiles phase.)
install_optional hyprpaper
install_optional swww

### -------------------------------------------------------------
### 3. Wayland utilities (screenshots, clipboard, brightness, audio, idle)
### -------------------------------------------------------------
install_optional \
    grim \
    slurp \
    wl-clipboard \
    hyprshot \
    hyprpicker \
    brightnessctl \
    playerctl \
    pamixer \
    pavucontrol \
    network-manager-applet \
    blueman \
    polkit-gnome

### -------------------------------------------------------------
### 4. Terminal + file manager + basic apps for the session
### -------------------------------------------------------------
install_optional \
    kitty \
    thunar \
    thunar-volman \
    gvfs

### -------------------------------------------------------------
### 5. Fonts (base repos + emoji). Nerd Fonts are added per-user later
###    in the dotfiles phase to avoid depending on extra COPRs here.
### -------------------------------------------------------------
install_optional \
    jetbrains-mono-fonts-all \
    google-noto-emoji-fonts \
    google-noto-sans-fonts \
    fontawesome-fonts-all

### -------------------------------------------------------------
### 6. CLI quality-of-life (optional but nice for a riced setup)
### -------------------------------------------------------------
install_optional \
    starship \
    eza \
    bat \
    fastfetch \
    jq

### -------------------------------------------------------------
### Cleanup: disable the COPR so it is not enabled on the final image
### -------------------------------------------------------------
dnf5 -y copr disable ashbuk/Hyprland-Fedora

echo "bazzite-kawaii: build.sh finished OK"
