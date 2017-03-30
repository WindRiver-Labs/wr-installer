#
# Copyright (C) 2012-2014 Wind River Systems, Inc.
#
# Image generation functions to setup the installer components
#

RPM_POSTPROCESS_COMMANDS_append = "wrl_installer;"

INSTPRODUCT ?= "${DISTRO_NAME}"
INSTVER     ?= "${DISTRO_VERSION}"
INSTBUGURL  ?= "http://www.windriver.com/"

# NOTE: Please update anaconda-init when you change INSTALLER_CONFDIR, use "="
#       but not "?=" since this is not configurable.
INSTALLER_CONFDIR = "${IMAGE_ROOTFS}/installer-config"
KICKSTART_FILE ?= ""
WRL_INSTALLER_CONF ?= ""

build_iso_prepend() {
	install -d ${ISODIR}
	ln -snf /.discinfo ${ISODIR}/.discinfo
	ln -snf /.buildstamp ${ISODIR}/.buildstamp
	ln -snf /Packages ${ISODIR}/Packages
}

build_iso_append() {
	implantisomd5 ${IMGDEPLOYDIR}/${IMAGE_NAME}.iso
}

# Check WRL_INSTALLER_CONF and copy it to
# ${IMAGE_ROOTFS}/.buildstamp.$prj_name when exists
wrl_installer_copy_buildstamp() {
    prj_name=$1
    buildstamp=$2
    if [ -f $buildstamp ]; then
        bbnote "Using $buildstamp as the buildstamp"
        cp $buildstamp ${IMAGE_ROOTFS}/.buildstamp.$prj_name
    else
        bbfatal "Can't find WRL_INSTALLER_CONF: $buildstamp"
    fi
}

# Hardlink when possible, otherwise copy.
# $1: src
# $2: target
wrl_installer_hardlinktree() {
    src_dev="`stat -c %d $1`"
    if [ -e "$2" ]; then
        tgt_dev="`stat -c %d $2`"
    else
        tgt_dev="`stat -c %d $(dirname $2)`"
    fi
    hdlink=""
    if [ "$src_dev" = "$tgt_dev" ]; then
        hdlink="--link"
    fi
    cp -rvf $hdlink $1 $2
}

wrl_installer_copy_local_repos() {
    if [ -d "$target_build/tmp/deploy/rpm" ]; then
        echo "Copy rpms from target build to installer image."
        mkdir -p ${IMAGE_ROOTFS}/Packages.$prj_name

        : > ${IMAGE_ROOTFS}/Packages.$prj_name/.treeinfo
        echo "[general]" >> ${IMAGE_ROOTFS}/Packages.$prj_name/.treeinfo
        echo "version = ${DISTRO_VERSION}" >> ${IMAGE_ROOTFS}/Packages.$prj_name/.treeinfo

        # Determine the max channel priority
        channel_priority=5
        for pt in $installer_target_archs ; do
            channel_priority=$(expr $channel_priority + 5)
        done

        : > ${IMAGE_ROOTFS}/Packages.$prj_name/.feedpriority
        for arch in $installer_target_archs; do
            if [ -d "$target_build/tmp/deploy/rpm/"$arch -a ! -d "${IMAGE_ROOTFS}/Packages.$prj_name/"$arch ]; then
                channel_priority=$(expr $channel_priority - 5)
                echo "$channel_priority $arch" >> ${IMAGE_ROOTFS}/Packages.$prj_name/.feedpriority
                wrl_installer_hardlinktree "$target_build/tmp/deploy/rpm/"$arch "${IMAGE_ROOTFS}/Packages.$prj_name/."
            fi
        done
        createrepo_c --update -q ${IMAGE_ROOTFS}/Packages.$prj_name/
    fi
}

