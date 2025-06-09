# raspi_info_display

[![Raspberry Pi OS](https://img.shields.io/badge/platform-raspberry%20pi%20os-red?logo=raspberrypi)](https://www.raspberrypi.com/software/)
[![Python 3](https://img.shields.io/badge/python-3.9%2B-blue.svg?logo=python)](https://www.python.org/)
[![Systemd](https://img.shields.io/badge/init-systemd-007ec6.svg?logo=linux)](https://freedesktop.org/wiki/Software/systemd/)
[![Headless Setup](https://img.shields.io/badge/headless-yes-success)](#)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

> Modular Raspberry Pi bootstrap system  
> Based on the work of [@leelooauto](https://github.com/leelooauto/system_info)

This repo contains a collection of scripts to **automatically configure Raspberry Pi devices** on first boot — with a focus on displaying system info via an OLED screen, and optional modular extensions (e.g., GitHub Actions runner, Tailscale).

---

## 🧾 Features

- 🖥️ **OLED info display** on boot  
  Shows hostname, IP address, CPU and memory usage  
  Controlled via GPIO button (press to show, long-press to reboot/shutdown)
- ⚙️ **Systemd-based startup service** for better reliability
- 🧩 **Modular architecture** for optional setups like:
  - GitHub Actions runner
  - Tailscale with SSH
  - Future custom modules
- 🧃 Fully headless & SSH-free provisioning using Raspberry Pi Imager

---

## 🗂️ Structure

```
/
├── firstrun-addon.sh         # Addon script that integrates with Pi Imager's firstrun.sh
├── system_info.py            # OLED display script
├── system_info.service       # Systemd service unit for OLED
├── optional.d/               # Drop-in directory for additional modules
│   ├── github-runner.sh      # Optional GitHub Actions + Tailscale setup
│   └── your-module.sh        # Add more scripts here
```

---

## 🚀 Usage

### 1. 🔧 Customize

- Edit `optional.d/github-runner.sh` and insert your:
  - `GITHUB_REPO_URL`
  - `GITHUB_RUNNER_TOKEN`
  - `TAILSCALE_AUTHKEY`
- Place additional `.sh` scripts in `optional.d/` as needed

---

### 2. 🖼️ Flash via Raspberry Pi Imager

1. Launch [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Press `Ctrl + Shift + X` for **Advanced Settings**
3. **🚨 CRITICAL**: Enable at least one setting to trigger first-run script:
   - **Enable SSH** (strongly recommended)
   - Configure Wi-Fi (if needed)  
   - Set custom username/password
   
   *(⚠️ **Without enabling at least one setting, Pi Imager won't create a `firstrun.sh` file!**)*

4. Choose the OS and storage as usual, then **write the image**

5. After flashing and **before booting**:
   - Open the SD card's `boot` partition (shows up as a USB drive)
   - Copy these files to the **root** of the `boot` partition:
     ```
     firstrun-addon.sh
     system_info.py
     system_info.service
     optional.d/ (entire folder, if using optional modules)
     ```

6. **Integration with Pi Imager's firstrun.sh:**
   - Open `firstrun.sh` (created by Pi Imager) in a text editor
   - Find the lines near the end:
     ```bash
     rm -f /boot/firstrun.sh
     sed -i 's| systemd.run.*||g' /boot/cmdline.txt
     exit 0
     ```
   - **Replace them with:**
     ```bash
     # Run Pi Info Display addon
     bash "$(dirname "${BASH_SOURCE[0]}")/firstrun-addon.sh"
     
     rm -f /boot/firstrun.sh
     sed -i 's| systemd.run.*||g' /boot/cmdline.txt
     exit 0
     ```

7. **Safely eject** the SD card and insert it into your Raspberry Pi

8. **First boot**: Your Pi will automatically run the setup script and configure everything

---

## 🛠️ Requirements

- Raspberry Pi with:
  - 128x32 SSD1306 OLED display (I2C)
  - Push button and optional LED connected to GPIO
- Raspberry Pi OS (Bookworm recommended)
- No monitor, keyboard, or SSH required — runs fully headless

---

## 🐛 Troubleshooting

**Script not running?**
1. Check you enabled SSH/WiFi/user in Pi Imager advanced settings
2. Verify `firstrun.sh` exists in the boot partition after flashing
3. Check `/boot/firstrun.log` and `/boot/firstrun-addon.log` for detailed error messages
4. Ensure all files were copied to the boot partition root (not in subfolders)
5. Verify the addon call was added correctly to `firstrun.sh`

**OLED not working?**
- Verify I2C wiring (SDA to GPIO 2, SCL to GPIO 3)
- Check that I2C is enabled: `sudo raspi-config` → Interface Options → I2C
- Test with: `sudo i2cdetect -y 1` (should show device at 0x3c)

---

## 💡 Example Modules

- `github-runner.sh`:  
  Creates a GitHub Actions runner using a Tailscale-authenticated hostname  
  Dynamically generates labels based on Pi model and architecture

- `my-other-module.sh`:  
  Add setup logic for sensors, custom apps, or automation tools

---

## 📦 Credits

Based on the original [system_info](https://github.com/leelooauto/system_info) project by [@leelooauto](https://www.thingiverse.com/sliderbor/designs).  
Adapted and extended for modular, headless provisioning.

---

## ⚠️ Security Note

> This repo is designed to be used **privately** or with your own automation workflows.  
> Do **not** commit secrets like GitHub tokens or Tailscale auth keys to this repo.

---

## 📬 Feedback

Feel free to open an issue or PR if you want to contribute a new `optional.d/` module or enhance the base setup!
