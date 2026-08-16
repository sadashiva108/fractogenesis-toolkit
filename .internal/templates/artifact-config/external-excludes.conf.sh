# EXTERNAL DRIVE GLOBAL EXCLUDES
# Applied to every rsync call. Use rsync filter pattern syntax.
# Add a pattern here instead of editing individual rsync calls.

EXTERNAL_EXCLUDES=(
  # Claude Code CLI (~/.claude/). Only two entries, both deliberate:
  # shell-snapshots/ and session-env/ capture the shell environment at
  # invocation time, so exported secrets can land there in plaintext. Excluded
  # for that reason, not for size. Transcripts, memory, plugins and settings are
  # all kept. telemetry/ and logs/ are already excluded further down.
  #
  # NOTE: every pattern in this list applies to EVERY target, at any depth — a
  # generic name like "cache/" would silently drop cache directories out of
  # Documents too. Keep new entries distinctive.
  "shell-snapshots/"
  "session-env/"

  # -- macOS noise -------------------------------------------------------------
  ".DS_Store"
  "desktop.ini"
  ".localized"

  # -- Office lock/temp files --------------------------------------------------
  "~\$*"

  # -- Dev artifacts safe to skip ----------------------------------------------
  "DockerDesktop/"              # Docker.raw virtual disk — rebuild from registries
  "github-copilot-intellij/"    # Plugin cache — reinstall post-reimage

  # -- Installers --------------------------------------------------------------
  "*.dmg"
  "*.pkg"
  "*.zip"
  "\$RECYCLE.BIN/"

  # -- Tool caches (large, regenerated) ----------------------------------------
  "github-copilot/"             # Inside ~/.config — caches, plugins, session DBs.
                                # NOT cache: intellij/*.md and intellij/mcp.json are
                                # hand-authored and re-captured by the Copilot Global
                                # Cfg target above.
  "auth.db"                     # Copilot OAuth store — machine-bound; re-auth after reimage
  "auth.db-shm"
  "auth.db-wal"
  "oauth.json"                  # Copilot OAuth tokens — re-auth rather than restore

  # -- Azure noise -------------------------------------------------------------
  "logs/"
  "telemetry/"

  # -- Copilot session noise ---------------------------------------------------
  "history-session-state/"
  "session-state/"
  "jb/"

)