# Update .buildstamp and copy rpm packages to IMAGE_ROOTFS
wrl_installer_copy_pkgs() {

    target_build="$1"
    target_image="$2"
    prj_name="$3"
    if [ -n "$4" ]; then
        installer_conf="$4"
    else
        installer_conf=""
    fi

    common_grep="-e '^ALL_MULTILIB_PACKAGE_ARCHS=.*' \
            -e '^MULTILIB_VARIANTS=.*' -e '^PACKAGE_ARCHS=.*'\
            -e '^PACKAGE_ARCH=.*' -e '^PACKAGE_INSTALL_ATTEMPTONLY=.*' \
            -e '^DISTRO=.*' -e '^DISTRO_NAME=.*' -e '^DISTRO_VERSION=.*' \
            "

    # Find target image env location: $T, and target rpm repo dir: $WORKDIR/rpms
    (cd $target_build; \
        flock $target_build -c \
        "PSEUDO_UNLOAD=1 bitbake -e $target_image" | \
        grep -e '^T=.*' -e '^WORKDIR=.*' > ${BB_LOGFILE}.distro_vals);
    eval `cat ${BB_LOGFILE}.distro_vals`

    if [ -f "$installer_conf" ]; then
        eval "grep -e \"^PACKAGE_INSTALL=.*\" $common_grep $installer_conf \
            | sed -e 's/=/=\"/' -e 's/$/\"/' > ${BB_LOGFILE}.distro_vals"
        eval `cat ${BB_LOGFILE}.distro_vals`
        if [ $? -ne 0 ]; then
            bbfatal "Something is wrong in $installer_conf, please correct it"
        fi
        if [ -z "$PACKAGE_ARCHS" -o -z "$PACKAGE_INSTALL" ]; then
            bbfatal "PACKAGE_ARCHS or PACKAGE_INSTALL is null, please check $installer_conf"
        fi
    else
        eval "cat $T/target_image_env | \
            grep $common_grep -e '^PN=.*' -e '^SUMMARY=.*' \
            -e '^DESCRIPTION=.*' -e '^export PACKAGE_INSTALL=.*' > ${BB_LOGFILE}.distro_vals"

        eval `cat ${BB_LOGFILE}.distro_vals`
    fi

    export installer_default_arch="$PACKAGE_ARCH"
    # Reverse it for priority
    export installer_default_archs="`for arch in $PACKAGE_ARCHS; do echo $arch; done | tac | tr - _`"
    installer_target_archs="$installer_default_archs"
    if [ -n "$MULTILIB_VARIANTS" ]; then
        export MULTILIB_VARIANTS
        mlarchs_reversed="`for mlarch in $ALL_MULTILIB_PACKAGE_ARCHS; do echo $mlarch; \
            done | tac | tr - _`"
        for arch in $mlarchs_reversed; do
            if [ "$arch" != "noarch" -a "$arch" != "all" -a "$arch" != "any" ]; then
                installer_target_archs="$installer_target_archs lib32_$arch"
            fi
        done
    fi
    export installer_target_archs

    # Save the vars to .buildstamp when no installer_conf
    if [ ! -f "$installer_conf" ]; then
        cat >> ${IMAGE_ROOTFS}/.buildstamp.$prj_name <<_EOF
DISTRO=$DISTRO
DISTRO_NAME=$DISTRO_NAME
DISTRO_VERSION=$DISTRO_VERSION

[Rootfs]
LIST=$PN

[$PN]
SUMMARY=$SUMMARY
DESCRIPTION=$DESCRIPTION

PACKAGE_INSTALL=$PACKAGE_INSTALL
PACKAGE_INSTALL_ATTEMPTONLY=$PACKAGE_INSTALL_ATTEMPTONLY
ALL_MULTILIB_PACKAGE_ARCHS=$ALL_MULTILIB_PACKAGE_ARCHS
MULTILIB_VARIANTS=$MULTILIB_VARIANTS
PACKAGE_ARCHS=$PACKAGE_ARCHS
PACKAGE_ARCH=$PACKAGE_ARCH
IMAGE_LINGUAS=${IMAGE_LINGUAS}
_EOF
    fi

    if [ -d "$target_build/tmp/deploy/rpm" ]; then
        # Copy local repos while the image is not initramfs
        bpn=${BPN}
        if [ "${bpn##*initramfs}" = "${bpn%%initramfs*}" ]; then
            wrl_installer_copy_local_repos
        fi
        echo "$DISTRO::$prj_name::$DISTRO_NAME::$DISTRO_VERSION" >> ${IMAGE_ROOTFS}/.target_build_list
    fi
}

