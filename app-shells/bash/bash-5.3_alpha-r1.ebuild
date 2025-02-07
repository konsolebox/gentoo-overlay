# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

_BASH_BUILD_INSTALL_TYPE=system
_BASH_BUILD_ETC_VERSION=1
_BASH_BUILD_PATCH_OPTIONS=(-p0)
_BASH_BUILD_PATCHES=(
	bash-5.0-syslog-history-extern.patch
	bash-5.3_alpha-fix-externs.patch
)
_BASH_BUILD_READLINE_VER=8.3_alpha
_BASH_BUILD_VERIFY_SIG=true

inherit bash-build

RESTRICT="mirror"
