#
# Copyright (C) 2012-2014 Wind River Systems, Inc.
#
# Image generation functions to setup the installer components
#

RPM_PREPROCESS_COMMANDS_append  = "wrl_installer_check; "

RPM_POSTPROCESS_COMMANDS_append = "wrl_installer_stamp; ${@['wrl_installer; ', '']['initramfs' in '${BPN}']}"

INSTPRODUCT ?= "${DISTRO_NAME}"
INSTVER     ?= "${DISTRO_VERSION}"
INSTBUGURL  ?= "http://www.windriver.com/"

# Code below is copied and adapted from package_rpm.bbclass implementation
# ARG1 should be the MULTILIB_PREFIX_LIST
wrl_installer_setup_local_multilibs() {
	MULTILIB="$1"

	installer_target_archs=""
	installer_default_arch=""
	for i in $MULTILIB ; do
		old_IFS="$IFS"
		IFS=":"
		set $i
		IFS="$old_IFS"
		if [ "$1" = "default" ]; then
			installer_default_arch="$2"
		fi
		shift # remove mlib
		while [ -n "$1" ]; do
			installer_target_archs="$installer_target_archs $1"
			shift
		done
	done
	installer_target_archs=`echo "$installer_target_archs" | tr - _`
	export installer_default_arch
	export installer_target_archs
}

wrl_installer_setup_local_smart() {
	MULTILIB="$1"

	wrl_installer_setup_local_multilibs "$MULTILIB"

	# Need to configure RPM/Smart so we can get a full pkglist from the distro
	rm -rf ${WORKDIR}/distro-tmp
	mkdir -p ${WORKDIR}/distro-tmp/tmp

	mkdir -p ${WORKDIR}/distro-tmp/etc/rpm
	echo "$installer_default_arch""${TARGET_VENDOR}-${TARGET_OS}" > ${WORKDIR}/distro-tmp/etc/rpm/platform
	mkdir -p ${WORKDIR}/distro-tmp/var/lib/smart
	for arch in $archs; do
		if [ -d "${INSTALLER_TARGET_BUILD}/bitbake_build/tmp/deploy/rpm/"$arch ] ; then
			echo "$arch""-.*-linux.*" >> ${WORKDIR}/distro-tmp/etc/rpm/platform
		fi
	done

	# Configure internal RPM environment when using Smart
	export RPM_ETCRPM=${WORKDIR}/distro-tmp/etc/rpm

	mkdir -p ${WORKDIR}/distro-tmp/${rpmlibdir}
	rpm --root ${WORKDIR}/distro-tmp --dbpath /var/lib/rpm -qa > /dev/null

	smart --data-dir=${WORKDIR}/distro-tmp/var/lib/smart config --set rpm-root=${WORKDIR}/distro-tmp
	smart --data-dir=${WORKDIR}/distro-tmp/var/lib/smart config --set rpm-dbpath=${rpmlibdir}
	smart --data-dir=${WORKDIR}/distro-tmp/var/lib/smart config --set rpm-extra-macros._var=${localstatedir}
	smart --data-dir=${WORKDIR}/distro-tmp/var/lib/smart config --set rpm-extra-macros._tmppath=/tmp

	archs=`for arch in $installer_target_archs ; do
		echo $arch
	done | sort | uniq`
	for arch in $archs; do
		if [ -d "${INSTALLER_TARGET_BUILD}/bitbake_build/tmp/deploy/rpm/"$arch ] ; then
			echo "Note: adding Smart channel $arch"
			smart --data-dir=${WORKDIR}/distro-tmp/var/lib/smart channel --add $arch type=rpm-md type=rpm-md baseurl="${INSTALLER_TARGET_BUILD}/bitbake_build/tmp/deploy/rpm/"$arch -y
		fi
	done
	
	# Dump a list of all available packages
	[ ! -e ${WORKDIR}/distro-tmp/tmp/fullpkglist.query ] && smart --data-dir=${WORKDIR}/distro-tmp/var/lib/smart query --output ${WORKDIR}/distro-tmp/tmp/fullpkglist.query
}