wrl_installer_get_count() {
    sum=0
    for i in $*; do
        sum=$(expr $sum + 1)
    done
    echo $sum
}

wrl_installer[vardepsexclude] = "DATETIME"
wrl_installer() {
    cat >${IMAGE_ROOTFS}/.discinfo <<_EOF
${DATETIME}
${DISTRO_NAME} ${DISTRO_VERSION}
${TARGET_ARCH}
_EOF

    : > ${IMAGE_ROOTFS}/.target_build_list
    counter=0
    targetimage_counter=0
    for target_build in ${INSTALLER_TARGET_BUILD}; do
        target_build="`readlink -f $target_build`"
        echo "Installer Target Build: $target_build"
        counter=$(expr $counter + 1)
        prj_name="`echo $target_build | sed -e 's#/ *$##g' -e 's#.*/##'`"
        prj_name="$prj_name-$counter"

	    # Generate .buildstamp
	    if [ -n "${WRL_INSTALLER_CONF}" ]; then
            installer_conf="`echo ${WRL_INSTALLER_CONF} | awk '{print $'"$counter"'}'`"
	        wrl_installer_copy_buildstamp $prj_name $installer_conf
	    else
	        cat >${IMAGE_ROOTFS}/.buildstamp.$prj_name <<_EOF
[Main]
Product=${INSTPRODUCT}
Version=${INSTVER}
BugURL=${INSTBUGURL}
IsFinal=True
UUID=${DATETIME}.${TARGET_ARCH}
_EOF
	    fi

	    if [ -f "$target_build" ]; then
	        filename=$(basename "$target_build")
	        extension="${filename##*.}"
	        bpn=${BPN}
	        # Do not copy image for initramfs
	        if [ "${bpn##*initramfs}" != "${bpn%%initramfs*}" ]; then
	            continue
	        elif [ "x$extension" = "xext2" -o "x$extension" = "xext3" -o "x$extension" = "xext4" ]; then
	            echo "Image based target install selected."
	            mkdir -p "${IMAGE_ROOTFS}/LiveOS.$prj_name"
	            wrl_installer_hardlinktree "$target_build" "${IMAGE_ROOTFS}/LiveOS.$prj_name/rootfs.img"
	            echo "::$prj_name::" >> ${IMAGE_ROOTFS}/.target_build_list
	        else
	            bberror "Unsupported image: $target_build."
	            bberror "The image must be ext2, ext3 or ext4"
	            exit 1
	        fi
	    elif [ -d "$target_build" ]; then
	        targetimage_counter=$(expr $targetimage_counter + 1)
	        target_image="`echo ${INSTALLER_TARGET_IMAGE} | awk '{print $'"$targetimage_counter"'}'`"
	        echo "Target Image: $target_image"
	        wrl_installer_copy_pkgs $target_build $target_image $prj_name $installer_conf
	    else
	        bberror "Invalid configuration of INSTALLER_TARGET_BUILD: $target_build."
	        bberror "It must either point to an image (ext2, ext3 or ext4) or to the root of another build directory"
	        exit 1
	    fi

	    ks_cfg="${INSTALLER_CONFDIR}/ks.cfg.$prj_name"
	    if [ -n "${KICKSTART_FILE}" ]; then
	        ks_file="`echo ${KICKSTART_FILE} | awk '{print $'"$counter"'}'`"
	        bbnote "Copying kickstart file $ks_file to $ks_cfg ..."
	        mkdir -p ${INSTALLER_CONFDIR}
	        cp $ks_file $ks_cfg
	    fi
    done

    # Setup the symlink if only one target build dir.
    if [ "$counter" = "1" ]; then
        prj_name="`awk -F:: '{print $2}' ${IMAGE_ROOTFS}/.target_build_list`"
        entries=".buildstamp LiveOS Packages installer-config/ks.cfg"
        for i in $entries; do
            if [ -e ${IMAGE_ROOTFS}/$i.$prj_name ]; then
                ln -sf `basename $i.$prj_name` ${IMAGE_ROOTFS}/$i
            fi
        done
    fi
}

