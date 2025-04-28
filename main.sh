#!/bin/bash
# this script intended for virtual machine desktop setup only

set -e

start_time=$(date +%s)

exec > >(tee -a "before_boot.log") 2>&1

clean_repo() {
  echo "cleaning repo..."
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

disable_grub_timeout() {
  echo "disabling grub timeout..."
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

enable_autologin() {
  echo "enabling autoligin..."
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

create_desktop_file() {
	echo "creating autorun desktop file..."
  mkdir -p ~/.config/autostart
	local exec_path="$1"
	local desktop_file="$HOME/.config/autostart/autorun.desktop"

	cat <<EOL > "$desktop_file"
[Desktop Entry]
Type=Application
Name=My Script
Exec=bash $exec_path
Terminal=true
X-GNOME-Autostart-enabled=true
EOL
	
}

disable_wayland() {
    sudo sed -i 's/^#\s*\(WaylandEnable=false\)/\1/' /etc/gdm3/daemon.conf
}

#####################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo -v
clean_repo
disable_grub_timeout
create_desktop_file "$SCRIPT_DIR/wrapper.sh"
sudo apt update && sudo apt install -y --no-install-suggests --no-install-recommends gnome-session gdm3 gnome-terminal gnome-shell-extension-dash-to-panel spice-vdagent xorg xdotool
enable_autologin
disable_wayland

echo "rebooting in 5 seconds..."
sleep 5
sudo reboot

end_time=$(date +%s)
execution_time=$((end_time - start_time))
echo "debian gnome minimal virtual machine setup has been successfully completed in $execution_time seconds."