wrl_installer_translate_oe_to_smart() {
	MULTILIB="$1"
	shift
	wrl_installer_setup_local_smart "$MULTILIB"

	# Start the package translation...
	default_archs=""

	pkgs_to_install=""
	not_found=""
	for pkg in "$@" ; do
		new_pkg="$pkg"
		for i in $MULTILIB ; do
			old_IFS="$IFS"
			IFS=":"
			set $i
			IFS="$old_IFS"
			mlib="$1"
			shift
			if [ "$mlib" = "default" ]; then
				if [ -z "$default_archs" ]; then
					default_archs=$@
				fi
				continue
			fi
			subst=${pkg#${mlib}-}
			if [ "$subst" != "$pkg" ]; then
				while [ -n "$1" ]; do
					arch="$1"
					arch=`echo "$arch" | tr - _`
					shift
					if grep -q '^'$subst'-[^-]*-[^-]*@'$arch'$' ${WORKDIR}/distro-tmp/tmp/fullpkglist.query ; then
						new_pkg="$subst@$arch"
						# First found is best match
						break
					fi
				done
				if [ "$pkg" = "$new_pkg" ]; then
					# Failed to translate, package not found!
					not_found="$not_found $pkg"
					continue
				fi
			fi
		done
		# Apparently not a multilib package...
		if [ "$pkg" = "$new_pkg" ]; then
			default_archs_fixed=`echo "$default_archs" | tr - _`
			for arch in $default_archs_fixed ; do
				if grep -q '^'$pkg'-[^-]*-[^-]*@'$arch'$' ${WORKDIR}/distro-tmp/tmp/fullpkglist.query ; then
					new_pkg="$pkg@$arch"
					# First found is best match
					break
				fi
			done
			if [ "$pkg" = "$new_pkg" ]; then
				# Failed to translate, package not found!
				not_found="$not_found $pkg"
				continue
			fi
		fi
		#echo "$pkg -> $new_pkg" >&2
		pkgs_to_install="${pkgs_to_install} ${new_pkg}"
	done

	# Parse the not_found items and see if they were dependencies (RPROVIDES)
	# Follow the parsing example above...
	for pkg in $not_found ; do
		new_pkg="$pkg"
		smart --data-dir=${WORKDIR}/distro-tmp/var/lib/smart query --provides=$pkg --output ${WORKDIR}/distro-tmp/tmp/provide.query
		grep '^[^@ ]*@[^@]*$' ${WORKDIR}/distro-tmp/tmp/provide.query | sed -e 's,\(.*\)-[^-]*-[^-]*\(@[^@]*\)$,\1\2,' > ${WORKDIR}/distro-tmp/tmp/provide.query.list || :
		prov=`echo $pkgs_to_install | xargs -n 1 echo | grep -f ${WORKDIR}/distro-tmp/tmp/provide.query.list || :`
		if [ -n "$prov" ]; then
			# Nothing to do, already in the list
			#echo "Skipping $pkg -> $prov, already in install set" >&2
			continue
		fi
		for i in $MULTILIB ; do
			old_IFS="$IFS"
			IFS=":"
			set $i
			IFS="$old_IFS"
			mlib="$1"
			shift
			if [ "$mlib" = "default" ]; then
				if [ -z "$default_archs" ]; then
					default_archs=$@
				fi
				continue
			fi
			subst=${pkg#${mlib}-}
			if [ "$subst" != "$pkg" ]; then
				feeds=$@
				smart --data-dir=${WORKDIR}/distro-tmp/var/lib/smart query --provides=$subst --output ${WORKDIR}/distro-tmp/tmp/provide.query
				grep '^[^@ ]*@[^@]*$' ${WORKDIR}/distro-tmp/tmp/provide.query | sed -e 's,\(.*\)-[^-]*-[^-]*\(@[^@]*\)$,\1\2,' > ${WORKDIR}/distro-tmp/tmp/provide.query.list || :
				while [ -n "$1" ]; do
					arch="$1"
					arch=`echo "$arch" | tr - _`
					shift
					# Select first found, we don't know if one is better then another...
					prov=`grep '^[^@ ]*@'$arch'$' ${WORKDIR}/distro-tmp/tmp/provide.query.list | head -n 1`
					if [ -n "$prov" ]; then
						new_pkg=$prov
						break
					fi
				done
				if [ "$pkg" = "$new_pkg" ]; then
					# Failed to translate, package not found!
					#echo "$pkg not found in the $mlib feeds ($feeds)." >&2
					continue
				fi
			fi
		done
		# Apparently not a multilib package...
		if [ "$pkg" = "$new_pkg" ]; then
			default_archs_fixed=`echo "$default_archs" | tr - _`
			for arch in $default_archs_fixed ; do
				# Select first found, we don't know if one is better then another...
				prov=`grep '^[^@ ]*@'$arch'$' ${WORKDIR}/distro-tmp/tmp/provide.query.list | head -n 1`
				if [ -n "$prov" ]; then
					new_pkg=$prov
					break
				fi
			done
			if [ "$pkg" = "$new_pkg" ]; then
				# Failed to translate, package not found!
				#echo "$pkg not found in the base feeds ($default_archs)." >&2
				really_not_found="$really_not_found $pkg"
				continue
			fi
		fi
		#echo "$pkg -> $new_pkg" >&2
		pkgs_to_install="${pkgs_to_install} ${new_pkg}"
	done
	echo "really_not_found = $really_not_found" >&2
	export pkgs_to_install
}

wrl_installer_check() {
	echo "Installer Target Build: ${INSTALLER_TARGET_BUILD}"
	if [ ! -e "${INSTALLER_TARGET_BUILD}" ]; then
		echo "Error: INSTALLER_TARGET_BUILD - ${INSTALLER_TARGET_BUILD}: directory or file doesn't exist!" >&2
		exit 1
	fi

	if [ -f "${INSTALLER_TARGET_BUILD}" ]; then
		filename=$(basename "${INSTALLER_TARGET_BUILD}")
		extension="${filename##*.}"
	fi

	if [ -f "${INSTALLER_TARGET_BUILD}" ]; then
		if [ "x$extension" = "xext2" -o "x$extension" = "xext3" -o "x$extension" = "xext4" ]; then
			echo "Image based target install selected."
		fi

	elif [ -d "${INSTALLER_TARGET_BUILD}/bitbake_build" ]; then
		# Find the DEFAULT_IMAGE....
		PSEUDO_UNLOAD=1 make -C ${INSTALLER_TARGET_BUILD} bbc \
			BBCMD="bitbake -e | grep -e '^DEFAULT_IMAGE=.*' > ${BB_LOGFILE}.distro_vals"

		eval `cat ${BB_LOGFILE}.distro_vals`

		# Use the DEFAULT_IMAGE to load the rest of the items...
		PSEUDO_UNLOAD=1 make -C ${INSTALLER_TARGET_BUILD} bbc \
			BBCMD="bitbake -e $DEFAULT_IMAGE | tee -a ${BB_LOGFILE}.bbc | grep -e '^DISTRO_NAME=.*' -e '^DISTRO_VERSION=.*' -e '^DEFAULT_IMAGE=.*' -e '^SUMMARY=.*' -e '^DESCRIPTION=.*' -e '^export PACKAGE_INSTALL=.*' -e '^PACKAGE_INSTALL_ATTEMPTONLY=.*' -e '^MULTILIB_PREFIX_LIST=.*' > ${BB_LOGFILE}.distro_vals"

		unset DISTRO_NAME DISTRO_VERSION DEFAULT_IMAGE SUMMARY DESCRIPTION MULTILIB_PRELIX_LIST PACKAGE_INSTALL PACKAGE_INSTALL_ATTEMPTONLY
		eval `cat ${BB_LOGFILE}.distro_vals`

		echo "Distro based install selected:"
		echo "  DISTRO_NAME='$DISTRO_NAME'"
		echo "  DISTRO_VERSION='$DISTRO_VERSION'"
		echo "  DEFAULT_IMAGE='$DEFAULT_IMAGE'"
		echo "  SUMMARY='$SUMMARY'"
		echo "  DESCRIPTION='$DESCRIPTION'"
		echo "  MULTILIB_PREFIX_LIST='$MULTILIB_PREFIX_LIST'"
		wrl_installer_translate_oe_to_smart "$MULTILIB_PREFIX_LIST" $PACKAGE_INSTALL
		echo "  PACKAGE_INSTALL='$pkgs_to_install'"
		wrl_installer_translate_oe_to_smart "$MULTILIB_PREFIX_LIST" $PACKAGE_INSTALL_ATTEMPTONLY
		echo "  PACKAGE_INSTALL_ATTEMPTONLY='$pkgs_to_install'"
		echo
	fi
}


wrl_installer_stamp() {
	echo "Installer Target Build: ${INSTALLER_TARGET_BUILD}"
	if [ ! -e "${INSTALLER_TARGET_BUILD}" ]; then
		echo "Error: INSTALLER_TARGET_BUILD - ${INSTALLER_TARGET_BUILD}: directory or file doesn't exist!" >&2
		exit 1
	fi

	if [ -f "${INSTALLER_TARGET_BUILD}" ]; then
		filename=$(basename "${INSTALLER_TARGET_BUILD}")
		extension="${filename##*.}"
	fi

	# Is this a build directory?
	if [ -d "${INSTALLER_TARGET_BUILD}/bitbake_build" ]; then
		eval `cat ${BB_LOGFILE}.distro_vals`
		echo "[Main]" > ${IMAGE_ROOTFS}/.buildstamp
		echo "Product=$DISTRO_NAME" >> ${IMAGE_ROOTFS}/.buildstamp
		echo "Version=$DISTRO_VERSION" >> ${IMAGE_ROOTFS}/.buildstamp
		echo "BugURL=${INSTBUGURL}" >> ${IMAGE_ROOTFS}/.buildstamp
		echo "IsFinal=True" >> ${IMAGE_ROOTFS}/.buildstamp
		echo "UUID=${DATETIME}.${TARGET_ARCH}" >> ${IMAGE_ROOTFS}/.buildstamp
		echo >> ${IMAGE_ROOTFS}/.buildstamp
		echo "[Rootfs]" >> ${IMAGE_ROOTFS}/.buildstamp
		echo "LIST=$DEFAULT_IMAGE" >> ${IMAGE_ROOTFS}/.buildstamp
		echo >> ${IMAGE_ROOTFS}/.buildstamp
		echo "[$DEFAULT_IMAGE]" >> ${IMAGE_ROOTFS}/.buildstamp
		echo "SUMMARY=$SUMMARY" >> ${IMAGE_ROOTFS}/.buildstamp
		echo "DESCRIPTION=$DESCRIPTION" >> ${IMAGE_ROOTFS}/.buildstamp
		wrl_installer_translate_oe_to_smart "$MULTILIB_PREFIX_LIST" $PACKAGE_INSTALL
		echo "PACKAGE_INSTALL=$pkgs_to_install" >> ${IMAGE_ROOTFS}/.buildstamp
		wrl_installer_translate_oe_to_smart "$MULTILIB_PREFIX_LIST" $PACKAGE_INSTALL_ATTEMPTONLY
		echo "PACKAGE_INSTALL_ATTEMPTONLY=$pkgs_to_install" >> ${IMAGE_ROOTFS}/.buildstamp
	else
		# Generate .buildstamp
		echo "[Main]" > ${IMAGE_ROOTFS}/.buildstamp
		echo "Product=${INSTPRODUCT}" >> ${IMAGE_ROOTFS}/.buildstamp
		echo "Version=${INSTVER}" >> ${IMAGE_ROOTFS}/.buildstamp
		echo "BugURL=${INSTBUGURL}" >> ${IMAGE_ROOTFS}/.buildstamp
		echo "IsFinal=True" >> ${IMAGE_ROOTFS}/.buildstamp
		echo "UUID=${DATETIME}.${TARGET_ARCH}" >> ${IMAGE_ROOTFS}/.buildstamp
	fi
}

wrl_installer() {
	echo ${DATETIME} > ${IMAGE_ROOTFS}/.discinfo
	echo ${DISTRO_NAME} ${DISTRO_VERSION} >> ${IMAGE_ROOTFS}/.discinfo
	echo ${TARGET_ARCH} >> ${IMAGE_ROOTFS}/.discinfo

	echo "Installer Target Build: ${INSTALLER_TARGET_BUILD}"
	if [ ! -e "${INSTALLER_TARGET_BUILD}" ]; then
		echo "Error: INSTALLER_TARGET_BUILD - ${INSTALLER_TARGET_BUILD}: directory or file doesn't exist!" >&2
		exit 1
	fi

	if [ -f "${INSTALLER_TARGET_BUILD}" ]; then
		filename=$(basename "${INSTALLER_TARGET_BUILD}")
		extension="${filename##*.}"
	fi

	if [ -f "${INSTALLER_TARGET_BUILD}" ]; then
		if [ "x$extension" = "xext2" -o "x$extension" = "xext3" -o "x$extension" = "xext4" ]; then
			echo "Image based target install selected."
			mkdir -p "${IMAGE_ROOTFS}/LiveOS"
			cp "${INSTALLER_TARGET_BUILD}" "${IMAGE_ROOTFS}/LiveOS/rootfs.img"
		fi

		# Configure for 'livecd' install (KS File?)

	elif [ -d "${INSTALLER_TARGET_BUILD}/bitbake_build/tmp/deploy/rpm" ]; then
		echo "Copy rpms from target build to installer image."
		mkdir -p ${IMAGE_ROOTFS}/Packages

		eval `cat ${BB_LOGFILE}.distro_vals`

		wrl_installer_setup_local_multilibs "$MULTILIB"

		# Determine the max channel priority
		channel_priority=5
		for pt in $installer_target_archs ; do
			channel_priority=$(expr $channel_priority + 5)
		done

		: > ${IMAGE_ROOTFS}/Packages/.feedpriority
		for arch in $installer_target_archs; do
			if [ -d "${INSTALLER_TARGET_BUILD}/bitbake_build/tmp/deploy/rpm/"$arch -a ! -d "${IMAGE_ROOTFS}/Packages/"$arch ]; then
				channel_priority=$(expr $channel_priority - 5)
				echo "$channel_priority $arch" >> ${IMAGE_ROOTFS}/Packages/.feedpriority
				cp -rvf "${INSTALLER_TARGET_BUILD}/bitbake_build/tmp/deploy/rpm/"$arch "${IMAGE_ROOTFS}/Packages/."
			fi
		done
	else
		echo "Invalid configuration of INSTALLER_TARGET_BUILD - ${INSTALLER_TARGET_BUILD}."
		echo "It must either point to a .ext3 image or to the root of another build directory"
		false
	fi

	# Need a link to make grub 0.97 grub-install work properly
	#if [ -f ${IMAGE_ROOTFS}/usr/share/grub/stage1 ]; then
	#	pushd ${IMAGE_ROOTFS}/usr/lib
	#	ln -sf ../share/grub grub
	#	popd

	#	pushd ${IMAGE_ROOTFS}/usr/share/grub
	#	ln -sf . i386-wrs
	#	popd
	#fi

	## Stop udev from automounting disks during install process
	#rm -f ${IMAGE_ROOTFS}/etc/udev/scripts/mount.sh
}

python __anonymous() {
    if "selinux" in d.getVar("DISTRO_FEATURES", True).split():
        bb.fatal("Unable to build the installer when selinux is enabled.")
        return False

    if bb.data.inherits_class('image', d) and not d.getVar('INSTALLER_TARGET_BUILD', True):
        d.setVar('INSTALLER_TARGET_BUILD', '${WRL_TOP_BUILD_DIR}')
}


