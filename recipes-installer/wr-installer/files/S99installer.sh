#!/bin/sh

PRELINK=strip

MNT_ROOT=/mnt/target
MNT_BOOT=${MNT_ROOT}/boot
MNT_IMAGE=/mnt/target-ext3
RPM_CMD=/usr/bin/rpm
KERNEL=bzImage
KERNEL_PATH=/boot/isolinux/${KERNEL}
TARGET_KERNEL=/mnt/target-kernel/bzImage
GRUB_MENU=${MNT_BOOT}/grub/grub.cfg
INITTAB=${MNT_ROOT}/etc/inittab
SECURETTY=${MNT_ROOT}/etc/securetty
PARTED=/usr/sbin/parted
GRUB_INSTALL=/usr/sbin/grub-install
MKFS=/sbin/mkfs.ext3
MKSWAP=/sbin/mkswap
SWAPOFF=/sbin/swapoff
INSTALLSW=/opt/installer/installsw/installsw

TMP_PACKAGES=/tmp/PACKAGES
INSTALLER_CONF_FILE=/etc/installer.conf
INSTALLER_CONF_FILE_NEW=/var/volatile/installer.conf

exit_install()
{
    echo $1;
    echo "Exiting setup script.  To restart, type \"sh /etc/rcS.d/S99installer.sh\"";
    exit 1;
}

trap exit_install SIGHUP SIGINT SIGQUIT

##
## Get a response from the user, unless installer.conf defines "<item>_INSTALL=foo".
## $1 is the item, the question which needs an answer; $2 is optional default response.
## If installer.conf defines "<item>_DEFAULT=bar", use that instead of $2.
## Record what answers ultimately got used in INSTALLER_CONF_FILE_NEW, as <item>_DEFAULT=xx.
##
get_answer()
{
    local a ins def
    [ -r $INSTALLER_CONF_FILE ] && {
        ins=`grep "^$1_INSTALL=" $INSTALLER_CONF_FILE | sed 's/^.*=//'` ;
        def=`grep "^$1_DEFAULT=" $INSTALLER_CONF_FILE | sed 's/^.*=//'` ; }

    # Let the user see what the default would be:
    if [ "x$def" = x ]; then
        def=$2
    fi
    echo -n " [$def] " >&2

    if [ "x$ins" != x ]; then
        a=$ins
        echo $ins >&2
    else
        read a
        if [ "x$a" = x ]; then
            a=$def
        fi
    fi
    echo $a
    echo $1_DEFAULT=$a >> $INSTALLER_CONF_FILE_NEW
}


##
## Alter the preference (Required, Desired, Optional...) of packages named in the
## installer.conf file, according to the "PACKAGES_<pkg_name>=[R|D|O]" lines.
##
config_packages()
{
    local i pref pkgName
    for i in `grep "^PACKAGES_" $INSTALLER_CONF_FILE` ; do
        # Make sure these choices go in the $INSTALLER_CONF_FILE_NEW file...
        echo $i >> $INSTALLER_CONF_FILE_NEW
        pkgName=`echo $i | sed -e 's/=.*//' -e 's/^PACKAGES_//'`
        pref=`echo $i | sed s/^.*=//`

        echo Changing pkg $pkgName to $pref...

        sed -i "/ $pkgName\./s/ \([A-Z]\) [RDOHI] \// \1 $pref \//" $TMP_PACKAGES
    done
}



# Initialize the file that records all answers to questions
> $INSTALLER_CONF_FILE_NEW

