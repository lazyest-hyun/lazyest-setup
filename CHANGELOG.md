# Changelog

This project uses the Setup app version in [`VERSION`](VERSION). GitHub Releases are not required.

## 0.4.0 - 2026-07-17

- Rebranded the one-time app and Swift package as Lazyest Setup.
- Renamed the separate runtime bridge from Agent to Lazyest Flow while preserving legacy installs and settings.
- Pinned the Flow installer to the matching Lazyest Flow 0.5.0 source commit.
- Kept existing bundle identifiers and Karabiner rule compatibility so the rename does not reset permissions or duplicate mappings.

## 0.3.2 - 2026-07-13

- Moved the right Command to F18 setup fully to a named Karabiner Complex Modification.
- Made Setup and audit verify the selected profile's exact Complex rule instead of matching unrelated text.
- Limited reset cleanup to the MacBootstrap-owned Complex rule and the legacy right Command to F18 Simple mapping.

## 0.3.1 - 2026-07-10

- Fixed the input-source shortcut action so it changes only input-source shortcuts and preserves Spotlight shortcuts.
- Corrected Setup state detection so Spotlight preferences do not affect the input-source status.

## 0.3.0 - 2026-07-10

- Split the always-running MacBootstrapAgent into its own repository and Swift package.
- Kept LazyestSetup focused on one-time macOS and app setup.
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
