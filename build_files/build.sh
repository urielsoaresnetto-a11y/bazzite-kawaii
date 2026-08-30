#!/bin/bash

set -ouex pipefail

#############################################
# bazzite-kawaii build script
#
# Adds a Hyprland (Wayland) session + tooling on top of
# bazzite-nvidia-open, WITHOUT removing KDE Plasma.
# KDE stays as the safety-net session (choose it at the SDDM login).
#
# Package strategy for Fedora 44 atomic:
#   - Hyprland stack comes from the ashbuk/Hyprland-Fedora COPR.
#     It uses vendored deps + RPATH isolation, so it avoids the
#     libdisplay-info.so.3 / aquamarine ABI breakage that affects
#     other COPRs on F44.
#   - Everything else comes from Fedora / RPMFusion repos already
#     enabled on the ublue base image.
#############################################

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### -------------------------------------------------------------
### 1. Hyprland compositor + session core (COPR: ashbuk/Hyprland-Fedora)
### -------------------------------------------------------------
# Enable the COPR only for the build; we disable it again at the end so
# it does not remain enabled on the shipped image.
dnf5 -y copr enable ashbuk/Hyprland-Fedora

# hyprland pulls in hyprlock + hypridle as subpackages per the COPR.
# xdg-desktop-portal-hyprland is REQUIRED for screen sharing / file pickers
# under Wayland (Discord/OBS/Zoom screen share, GTK/portal file dialogs).
dnf5 -y install \
    hyprland \
    xdg-desktop-portal-hyprland

### -------------------------------------------------------------
### 2. Wayland session components (bar, launcher, notifications, wallpaper)
### -------------------------------------------------------------
dnf5 -y install \
    waybar \
    wofi \
    mako \
    swww \
    wlogout

### -------------------------------------------------------------
### 3. Wayland utilities (screenshots, clipboard, brightness, audio, idle helpers)
### -------------------------------------------------------------
# X11 screenshot tools do NOT work under Wayland; these are the native ones.
dnf5 -y install \
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
dnf5 -y install \
    kitty \
    thunar \
    thunar-volman \
    gvfs

### -------------------------------------------------------------
### 5. Fonts (Nerd Fonts + emoji + cute-friendly families)
### -------------------------------------------------------------
# Nerd Fonts provide the glyphs/icons Waybar and prompts need.
dnf5 -y install \
    jetbrains-mono-nerd-fonts \
    fira-code-fonts \
    google-noto-emoji-fonts \
    google-noto-sans-fonts \
    rsms-inter-fonts \
    fontawesome-fonts-all || true

### -------------------------------------------------------------
### 6. CLI quality-of-life (optional but nice for a riced setup)
### -------------------------------------------------------------
dnf5 -y install \
    starship \
    eza \
    bat \
    fastfetch \
    jq \
    || true

### -------------------------------------------------------------
### Cleanup: disable the COPR so it is not enabled on the final image
### -------------------------------------------------------------
dnf5 -y copr disable ashbuk/Hyprland-Fedora

echo "bazzite-kawaii: build.sh finished OK"
