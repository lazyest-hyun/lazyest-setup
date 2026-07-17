# mac-bootstrap Skill

Use this skill for the one-time Lazyest Setup project. Runtime Flow work belongs in the separate `mac-bootstrap-agent` repository.

## Principles

- Start with read-only state checks.
- Do not install apps or apply macOS settings without an explicit user request.
- Keep each setting independently applicable and reversible where possible.
- Never print secrets, full environment variables, Keychain values, passwords, or tokens.
- Verify the installed app and real macOS state instead of relying only on command output.

## Workflow

1. Run `./bootstrap.sh audit`.
2. Run `./bootstrap.sh plan` and `./bootstrap.sh install-plan`.
3. Preview the requested action with its `--dry-run` option.
4. Build Setup with `./bootstrap.sh build-setup` when source changed.
5. Install Setup only when requested with `./bootstrap.sh install-setup`.
6. Treat `./bootstrap.sh install-flow` as a bridge to the separate Agent repository.

## Boundaries

- Setup owns app installation, Korean input, keyboard defaults, desktop defaults, and Dock configuration.
- Lazyest Flow owns app hotkeys, screenshot clipboard copy, sleep prevention, and Dock anchoring.
- Do not add Flow source or runtime defaults back into this repository.