##
## See if /tmp/root/boot exists.  If it does, we can assume that
## it is the target disk and has been formatted, but check with
## the user just to be safe.
##
if [ "$SKIP_FORMAT" != "YES" -a -d ${MNT_BOOT} ]; then
    SKIP_FORMAT=YES
    echo "${MNT_BOOT} exists."
    echo -n "Do you want to unmount and re-format the disk?"
    a=$(get_answer Reformat "no")
    if [ "x$a" = "xyes" ]; then
        umount ${MNT_BOOT}
        umount ${MNT_ROOT}
        SKIP_FORMAT=NO
    else
        ## Determine the device from how ${MNT_ROOT}
        ## is mounted, and then use parted to figure out
        ## how big the swap partition is.
        DEVICE=`mount | grep " ${MNT_ROOT} " | sed -e 's/[0-9]* .*//'`
        ROOT_UNIT=`mount | grep " ${MNT_ROOT} " | \
            sed -e 's/[^0-9]*\([0-9]*\).*/\1/'`
        MB_SWAP=`parted ${DEVICE} print | grep linux-swap |
          sed -e 's/^ *[0-9]* *[0-9]*MB *[0-9]*MB *\([0-9]*\)MB.*$/\1/'`
        if [ "x${MB_SWAP}" = "x" ]; then
            MB_SWAP=0
        fi
    fi
elif [ -z "$SKIP_FORMAT" ]; then
    SKIP_FORMAT=NO
fi

##
## Determine what disk we are going to format.  Give the
## user a list of options, as determined by searching
## /proc/partitions for hd? and sd?.  If the user gives
## us something other than what is in the list, we'll
## still accept it as long as it is a block device.
##
DEVS=`grep -e 'sd.$' -e 'hd.$' </proc/partitions |
        (while read a; do set $a; echo $4; done)`

set ${DEVS}
DEV_NAME=$1

ind=0
for i in ${DEVS}
do
    if [ ${DEV_NAME} = $i ]; then
        break
    fi
    ind=$((${ind} + 1))
done
HD=hd${ind}

