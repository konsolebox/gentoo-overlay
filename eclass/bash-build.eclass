# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

[[ ${EAPI} == 7 ]] || die "EAPI needs to be 7."

inherit flag-o-matic toolchain-funcs multilib prefix

[[ ${PV} == *9999* ]] && inherit autotools git-r3

# @ECLASS: bash-build.eclass
# @MAINTAINER:
# konsolebox@gmail.com
# @AUTHOR:
# konsolebox <konsolebox@gmail.com>
# Authors of app-shells/bash::gentoo
# @SUPPORTED_EAPIS: 7
# @BLURB: Eclass for building bash
# @DESCRIPTION:
# This eclass contains unified code for building bash.

# @ECLASS_VARIABLE: _BASH_BUILD_ALLOW_BASH_SOURCE_FULLPATH_DEFAULT
# @DESCRIPTION:
# Whether to allow the '--bash-source-fullpath-default' configure option of Bash to be enabled
# through the bash-source-fullpath-default IUSE flag

# @ECLASS_VARIABLE: _BASH_BUILD_ETC_VERSION
# @DESCRIPTION:
# Indicates the collective vesion of the bash-related files installed in /etc
# This defaults to 0.

# @ECLASS_VARIABLE: _BASH_BUILD_INSTALL_TYPE
# @DESCRIPTION:
# Indicates whether the installation type is 'system' or 'supplemental'
# @REQUIRED

# @ECLASS_VARIABLE: _BASH_BUILD_PATCH_OPTIONS
# @DESCRIPTION:
# Specifies the options for epatch

# @ECLASS_VARIABLE: _BASH_BUILD_PATCHES
# @DESCRIPTION:
# Specifies the non-official patches

# @ECLASS_VARIABLE: _BASH_BUILD_READLINE_VER
# @DESCRIPTION:
# Declares the required version of Readline.
# This doesn't have to be specified in *9999* ebuilds.

# @ECLASS_VARIABLE: _BASH_BUILD_REQUIRE_BISON
# @DESCRIPTION:
# Whether to specify Bison as a build-time dependency or not

# @ECLASS_VARIABLE: _BASH_BUILD_USE_ARCHIVED_PATCHES
# @DESCRIPTION:
# Whether to use patches from github.com/konsolebox/gentoo-bash-patches

# @ECLASS_VARIABLE: _BASH_BUILD_VERIFY_SIG
# @DESCRIPTION:
# Whether to provide the 'verify-sig' flag and allow verification of signatures

if [[ ${_BASH_BUILD_VERIFY_SIG-} == true ]]; then
	VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/chetramey.asc
	inherit verify-sig
fi

# @ECLASS_VARIABLE: _BASH_BUILD_SNAPSHOT_COMMIT
# @DESCRIPTION:
# If this vaiable is set, git commit snapshots from
# https://git.savannah.gnu.org/cgit/bash.git/snapshot/ are used as sources instead.
# The PV won't matter.

# @ECLASS_VARIABLE: _BASH_BUILD_PATCH_COMMIT
# @DESCRIPTION:
# Commit version of old Bash patches uploaded in https://github.com/konsolebox/gentoo-bash-patches.
# Only old versions of Bash need this.
# @INTERNAL
_BASH_BUILD_PATCH_COMMIT=693bbda26e14280fa11cfdbe8930f63355c00cc3

# @ECLASS_VARIABLE: _BASH_BUILD_PLEVEL
# @DESCRIPTION:
# Bash's patch level
# @INTERNAL
_BASH_BUILD_PLEVEL=0

