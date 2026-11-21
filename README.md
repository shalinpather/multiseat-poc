<!--
SPDX-License-Identifier: 0BSD
-->

# Single-GPU Linux Multiseat Proof-of-Concept

**This document is under construction.**

## Table of Contents

- [License](#license)
  - [Third-Party Attribution](#third-party-attribution)

## Overview

This project aims to produce a proof-of-concept for a contemporary graphical [multiseat](https://en.wikipedia.org/wiki/Multiseat_configuration) system using [Debian GNU/Linux 13 (Trixie)](https://www.debian.org/).
This enables a single GNU/Linux system to serve multiple physical users simultaneously, each with a dedicated monitor, keyboard and mouse, as opposed to the traditional model of one computer per user.
It is the modern graphical equivalent to historic text-based [time-sharing systems](https://en.wikipedia.org/wiki/Time-sharing).

The ability to scale a single computer to multiple users enables frugal innovation.
Linux provides the technology required for this setup.
By design, it enables a secure, efficient, and robust multi-user system.
Moreover, it allows older computers rendered unusable by [planned obsolescence](https://endof10.org) to continue serving users.
In constrained and under-resourced environments, such as schools and public libraries across the [Global South](https://en.wikipedia.org/wiki/Global_North_and_Global_South), this improves the efficiency, feasibility, and accesibility of mass computing.

The project was motivated by such applications and the lack of relevant, recent documentation required to produce a functional multiseat system.
Using modern Linux primitives, such as [DRM/KMS](https://docs.kernel.org/gpu/drm-kms.html), a robust setup can be achieved for production environments.
These were unavailable in previous multiseat deployments, such as the Brazillian [C3SL](https://multiterminal.c3sl.ufpr.br/) architecture.

This proof-of-concept is not suitable for production deployments.
For instance, peripheral identifiers and video connectors must be hardcoded.
Hotplugging may cause malfunction.
Next, no robust lifecycle management and recovery mechanisms have been implemented.
Finally, intimate technical knowledge is required simply to bring up and maintain this setup, and to recover from errors.
The human reality of computing, especially in a public setting, necessitates handling them seamlessly.
Thus, future work involves the development of a more robust, highly available, and automated setup.

Nevertheless, this proof-of-concept provides a platform for hackers to explore.
It is fully functional within the aforementioned constraints.
While future work aims to focus on the internal mechanism that supports multiple seats, the user-facing interface (i.e., the graphical desktop environment) remains unchanged.
Thus, the multiseat setup may be explored and used feasibly today in a limited or testing capacity for daily work.
Moreover, necessary improvements may be explored and implemented, such as per-seat audio.

Overall, this project aims to benefit the open-source community with new relevant information on multiseat computing.
It aims to deliver a functional *contemporary* multiseat setup.
Being a crude proof-of-concept, it is not open to direct contributions or pull requests.
However, it aims to start a broader movement and revive interest in multiseat computing as an efficient solution to issues facing society.
Moreover, it does not pretend to have invented a generic setup wizard for any machine.
The code in this repository simply automates the creation of the functional mltiseat environment for the test setup used in this project's development.
Interested users may fork and modify this repository for further exploration.

<!-- TODO: upload LinkedIn video to YouTube and link here -->

## License

&copy; 2026 Shalin Pather [shalin.pather01@gmail.com]

Unless otherwise noted, all code and documentation in this repository are licensed under the BSD Zero Clause License (`0BSD`).
See [LICENSE.md](LICENSE.md) in the project root, or https://opensource.org/licenses/0BSD for full license information.

The [SPDX](https://spdx.dev) license identifier for this project is `0BSD`.

### Third-Party Attribution

- **`xserver_multiseat.patch`**: Authored by **Pixo** and originally shared on the [Level1Techs Forum](https://forum.level1techs.com/t/drm-lease-manager-service/197584) (2024/12/19 20:03:00) as a patch against upstream `xorg-server` (MIT/X11
  license).
  The patch was modified around the `if (fd < 0)` block to add missing braces, ensuring conditional fallback to a DRM render node only if opening the primary node fails.
