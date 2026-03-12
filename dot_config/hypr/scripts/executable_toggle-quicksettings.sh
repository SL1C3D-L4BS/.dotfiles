#!/usr/bin/env bash
# SL1C3D-L4BS — Toggle quicksettings (AGS)

set -e

HOME_DIR="${HOME:-/home/the_architect}"

if ! "$HOME_DIR/.config/SL1C3D-L4BS/bin/sl1c3d-ags" doctor >/dev/null 2>&1; then
  "$HOME_DIR/.config/SL1C3D-L4BS/bin/sl1c3d-ags" doctor
  exit 1
fi

ags toggle quicksettings
