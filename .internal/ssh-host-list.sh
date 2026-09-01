#!/usr/bin/env bash
# ssh-host-list.sh -- the normalized `Host` list from an ssh_config file.
#
# Sourced, never run. Defines one function, sets no options, exports nothing.
#
# Two scripts on opposite sides of the reimage need this answer in the same
# shape: `capture-system-inventory.sh` writes it into the pre-image `08-git.txt`
# as `ssh.hosts=`, and `compare-restored-state.sh` derives it from the live file
# so the two can be compared as a single value. Deriving it separately in each
# place is how they drift into disagreeing about formatting and reporting a
# mismatch that is not one, so it lives here once.
#
# `[Hh]ost[[:space:]]` and not `[Hh]ost`: `HostName` also begins with "Host",
# and matching it would put every server's real address into a list meant to
# hold the names the operator types in a clone URL -- which is exactly the
# distinction that matters when one of them is an alias. A `Host` line may
# carry several patterns, so they are split apart, and the result is sorted so
# the value does not depend on the order blocks happen to sit in the file.
#
# `LC_ALL=C` on the sort is not decoration. The capture runs on the pre-image
# Mac and the comparison on the restored one, and a collation difference between
# them reorders the list without changing its contents -- a mismatch reported
# against two identical sets of hosts.
#
# Prints nothing and returns 0 when the file is absent. That is deliberate: an
# empty value compared against a recorded one is a visible difference, whereas
# a non-zero return would read as the check itself having failed.

ssh_host_list() {
  local cfg="${1:-$HOME/.ssh/config}"
  [ -f "$cfg" ] || return 0
  sed -nE 's/^[[:space:]]*[Hh]ost[[:space:]]+(.*)$/\1/p' "$cfg" \
    | tr '[:blank:]' '\n' \
    | grep -v '^$' \
    | LC_ALL=C sort -u \
    | paste -sd, -
}
