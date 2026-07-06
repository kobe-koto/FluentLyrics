MediaRemote Adapter
===================

This directory stores the vendored files that are bundled into the macOS app
for MediaRemote access.

Pinned upstream version: v0.7.6
Upstream: https://github.com/ungive/mediaremote-adapter
License: BSD-3-Clause, see LICENSE.

Expected files after preparing the vendor directory:

- bin/mediaremote-adapter.pl
- MediaRemoteAdapter.framework
- MediaRemoteAdapterTestClient (optional, used by upstream's test command)
- LICENSE
- VERSION

Run this from a macOS machine to build/update the native artifacts:

    ./tool/macos_prepare_mediaremote_adapter.sh

The Flutter macOS Xcode target fails fast when the framework is missing,
because macOS media integration no longer has an osascript fallback.
