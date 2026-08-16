# ONEDRIVE TARGETS
# Subset of EXTERNAL_TARGETS. Keep narrower — OneDrive is for documents,
# not dotfiles or secrets.
#
# Same format as EXTERNAL_TARGETS. DEST is relative to $ONEDRIVE_DEST/.
# Comment out lines to disable.
#
# This destination is corporate cloud storage. Never add a path holding raw
# secrets; see the sensitive-file-type patterns in onedrive-extra-excludes.conf.sh.

ONEDRIVE_TARGETS=(
  "Documents | $HOME/Documents/ | Documents | home | Work documents synced to corporate OneDrive"
  "Desktop   | $HOME/Desktop/   | Desktop   | home | Desktop files synced to corporate OneDrive"
  # "Downloads | $HOME/Downloads/ | Downloads | home | Downloaded files — uncomment if wanted"
  # "Music     | $HOME/Music/     | Music     | media | Personal music — uncomment if wanted"
  # "Pictures  | $HOME/Pictures/  | Pictures  | media | Photos — uncomment if wanted"
)
