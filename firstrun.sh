#!/bin/bash
exec &> /boot/firstrun.log
set -ex

echo "🔧 Base system setup started..."

# Update and install base dependencies
apt update && apt full-upgrade -y
raspi-config nonint do_i2c 0
raspi-config nonint do_spi 0
apt install -y python3-pip python3-pil python3-smbus i2c-tools git

# OLED dependencies
pip3 install --break-system-packages adafruit-circuitpython-ssd1306 psutil

# Install OLED script and systemd service
cp /boot/system_info.py /home/pi/system_info.py
cp /boot/system_info.service /etc/systemd/system/system_info.service
chmod +x /home/pi/system_info.py
chown pi:pi /home/pi/system_info.py
systemctl enable system_info.service
systemctl start system_info.service

# Run all optional setup scripts if any exist
OPTIONAL_DIR="/boot/optional.d"
if [ -d "$OPTIONAL_DIR" ]; then
  echo "📦 Found optional modules. Running each..."
  for script in "$OPTIONAL_DIR"/*.sh; do
    [ -f "$script" ] || continue
    echo "▶️ Running optional module: $script"
    bash "$script" &>> /boot/$(basename "$script").log
  done
else
  echo "ℹ️ No optional modules found. Skipping."
fi

echo "✅ Base setup complete. All optional modules executed."
