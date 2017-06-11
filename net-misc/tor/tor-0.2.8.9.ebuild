# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils flag-o-matic readme.gentoo-r1 systemd toolchain-funcs versionator user

MY_PV=$(replace_version_separator 4 -)
MY_PF=tor-${MY_PV}
DESCRIPTION="Anonymizing overlay network for TCP"
HOMEPAGE="http://www.torproject.org/"
SRC_URI="https://www.torproject.org/dist/${MY_PF}.tar.gz
	https://archive.torproject.org/tor-package-archive/${MY_PF}.tar.gz"
S=${WORKDIR}/${MY_PF}

LICENSE="BSD GPL-2"
SLOT=0
KEYWORDS="~amd64 ~x86"
IUSE="chroot -bufferevents libressl scrypt seccomp selinux stats systemd tor-hardening transparent-proxy test web"

DEPEND="
	app-text/asciidoc
	dev-libs/libevent
	sys-libs/zlib
	bufferevents? ( dev-libs/libevent[ssl] )
	!libressl? ( dev-libs/openssl:0=[-bindist] )
	libressl? ( dev-libs/libressl:0= )
	scrypt? ( app-crypt/libscrypt )
	seccomp? ( sys-libs/libseccomp )
	systemd? ( sys-apps/systemd )"
RDEPEND="${DEPEND}
	chroot? (
		sys-apps/rcopy
		sys-process/psmisc
		virtual/awk
	)
	selinux? ( sec-policy/selinux-tor )"

pkg_setup() {
	enewgroup tor
	enewuser tor -1 -1 /var/lib/tor tor
}

src_prepare() {
	epatch_user
}

src_configure() {
	# Upstream isn't sure of all the user provided CFLAGS that
	# will break tor, but does recommend against -fstrict-aliasing.
	# We'll filter-flags them here as we encounter them.
	filter-flags -fstrict-aliasing

	econf \
		--enable-system-torrc \
		--enable-asciidoc \
		--docdir="${EPREFIX}/usr/share/doc/${PF}" \
		$(use_enable stats instrument-downloads) \
		$(use_enable bufferevents) \
		$(use_enable scrypt libscrypt) \
		$(use_enable seccomp) \
		$(use_enable systemd) \
		$(use_enable tor-hardening gcc-hardening) \
		$(use_enable tor-hardening linker-hardening) \
		$(use_enable transparent-proxy transparent) \
		$(use_enable web tor2web-mode) \
		$(use_enable test unittests) \
		$(use_enable test coverage)
}

src_install() {
	readme.gentoo_create_doc

	newconfd "${FILESDIR}"/tor.confd-r1 tor
	newinitd "${FILESDIR}"/tor.initd-r1 tor

	if use chroot; then
		newconfd "${FILESDIR}"/tor-chroot.confd-r1 tor-chroot
		newinitd "${FILESDIR}"/tor-chroot.initd-r1 tor-chroot
	fi

	systemd_dounit "${FILESDIR}"/tor.service

	emake DESTDIR="${ED}" install

	keepdir /var/lib/tor

	dodoc -r README ChangeLog ReleaseNotes doc/HACKING

	fperms 750 /var/lib/tor
	fowners tor:tor /var/lib/tor

	insinto /etc/tor/
	newins "${FILESDIR}"/torrc torrc
	newins "${FILESDIR}"/torrc.notes torrc.notes
}

pkg_postinst() {
	readme.gentoo_create_doc

	einfo ""

	if use chroot; then
		einfo "If you plan to run Tor in chroot mode, configure /etc/conf.d/tor-chroot,"
		einfo "and run /etc/init.d/tor-chroot setup."
	else
		einfo "If you plan to run Tor in chroot mode, please enable 'chroot' use flag."
	fi

	einfo ""
}