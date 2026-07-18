# EXTERNAL DRIVE DOTFILES
# Individual files at ~/. Missing files are silently skipped.
#
# Format: "FILENAME | CATEGORY | DESCRIPTION"

EXTERNAL_DOTFILES=(

  # -- Shell -------------------------------------------------------------------
  ".zshrc             | dotfiles | Primary Zsh config — prompt, options, plugin loading"
  ".bashrc            | dotfiles | Bash interactive shell config"
  ".bash_profile      | dotfiles | Bash login shell config — sourced for login shells"
  ".zprofile          | dotfiles | Zsh login shell config — PATH and env setup"
  ".exports           | dotfiles | Exported environment variables (PATH, JAVA_HOME, etc.)"
  ".aliases           | dotfiles | Additional alias definitions"
  ".functions         | dotfiles | Shell function definitions"

  # -- Git ---------------------------------------------------------------------
  ".gitconfig         | dotfiles | Global Git config — user, aliases, merge tool, credential helper"
  ".gitignore_global  | dotfiles | Global gitignore patterns applied to all repos"

  # -- Package managers --------------------------------------------------------
  ".npmrc             | secrets  | npm config — registry, auth tokens, default options; also include in secrets DMG"
  ".yarnrc            | secrets  | Yarn v1 config; may contain registry auth settings"
  ".yarnrc.yml        | secrets  | Yarn v2+ (Berry) config; may contain npm auth tokens"

  # -- Sensitive ---------------------------------------------------------------
  ".netrc             | secrets  | FTP/HTTP credentials — also include in secrets DMG"

)
