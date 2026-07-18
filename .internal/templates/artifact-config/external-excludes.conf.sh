# EXTERNAL DRIVE GLOBAL EXCLUDES
# Applied to every rsync call. Use rsync filter pattern syntax.
# Add a pattern here instead of editing individual rsync calls.

EXTERNAL_EXCLUDES=(

  # -- macOS noise -------------------------------------------------------------
  ".DS_Store"
  "desktop.ini"
  ".localized"

  # -- Office lock/temp files --------------------------------------------------
  "~$*"

  # -- Dev artifacts safe to skip ----------------------------------------------
  "DockerDesktop/"              # Docker.raw virtual disk — rebuild from registries
  "github-copilot-intellij/"    # Plugin cache — reinstall post-reimage

  # -- Installers --------------------------------------------------------------
  "*.dmg"
  "*.pkg"
  "*.zip"
  "\$RECYCLE.BIN/"

  # -- Tool caches (large, regenerated) ----------------------------------------
  "github-copilot/"             # Inside ~/.config — 54 MB cache

  # -- Azure noise -------------------------------------------------------------
  "logs/"
  "telemetry/"

  # -- Copilot session noise ---------------------------------------------------
  "history-session-state/"
  "session-state/"
  "jb/"

)
