#
# Copyright (C) 2012-2014 Wind River Systems, Inc.
#
# Image generation functions to setup the installer components
#

RPM_POSTPROCESS_COMMANDS_append = "${@['', 'wrl_installer;']['wrlinux-image-installer' in '${BPN}']}"

INSTPRODUCT ?= "${DISTRO_NAME}"
INSTVER     ?= "${DISTRO_VERSION}"
INSTBUGURL  ?= "http://www.windriver.com/"

# NOTE: Please update anaconda-init when you change INSTALLER_CONFDIR, use "="
#       but not "?=" since this is not configurable.
INSTALLER_CONFDIR = "${IMAGE_ROOTFS}/installer-config"
KICKSTART_FILE ?= ""
WRL_INSTALLER_CONF ?= ""

WRINSTALL_TARGET_RPMS ?= '${INSTALLER_TARGET_BUILD}/tmp/deploy/rpm'

build_iso_prepend() {
	install -d ${ISODIR}
	ln -snf /.discinfo ${ISODIR}/.discinfo
	ln -snf /.buildstamp ${ISODIR}/.buildstamp
	ln -snf /Packages ${ISODIR}/Packages
}

build_iso_append() {
	implantisomd5 ${IMGDEPLOYDIR}/${IMAGE_NAME}.iso
}

# Code below is copied and adapted from package_rpm.bbclass implementation
wrl_installer_setup_local_smart() {

    target_build=$1
    target_repo_dir=$2

    # Need to configure RPM/Smart so we can get a full pkglist from the distro
    rm -rf ${WORKDIR}/distro-tmp
    mkdir -p ${WORKDIR}/distro-tmp/tmp

    mkdir -p ${WORKDIR}/distro-tmp/etc/rpm
    echo "$installer_default_arch""${TARGET_VENDOR}-${TARGET_OS}" > ${WORKDIR}/distro-tmp/etc/rpm/platform
    mkdir -p ${WORKDIR}/distro-tmp/var/lib/smart
    for arch in $installer_target_archs; do
        if [ -d "${WRINSTALL_TARGET_RPMS}/"$arch ] ; then
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
        if [ -d "${WRINSTALL_TARGET_RPMS}/"$arch ] ; then
            echo "Note: adding Smart channel $arch"
            smart --data-dir=${WORKDIR}/distro-tmp/var/lib/smart channel --add $arch type=rpm-md type=rpm-md baseurl=$target_repo_dir/$arch -y
        fi
    done

    # Dump a list of all available packages
    [ ! -e ${WORKDIR}/distro-tmp/tmp/fullpkglist.query ] && smart --data-dir=${WORKDIR}/distro-tmp/var/lib/smart query --output ${WORKDIR}/distro-tmp/tmp/fullpkglist.query
}

