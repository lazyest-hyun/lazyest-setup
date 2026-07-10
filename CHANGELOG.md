# Changelog

This project uses the Setup app version in [`VERSION`](VERSION). GitHub Releases are not required.

## Unreleased

- Updated the pinned MacBootstrapAgent source to `0.2.1` with equal-width app hotkey rows.

## 0.3.0 - 2026-07-10

- Split the always-running MacBootstrapAgent into its own repository and Swift package.
- Kept MacBootstrapSetup focused on one-time macOS and app setup.
- Changed the Setup Agent row to download and install the separate Agent project directly.
- Gave Setup its own language settings and independent build command.

## 0.2.0 - 2026-07-10

- Added the state-driven Setup UI for optional apps, Korean input, desktop defaults, and Dock configuration.
- Expanded the menu bar Agent with configurable app hotkeys, screenshot clipboard copy, sleep prevention, and Dock anchoring.
- Made fresh installs inert: no default hotkeys and no runtime feature enabled automatically.
- Changed screenshot clipboard copy to publish complete image data immediately after the saved file is ready.
- Added an explicit immediate-copy switch that disables the macOS floating screenshot thumbnail and avoids its file-save delay.
- Added shared Korean and English UI selection.

## 0.1.0 - 2026-07-08

- Added the first public reusable bootstrap scripts and native macOS app scaffolds.