# @ECLASS_VARIABLE: _BASH_BUILD_PV
# @DESCRIPTION:
# Generated PV without patch.
# @INTERNAL
_BASH_BUILD_PV=${PV/_p*} _BASH_BUILD_PV=${_BASH_BUILD_PV//_/-}

# @ECLASS_VARIABLE: _BASH_BUILD_PV_PARTS
# @DESCRIPTION:
# Split ${_BASH_BUILD_PV}
# @INTERNAL
_BASH_BUILD_PV_PARTS=(${_BASH_BUILD_PV//[.-]/ })

# @ECLASS_VARIABLE: _BASH_BUILD_TARBALL
# @DESCRIPTION:
# Main source tarball file
# @INTERNAL

# @FUNCTION: _bash-build_get_patches
# @USAGE: result_var, [-s]
# @DESCRIPTION:
# Gets a list of official patches based on _BASH_BUILD_PLEVEL.
# Specifying '-s' returns the location of the files in the filesystem.
# Not specifying '-s' returns their remote URI.
# List of patches are stored in the _patches variable.
# @RETURN: OK status (0) if there are patches, or FAIL status (1) otherwise.
# @INTERNAL
_bash-build_get_patches() {
	local opt=$1 prefix=bash${_BASH_BUILD_PV/\.} patches=() i s p

	for (( i = 1; i <= _BASH_BUILD_PLEVEL; ++i )); do
		printf -v 'patches[i]' "${prefix}-%03d" "${i}"
	done

	if [[ ${opt} == -s ]]; then
		_patches=("${patches[@]/#/${DISTDIR}/}")
	else
		_patches=()

		for s in "mirror://gnu/bash" "ftp://ftp.cwru.edu/pub/bash"; do
			_patches+=("${patches[@]/#/${s}/bash-${_BASH_BUILD_PV}-patches/}")
		done
	fi

	[[ ${#_patches[@]} -gt 0 ]]
}

# @FUNCTION: _bash-build_set_globals
# @DESCRIPTION:
# Sets up global variables
# @INTERNAL
_bash-build_set_globals() {
	DESCRIPTION="The standard GNU Bourne again shell"
	HOMEPAGE="http://tiswww.case.edu/php/chet/bash/bashtop.html"

	if [[ ${PV%%.*} -ge 4 ]]; then
		LICENSE="GPL-3"
	else
		LICENSE="GPL-2"
	fi

	IUSE="afs bundled-readline mem-scramble +net nls pgo +readline static vanilla"

	if [[ ${_BASH_BUILD_ALLOW_BASH_SOURCE_FULLPATH_DEFAULT-} == true ]]; then
		IUSE+=" bash-source-fullpath-default"
	fi

	[[ ${_BASH_BUILD_VERIFY_SIG-} == true ]] && IUSE+=" verify-sig"

	if [[ ${_BASH_BUILD_INSTALL_TYPE} == system ]]; then
		SLOT=0
		IUSE+=" bashlogger examples plugins"

		if [[ _BASH_BUILD_PV_PARTS -lt 4 || (_BASH_BUILD_PV_PARTS -eq 4 &&
				_BASH_BUILD_PV_PARTS[1] -lt 3) ]]; then
			die "System bash must at least be version 4.3."
		fi
	elif [[ ${_BASH_BUILD_INSTALL_TYPE} == supplemental ]]; then
		if [[ ${PV} == *_alpha* || ${PV} == *_beta* || ${PV} == *_rc* ]]; then
			SLOT=${PV/_p/-}
		else
			SLOT=${PV/_p/.}
		fi

		SLOT=${SLOT//_/-}
	else
		die "Invalid install type: ${_BASH_BUILD_INSTALL_TYPE}"
	fi

	local may_use_system_readline=false _patches

	if [[ ${_BASH_BUILD_VERIFY_SIG-} == true ]]; then
		if [[ ${_BASH_BUILD_SNAPSHOT_COMMIT+.} ]]; then
			die "Verify-sig can't be enabled when _BASH_BUILD_SNAPSHOT_COMMIT is set."
		elif [[ ${PV} == *9999* ]]; then
			die "Verify-sig can't be enabled in *9999* versions."
		fi
	fi

	if [[ ${_BASH_BUILD_SNAPSHOT_COMMIT+.} ]]; then
		_BASH_BUILD_TARBALL=bash-${PV}-${_BASH_BUILD_SNAPSHOT_COMMIT}.tar.gz
		SRC_URI="https://git.savannah.gnu.org/cgit/bash.git/snapshot/bash-${_BASH_BUILD_SNAPSHOT_COMMIT}.tar.gz ->
				${_BASH_BUILD_TARBALL}"
		S=${WORKDIR}/bash-${_BASH_BUILD_SNAPSHOT_COMMIT}
	elif [[ ${PV} == *9999* ]]; then
		EGIT_REPO_URI="https://git.savannah.gnu.org/git/bash.git"

		if [[ ${PV} == 9999 ]]; then
			EGIT_BRANCH=master
		elif [[ ${PV} == 99999 ]]; then
			EGIT_BRANCH=devel
		else
			die "Invalid *9999* version"
		fi
	elif [[ ${PV} == *_alpha* || ${PV} == *_beta* || ${PV} == *_rc* ]]; then
		_BASH_BUILD_TARBALL=bash-${_BASH_BUILD_PV}.tar.gz
		SRC_URI="mirror://gnu/bash/${_BASH_BUILD_TARBALL} ftp://ftp.cwru.edu/pub/bash/${_BASH_BUILD_TARBALL}"
		[[ ${_BASH_BUILD_VERIFY_SIG-} == true ]] && SRC_URI+=" verify-sig? ( ${SRC_URI//.gz/.gz.sig} )"
		S=${WORKDIR}/bash-${_BASH_BUILD_PV}
	else
		_BASH_BUILD_TARBALL=bash-${_BASH_BUILD_PV}.tar.gz
		[[ ${SLOT} == 0 ]] && may_use_system_readline=true
		SRC_URI="mirror://gnu/bash/${_BASH_BUILD_TARBALL}"
		[[ ${_BASH_BUILD_VERIFY_SIG-} == true ]] && SRC_URI+=" verify-sig? ( ${SRC_URI}.sig )"
		[[ ${PV} == *_p* ]] && _BASH_BUILD_PLEVEL=${PV##*_p}

		if [[ _BASH_BUILD_PLEVEL -gt 0 ]]; then
			_bash-build_get_patches || die
			SRC_URI+=" ${_patches[*]}"
			[[ ${_BASH_BUILD_VERIFY_SIG-} == true ]] && SRC_URI+=" verify-sig? ( ${_patches[*]/%/.sig} )"
		fi

		S=${WORKDIR}/bash-${_BASH_BUILD_PV}
	fi

	if [[ ${#_BASH_BUILD_PATCHES[@]} -gt 0 && ${_BASH_BUILD_USE_ARCHIVED_PATCHES-} == true ]]; then
		SRC_URI+=" https://github.com/konsolebox/gentoo-bash-patches/archive/${_BASH_BUILD_PATCH_COMMIT}.tar.gz -> gentoo-bash-patches-${_BASH_BUILD_PATCH_COMMIT}.tar.gz"
	fi

	local static_readline_dep= non_static_readline_dep=

	if [[ ${may_use_system_readline} == true ]]; then
		[[ -z ${_BASH_BUILD_READLINE_VER-} ]] && die "Readline version needs to be provided."
		non_static_readline_dep="readline? ( !bundled-readline? ( >=sys-libs/readline-${_BASH_BUILD_READLINE_VER}:0= ) )"
		static_readline_dep="readline? ( !bundled-readline? ( >=sys-libs/readline-${_BASH_BUILD_READLINE_VER}[static-libs(+)] ) )"
	else
		REQUIRED_USE="readline? ( bundled-readline )"
	fi

	RDEPEND="
		!static? (
			>=sys-libs/ncurses-5.9-r3:0=
			${non_static_readline_dep}
		)
	"

	DEPEND="
		${RDEPEND}
		static? (
			>=sys-libs/ncurses-5.9-r3[static-libs(+)]
			${static_readline_dep}
		)
		nls? ( virtual/libintl )
		!<sys-apps/portage-2.1.6.7_p1
		!sys-libs/libtermcap-compat
	"

	BDEPEND="pgo? ( dev-util/gperf )"
	[[ ${_BASH_BUILD_REQUIRE_BISON-} == true ]] && BDEPEND+=" sys-devel/bison"
	[[ ${_BASH_BUILD_VERIFY_SIG} == true ]] && BDEPEND+=" verify-sig? ( sec-keys/openpgp-keys-chetramey )"
	[[ ${SLOT} != 0 && ${PN} != bash ]] && RDEPEND+="!app-shells/bash:${SLOT}"
}

# @FUNCTION: bash-build_pkg_setup
# @DESCRIPTION:
# Implements pkg_setup
bash-build_pkg_setup() {
	if is-flag -malign-double; then #7332
		die "CFLAGS '-malign-double' breaks LFS (struct stat64) on x86."
	fi

	if [[ ${SLOT} == 0 ]] && use bashlogger; then
		ewarn "The logging patch should ONLY be used in restricted (i.e. honeypot) envs."
		ewarn "This will log ALL output you enter into the shell, you have been warned."
	fi
}

# @FUNCTION: bash-build_src_unpack
# @DESCRIPTION:
# Implements src_unpack
bash-build_src_unpack() {
	if [[ ${_BASH_BUILD_TARBALL-} ]]; then
		if [[ ${_BASH_BUILD_VERIFY_SIG-} == true ]] && use verify-sig; then
			verify-sig_verify_detached "${DISTDIR}/bash-${_BASH_BUILD_PV}.tar.gz"{,.sig}

			if [[ _BASH_BUILD_PLEVEL -gt 0 ]]; then
				local patch
				_bash-build_get_patches -s || die

				for patch in "${_patches[@]}" ; do
					verify-sig_verify_detached "${patch}"{,.sig}
				done
			fi
		fi

		unpack "${_BASH_BUILD_TARBALL}"
	else
		git-r3_src_unpack
	fi

	if [[ ${#_BASH_BUILD_PATCHES[@]} -gt 0 && ${_BASH_BUILD_USE_ARCHIVED_PATCHES-} == true ]] &&
			! use vanilla; then
		unpack "gentoo-bash-patches-${_BASH_BUILD_PATCH_COMMIT}.tar.gz"
	fi
}

# @FUNCTION: bash-build_src_prepare
# @DESCRIPTION:
# Implements src_prepare
bash-build_src_prepare() {
	local _patches

	# Include official patches
	if [[ _BASH_BUILD_PLEVEL -gt 0 ]]; then
		_bash-build_get_patches -s || die
		eapply -p0 "${_patches[@]}"
	fi

	if ! use bundled-readline; then
		# Clean out local libs so we know we use system ones
		rm -rf lib/{readline,termcap}/* || die
		touch lib/{readline,termcap}/Makefile.in || die # for config.status
		sed -ri -e 's:\$[{(](RL|HIST)_LIBSRC[)}]/[[:alpha:]_-]*\.h::g' Makefile.in || die
	fi

	# Prefixify hardcoded path names. No-op for non-prefix.
	[[ -e pathnames.h.in ]] && hprefixify pathnames.h.in

	# Avoid regenerating docs after patches #407985
	sed -i -r '/^(HS|RL)USER/s:=.*:=:' doc/Makefile.in || die
	touch -r . doc/*

	if [[ ${#_BASH_BUILD_PATCHES[@]} -gt 0 ]] && ! use vanilla; then
		local prefix=${FILESDIR%/}/

		if [[ ${_BASH_BUILD_USE_ARCHIVED_PATCHES-} == true ]]; then
			prefix=${WORKDIR}/gentoo-bash-patches-${_BASH_BUILD_PATCH_COMMIT}/patches/
		fi

		eapply "${_BASH_BUILD_PATCH_OPTIONS[@]}" "${_BASH_BUILD_PATCHES[@]/#/${prefix}}"
	fi

	# Do not remove generated builtins/*.c files when installsources is enabled
	# The .def may still be the ones referenced in GDB's output and not the
	# generateds .c files but these are still worth keeping and keeping them
	# removes the annoyinge rsync error messages.
	if has installsources ${FEATURES}; then
		sed -i -e '/^[[:space:]]*\$(RM) \$\*\.c/d' builtins/Makefile.in || die
	fi

	# Exclude pushd from generated plugins since it's already a builtin.
	# It also makes rsync generate a nonexisting pushd.def file when
	# installsources is enabled.  For some reason the builtins/pushd.def path
	# is not populated with the base directory in debug.sources, like
	# bash-99999/builtins/pushd.def for example.  This behavior can be debugged
	# in the estrip binary of sys-apps/portage.  Directly running
	# "/usr/bin/debugedit -i -b /var/tmp/portage/app-shells/bash-99999/work \
	# -d /usr/src/debug/app-shells/bash-99999 -l pushd.temp \
	# /var/tmp/portage/app-shells/bash-99999/image/usr/lib64/bash/pushd",
	# and examing the contents of "pushd.temp" with "xargs -0" for example
	# would show an instance of builtins/pushd.def" without bash-99999.
	if [[ ${SLOT} == 0 ]] && use plugins; then
		sed -i -e '/^OTHERPROG = /s| pushd||' examples/loadables/Makefile.in || die
	fi

	eapply_user
	[[ ${PV} == *9999* ]] && eautoreconf
}

# @FUNCTION: bash-build_src_configure
# @USAGE: [additional-econf-options]
# @DESCRIPTION:
# Implements src_configure
bash-build_src_configure() {
	local conf=(
		--with-curses
		$(use_with afs)
		$(use_enable net net-redirections)
		--disable-profiling
		$(use_enable mem-scramble)
		$(use_with mem-scramble bash-malloc)
		$(use_enable readline)
		$(use_enable readline history)
		$(use_enable readline bang-history)
		"$@"
	)

	has bash-source-fullpath-default ${IUSE} && conf+=($(use_enable bash-source-fullpath-default))

	if [[ _BASH_BUILD_PV_PARTS -lt 4 ]]; then
		# Force pgrp synchronization
		# https://bugzilla.redhat.com/bugzilla/show_bug.cgi?id=81653
		export bash_cv_pgrp_pipe=yes

		# Disable LTO in older versions
		# https://gitweb.gentoo.org/repo/gentoo.git/commit/app-shells/bash?id=6eea46091ef4e2f853c746f4544858bc79f63a73
		declare -f filter-lto >/dev/null && filter-lto
	fi

	# For descriptions of these, see config-top.h
	# bashrc/#26952 bash_logout/#90488 ssh/#24762
	append-cppflags \
		-DDEFAULT_PATH_VALUE="'\"${EPREFIX}/usr/local/sbin:${EPREFIX}/usr/local/bin:${EPREFIX}/usr/sbin:${EPREFIX}/usr/bin:${EPREFIX}/sbin:${EPREFIX}/bin\"'" \
		-DSTANDARD_UTILS_PATH="'\"${EPREFIX}/bin:${EPREFIX}/usr/bin:${EPREFIX}/sbin:${EPREFIX}/usr/sbin\"'" \
		-DSYS_BASHRC="'\"${EPREFIX}/etc/bash/bashrc\"'" \
		-DSYS_BASH_LOGOUT="'\"${EPREFIX}/etc/bash/bash_logout\"'" \
		-DNON_INTERACTIVE_LOGIN_SHELLS \
		-DSSH_SOURCE_BASHRC

	if [[ _BASH_BUILD_PV_PARTS -le 3 || (_BASH_BUILD_PV_PARTS -eq 4 && _BASH_BUILD_PV_PARTS[1] -le 3) ]]; then
		append-cppflags -DUSE_MKTEMP -DUSE_MKSTEMP # mktemp/#574426
	fi

	if [[ ${SLOT} == 0 ]]; then
		use bashlogger && append-cppflags -DSYSLOG_HISTORY

		if use plugins; then
			append-ldflags "-Wl,-rpath,${EPREFIX}/usr/$(get_libdir)/bash"
		else
			# Disable the plugins logic by hand since bash doesn't
			# provide a way of doing it.
			export ac_cv_func_dl{close,open,sym}=no ac_cv_lib_dl_dlopen=no ac_cv_header_dlfcn_h=no
			sed -i -e '/LOCAL_LDFLAGS=/s:-rdynamic::' configure || die
		fi
	fi

	use static && append-ldflags -static
	use nls || conf+=( --disable-nls )

	if ! use bundled-readline; then
		conf+=( --with-installed-readline=. )
		export ac_cv_rl_version=${_BASH_BUILD_READLINE_VER%%_*}
	fi

	tc-export AR #444070

	# Upstream only test with Bison and require GNUisms like YYEOF and
	# YYERRCODE. The former at least may be in POSIX soon:
	# https://www.austingroupbugs.net/view.php?id=1269.
	# configure warns on use of non-Bison but doesn't abort. The result
	# may misbehave at runtime.
	unset YACC

	econf "${conf[@]}"
}

# @FUNCTION: bash-build_src_compile
# @DESCRIPTION:
# Implements src_compile
bash-build_src_compile() {
	if use pgo; then
		# -fprofile-partial-training because upstream note the test suite isn't super comprehensive
		# See https://documentation.suse.com/sbp/all/html/SBP-GCC-10/index.html#sec-gcc10-pgo
		local fprofile_partial_training=$(test-flags-CC -fprofile-partial-training)
		local pgo_generate_flags="-fprofile-update=atomic -fprofile-dir=${T}/pgo -fprofile-generate=${T}/pgo ${fprofile_partial_training}"
		local pgo_use_flags="-fprofile-use=${T}/pgo -fprofile-dir=${T}/pgo ${fprofile_partial_training}"

		# Build Bash and run its tests to generate profile data.
		emake CFLAGS="${CFLAGS} ${pgo_generate_flags}"
		unset A # Used in test suite
		emake CFLAGS="${CFLAGS} ${pgo_generate_flags}" -k check

		if tc-is-clang; then
			llvm-profdata merge "${T}"/pgo --output="${T}"/pgo/default.profdata || die
		fi

		# Rebuild Bash using the genarated profiling data.
		emake clean
		emake CFLAGS="${CFLAGS} ${pgo_use_flags}"
		[[ ${SLOT} == 0 ]] && use plugins && emake -C examples/loadables \
				CFLAGS="${CFLAGS} ${pgo_use_flags}" all others
	else
		emake
		[[ ${SLOT} == 0 ]] && use plugins && emake -C examples/loadables all others
	fi
}

# @FUNCTION: _bash-build_prefixed_newins
# @USAGE: <file> <new_file> <raw_prefix>
# @DESCRIPTION:
# Applies EPREFIX to a file's content and does newins to it
# @INTERNAL
_bash-build_prefixed_newins() {
	local file=$1 new_file=$2 raw_prefix=$3 MAPFILE=()

	mapfile -t < "${file}" || die "Failed to read '${file}'"
	newins - "${new_file}" < <(printf "${MAPFILE+%s\\n}" \
			"${MAPFILE[@]//${raw_prefix}/${EPREFIX}${raw_prefix}}")
}

# @FUNCTION: bash-build_src_install
# @DESCRIPTION:
# Implements src_install
bash-build_src_install() {
	if [[ ${SLOT} == 0 ]]; then
		default

		dodir /bin
		mv "${ED%/}"/usr/bin/bash "${ED%/}"/bin/ || die
		dosym bash /bin/rbash

		insinto /etc/bash
		doins "${FILESDIR}"/bash_logout

		if [[ ${_BASH_BUILD_ETC_VERSION-0} == 1 ]]; then
			_bash-build_prefixed_newins "${FILESDIR}"/bashrc-r1 bashrc /etc

			insinto /etc/bash/bashrc.d
			_bash-build_prefixed_newins "${FILESDIR}"/bashrc.d/10-gentoo-color.bash \
					10-gentoo-color.bash /etc
			newins "${FILESDIR}"/bashrc.d/10-gentoo-title-r1.bash 10-gentoo-title.bash
			[[ ${EPREFIX} ]] || doins "${FILESDIR}"/bashrc.d/15-gentoo-bashrc-check.bash
		else
			_bash-build_prefixed_newins "${FILESDIR}"/bashrc bashrc /etc
			keepdir /etc/bash/bashrc.d
		fi

		local f d
		insinto /etc/skel

		for f in bash{_logout,_profile,rc}; do
			newins "${FILESDIR}/dot-${f}" ".${f}"
		done

		local sed_args=(-e "s:#${USERLAND}#@::" -e '/#@/d')
		use readline || sed_args+=(-e '/^shopt -s histappend/s:^:#:'
				-e 's:use_color=true:use_color=false:') #432338
		sed -i "${sed_args[@]}" "${ED%/}"/etc/skel/.bashrc "${ED%/}"/etc/bash/bashrc || die

		if use plugins; then
			exeinto "/usr/$(get_libdir)/bash"
			local loadables=(examples/loadables/*.o)
			[[ ${#loadables[@]} -gt 0 && -e ${loadables} ]] && doexe "${loadables[@]%.o}"
			insinto /usr/include/bash-plugins
			doins *.h builtins/*.h include/*.h lib/{glob/glob.h,tilde/tilde.h}
		fi

		if use examples; then
			for d in examples/{functions,misc,scripts,startup-files}; do
				exeinto "/usr/share/doc/${PF}/${d}"
				insinto "/usr/share/doc/${PF}/${d}"

				for f in "${d}"/*; do
					if [[ ${f##*/} != PERMISSION && ${f##*/} != *README ]]; then
						doexe "${f}"
					else
						doins "${f}"
					fi
				done
			done
		fi

		emake -C doc DESTDIR="${D}" install_builtins
		sed 's:bash\.1:man1/&:' doc/rbash.1 > "${T}"/rbash.1 || die
		doman "${T}"/rbash.1
		newdoc CWRU/changelog ChangeLog
		dosym bash.info /usr/share/info/bashref.info
	else
		into /
		newbin bash "bash-${SLOT}"
		newman doc/bash.1 "bash-${SLOT}.1"
		newman doc/builtins.1 "bash_builtins-${SLOT}.1"
		insinto /usr/share/info
		newins doc/bashref.info "bash-${SLOT}.info"
		dosym "bash-${SLOT}.info" "/usr/share/info/bashref-${SLOT}.info"
		dodoc README NEWS AUTHORS CHANGES COMPAT Y2K doc/FAQ doc/INTRO
	fi
}

# @FUNCTION: bash-build_src_test
# @DESCRIPTION:
# Implements src_test
bash-build_src_test() {
	unset A # Used in test suite
	default
}

# @FUNCTION: bash-build_pkg_preinst
# @DESCRIPTION:
# Implements pkg_preinst
bash-build_pkg_preinst() {
	if [[ ${SLOT} == 0 ]]; then
		if [[ -e ${EROOT}/etc/bashrc && ! -d ${EROOT}/etc/bash ]]; then
			mkdir -p "${EROOT}"/etc/bash
			mv -f "${EROOT}"/etc/bashrc "${EROOT}"/etc/bash/
		fi
	fi
}

# @FUNCTION: bash-build_pkg_postinst
# @DESCRIPTION:
# Implements pkg_postinst
bash-build_pkg_postinst() {
	if [[ ${SLOT} == 0 ]]; then
		# If /bin/sh does not exist, provide it.
		[[ -e ${EROOT}/bin/sh ]] || ln -sf bash "${EROOT}"/bin/sh
	fi
}

_bash-build_set_globals

EXPORT_FUNCTIONS pkg_setup src_unpack src_prepare src_configure src_compile src_install src_test \
		pkg_preinst pkg_postinst
