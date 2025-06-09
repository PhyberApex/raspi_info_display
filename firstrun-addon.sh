#!/bin/bash

# Pi Info Display - Addon Script
# This script is designed to be called from Pi Imager's firstrun.sh
# It runs AFTER all the standard Pi setup is complete

# Ensure we're running from the correct directory context
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
BOOT_DIR="$(readlink -f "$SCRIPT_DIR")"

# Create detailed logging
exec 1> >(tee -a "$BOOT_DIR/firstrun-addon.log")
exec 2>&1

echo "$(date): 🚀 Pi Info Display addon started from: $BOOT_DIR"
echo "$(date): Running as user: $(whoami), UID: $(id -u)"

# Function to log and execute commands
log_exec() {
    echo "$(date): Executing: $*"
    "$@"
    local exit_code=$?
    echo "$(date): Command exit code: $exit_code"
    return $exit_code
}

# Get the actual first user (Pi Imager may have set this up)
FIRSTUSER=$(getent passwd 1000 | cut -d: -f1 2>/dev/null || echo "pi")
FIRSTUSERHOME=$(getent passwd 1000 | cut -d: -f6 2>/dev/null || echo "/home/$FIRSTUSER")

echo "$(date): Detected first user: $FIRSTUSER ($FIRSTUSERHOME)"

# Update and install base dependencies
echo "$(date): 🔧 Starting base system setup..."
log_exec apt update
log_exec apt full-upgrade -y
log_exec raspi-config nonint do_i2c 0
log_exec raspi-config nonint do_spi 0
log_exec apt install -y python3-pip python3-pil python3-smbus i2c-tools git

# OLED dependencies
echo "$(date): 📦 Installing Python dependencies..."
log_exec pip3 install --break-system-packages adafruit-circuitpython-ssd1306 psutil

# Install OLED script and systemd service
echo "$(date): 🖥️ Installing OLED script for user: $FIRSTUSER"

# Use absolute paths for better reliability
if [ -f "$BOOT_DIR/system_info.py" ]; then
    log_exec cp "$BOOT_DIR/system_info.py" "$FIRSTUSERHOME/system_info.py"
    log_exec chmod +x "$FIRSTUSERHOME/system_info.py"
    log_exec chown "$FIRSTUSER:$FIRSTUSER" "$FIRSTUSERHOME/system_info.py"
    echo "$(date): ✅ system_info.py installed"
else
    echo "$(date): ❌ ERROR: system_info.py not found in $BOOT_DIR"
fi

if [ -f "$BOOT_DIR/system_info.service" ]; then
    log_exec cp "$BOOT_DIR/system_info.service" /etc/systemd/system/system_info.service
    
    # Update the service file to use the correct user and paths
    log_exec sed -i "s/User=pi/User=$FIRSTUSER/g" /etc/systemd/system/system_info.service
    log_exec sed -i "s/Group=pi/Group=$FIRSTUSER/g" /etc/systemd/system/system_info.service
    log_exec sed -i "s|/home/pi/|$FIRSTUSERHOME/|g" /etc/systemd/system/system_info.service
    
    log_exec systemctl enable system_info.service
    log_exec systemctl start system_info.service
    echo "$(date): ✅ system_info.service installed and started"
else
    echo "$(date): ❌ ERROR: system_info.service not found in $BOOT_DIR"
fi

# Run all optional setup scripts if any exist
OPTIONAL_DIR="$BOOT_DIR/optional.d"
if [ -d "$OPTIONAL_DIR" ]; then
    echo "$(date): 📦 Found optional modules in $OPTIONAL_DIR. Running each..."
    for script in "$OPTIONAL_DIR"/*.sh; do
        [ -f "$script" ] || continue
        echo "$(date): ▶️ Running optional module: $(basename "$script")"
        bash "$script" &>> "$BOOT_DIR/$(basename "$script").log"
        echo "$(date): ✅ Completed: $(basename "$script")"
    done
else
    echo "$(date): ℹ️ No optional modules found in $OPTIONAL_DIR. Skipping."
fi

echo "$(date): ✅ Pi Info Display addon setup complete!"

# Clean up our files (but leave logs for debugging)
echo "$(date): 🧹 Cleaning up installation files..."
rm -f "$BOOT_DIR/firstrun-addon.sh"
rm -f "$BOOT_DIR/system_info.py"
rm -f "$BOOT_DIR/system_info.service"
rm -rf "$BOOT_DIR/optional.d"

echo "$(date): 🎉 Pi Info Display setup completed successfully!" 