if [ ${SKIP_FORMAT} = NO ]; then

    echo -n "What disk do you want to format? (${DEVS})"
    a=$(get_answer WhichDisk $1)
    if [ "x$a" != x ]; then
        DEV_NAME=$a
    fi
    DEVICE=/dev/${DEV_NAME}

    ##
    ## Attempt to create the device if it doesn't exist, and then
    ## verify that it is a block device.
    ##
    if [ ! -e ${DEVICE} ]; then
        echo "warning: ${DEVICE} does not exist; attempting to create it"
        if ! /sbin/MAKEDEV ${DEV_NAME}; then
            exit_install
        fi
    fi
    if [ ! -b ${DEVICE} ]; then
        exit_install "${DEVICE} is not a block device"
    fi

    ## check if there are existing partitions on the disk
    if grep -q "${DEV_NAME}[1-9]" /proc/partitions
    then
        echo "The selected disk ${DEVICE} is already partitioned."
        echo -n "Delete existing partitions and ALL data? (yes/no) "
        delete_partitions=$(get_answer DeleteExistingPartitions "no")
        if [ "x$delete_partitions" != "xyes" ]; then
            echo -n "Unable to reuse existing partitions. Aborting install."
            exit_install
        fi

        ## By default there is no swap in installer image.
        ## But if there is a swap partition on the target drive
        ## it may have been mounted automatically
        ${SWAPOFF} --all
    fi

    #Make sure target disk is not mounted
    if grep -q "^/dev/${DEV_NAME}[0-9]+" /proc/mounts
    then
        echo "/dev/${DEV_NAME} is mounted in /proc/mounts."
        echo -n "Please unmount all the partitions of ${DEV_NAME}. Aborting install."
        exit_install
    fi

    ##
    ## Figure out how big the partitions should be, and
    ## query the user for confirmation
    ##

    set `grep MemTotal /proc/meminfo`
    MB_SWAP=$((($2+1023)/1024*2))
    MB_BOOT=`du -shm /boot | awk '{print $1}'`
    MB_BOOT=`expr ${MB_BOOT} \* 2`
    MB_ROOT=-1

    echo -n "How many MB for the /boot partition"
    MB_BOOT=$(get_answer BootPartMB ${MB_BOOT})

    echo -n "How many MB for the swap partition"
    MB_SWAP=$(get_answer SwapPartMB ${MB_SWAP})

    echo -n "How many MB for the root partition (-1 == rest of disk)"
    MB_ROOT=$(get_answer RootPartMB ${MB_ROOT})

    ##
    ## Create the disk label, and three partitions.
    ##
    ## Set ${ROOT_UNIT} based on whether or not we create
    ## a swap partition.
    ##
    echo "Creating label on hard drive..."
    ${PARTED} -s ${DEVICE} mklabel msdos ||
    exit_install "Failed to create disk label"

    echo "Creating ${MB_BOOT}MB /boot partition"
    #First partition must start at 1 to make space for grub
    ${PARTED} -s ${DEVICE} mkpart primary ext2 1 ${MB_BOOT} ||
    exit_install "Failed to create /boot partition"

    sleep 1
    ${MKFS} "${DEVICE}1"
    echo

    if [ ${MB_SWAP} -gt 0 ]; then
        echo "Creating ${MB_SWAP}MB swap partition"
        ${PARTED} -s ${DEVICE} mkpart primary linux-swap \
            ${MB_BOOT} $((${MB_BOOT} + ${MB_SWAP})) ||
        exit_install "Failed to create swap partition"

        sleep 1
        ${MKSWAP} ${DEVICE}2
        ROOT_UNIT=3
    else
        ROOT_UNIT=2
    fi
    echo

    if [ ${MB_ROOT} -eq -1 ]; then
        echo "Creating root partition on the rest of the disk"
        END="100%"
    else
        echo "Creating ${MB_ROOT}MB root partition"
        END=$((${MB_BOOT} + ${MB_SWAP} + ${MB_ROOT}))
    fi
    ${PARTED} -s ${DEVICE} mkpart primary ext2 \
        $((${MB_BOOT} + ${MB_SWAP})) ${END} ||
    exit_install "Failed to create root partition"

    sleep 1
    ${MKFS} "${DEVICE}${ROOT_UNIT}"
    echo

    ##
    ## Mount the newly created partitions under /tmp
    ##
    echo "Mounting ${DEVICE}${ROOT_UNIT} on ${MNT_ROOT}"
    [ -d ${MNT_ROOT} ] || mkdir ${MNT_ROOT} ||
    exit_install "Failed to make directory ${MNT_ROOT}"

    ## There seems to be a race condition under QEMU, so do a
    ## brief pause before mounting the root partition.
    sleep 1
    mount ${DEVICE}${ROOT_UNIT} ${MNT_ROOT} ||
    exit_install "Failed to mount root partition"
    [ -d ${MNT_BOOT} ] || mkdir ${MNT_BOOT} ||
    exit_install "Failed to make directory ${MNT_BOOT}"
    echo "Mounting ${DEVICE}1 on ${MNT_BOOT}"
    mount ${DEVICE}1 ${MNT_BOOT} ||
    exit_install "Failed to mount /boot partition"
fi

