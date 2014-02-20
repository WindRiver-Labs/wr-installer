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

	if [ -f "${INSTALLER_TARGET_BUILD}" -a "x$extension" = "xext3" ]; then
		echo "Image based target install selected."

	elif [ -d "${INSTALLER_TARGET_BUILD}/bitbake_build" ]; then
		# Find the DEFAULT_IMAGE....
		PSEUDO_UNLOAD=1 make -C ${INSTALLER_TARGET_BUILD} bbc \
			BBCMD="bitbake -e | grep -e '^DEFAULT_IMAGE=.*' > ${BB_LOGFILE}.distro_vals"

		eval `cat ${BB_LOGFILE}.distro_vals`

		# Use the DEFAULT_IMAGE to load the rest of the items...
		PSEUDO_UNLOAD=1 make -C ${INSTALLER_TARGET_BUILD} bbc \
			BBCMD="bitbake -e $DEFAULT_IMAGE | tee -a ${BB_LOGFILE}.bbc | grep -e '^DISTRO_NAME=.*' -e '^DISTRO_VERSION=.*' -e '^DEFAULT_IMAGE=.*' -e '^SUMMARY=.*' -e '^DESCRIPTION=.*' -e '^IMAGE_INSTALL=.*' -e '^FEATURE_INSTALL=.*' > ${BB_LOGFILE}.distro_vals"

		eval `cat ${BB_LOGFILE}.distro_vals`

		echo "Distro based install selected:"
		echo "  DISTRO_NAME='$DISTRO_NAME'"
		echo "  DISTRO_VERSION='$DISTRO_VERSION'"
		echo "  DEFAULT_IMAGE='$DEFAULT_IMAGE'"
		echo "  SUMMARY='$SUMMARY'"
		echo "  DESCRIPTION='$DESCRIPTION'"
		echo "  IMAGE_INSTALL='$IMAGE_INSTALL'"
		echo "  FEATURE_INSTALL='$FEATURE_INSTALL'"
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
		echo "IMAGE_INSTALL=$IMAGE_INSTALL" >> ${IMAGE_ROOTFS}/.buildstamp
		echo "FEATURE_INSTALL=$FEATURE_INSTALL" >> ${IMAGE_ROOTFS}/.buildstamp
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
	if [ -f "${INSTALLER_TARGET_BUILD}" -a "x$extension" = "xext3" ]; then
		echo "Image based target install selected."
		mkdir -p "${IMAGE_ROOTFS}/LiveOS"
		cp "${INSTALLER_TARGET_BUILD}" "${IMAGE_ROOTFS}/LiveOS/rootfs.img"

		# Configure for 'livecd' install (KS File?)

	elif [ -d "${INSTALLER_TARGET_BUILD}/bitbake_build/tmp/deploy/rpm" ]; then
		echo "Copy rpms from target build to installer image."
		mkdir -p ${IMAGE_ROOTFS}/Packages

		# Determine the max channel priority
		channel_priority=5
		if [ ! -z "$INSTALL_PLATFORM_EXTRA_RPM" ]; then
			for pt in $INSTALL_PLATFORM_EXTRA_RPM ; do
				channel_priority=$(expr $channel_priority + 5)
			done
		fi

		: > ${IMAGE_ROOTFS}/Packages/.feedpriority
		for canonical_arch in $INSTALL_PLATFORM_EXTRA_RPM; do
			arch=$(echo $canonical_arch | sed "s,\([^-]*\)-.*,\1,")
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

