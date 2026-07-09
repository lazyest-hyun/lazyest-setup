# mac-bootstrap

Korean-first macOS bootstrap toolkit for a fresh development Mac.

This project has two parts:

- `MacBootstrapSetup.app`: one-time setup UI for macOS defaults, Korean input, Dock cleanup, and optional app installs.
- `MacBootstrapAgent.app`: always-running menu bar app for app hotkeys, screenshot clipboard copy, sleep prevention, and Dock anchoring.

The default path is explicit and minimal. The scripts and apps do not depend on Raycast or Hammerspoon.

## Current Status

- Reusable shell entrypoint: ready.
- Setup app: buildable and installable.
- Agent app: buildable and installable.
- Dock anchoring: live-tested with Accessibility permission. The Dock stayed on the pinned display while probing another display's Dock edge.
- App hotkeys: config-driven with no default bindings.
- Korean setup: includes Gureum, Karabiner, input-source shortcuts, function keys, Globe/Fn key, key repeat, and press-and-hold defaults.

## Requirements

- macOS 13 or later.
- Swift toolchain from Xcode or Command Line Tools.
- Admin password for commands that install to `/Applications` or use Homebrew/system installers.
- Accessibility permission for `MacBootstrapAgent.app` if you use app hotkeys, app hiding/activation, or Dock anchoring.

## Quick Start

```sh
./bootstrap.sh audit
./bootstrap.sh plan
./bootstrap.sh install-plan

./bootstrap.sh build-agent
./bootstrap.sh install-setup
./bootstrap.sh install-agent

open /Applications/MacBootstrapSetup.app
open /Applications/MacBootstrapAgent.app
```

Use `--dry-run` before applying system changes:

```sh
./bootstrap.sh apply-defaults --dry-run
./bootstrap.sh dock-apply --dry-run
./bootstrap.sh dock-cleanup --dry-run
```

## Commands

```sh
./bootstrap.sh help
./bootstrap.sh audit
./bootstrap.sh plan
./bootstrap.sh install-plan

./bootstrap.sh apply-defaults [--dry-run] [--restart-ui]
./bootstrap.sh apply-korean-input [--dry-run]
./bootstrap.sh apply-gureum-option-key [--dry-run]
./bootstrap.sh apply-input-sources [--dry-run]
./bootstrap.sh reset-input-sources [--dry-run]
./bootstrap.sh apply-input-shortcuts [--dry-run]
./bootstrap.sh reset-input-shortcuts [--dry-run]
./bootstrap.sh apply-key-repeat [--dry-run]
./bootstrap.sh apply-press-and-hold [--dry-run]
./bootstrap.sh apply-function-keys [--dry-run]
./bootstrap.sh apply-globe-key [--dry-run]
./bootstrap.sh apply-karabiner [--dry-run]
./bootstrap.sh reset-karabiner [--dry-run]

./bootstrap.sh dock-apply [--dry-run] [--no-restart-ui]
./bootstrap.sh dock-cleanup [--dry-run] [--no-restart-ui]

./bootstrap.sh agent-plan
./bootstrap.sh build-agent [--dry-run]
./bootstrap.sh install-agent [--dry-run]
./bootstrap.sh uninstall-agent [--dry-run]
./bootstrap.sh install-setup [--dry-run]
./bootstrap.sh uninstall-setup [--dry-run]
```

Read-only commands:

- `audit`
- `plan`
- `install-plan`
- `agent-plan`

## Configuration

- [config/bootstrap.conf](config/bootstrap.conf): paths, macOS default toggles, install candidates, Dock labels.
- [config/hotkeys.conf](config/hotkeys.conf): optional app hotkey bindings.

`config/hotkeys.conf` intentionally has no active default shortcuts. Add bindings from `MacBootstrapAgent.app` Settings or edit the file:

```text
toggle-app|ctrl+w|com.google.Chrome.app.google-chat|Google Chat
```

## One-Time Setup App

Install:

```sh
./bootstrap.sh build-agent
./bootstrap.sh install-setup
open /Applications/MacBootstrapSetup.app
```

The Setup app is for one-time changes:

- Homebrew install entry point.
- Optional app install candidates.
- Text and keyboard defaults.
- Gureum input method setup.
- Karabiner right Command to F18 rule.
- Input-source shortcuts.
- Key repeat and press-and-hold behavior.
- Screenshot folder and macOS screenshot defaults.
- Desktop and Dock cleanup settings.

Remove it after setup:

```sh
./bootstrap.sh uninstall-setup
```

## Always-Running Agent

Install:

```sh
./bootstrap.sh build-agent
./bootstrap.sh install-agent
open /Applications/MacBootstrapAgent.app
```

The Agent is a menu bar app. It provides:

- App toggle hotkeys.
- Screenshot-folder watch and clipboard copy.
- Sleep prevention using macOS power assertions.
- Dock anchoring using Accessibility event monitoring.

Dock anchoring works like DockAnchor: it watches mouse movement and blocks Dock trigger events on non-pinned displays. The monitor selector is disabled while Dock anchoring is running; turn Dock anchoring off before changing the pinned display.

Remove it:

```sh
./bootstrap.sh uninstall-agent
```

## Korean Input Notes

Recommended order:

1. Install Gureum.
2. Log out and back in if macOS does not register `Gureum / Han 2set`.
3. Apply input sources.
4. Apply input-source shortcuts.
5. Install/apply Karabiner right Command to F18.

Useful commands:

```sh
./bootstrap.sh apply-korean-input --dry-run
./bootstrap.sh apply-korean-input
./bootstrap.sh apply-gureum-option-key
./bootstrap.sh apply-karabiner
```

## Optional Install Candidates

`install-plan` reports status and official/manual install paths. It does not install everything automatically.

Included candidates:

- Raycast
- Claude
- Microsoft Teams
- Slack
- Karabiner-Elements
- Gureum
- LinearMouse
- Amphetamine

Chrome and Codex are treated as fresh-Mac assumptions and audited only.

## Security And Permissions

- No secrets, tokens, Keychain values, or environment dumps are printed by the scripts.
- `install-agent` uses ad-hoc signing by default.
- To use a stable local code signing identity, pass `MAC_BOOTSTRAP_CODESIGN_IDENTITY`.
- The scripts do not create or trust a root signing certificate automatically.
- Dock anchoring and app activation require Accessibility permission for `/Applications/MacBootstrapAgent.app`.

## Validation

Run before publishing or changing behavior:

```sh
bash -n bootstrap.sh scripts/*.sh
./bootstrap.sh audit
./bootstrap.sh plan
./bootstrap.sh install-plan
./bootstrap.sh apply-defaults --dry-run
./bootstrap.sh agent-plan
./bootstrap.sh build-agent --dry-run
./bootstrap.sh build-agent
```

Manual checks:

- Open `MacBootstrapSetup.app` and confirm the tabs render correctly.
- Open `MacBootstrapAgent.app` and confirm menu bar behavior.
- Grant Accessibility permission and test Dock anchoring on a multi-display setup.
- Add one app hotkey and confirm toggle behavior.
- Confirm Gureum registration after logout/login on Korean input setups.

## Repository Notes

Generated files are ignored:

- SwiftPM `.build/`
- generated `.app` bundles
- archives and disk images
- editor and local runtime state

This repository is released under [The Unlicense](UNLICENSE), as close as practical to public-domain, unrestricted reuse.
