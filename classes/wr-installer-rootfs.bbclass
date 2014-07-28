#
# Copyright (C) 2012-2014 Wind River Systems, Inc.
#
# Image generation functions to setup the installer components
#

RPM_POSTPROCESS_COMMANDS_append = "${@['wrl_installer; ', '']['initramfs' in '${BPN}']}"

INSTPRODUCT ?= "${DISTRO_NAME}"
INSTVER     ?= "${DISTRO_VERSION}"
INSTBUGURL  ?= "http://www.windriver.com/"

# NOTE: Please update anaconda-init when you change INSTALLER_CONFDIR, use "="
#       but not "?=" since this is not configurable.
INSTALLER_CONFDIR = "${IMAGE_ROOTFS}/installer-config"
KICKSTART_FILE ?= ""
WRL_INSTALLER_CONF ?= ""

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

    vars="target_build prj_name MULTILIB"
    for i in $vars; do
        eval $i="\"$1\""
        shift
    done

    wrl_installer_setup_local_multilibs "$MULTILIB"

    # Need to configure RPM/Smart so we can get a full pkglist from the distro
    rm -rf ${WORKDIR}/distro-tmp
    mkdir -p ${WORKDIR}/distro-tmp/tmp

    mkdir -p ${WORKDIR}/distro-tmp/etc/rpm
    echo "$installer_default_arch""${TARGET_VENDOR}-${TARGET_OS}" > ${WORKDIR}/distro-tmp/etc/rpm/platform
    mkdir -p ${WORKDIR}/distro-tmp/var/lib/smart
    for arch in $archs; do
        if [ -d "$target_build/bitbake_build/tmp/deploy/rpm/"$arch ] ; then
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
        if [ -d "$target_build/bitbake_build/tmp/deploy/rpm/"$arch ] ; then
            echo "Note: adding Smart channel $arch"
            smart --data-dir=${WORKDIR}/distro-tmp/var/lib/smart channel --add $arch type=rpm-md type=rpm-md baseurl="$target_build/bitbake_build/tmp/deploy/rpm/"$arch -y
        fi
    done

    # Dump a list of all available packages
    [ ! -e ${WORKDIR}/distro-tmp/tmp/fullpkglist.query ] && smart --data-dir=${WORKDIR}/distro-tmp/var/lib/smart query --output ${WORKDIR}/distro-tmp/tmp/fullpkglist.query
}

