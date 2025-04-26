#!/bin/bash
# this script intended for virtual machine desktop setup only

set -e

sudo test || true

start_time=$(date +%s)

exec > >(tee -a "logfile.log") 2>&1

clean_repo() {
  file="/etc/apt/sources.list"
  
  # Check if backup file already exist.
  if [ -e "$file.bak" ]; then
    echo "Backup file: $file.bak already exists. Skipping..."
    return 0
  fi
  
  # Backup the original file.
  sudo cp -i $file $file.bak
  
  # remove deb-src repo
  sudo sed -i '/deb-src/d' $file
  
  # remove backports repo
  sudo sed -i '/backports/d' $file
  
  # remove commented lines
  sudo sed -i '/^#/d' $file
  
  # remove empty lines
  sudo sed -i '/^$/d' $file
  
  echo "Repo is cleaned."
}

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

enable_autologin() {
  # Get current username
  CURRENT_USER=$(whoami)
  
  # Set GDM configuration file
  GDM_CONFIG_FILE="/etc/gdm3/daemon.conf"
  
  if [ ! -f "$GDM_CONFIG_FILE" ]; then
      echo "file: $GDM_CONFIG_FILE not found"
      return 1
  fi
  
  # Enable autologin for the current user
  sudo sed -i 's/# *\(AutomaticLoginEnable\).*/\1 = true/' $GDM_CONFIG_FILE
  sudo sed -i "s/# *\(AutomaticLogin\).*/\1 = $CURRENT_USER/" $GDM_CONFIG_FILE
  
  echo "Autologin enabled for $CURRENT_USER."
}

disable_grub_timeout() {
  # Path to the GRUB configuration file
  GRUB_FILE="/etc/default/grub"
  
  # Check if the GRUB file exists
  if [[ ! -f $GRUB_FILE ]]; then
      echo "GRUB configuration file not found at $GRUB_FILE" >&2
      return 1
  fi
  
  # Backup the original GRUB file
  sudo cp "$GRUB_FILE" "$GRUB_FILE.bak"
  
  # Update GRUB_TIMEOUT setting
  sudo sed -i 's/^GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=0/' "$GRUB_FILE"
  
  # Update GRUB configuration
  echo "Updating GRUB configuration..."
  sudo update-grub
  
  echo "GRUB timeout has been disabled. Original configuration backed up as $GRUB_FILE.bak"
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

#####################################################################

clean_repo

sudo apt update && sudo apt install -y --no-install-suggests --no-install-recommends \
  gnome-session gdm3 gnome-terminal nautilus gnome-text-editor spice-vdagent firefox-esr

set_terminal_color_bright
enable_autologin
disable_grub_timeout

end_time=$(date +%s)
execution_time=$((end_time - start_time))
echo "debian gnome minimal virtual machine setup has been successfully completed in $execution_time seconds."
