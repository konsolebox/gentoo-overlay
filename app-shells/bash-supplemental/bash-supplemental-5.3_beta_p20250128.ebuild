# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

_BASH_BUILD_INSTALL_TYPE=supplemental
_BASH_BUILD_ALLOW_BASH_SOURCE_FULLPATH_DEFAULT=true
_BASH_BUILD_PATCH_OPTIONS=(-p0)
_BASH_BUILD_PATCHES=(bash-5.0-syslog-history-extern.patch)
_BASH_BUILD_READLINE_VER=8.3_alpha
_BASH_BUILD_SNAPSHOT_COMMIT=0390b4354a9e5df517ef2d4f9d78a099063b22b4

inherit bash-build

RESTRICT="mirror"
