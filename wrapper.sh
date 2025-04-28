SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
gnome-terminal -- bash -c "bash $SCRIPT_DIR/after_boot.sh; exec bash"