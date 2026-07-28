# Changelog

## 1.1.0 - 2026-07-28

- Added Quick Setup as a focused, step-by-step flow for Homebrew, desktop, Dock, and text/keyboard settings while leaving optional app installs separate.
- Added independent top-right Mission Control and bottom-right Show Desktop Hot Corner settings, including rightmost-display guidance for multi-monitor Macs.
- Made the Dock checklist load current state once, refresh only on request, preserve localized aliases, and report apply failures instead of showing false success.
- Linked Gureum installation, input-source registration, Karabiner, right Command to F18, and the F18 input-source shortcut as one dependency-aware keyboard flow.
- Clarified that end users do not need full Xcode and that Swift from Command Line Tools is requested only for Gureum input-source registration.
- Changed the Flow action to open the latest public Lazyest Flow release instead of building Flow source on the user's Mac.
- Prevented multiple Lazyest Setup instances from running at the same time.

## 1.0.0 - 2026-07-18

- Bundled the setup runtime scripts and configuration inside the app so actions continue to work after an installer removes its temporary source checkout.
- Resolved the bundled runtime relative to the app instead of persisting a machine-specific source path.
- Clarified that only selected settings are changed and added inset spacing to the launch guidance.
- Added Developer ID signing, notarization, Gatekeeper verification, and SHA-256 release packaging.

This project uses the Setup app version in [`VERSION`](VERSION). Public GitHub Releases contain the signed and notarized ZIP and DMG downloads.

## 0.4.0 - 2026-07-17

- Rebranded the one-time app and Swift package as Lazyest Setup.
- Renamed the separate runtime bridge from Agent to Lazyest Flow while preserving legacy installs and settings.
- Changed the Flow action from a source build to opening the latest GitHub Release page.
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