#check for image based install
if [ -d "/image" ]; then
    echo "Starting Image Install"
    image=$(readlink -f /image/*.ext3)
    mount -o loop "$image" ${MNT_IMAGE}
    cp -av ${MNT_IMAGE}/* ${MNT_ROOT}
    echo "Finished Image Install"
else

    ##
    ## Alter PACKAGES file according to installer.conf
    ##
    cat /opt/installer/installsw/PACKAGES > $TMP_PACKAGES
    if [ -r $INSTALLER_CONF_FILE ]; then
        echo Altering PACKAGES according to installer.conf...
        config_packages
        echo Altered PACKAGES according to installer.conf.
    fi

    ##
    ## Run the software installer program
    ##
    echo "Ready to run WR Linux software installer."
    echo -n "Install extra image features? (dev-pkgs staticdev-pkgs doc-pkgs dbg-pkgs) "
    IMAGE_FEATURES=$(get_answer ExtraImageFeatures "none")
    echo -n "Install languages? "
    IMAGE_LINGUAS=$(get_answer LinguasInstall "")
    echo -n "Would you like to view or modify what will be installed? "
    case $(get_answer ViewInstalled "no") in
        [yY]*)  HOW=
		;;
        *) HOW=-sd ;;
    esac

    PATH=/opt/installer/bitbake/bin:/opt/installer/oe-core/scripts:/opt/installer/installsw:$PATH
    export PATH IMAGE_FEATURES IMAGE_LINGUAS
    ${INSTALLSW} ${HOW} -a $TMP_PACKAGES -c /opt/installer/ -d ${MNT_ROOT} -L -E ||
    exit_install "installsw failed"

    # We need a way to login, by default there are no passwords selected.
    echo "Clearing the root password, be sure to configure the root password!"
    sed 's%^root:[^:]*:%root::%' < ${MNT_ROOT}/etc/passwd > ${MNT_ROOT}/etc/passwd.new
    mv ${MNT_ROOT}/etc/passwd.new ${MNT_ROOT}/etc/passwd
fi

#if a kernel is not already present in boot partition
if [ -f ${TARGET_KERNEL} ] && [ ! -f $(readlink -f ${MNT_BOOT}/${KERNEL}) ]; then
    rm -f ${MNT_BOOT}/${KERNEL}
    cp -f ${TARGET_KERNEL} ${MNT_BOOT}/${KERNEL} ||
    exit_install "copy of kernel failed"
fi

##
## Install the Grub bootloader
##
echo "Installing Grub bootloader on hard disk"
${GRUB_INSTALL} --root-directory=${MNT_ROOT} --no-floppy ${DEVICE} ||
exit_install "grub-install failed"

##
## Create the Grub menu
##
if [ -d /etc/grub.d ]; then
    #GRUB 1.99+

    cat >${GRUB_MENU} <<!EOF
set default=0
set timeout=10

insmod serial
insmod gzio
insmod part_msdos
insmod ext2
serial --unit=0 --speed=115200
terminal_input console serial ; terminal_output console serial

menuentry "Wind River Linux 5.0.1, Kernel 3.4.0" {
    set root='$HD,msdos1'
    linux /bzImage root=${DEVICE}${ROOT_UNIT} rw console=tty0
}

menuentry "Wind River Linux 5.0.1, Kernel 3.4.0 - Serial Console" {
    set root='$HD,msdos1'
    linux /bzImage root=${DEVICE}${ROOT_UNIT} rw console=ttyS0,115200
}

!EOF
else
    #GRUB 1
    cat >${GRUB_MENU} <<!EOF

default=0
timeout=10
title Wind River Linux 5.0.1, Kernel 3.4.0
    root=($HD,0)
    kernel /bzImage root=${DEVICE}${ROOT_UNIT} rw console=tty0

title Wind River Linux 5.0.1, Kernel 3.4.0 - Serial Console
    root=($HD,0)
    kernel /bzImage root=${DEVICE}${ROOT_UNIT} rw console=ttyS0,115200

!EOF

    pushd ${MNT_BOOT}/grub
    ln -sf grub.cfg menu.lst
    popd
fi

##
## Add /boot to /etc/fstab
##
echo "Adding /boot to /etc/fstab on hard disk"
cp ${MNT_ROOT}/etc/fstab ${MNT_ROOT}/etc/fstab.original
grep -v /boot ${MNT_ROOT}/etc/fstab.original >${MNT_ROOT}/etc/fstab
(if [ ${MB_SWAP} -gt 0 ]; then
    echo "${DEVICE}2    swap    swap    defaults    0   0"
    fi
    echo "${DEVICE}1    /boot   ext3    rw  0   0"
) >>${MNT_ROOT}/etc/fstab

# set root password in /etc/shadow
if [ -f ${MNT_ROOT}/etc/shadow ]; then
    echo "Setting root password"
    sed -e 's/root:\*:/root:$1$qGmxLn8v$yTzaaXdb6.6QLLgS0Euz.1:/' \
        -i ${MNT_ROOT}/etc/shadow
fi

## Copy installer conf to disk
cp ${INSTALLER_CONF_FILE_NEW} ${MNT_ROOT}/var/log

##
## All done
##
echo "Unmounting the hard disk partitions"
umount ${MNT_BOOT}
umount ${MNT_ROOT}

echo "Initial installation is now complete"
echo "Please remove the install media, and reboot from the hard disk"
echo
exit 0
