# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

_BASH_BUILD_INSTALL_TYPE=system
_BASH_BUILD_READLINE_VER=8.2
_BASH_BUILD_PATCHES=(
	bash-5.0-syslog-history-extern.patch
	bash-5.2_p15-random-ub.patch
	bash-5.2_p15-configure-clang16.patch
)
_BASH_BUILD_PATCH_OPTIONS=(-p0)
_BASH_BUILD_REQUIRE_YACC=true
_BASH_BUILD_USE_ARCHIVED_PATCHES=false

inherit bash-build

KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86 ~x64-cygwin ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"