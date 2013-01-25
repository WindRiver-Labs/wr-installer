#
# Copyright (C) 2012 Wind River Systems, Inc.
#
# Image generation functions to setup the installer components
#

ROOTFS_POSTPROCESS_COMMAND += "wrl_config_oe ; wrl_installer; "

def dump_multilib_config(d):
    localdata = bb.data.createCopy(d)

    tune = localdata.getVar('DEFAULTTUNE', True)
    ret  = "DEFAULTTUNE = '%s'\n" % (tune)
    ret += "TUNE_PKGARCH_tune-%s = '%s'\n" % (tune, localdata.getVar('TUNE_PKGARCH', True))
    ret += "PACKAGE_EXTRA_ARCHS_tune-%s = '%s'\n" % (tune, localdata.getVar('PACKAGE_EXTRA_ARCHS', True))
    ret += "TUNE_FEATURES_tune-%s = '%s'\n" % (tune, tune)
    ret += "TUNEVALID[%s] = '%s'\n" % (tune, tune)
    ret += "TUNE_ARCH_tune-%s = '%s'\n" % (tune, localdata.getVar('TUNE_ARCH', True))
    ret += "\n"

    for mlib in (d.getVar('MULTILIB_VARIANTS', True) or "").split():
        # Use 'd' to avoid having to recopy each iteration...
        overrides = d.getVar("OVERRIDES", False) + ":virtclass-multilib-" + mlib
        localdata.setVar("OVERRIDES", overrides)
        bb.data.update_data(localdata)
        tune = localdata.getVar('DEFAULTTUNE', True)
        ret += "DEFAULTTUNE_virtclass-multilib-%s = '%s'\n" % (mlib, tune)
        ret += "TUNE_PKGARCH_tune-%s = '%s'\n" % (tune, localdata.getVar('TUNE_PKGARCH', True))
        ret += "PACKAGE_EXTRA_ARCHS_tune-%s = '%s'\n" % (tune, localdata.getVar('PACKAGE_EXTRA_ARCHS', True))
        ret += "TUNE_FEATURES_tune-%s = '%s'\n" % (tune, tune)
        ret += "TUNEVALID[%s] = '%s'\n" % (tune, tune)
        ret += "TUNE_ARCH_tune-%s = '%s'\n" % (tune, localdata.getVar('TUNE_ARCH', True))
        ret += "\n"

    return ret

wrl_config_oe() {
  mkdir -p ${IMAGE_ROOTFS}/opt/installer/build/conf/

  install -m 0644 ${WRINSTALLER_FILES}/bblayers.conf ${IMAGE_ROOTFS}/opt/installer/build/conf/.
  install -m 0644 ${WRINSTALLER_FILES}/sanity_info ${IMAGE_ROOTFS}/opt/installer/build/conf/.

  install -m 0644 ${WRINSTALLER_FILES}/local.conf.frag ${IMAGE_ROOTFS}/opt/installer/build/conf/local.conf

  echo '#### System Configuration' >> ${IMAGE_ROOTFS}/opt/installer/build/conf/local.conf
  echo 'ABIEXTENSION = "'"${@(d.getVar('ABIEXTENSION', False).replace('"', "'")).replace('$', '%')}"'"' | tr '%' '$' >> ${IMAGE_ROOTFS}/opt/installer/build/conf/local.conf
  echo 'LIBCEXTENSION = "'"${@(d.getVar('LIBCEXTENSION', False).replace('"', "'")).replace('$', '%')}"'"' | tr '%' '$' >> ${IMAGE_ROOTFS}/opt/installer/build/conf/local.conf
  echo 'TARGET_VENDOR = "'"${@(d.getVar('TARGET_VENDOR', False).replace('"', "'")).replace('$', '%')}"'"' | tr '%' '$' >> ${IMAGE_ROOTFS}/opt/installer/build/conf/local.conf
  echo 'TARGET_OS = "'"${@(d.getVar('TARGET_OS', False).replace('"', "'")).replace('$', '%')}"'"' | tr '%' '$' >> ${IMAGE_ROOTFS}/opt/installer/build/conf/local.conf
  echo  >> ${IMAGE_ROOTFS}/opt/installer/build/conf/local.conf
  echo 'MACHINE_ARCH = "${MACHINE_ARCH}"' >> ${IMAGE_ROOTFS}/opt/installer/build/conf/local.conf
  echo >> ${IMAGE_ROOTFS}/opt/installer/build/conf/local.conf
  echo '#### Multilib Configuration' >> ${IMAGE_ROOTFS}/opt/installer/build/conf/local.conf
  echo 'MULTILIBS = "${@d.getVar('MULTILIBS', True)}"' >> ${IMAGE_ROOTFS}/opt/installer/build/conf/local.conf
  echo "MULTILIB_VARIANTS = '${@extend_variants(d,"MULTILIBS","multilib")}'" >> ${IMAGE_ROOTFS}/opt/installer/build/conf/local.conf
  echo >> ${IMAGE_ROOTFS}/opt/installer/build/conf/local.conf
  cat <<EOF >> ${IMAGE_ROOTFS}/opt/installer/build/conf/local.conf
${@dump_multilib_config(d)}
EOF
}