wrl_installer_translate_oe_to_smart() {

    vars="target_build prj_name MULTILIB"
    for i in $vars; do
        eval $i="\"$1\""
        shift
    done

    wrl_installer_setup_local_smart $target_build $prj_name "$MULTILIB"

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

# Update .buildstamp and copy rpm packages to IMAGE_ROOTFS
wrl_installer_copy_pkgs() {

    target_build="$1"
    prj_name="$2"
    if [ -n "$3" ]; then
        installer_conf="$3"
    else
        installer_conf=""
    fi

    if [ -f "$installer_conf" ]; then
        eval `grep -e "^MULTILIB_PREFIX_LIST=" -e "^PACKAGE_INSTALL=.*" \
                   -e "^PACKAGE_INSTALL_ATTEMPTONLY=" $installer_conf \
                   -e "^DISTRO=.*" -e "^DISTRO_NAME=.*" -e "^DISTRO_VERSION=.*" \
                    | sed -e 's/=/="/' -e 's/$/"/'`
        if [ $? -ne 0 ]; then
            bbfatal "Something is wrong in $installer_conf, please correct it"
        fi
        if [ -z "$MULTILIB_PREFIX_LIST" -o -z "$PACKAGE_INSTALL" ]; then
            bbfatal "MULTILIB_PREFIX_LIST or PACKAGE_INSTALL is null, please check $installer_conf"
        fi

        wrl_installer_translate_oe_to_smart $target_build $prj_name "$MULTILIB_PREFIX_LIST" $PACKAGE_INSTALL
        wrl_installer_translate_oe_to_smart $target_build $prj_name "$MULTILIB_PREFIX_LIST" $PACKAGE_INSTALL_ATTEMPTONLY
    else
        # Find the DEFAULT_IMAGE....
        PSEUDO_UNLOAD=1 make -C $target_build bbc \
        BBCMD="bitbake -e | grep -e '^DEFAULT_IMAGE=.*' > ${BB_LOGFILE}.distro_vals"
        eval `cat ${BB_LOGFILE}.distro_vals`

        # Use the DEFAULT_IMAGE to load the rest of the items...
        # Need the DISTRO
        echo "DISTRO[unexport] = ''" > ${WORKDIR}/export-distro.conf
        PSEUDO_UNLOAD=1 make -C $target_build bbc \
        BBCMD="bitbake -R ${WORKDIR}/export-distro.conf -e $DEFAULT_IMAGE | tee -a ${BB_LOGFILE}.bbc | \
            grep -e '^DISTRO=.*' -e '^DISTRO_NAME=.*' -e '^DISTRO_VERSION=.*' \
            -e '^DEFAULT_IMAGE=.*' -e '^SUMMARY=.*' \
            -e '^DESCRIPTION=.*' -e '^export PACKAGE_INSTALL=.*' \
            -e '^PACKAGE_INSTALL_ATTEMPTONLY=.*' \
            -e '^MULTILIB_PREFIX_LIST=.*' > ${BB_LOGFILE}.distro_vals"

        eval `cat ${BB_LOGFILE}.distro_vals`
        cat >> ${IMAGE_ROOTFS}/.buildstamp.$prj_name <<_EOF
DISTRO=$DISTRO
DISTRO_NAME=$DISTRO_NAME
DISTRO_VERSION=$DISTRO_VERSION

[Rootfs]
LIST=$DEFAULT_IMAGE

[$DEFAULT_IMAGE]
SUMMARY=$SUMMARY
DESCRIPTION=$DESCRIPTION
_EOF
        wrl_installer_translate_oe_to_smart $target_build $prj_name "$MULTILIB_PREFIX_LIST" $PACKAGE_INSTALL
        echo "PACKAGE_INSTALL=$pkgs_to_install" >> ${IMAGE_ROOTFS}/.buildstamp.$prj_name
        wrl_installer_translate_oe_to_smart $target_build $prj_name "$MULTILIB_PREFIX_LIST" $PACKAGE_INSTALL_ATTEMPTONLY
        echo "PACKAGE_INSTALL_ATTEMPTONLY=$pkgs_to_install" >> ${IMAGE_ROOTFS}/.buildstamp.$prj_name
        # The MULTILIB_PREFIX_LIST in .buildstamp is only used for
        # wrl_installer_copy_pkgs() reads it.
        echo "MULTILIB_PREFIX_LIST=$MULTILIB_PREFIX_LIST" >> ${IMAGE_ROOTFS}/.buildstamp.$prj_name
    fi

    if [ -d "$target_build/bitbake_build/tmp/deploy/rpm" ]; then
        echo "Copy rpms from target build to installer image."
        mkdir -p ${IMAGE_ROOTFS}/Packages.$prj_name

        # Determine the max channel priority
        channel_priority=5
        for pt in $installer_target_archs ; do
            channel_priority=$(expr $channel_priority + 5)
        done

        : > ${IMAGE_ROOTFS}/Packages.$prj_name/.feedpriority
        for arch in $installer_target_archs; do
            if [ -d "$target_build/bitbake_build/tmp/deploy/rpm/"$arch -a ! -d "${IMAGE_ROOTFS}/Packages.$prj_name/"$arch ]; then
                channel_priority=$(expr $channel_priority - 5)
                echo "$channel_priority $arch" >> ${IMAGE_ROOTFS}/Packages.$prj_name/.feedpriority
                wrl_installer_hardlinktree "$target_build/bitbake_build/tmp/deploy/rpm/"$arch "${IMAGE_ROOTFS}/Packages.$prj_name/."
                createrepo --update -q ${IMAGE_ROOTFS}/Packages.$prj_name/$arch
            fi
        done
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
	        if [ "x$extension" = "xext2" -o "x$extension" = "xext3" -o "x$extension" = "xext4" ]; then
	            echo "Image based target install selected."
	            mkdir -p "${IMAGE_ROOTFS}/LiveOS.$prj_name"
	            wrl_installer_hardlinktree "$target_build" "${IMAGE_ROOTFS}/LiveOS.$prj_name/rootfs.img"
                echo "::`basename $target_build::`" >> ${IMAGE_ROOTFS}/.target_build_list
	        else
	            bberror "Unsupported image: $target_build."
	            bberror "The image must be ext2, ext3 or ext4"
	            exit 1
	        fi
	    elif [ -d "$target_build/bitbake_build" ]; then
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
        if not d.getVar('INSTALLER_TARGET_BUILD', True):
            bb.fatal("No INSTALLER_TARGET_BUILD is found, missing --with-installer-target-build ?")
        elif d.getVar('INSTALLER_TARGET_BUILD', True) == d.getVar('WRL_TOP_BUILD_DIR', True):
            bb.fatal("The INSTALLER_TARGET_BUILD can't be the current dir")
}

