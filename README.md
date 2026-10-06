# Systats

A lightweight macOS menu bar app that monitors your system stats in real time.

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Menu bar display** — live CPU and Memory percentages right in your menu bar
- **Detailed dropdown** with:
  - CPU usage
  - Memory usage (used / total GB)
  - Disk usage (used / total GB)
  - Network download & upload rate
  - Battery percentage with charging indicator
  - System uptime
- **Configurable refresh interval** — 1s, 2s, 5s, or 10s
- **Toggle individual stats** on or off
- **Launch at login** support
- **Copy stats** to clipboard in one click
- **Native Mach APIs** — no shell commands, no sandbox issues

## Screenshots
> <img width="280" height="279" alt="image" src="https://github.com/user-attachments/assets/bdf1e2b8-0609-4d94-a4bf-336aadb9eb20" />

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (for building from source)

## Installation

### Option 1: Download the pre-built app

1. Go to the [Releases](../../releases) page.
2. Download the latest `Systats.zip`.
3. Unzip and drag `Systats.app` into your **Applications** folder.
4. **First launch:** Right-click the app and select **Open** (required because the app is not notarized). Confirm in the dialog.

### Option 2: Build from source

```bash
git clone https://github.com/YOUR_USERNAME/Systats.git
cd Systats
open Systats.xcodeproj
```
#Notice
Settings button may not work
