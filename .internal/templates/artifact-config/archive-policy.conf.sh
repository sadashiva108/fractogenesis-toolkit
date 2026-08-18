# ARCHIVE POLICY
#
# Which compressed archives get copied to the artifact root and to OneDrive.
#
# Default is KEEP. An archive is copied unless a pattern in ARCHIVE_SKIP
# matches it. ARCHIVE_KEEP is evaluated first and wins, so it carves an
# exception out of a broad ARCHIVE_SKIP entry.
#
# Why default-keep rather than default-skip. A blanket "*.zip" style rule
# belongs nowhere in external-excludes.conf.sh: that list is passed to EVERY
# rsync call at any depth, so an extension rule aimed at an installer folder
# silently drops evidence bundles, exported collections and archived reports
# out of every other target as well. A curated keep-list is the obvious
# alternative and does not hold either -- archives are named by whoever made
# them, so any hand-written list of shapes will miss some. Defaulting to keep
# means an unforeseen archive is backed up rather than silently lost, and the
# cost of a wrong keep is disk, while the cost of a wrong skip is data.
#
# Skip an archive when it is large AND its content is already captured in a
# better form elsewhere on the artifact root, or when it is a redistributable
# installer that can simply be downloaded again. Say which in the comment, so
# a later reader can tell a deliberate skip from an accident.
#
# Patterns are rsync filter rules:
#   - no "/" matches the filename at any depth
#   - with a "/" it is matched against the path relative to that target's own
#     source root, e.g. "some-folder/*.zip"
#
# Both lists apply to the external drive and to OneDrive. OneDrive's own
# ONEDRIVE_EXTRA_EXCLUDES still runs on top, so anything already blocked from
# corporate cloud there needs no entry here.

ARCHIVE_KEEP=(
  # Exceptions that beat ARCHIVE_SKIP below. Only needed once ARCHIVE_SKIP
  # contains a pattern broad enough to catch something worth keeping.
  #
  #   "incident-evidence-*.zip"
)

ARCHIVE_SKIP=(
  # Empty by default: every archive under a target is backed up. Add an entry
  # only for a specific archive you have decided not to keep, with the reason.
  #
  #   # ~6 GB raw watcher logs; the extracted evidence is already under
  #   # office-stability/watcher-history/.
  #   "some-watcher-archive.zip"
  #
  #   # Vendor installer, re-downloadable.
  #   "SomeVendorInstaller-*.dmg"
)
