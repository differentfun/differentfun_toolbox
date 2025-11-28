#!/bin/bash

# GUI helper for sudo when no terminal is available.
# Prints the password to stdout so sudo -A can read it.
PROMPT="${SUDO_ASKPASS_PROMPT:-Inserisci la password amministratore per continuare:}"

if ! command -v zenity >/dev/null 2>&1; then
  echo "zenity is required to request administrator privileges." >&2
  exit 1
fi

zenity --password \
  --title="DifferentFun Toolbox" \
  --text="$PROMPT"
