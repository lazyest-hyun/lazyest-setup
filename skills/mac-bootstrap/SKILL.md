# mac-bootstrap Skill

Use this skill when helping set up or audit a macOS machine with this repository.

## Principles

- Prefer read-only audit before applying settings.
- Do not install optional apps unless the user explicitly asks.
- Do not print secrets, full environment variables, Keychain values, or tokens.
- Treat GUI-only macOS settings as manual checks unless a stable defaults key is known.
- Keep scripts reusable and idempotent.

## Workflow

1. Run `./bootstrap.sh audit` and summarize what is already applied.
2. Use `./bootstrap.sh apply-minimal --dry-run` to preview native changes.
3. Apply with `./bootstrap.sh apply-minimal` only after the user confirms.
4. For Dock changes, run `./bootstrap.sh dock-plan` first.
5. For Karabiner, use `./bootstrap.sh karabiner-template` and only install Karabiner if needed.
6. Keep app installs optional; use `./bootstrap.sh downloads` for official references.

## Classification

- Already applied: current state already matches the desired setup.
- No-install/native path: can be handled by macOS defaults, AppleScript, Shortcuts, Automator, or a small Swift helper.
- Install only if missing/needed: useful apps that should not be installed by default.
- Unknown/manual check: GUI state that cannot be safely inferred from stable command-line state.

