# 🎛️ DifferentFun Multimedia Toolbox (Zenity GUI)

A set of Bash-powered multimedia tools with a simple graphical interface using **Zenity**.  
Supports audio/video/image conversion, ISO creation/extraction, and more — all in one place.

---

## 🧰 Included Tools

- **PNG Compressor**
- **Audio Converter** (mp3, ogg, flac, etc.)
- **Image Converter**
- **Video Converter** (with optional HW acceleration)
- **Video → Frames** extractor
- **Frames → Video** builder
- **Create ISO** from folder
- **Extract ISO** to folder

---

## 🐧 Linux Compatibility

Tested on:

- Debian
- Ubuntu
- Linux Mint

> Arch/Fedora support planned.

---

## 📜 License

You can **use** this toolbox and anything you **create with it** in any kind of project — personal, educational, or commercial.

You can also **share the toolbox freely** with others.

However, you **cannot sell this toolbox**, nor **include it in commercial software, products, or services**.

In short:  
✅ Use it  
✅ Share it  
❌ Don't sell it  
❌ Don't bundle it in commercial apps

Licensed under a custom "Non-Commercial Integration License".

---

## 🚀 Getting Started

### 0. Requirements

The toolbox will prompt to install:

- `zenity`, `ffmpeg`, `pngquant`, `p7zip-full`, `genisoimage`

Or run manually:

$ bash toolset/requirements_debian.sh

### 1. Clone the repository

$ `git clone https://github.com/differentfun/differentfun_toolbox.git `

$ `cd differentfun_toolbox`

### 2. Run the launcher
$ `bash main.sh`

### 3. Optional
You can create a symlink in the user menu launching

$ `bash install_toolbox_menu_entry.sh`
