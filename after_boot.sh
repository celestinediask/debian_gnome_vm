#!/bin/bash
# this script intended to run automaticaly on the first boot

set -e

start_time=$(date +%s)

set_terminal_color_bright() {
  # Get the default profile UUID
  PROFILE_UUID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
  
  # Enable bold text in bright colors
  gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_UUID/ bold-is-bright true
  
  # Verify the change
  BOLD_IS_BRIGHT=$(gsettings get org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_UUID/ bold-is-bright)
  
  if [ "$BOLD_IS_BRIGHT" = "true" ]; then
      echo "Successfully enabled 'Show bold text in bright colors'"
      echo "Please restart your GNOME Terminal for the changes to take effect."
  else
      echo "Failed to enable 'Show bold text in bright colors'"
      echo "Current setting: $BOLD_IS_BRIGHT"
      return 1
  fi
}



apply_gsettings() {
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark
  gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
  gsettings set org.gnome.desktop.interface gtk-theme 'HighContrastInverse'
  gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
  gsettings set org.gnome.desktop.privacy remember-recent-files false
  gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
  gsettings set org.gnome.desktop.interface show-battery-percentage true
  gsettings set org.gnome.shell favorite-apps "['org.gnome.Terminal.desktop', 'org.gnome.Nautilus.desktop', 'firefox-esr.desktop']"
  gsettings set org.gnome.desktop.background primary-color '#000000' # black
  gsettings set org.gnome.desktop.sound allow-volume-above-100-percent 'true'
  gsettings set org.gnome.nautilus.icon-view captions "['none', 'size', 'none']"
  gsettings set org.gnome.TextEditor restore-session false
  gsettings set org.gnome.desktop.screensaver lock-enabled false
  #gsettings set org.gnome.desktop.session idle-delay 0
  
  echo "successfully applied custom gnome settings for virtual machine"
}

check_xdotool_installed() {
  if ! command -v xdotool &> /dev/null; then
    echo "Error: xdotool is not installed. Please install it and try again."
    exit 1
  fi
}

exit_if_wayland() {
  if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    echo "Error: Wayland session detected. xdotool requires an X11 session."
    exit 1
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sleep 1
echo "after boot script running..."
xdotool key Escape
exit_if_wayland
check_xdotool_installed

gnome-extensions enable dash-to-panel@jderose9.github.com
set_terminal_color_bright

bash $SCRIPT_DIR/auth.sh &
echo "no need to enter password manualy here..."
sudo apt install -y nautilus gnome-text-editor firefox-esr

apply_gsettings

end_time=$(date +%s)
execution_time=$((end_time - start_time))
echo "debian gnome minimal virtual machine setup has been successfully completed in $execution_time seconds."
