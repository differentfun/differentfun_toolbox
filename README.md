# 🎛️ DifferentFun Multimedia Toolbox (Zenity GUI)

A set of Bash-powered multimedia tools with a simple graphical interface using **Zenity**.  
Supports audio/video/image conversion, ISO creation/extraction, and more — all in one place.

---

## 🧰 Included Tools

### 🎵 Audio / 🎞️ Video / 🖼️ Images

- **PNG Compressor**
- **Audio Converter** (mp3, ogg, flac, etc.)
- **YaBridge Manager** (Only on Debian 12 \ MX Linux)
- **Image Converter**
- **Video Converter** (with optional HW acceleration)
- **Video → Frames** extractor
- **Frames → Video** builder
- **Reverse Image Search** on the web
- **Fast Image Upload** on the web, returns url
- **Youtube Downloader** with format options
- **Recursive File Date Changer** assess or modified time

### 💽 ISO Tools

- **Create ISO** from folder
- **Extract ISO** to folder

### 🗜️ ZIP Tools

- **Create a Splitted Archive** using zip
- **Rejoin and decompress a Splitted Archive** using zip

### 🔐 Crypt & Decrypt Utils

- **Encrypt and Decrypt Files** using GPG

### 🧑‍💻 Git & Dev

- **GIT Tools** – Manage your repositories with a menu-driven interface

### 🆙 Toolbox Maintenance

- **Look for Toolbox Updates** – Checks for updates from the official GitHub repository and pulls the latest version if available.


---

## 🐧 Tested on:

- Debian, Ubuntu, Linux Mint, MX Linux

## 🐧 Also supported (via specific installer scripts):

🟢 Debian-based:
- Kali Linux, Pop!_OS, Zorin OS, Elementary OS, antiX, PureOS, Parrot OS

🔵 Red Hat-based:
- Fedora, RHEL (Red Hat Enterprise Linux), AlmaLinux, Rocky Linux

🟡 Arch-based:
- Arch Linux, Manjaro, EndeavourOS, Garuda Linux

🟣 openSUSE-based:
- openSUSE Leap, openSUSE Tumbleweed, GeckoLinux

---

## 📜 License

You can **use** this toolbox and anything you **create with it** in any kind of project — personal, educational, or commercial.

You can also **share the toolbox freely** with others.

However, you **cannot sell this toolbox**, nor **include it in commercial software, products, or services**.

In short:  

✅ Use it and share it

❌ Don't sell it and don't bundle it in commercial apps

Licensed under a custom "Non-Commercial Integration License".

---

## 🚀 Getting Started

### 0. Requirements

The toolbox will prompt to install:

- zenity, ffmpeg, pngquant, p7zip (o p7zip-full), genisoimage (or cdrkit), zip, coreutils, gnupg (or gnupg2)

### 1. Clone the repository

```bash
git clone https://github.com/differentfun/differentfun_toolbox.git
```

```bash
cd differentfun_toolbox
```

### 2. Run the launcher

```bash
bash main.sh
```

### 3. Optional
You can create a symlink in the user menu launching

```bash
bash install_toolbox_menu_entry.sh
```
