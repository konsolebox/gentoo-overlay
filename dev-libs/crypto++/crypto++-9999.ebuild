# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit flag-o-matic git-r3 toolchain-funcs

DESCRIPTION="C++ class library of cryptographic schemes"
HOMEPAGE="http://cryptopp.com"
EGIT_REPO_URI='https://github.com/weidai11/cryptopp.git'

LICENSE="Boost-1.0"
SLOT="0"
KEYWORDS=
IUSE="static-libs"

DEPEND="app-arch/unzip"

pkg_setup() {
	export CXX="$(tc-getCXX)"
	export LIBDIR="${EPREFIX}/usr/$(get_libdir)"
	export PREFIX="${EPREFIX}/usr"
}

src_compile() {
	# higher optimizations cause problems
	replace-flags -O3 -O2
	# ASM isn't Darwin/Mach-O ready, #479554, buildsys doesn't grok CPPFLAGS
	[[ ${CHOST} == *-darwin* ]] && append-cxxflags -DCRYPTOPP_DISABLE_ASM

	emake -f GNUmakefile all shared
}

src_install() {
	default

	# remove leftovers as build system sucks
	rm -fr "${ED}"/usr/bin "${ED}"/usr/share/cryptopp
	use static-libs || rm -f "${ED}${EPREFIX}/usr/$(get_libdir)/"*.a

	# compatibility
	dosym cryptopp "${EPREFIX}"/usr/include/crypto++
	for f in "${ED}${EPREFIX}/usr/$(get_libdir)/"*; do
		ln -s "${f##*/}" "${f/cryptopp/crypto++}" || die
	done
}

pkg_preinst() {
	# we switched directory to symlink
	# make sure portage digests that
	rm -fr "${EROOT}/usr/include/crypto"{++,pp}
}