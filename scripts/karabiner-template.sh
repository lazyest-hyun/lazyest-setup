#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
Reusable Karabiner complex modification:

{
  "description": "Right Command to F18",
  "manipulators": [
    {
      "type": "basic",
      "from": {
        "key_code": "right_command",
        "modifiers": {
          "optional": ["any"]
        }
      },
      "to": [
        {
          "key_code": "f18"
        }
      ]
    }
  ]
}

Recommended path:
  ~/.config/karabiner/assets/complex_modifications/right_command_to_f18.json

Then enable it in Karabiner-Elements UI.
EOF