python __anonymous() {
    if "selinux" in d.getVar("DISTRO_FEATURES", True).split():
        bb.fatal("Unable to build the installer when selinux is enabled.")
        return False

    if bb.data.inherits_class('image', d):
        target_builds = d.getVar('INSTALLER_TARGET_BUILD', True)
        if not target_builds:
            errmsg = "No INSTALLER_TARGET_BUILD is found,\n"
            errmsg += "set INSTALLER_TARGET_BUILD = '<target-build-topdir>' and\n"
            errmsg += "INSTALLER_TARGET_IMAGE = '<target-image-pn>' to do RPMs\n"
            errmsg += "install, or\n"
            errmsg += "set INSTALLER_TARGET_BUILD = '<target-build-image>' to do\n"
            errmsg += "image copy install"
            bb.fatal(errmsg)

        count = 0
        for target_build in target_builds.split():
            if target_build == d.getVar('TOPDIR', True):
                bb.fatal("The INSTALLER_TARGET_BUILD can't be the current dir")
            elif not os.path.exists(target_build):
                bb.fatal("The %s of INSTALLER_TARGET_BUILD does not exist" % target_build)

            if os.path.isdir(target_build):
                count += 1

        # While do package management install
        if count > 0:
            target_images = d.getVar('INSTALLER_TARGET_IMAGE', True)
            if not target_images:
                errmsg = "The INSTALLER_TARGET_BUILD is a dir, but not found INSTALLER_TARGET_IMAGE,\n"
                errmsg += "set INSTALLER_TARGET_IMAGE = '<target-image-pn>' to do RPMs install"
                bb.fatal(errmsg)

            elif count != len(target_images.split()):
                errmsg = "The INSTALLER_TARGET_BUILD has %s build dirs: %s\n" % (count, target_builds)
                errmsg += "But INSTALLER_TARGET_IMAGE has %s build images: %s\n" % (len(target_images.split()), target_images)
                bb.fatal(errmsg)

        # The count of INSTALLER_TARGET_BUILD and WRL_INSTALLER_CONF must match when set.
        wrlinstaller_confs = d.getVar('WRL_INSTALLER_CONF', True)
        if wrlinstaller_confs:
            if len(wrlinstaller_confs.split()) != len(target_builds.split()):
                bb.fatal("The count of INSTALLER_TARGET_BUILD and WRL_INSTALLER_CONF not match!")
            for wrlinstaller_conf in wrlinstaller_confs.split():
                if not os.path.exists(wrlinstaller_conf):
                    bb.fatal("The installer conf %s in WRL_INSTALLER_CONF doesn't exist!" % wrlinstaller_conf)

        # The count of INSTALLER_TARGET_IMAGE and KICKSTART_FILE must match when set.
        kickstart_files = d.getVar('KICKSTART_FILE', True)
        if kickstart_files:
            if len(kickstart_files.split()) != len(target_builds.split()):
                bb.fatal("The count of INSTALLER_TARGET_BUILD and KICKSTART_FILE not match!")
            for kickstart_file in kickstart_files.split():
                if not os.path.exists(kickstart_file):
                    bb.fatal("The kickstart file %s in KICKSTART_FILE doesn't exist!" % kickstart_file)

}

