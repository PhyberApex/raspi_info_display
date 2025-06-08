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
├── firstrun-user.sh          # Your custom one-time setup script
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
3. Enable:
   - SSH
   - Wi-Fi (if needed)
   - Set username/password  
   *(⚠️ At least one setting must be enabled to trigger `firstrun.sh` injection!)*
4. Choose the OS and storage as usual, then **write the image**
5. After flashing and **before booting**:
   - Open the SD card’s `boot` partition (shows up as a USB drive)
   - Copy the following files into the root of the `boot` partition:
     ```
     firstrun-user.sh
     system_info.py
     system_info.service
     optional.d/ (entire folder, if using optional modules)
     ```
6. **Open the file** `firstrun.sh` (already present in the `boot` partition) in a text editor
7. **Right above the final line** `exit 0`, add this line:
   ```bash
   bash /boot/firstrun-user.sh
   ```
   So the file should look like:
   ```bash
   ...
   bash /boot/firstrun-user.sh
   exit 0
   ```
8. Save the file, safely eject the SD card, and insert it into your Raspberry Pi
9. On first boot, your custom script and all configuration will run once and automatically clean itself up

---

## 🛠️ Requirements

- Raspberry Pi with:
  - 128x32 SSD1306 OLED display (I2C)
  - Push button and optional LED connected to GPIO
- Raspberry Pi OS (Bookworm recommended)
- No monitor, keyboard, or SSH required — runs fully headless

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