wrl_installer_translate_oe_to_smart() {

    target_build=$1
    shift

    # Start the package translation...
    pkgs_to_install=""
    not_found=""
    for pkg in "$@" ; do
        new_pkg="$pkg"
        for i in $installer_target_archs; do
            set $i
            shift
            subst=${pkg#${MULTILIB_VARIANTS}-}
            if [ "$subst" != "$pkg" ]; then
                while [ -n "$1" ]; do
                    arch="$1"
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
            for arch in $installer_default_archs; do
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
        for i in $installer_target_archs; do
            set $i
            shift
            subst=${pkg#${MULTILIB_VARIANTS}-}
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
                    echo "$pkg not found in the $mlib feeds ($feeds)." >&2
                    continue
                fi
            fi
        done
        # Apparently not a multilib package...
        if [ "$pkg" = "$new_pkg" ]; then
            for arch in $installer_default_archs; do
                # Select first found, we don't know if one is better then another...
                prov=`grep '^[^@ ]*@'$arch'$' ${WORKDIR}/distro-tmp/tmp/provide.query.list | head -n 1`
                if [ -n "$prov" ]; then
                    new_pkg=$prov
                    break
                fi
            done
            if [ "$pkg" = "$new_pkg" ]; then
                # Failed to translate, package not found!
                echo "$pkg not found in the base feeds ($installer_default_archs)." >&2
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
    if [ -d "${WRINSTALL_TARGET_RPMS}" ]; then
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
            if [ -d "${WRINSTALL_TARGET_RPMS}/"$arch -a ! -d "${IMAGE_ROOTFS}/Packages.$prj_name/"$arch ]; then
                channel_priority=$(expr $channel_priority - 5)
                echo "$channel_priority $arch" >> ${IMAGE_ROOTFS}/Packages.$prj_name/.feedpriority
                wrl_installer_hardlinktree "${WRINSTALL_TARGET_RPMS}/"$arch "${IMAGE_ROOTFS}/Packages.$prj_name/."
            fi
        done
        createrepo --update -q ${IMAGE_ROOTFS}/Packages.$prj_name/
    fi
}

# Update .buildstamp and copy rpm packages to IMAGE_ROOTFS
wrl_installer_copy_pkgs() {

    target_build="$1"
    prj_name="$2"
    if [ -n "$3" ]; then
        installer_conf="$3"
    else
        installer_conf=""
    fi

        common_grep="-e '^ALL_MULTILIB_PACKAGE_ARCHS=.*' \
            -e '^MULTILIB_VARIANTS=.*' -e '^PACKAGE_ARCHS=.*'\
            -e '^PACKAGE_ARCH=.*' -e '^PACKAGE_INSTALL_ATTEMPTONLY=.*' \
            -e '^DISTRO=.*' -e '^DISTRO_NAME=.*' -e '^DISTRO_VERSION=.*' \
            "
    if [ -f "$installer_conf" ]; then
        eval `grep -e "^PACKAGE_INSTALL=.*" $common_grep $installer_conf \
            | sed -e 's/=/="/' -e 's/$/"/'`
        if [ $? -ne 0 ]; then
            bbfatal "Something is wrong in $installer_conf, please correct it"
        fi
        if [ -z "$PACKAGE_ARCHS" -o -z "$PACKAGE_INSTALL" ]; then
            bbfatal "PACKAGE_ARCHS or PACKAGE_INSTALL is null, please check $installer_conf"
        fi
    else
        # Find target image env location
        (cd $target_build; \
            flock $target_build -c \
            "PSEUDO_UNLOAD=1 bitbake -e ${INSTALLER_TARGET_IMAGE}" | \
            grep '^T=.*' > ${BB_LOGFILE}.distro_vals);
        eval `cat ${BB_LOGFILE}.distro_vals`

        eval "cat $T/target_image_env | \
            grep $common_grep -e '^PN=.*' -e '^SUMMARY=.*' -e '^WORKDIR=.*' \
            -e '^DESCRIPTION=.*' -e '^export PACKAGE_INSTALL=.*' > ${BB_LOGFILE}.distro_vals"

        eval `cat ${BB_LOGFILE}.distro_vals`

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
    fi

    echo "wrl_installer_setup_local_smart $target_build $WORKDIR/rpms"
    wrl_installer_setup_local_smart $target_build $WORKDIR/rpms
    wrl_installer_translate_oe_to_smart $target_build $PACKAGE_INSTALL
    install="$pkgs_to_install"
    wrl_installer_translate_oe_to_smart $target_build $PACKAGE_INSTALL_ATTEMPTONLY
    install_attemptonly="$pkgs_to_install"
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

PACKAGE_INSTALL=$install
PACKAGE_INSTALL_ATTEMPTONLY=$install_attemptonly
ALL_MULTILIB_PACKAGE_ARCHS=$ALL_MULTILIB_PACKAGE_ARCHS
MULTILIB_VARIANTS=$MULTILIB_VARIANTS
PACKAGE_ARCHS=$PACKAGE_ARCHS
PACKAGE_ARCH=$PACKAGE_ARCH
IMAGE_LINGUAS=${IMAGE_LINGUAS}
_EOF
    fi

    if [ -d "${WRINSTALL_TARGET_RPMS}" ]; then
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

    # The count of INSTALLER_TARGET_BUILD, WRL_INSTALLER_CONF and
    # KICKSTART_FILE must match when set.
    cnt_target=$(wrl_installer_get_count ${INSTALLER_TARGET_BUILD})
    if [ -n "${WRL_INSTALLER_CONF}" ]; then
        cnt_conf=$(wrl_installer_get_count ${WRL_INSTALLER_CONF})
        [ $cnt_conf -eq $cnt_target ] || \
            bbfatal "The count of INSTALLER_TARGET_BUILD and WRL_INSTALLER_CONF not match!"
    fi
    if [ -n "${KICKSTART_FILE}" ]; then
        cnt_ks=$(wrl_installer_get_count ${KICKSTART_FILE})
        [ $cnt_ks -eq $cnt_target ] || \
            bbfatal "The count of INSTALLER_TARGET_BUILD and KICKSTART_FILE not match!"
    fi

    : > ${IMAGE_ROOTFS}/.target_build_list
    counter=0
    for target_build in ${INSTALLER_TARGET_BUILD}; do
        target_build="`readlink -f $target_build`"
        echo "Installer Target Build: $target_build"
        counter=$(expr $counter + 1)
        prj_name="`echo $target_build | sed -e 's#/ *$##g' -e 's#.*/##'`"

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
	            echo "::`basename $target_build::`" >> ${IMAGE_ROOTFS}/.target_build_list
	        else
	            bberror "Unsupported image: $target_build."
	            bberror "The image must be ext2, ext3 or ext4"
	            exit 1
	        fi
	    elif [ -d "$target_build" ]; then
	        wrl_installer_copy_pkgs $target_build $prj_name $installer_conf
	    else
	        bberror "Invalid configuration of INSTALLER_TARGET_BUILD: $target_build."
	        bberror "It must either point to an image (ext2, ext3 or ext4) or to the root of another build directory"
	        exit 1
	    fi

	    ks_cfg="${INSTALLER_CONFDIR}/ks.cfg.$prj_name"
	    if [ -n "${KICKSTART_FILE}" ]; then
            ks_file="`echo ${KICKSTART_FILE} | awk '{print $'"$counter"'}'`"
	        if [ -e "$ks_file" ]; then
                bbnote "Copying kickstart file $ks_file to $ks_cfg ..."
                mkdir -p ${INSTALLER_CONFDIR}
                cp $ks_file $ks_cfg
	        else
	            bberror "The kickstart file $ks_file doesn't exist!"
	        fi
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
        target_build = d.getVar('INSTALLER_TARGET_BUILD', True)
        if not target_build:
            errmsg = "No INSTALLER_TARGET_BUILD is found,\n"
            errmsg += "set INSTALLER_TARGET_BUILD = '<target-build-topdir>' and\n"
            errmsg += "INSTALLER_TARGET_IMAGE = '<target-image-pn>' to do RPMs\n"
            errmsg += "install, or\n"
            errmsg += "set INSTALLER_TARGET_BUILD = '<target-build-image>' to do\n"
            errmsg += "image copy install"
            bb.fatal(errmsg)
        elif target_build == d.getVar('TOPDIR', True):
            bb.fatal("The INSTALLER_TARGET_BUILD can't be the current dir")
        elif not os.path.exists(target_build):
            bb.fatal("The INSTALLER_TARGET_BUILD does not exist")
        elif os.path.isdir(target_build) and not d.getVar('INSTALLER_TARGET_IMAGE', True):
            errmsg = "The INSTALLER_TARGET_BUILD is a dir, but not found INSTALLER_TARGET_IMAGE,\n"
            errmsg += "set INSTALLER_TARGET_IMAGE = <target-image-pn>' to do RPMs install"
            bb.fatal(errmsg)
}