WRL_INSTALLER_CONF ?= "${TOPDIR}/conf/installer.conf"

wrl_installer() {
    echo "Installer Target Build: ${INSTALLER_TARGET_BUILD}"
    if [ ! -e "${INSTALLER_TARGET_BUILD}" ]; then
        echo "Error: INSTALLER_TARGET_BUILD - ${INSTALLER_TARGET_BUILD}: directory doesn't exist!" >&2
        exit 1
    fi

    kernel_dir=""

    if [ -f "${INSTALLER_TARGET_BUILD}" ]; then
        filename=$(basename "${INSTALLER_TARGET_BUILD}")
        extension="${filename##*.}"
    fi
    if [ -f "${INSTALLER_TARGET_BUILD}" -a "x$extension" = "xext3" ]; then
            echo "Image based target install selected."
            mkdir -p "${IMAGE_ROOTFS}/image"
            cp "${INSTALLER_TARGET_BUILD}" "${IMAGE_ROOTFS}/image"

            ## Make a directory to mount the image for loopback mount
            mkdir -p "${IMAGE_ROOTFS}/mnt/target-ext3"

            # Assume kernel is in same directory as image
            kernel_dir=$(dirname ${INSTALLER_TARGET_BUILD})
    elif [ -d "${INSTALLER_TARGET_BUILD}/bitbake_build/tmp/deploy/rpm" ]; then
        echo "Copy rpms from target build to installer image."
        mkdir -p ${IMAGE_ROOTFS}/opt/installer/feed
        cp -rvf "${INSTALLER_TARGET_BUILD}/bitbake_build/tmp/deploy/rpm/"* "${IMAGE_ROOTFS}/opt/installer/feed/."

	echo "Copy pkgdata from target build to installer image."
	rm -rf ${IMAGE_ROOTFS}/opt/installer/pkgdata
	cp -rvf "${INSTALLER_TARGET_BUILD}/bitbake_build/tmp/pkgdata" "${IMAGE_ROOTFS}/opt/installer/."

	# Use the other configuration file to define the default setup.
	DEFAULT_TARGET_IMAGE=`awk '/^DEFAULT_IMAGE = / { gsub(/\"/, "", $3) ; printf("%s\n", $3) }' ${INSTALLER_TARGET_BUILD}/bitbake_build/conf/local.conf`

	# Use the default image to list out the most likely solution.  (Later used to seed the installsw code.)
	echo "Determining desired package list..."
	wrl-gen-image.py \
		--dirs ${INSTALLER_TARGET_BUILD}/bitbake_build/tmp/pkgdata-prelim \
		       ${INSTALLER_TARGET_BUILD}/bitbake_build/tmp/pkgdata \
		--image $DEFAULT_TARGET_IMAGE --noexpansion \
		> ${IMAGE_ROOTFS}/opt/installer/installsw/desired-$DEFAULT_TARGET_IMAGE

	# Determine kernel dir...
        kernel_dir="${INSTALLER_TARGET_BUILD}/bitbake_build/tmp/deploy/images"
    else
        echo "Invalid configuration of INSTALLER_TARGET_BUILD - ${INSTALLER_TARGET_BUILD}."
        echo "It must either point to a .ext3 image or to the root of another build directory"
        false
    fi

    #Copy kernel from target build to put onto disk
    target_kernel_dir="${IMAGE_ROOTFS}/mnt/target-kernel"
    mkdir -p "${target_kernel_dir}"
    #Choose newest kernel image in directory
    kernel=$(readlink -f $(find ${kernel_dir} -maxdepth 1 -name *bzImage* | head -n 1))
    cp ${kernel} ${target_kernel_dir}/bzImage

    if [ -d ${IMAGE_ROOTFS}/opt/installer/feed ]; then
        # Clear out a common temp file...
        rm -f ${IMAGE_ROOTFS}/opt/installer/feed/rpm.lock

        echo "Constructing repository data for the feed..."
        for arch in `ls -1 ${IMAGE_ROOTFS}/opt/installer/feed` ; do
            if [ ! -d ${IMAGE_ROOTFS}/opt/installer/feed/$arch ]; then
                continue
            fi
            echo "   $arch..."
            rm -rf ${IMAGE_ROOTFS}/opt/installer/feed/$arch/repodata
            createrepo --update -q ${IMAGE_ROOTFS}/opt/installer/feed/$arch
        done
        echo "done."

        #echo "Constructing pkgdata from the feed."
        #mkdir -p ${IMAGE_ROOTFS}/opt/installer/pkgdata
        #
        #${IMAGE_ROOTFS}/opt/installer/oe-core/scripts/gen_rpmfeed_pkgdata \
        #    ${IMAGE_ROOTFS}/opt/installer/build \
        #    ${IMAGE_ROOTFS}/opt/installer/pkgdata \
        #    ${IMAGE_ROOTFS}/opt/installer/feed

	mkdir -p ${IMAGE_ROOTFS}/opt/installer/build/tmp
	ln -s /opt/installer/pkgdata ${IMAGE_ROOTFS}/opt/installer/build/tmp/pkgdata

	echo "Constructing installsw package information."
	${IMAGE_ROOTFS}/opt/installer/installsw/gen_installsw_packages \
	    ${IMAGE_ROOTFS}/opt/installer/installsw/wrpylibs \
	    ${IMAGE_ROOTFS}/opt/installer \
	    ${IMAGE_ROOTFS}/opt/installer/installsw/desired-$DEFAULT_TARGET_IMAGE \
	    ${IMAGE_ROOTFS}/opt/installer/installsw/PACKAGES_unsorted
	sort -k 7 -u \
	    -o ${IMAGE_ROOTFS}/opt/installer/installsw/PACKAGES \
	       ${IMAGE_ROOTFS}/opt/installer/installsw/PACKAGES_unsorted
    fi

    if grep initdefault "${IMAGE_ROOTFS}/etc/inittab" >/dev/null; then
        echo "Enable root auto login"
        sed -i 's/mingetty/mingetty --noclear --autologin root /' "${IMAGE_ROOTFS}/etc/inittab"
    fi

    # Need a link to make grub 0.97 grub-install work properly
    if [ -f ${IMAGE_ROOTFS}/usr/share/grub/stage1 ]; then
        pushd ${IMAGE_ROOTFS}/usr/lib
        ln -sf ../share/grub grub
        popd

        pushd ${IMAGE_ROOTFS}/usr/share/grub
        ln -sf . i386-wrs
        popd
    fi

    ## Make a directory to mount the target
    mkdir -p "${IMAGE_ROOTFS}/mnt/target"

    ## If it exists, copy the installer.conf file
    if [ -n "${WRL_INSTALLER_CONF}" -a -e "${WRL_INSTALLER_CONF}" ]; then
        install -m 0644 ${WRL_INSTALLER_CONF} ${IMAGE_ROOTFS}${sysconfdir}/
    fi
}

python __anonymous() {
    if bb.data.inherits_class('image', d) and not d.getVar('INSTALLER_TARGET_BUILD', True):
        d.setVar('INSTALLER_TARGET_BUILD', '${WRL_TOP_BUILD_DIR}')
}
