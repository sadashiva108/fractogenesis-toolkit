# EXTERNAL DRIVE TARGETS
# Format: "LABEL | SOURCE | DEST_RELATIVE_TO_home-files-backup/ | CATEGORY | DESCRIPTION"
#
# LABEL       Short display name shown in script output and size audit
# SOURCE      Full path. Trailing slash = sync contents; no slash = sync dir itself
# DEST        Path relative to $REIMAGE_ARTIFACT_ROOT/home-files-backup/
# CATEGORY    Used in the reference doc and size audit grouping:
#               home | dotfiles | secrets | dev | media
# DESCRIPTION One-line human description (shown in reference doc and audit)
#
# To disable a target: comment out the line.

EXTERNAL_TARGETS=(

  # -- Home dirs ---------------------------------------------------------------
  "Documents           | $HOME/Documents/                     | home/Documents           | home      | Work documents, project notes, architecture docs, and personal files"
  "Desktop             | $HOME/Desktop/                       | home/Desktop             | home      | Active working files, crash triage folders, and desktop scripts"
  #"Downloads           | $HOME/Downloads/                     | home/Downloads           | home      | Recently downloaded documents and reference files (installers excluded)"
  "Music               | $HOME/Music/                         | home/Music               | media     | Personal music library (13 MB)"
  "Pictures            | $HOME/Pictures/                      | home/Pictures            | media     | Photos library and screenshots (11 MB)"
  "Movies              | $HOME/Movies/                        | home/Movies              | media     | Screen recordings and captured video (56 KB)"

  # -- Root-level personal dirs ------------------------------------------------
  #"IdeaSnapshots       | $HOME/IdeaSnapshots/                 | home/IdeaSnapshots       | dev       | IntelliJ workspace snapshots stored outside the project tree"

  # -- Development extras ------------------------------------------------------
  #"runConfigurations   | $HOME/Development/runConfigurations/ | home/Development/runConfigurations | dev | IntelliJ run/debug configurations stored outside repos"

  # -- Dotfile dirs ------------------------------------------------------------
  "~/.config           | $HOME/.config/                       | dotfiles/config          | dotfiles  | CLI tool configs: gh, git, wireshark, configstore, raycast (copilot cache excluded)"
  "~/.kube             | $HOME/.kube/                         | dotfiles/kube            | dotfiles  | Kubernetes cluster config and context definitions"
  "~/.cf               | $HOME/.cf/                           | dotfiles/cf              | dotfiles  | Cloud Foundry CLI config and installed plugins"
  "~/.azure            | $HOME/.azure/                        | dotfiles/azure           | dotfiles  | Azure CLI subscriptions, credentials, and command config (logs excluded)"
  "~/.fiddler          | $HOME/.fiddler/                      | dotfiles/fiddler         | dotfiles  | Fiddler proxy certificates, settings, and unmanaged resources"
  "~/.copilot/instructions | $HOME/.copilot/instructions/     | dotfiles/copilot/instructions | dotfiles | GitHub Copilot custom instruction files"
  "~/.copilot/prompts  | $HOME/.copilot/prompts/              | dotfiles/copilot/prompts | dotfiles  | GitHub Copilot saved prompt templates"
  "~/.copilot/ide      | $HOME/.copilot/ide/                  | dotfiles/copilot/ide     | dotfiles  | GitHub Copilot IDE integration settings"
  "dotfiles.falkor.d   | $HOME/dotfiles.falkor.d/             | dotfiles/dotfiles.falkor.d | dotfiles | Falkor dotfiles framework — shell theme, aliases, and environment config"

)
