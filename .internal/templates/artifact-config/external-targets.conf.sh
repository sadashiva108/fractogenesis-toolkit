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
#
# Do NOT add a source path that holds raw, unencrypted secrets — private keys,
# keystores, credential files, token caches. Everything listed here is copied in
# the clear, and the loose-plaintext cleanup in create-secrets-dmg.md only knows
# about the staging folders it packaged, so a plaintext copy left here survives.
# Secret-bearing paths belong in secrets-targets.conf.sh, which routes them into
# secrets-encrypted/ for the DMG to encrypt.

EXTERNAL_TARGETS=(

  # -- Home dirs ---------------------------------------------------------------
  "Documents           | $HOME/Documents/                     | home/Documents           | home      | Work documents, project notes, architecture docs, and personal files"
  "Desktop             | $HOME/Desktop/                       | home/Desktop             | home      | Active working files and desktop scripts"
  #"Downloads           | $HOME/Downloads/                     | home/Downloads           | home      | Recently downloaded documents and reference files (installers excluded)"
  "Music               | $HOME/Music/                         | home/Music               | media     | Personal music library"
  "Pictures            | $HOME/Pictures/                      | home/Pictures            | media     | Photos library and screenshots"
  "Movies              | $HOME/Movies/                        | home/Movies              | media     | Screen recordings and captured video"

  # -- Root-level personal dirs ------------------------------------------------
  # Examples. Uncomment and edit for the directories this Mac actually has.
  #"<personal-dir>      | $HOME/<personal-dir>/                | home/<personal-dir>      | home      | A top-level directory you keep work in"

  # -- Development extras ------------------------------------------------------
  # Examples. IDE state kept outside repo working trees.
  #"runConfigurations   | $HOME/<dev-dir>/runConfigurations/   | home/runConfigurations   | dev       | IDE run/debug configurations stored outside repos"
  #"ide-snapshots       | $HOME/<ide-snapshots-dir>/           | home/ide-snapshots       | dev       | IDE workspace snapshots stored outside the project tree"

  # -- Dotfile dirs ------------------------------------------------------------
  "~/.config           | $HOME/.config/                       | dotfiles/config          | dotfiles  | CLI tool configs: gh, git, wireshark, configstore, raycast (copilot cache excluded)"
  "~/.kube             | $HOME/.kube/                         | dotfiles/kube            | dotfiles  | Kubernetes cluster config and context definitions"
  "~/.cf               | $HOME/.cf/                           | dotfiles/cf              | dotfiles  | Cloud Foundry CLI config and installed plugins"
  "~/.azure            | $HOME/.azure/                        | dotfiles/azure           | dotfiles  | Azure CLI subscriptions, credentials, and command config (logs excluded)"
  "~/.fiddler          | $HOME/.fiddler/                      | dotfiles/fiddler         | dotfiles  | Fiddler proxy certificates, settings, and unmanaged resources"
  "~/.copilot/instructions | $HOME/.copilot/instructions/     | dotfiles/copilot/instructions | dotfiles | GitHub Copilot custom instruction files"
  "~/.copilot/prompts  | $HOME/.copilot/prompts/              | dotfiles/copilot/prompts | dotfiles  | GitHub Copilot saved prompt templates"
  "~/.copilot/ide      | $HOME/.copilot/ide/                  | dotfiles/copilot/ide     | dotfiles  | GitHub Copilot IDE integration settings"
  #"dotfiles-framework  | $HOME/<dotfiles-dir>/                | dotfiles/<dotfiles-dir>  | dotfiles  | Example: a dotfiles framework directory — shell theme, aliases, environment config"

)
