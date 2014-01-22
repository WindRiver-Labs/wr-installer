#
# Copyright (C) 2012-2014 Wind River Systems, Inc.
#
# Image generation functions to setup the installer components
#

ROOTFS_POSTPROCESS_COMMAND += "wrl_installer; "

wrl_installer() {
	echo ${DATETIME} > ${IMAGE_ROOTFS}/.discinfo
	echo ${DISTRO_NAME} ${DISTRO_VERSION} >> ${IMAGE_ROOTFS}/.discinfo
	echo ${TARGET_ARCH} >> ${IMAGE_ROOTFS}/.discinfo

	echo "Installer Target Build: ${INSTALLER_TARGET_BUILD}"
	if [ ! -e "${INSTALLER_TARGET_BUILD}" ]; then
		echo "Error: INSTALLER_TARGET_BUILD - ${INSTALLER_TARGET_BUILD}: directory doesn't exist!" >&2
		exit 1
	fi

	if [ -f "${INSTALLER_TARGET_BUILD}" ]; then
		filename=$(basename "${INSTALLER_TARGET_BUILD}")
		extension="${filename##*.}"
	fi
	if [ -f "${INSTALLER_TARGET_BUILD}" -a "x$extension" = "xext3" ]; then
		echo "Image based target install selected."
		mkdir -p "${IMAGE_ROOTFS}/LiveOS"
		cp "${INSTALLER_TARGET_BUILD}" "${IMAGE_ROOTFS}/LiveOS/rootfs.img"

		# Configure for 'livecd' install (KS File?)

	elif [ -d "${INSTALLER_TARGET_BUILD}/bitbake_build/tmp/deploy/rpm" ]; then
		echo "Copy rpms from target build to installer image."
		mkdir -p ${IMAGE_ROOTFS}/Packages
		cp -rvf "${INSTALLER_TARGET_BUILD}/bitbake_build/tmp/deploy/rpm/"* "${IMAGE_ROOTFS}/Packages/."

		# Define repo dirs
		target_archs=""
		for i in ${MULTILIB_PREFIX_LIST} ; do
			old_IFS="$IFS"
			IFS=":"
			set $i
			IFS="$old_IFS"
			shift # remove mlib
			while [ -n "$1" ]; do
				target_archs="$target_archs $1"
				shift
			done
		done

		target_archs=`echo "$target_archs" | tr - _`

		archs=`for arch in $target_archs ; do
			echo $arch
		done | sort | uniq`

		rm -f ${IMAGE_ROOTFS}/Packages/.feedpriority
		for arch in $archs ; do
			if [ -d ${IMAGE_ROOTFS}/Packages/$arch ] ; then
				echo "5 $arch" >> ${IMAGE_ROOTFS}/Packages/.feedpriority
			fi
		done

		# Define various group info, etc...
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

