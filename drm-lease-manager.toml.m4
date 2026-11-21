divert(-1)
SPDX-License-Identifier: 0BSD

drm-lease-manager.toml
DRM Lease Manager configuration template for the single-GPU multiseat
proof-of-concept.

Shalin Pather
shalin.pather01@gmail.com
2026/11/21

Usage:
echo 'CONF(<N>, <con>)' | m4 drm-lease-manager.toml -

- N: number of the current seat (whole number)
- con: connector name (e.g., `HDMI-A-1')

define(`CONF', `dnl
[[lease]]
name = "seat$1"
connectors = ["$2"]dnl
')

divert(0)dnl
