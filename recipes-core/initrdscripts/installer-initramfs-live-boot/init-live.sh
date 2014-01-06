#!/bin/sh

# Parts taken from dmsquash-live-root.sh in dracut
PATH=/sbin:/bin:/usr/sbin:/usr/bin

NEWROOT="/sysroot"
MOUNT="/bin/mount"
UMOUNT="/bin/umount"
live_dir="LiveOS"
init_bin="/sbin/init"

# Copied from initramfs-framework. The core of this script probably should be
# turned into initramfs-framework modules to reduce duplication.
udev_daemon() {
	OPTIONS="/sbin/udevd /lib/udev/udevd /lib/systemd/systemd-udevd"

	for o in $OPTIONS; do
		if [ -x "$o" ]; then
			echo $o
			return 0
		fi
	done

	return 1
}

_UDEV_DAEMON=`udev_daemon`

early_setup() {
    mkdir -p /var/lock
    mkdir -p /etc 
    touch /etc/mtab

    mkdir -p /proc
    mkdir -p /sys
    mount -t proc proc /proc
    mount -t sysfs sysfs /sys
    mount -t devtmpfs none /dev

    # support modular kernel
    modprobe isofs 2> /dev/null

    mkdir -p /run
    mkdir -p /var/run

    $_UDEV_DAEMON --daemon
    udevadm trigger --action=add
}

read_args() {
    [ -z "$CMDLINE" ] && CMDLINE=`cat /proc/cmdline`
    for arg in $CMDLINE; do
        optarg=`expr "x$arg" : 'x[^=]*=\(.*\)'`
        case $arg in
            root=*)
                root=$optarg ;;
            rootfstype=*)
                modprobe $optarg 2> /dev/null ;;
            video=*)
                video_mode=$arg ;;
            vga=*)
                vga_mode=$arg ;;
            console=*)
                if [ -z "${console_params}" ]; then
                    console_params=$arg
                else
                    console_params="$console_params $arg"
                fi ;;
            init=*)
                init_bin=$optarg ;;
            ro)
                liverw=ro ;;
            rw)
                liverw=rw ;;
            overlay)
                overlay=${optarg:-y} ;;
            readonly_overlay)
                read_overlay="--readonly" ;;
            reset_overlay)
                reset_overlay=${optarg:-y};;
            rootflags)
                rootflags=$optarg ;;
            debugshell*)
                if [ -z "$optarg" ]; then
                        shelltimeout=30
                else
                        shelltimeout=$optarg
                fi 
        esac
    done
}

# determine filesystem type for a filesystem image
det_img_fs() {
    blkid -s TYPE -u noraid -o value "$1"
}

info() {
    echo $1 >$CONSOLE
    echo >$CONSOLE
}

fatal() {
    echo $1 >$CONSOLE
    echo >$CONSOLE
    exec sh
}

do_live_overlay() {
    # create a sparse file for the overlay
    # overlay: if non-ram overlay searching is desired, do it,
    #              otherwise, create traditional overlay in ram
    OVERLAY_LOOPDEV=$( losetup -f )

    l=$(blkid -s LABEL -o value $livedev) || l=""
    u=$(blkid -s UUID -o value $livedev) || u=""

    if [ -z "$overlay" ]; then
        pathspec="/${live_dir}/overlay-$l-$u"
    elif ( echo $overlay | grep -q ":" ); then
        # pathspec specified, extract
        pathspec=$( echo $overlay | sed -e 's/^.*://' )
    fi

    if [ -z "$pathspec" -o "$pathspec" = "auto" ]; then
        pathspec="/${live_dir}/overlay-$l-$u"
    fi
    devspec=$( echo $overlay | sed -e 's/:.*$//' )

    # need to know where to look for the overlay
    setup=""
    if [ -n "$devspec" -a -n "$pathspec" -a -n "$overlay" ]; then
        mkdir -m 0755 /run/initramfs/overlayfs
        mount -n -t auto $devspec /run/initramfs/overlayfs || :
        if [ -f /run/initramfs/overlayfs$pathspec -a -w /run/initramfs/overlayfs$pathspec ]; then
            losetup $OVERLAY_LOOPDEV /run/initramfs/overlayfs$pathspec
            if [ -n "$reset_overlay" ]; then
                dd if=/dev/zero of=$OVERLAY_LOOPDEV bs=64k count=1 2>/dev/null
            fi
            setup="yes"
        fi
        umount -l /run/initramfs/overlayfs || :
    fi

    if [ -z "$setup" ]; then
        if [ -n "$devspec" -a -n "$pathspec" ]; then
            warn "Unable to find persistent overlay; using temporary"
            sleep 5
        fi

        dd if=/dev/null of=/overlay bs=1024 count=1 seek=$((512*1024)) 2> /dev/null
        losetup $OVERLAY_LOOPDEV /overlay
    fi

    # set up the snapshot
    echo 0 `blockdev --getsz $BASE_LOOPDEV` snapshot $BASE_LOOPDEV $OVERLAY_LOOPDEV p 8 | dmsetup create $readonly_overlay live-rw
}

# live cd helper function
do_live_from_base_loop() {
    do_live_overlay
}

early_setup

[ -z "$CONSOLE" ] && CONSOLE="/dev/console"

read_args

if [ "${root%%:*}" = "live" ] ; then
    liveroot=$root
fi  

if [ "${liveroot%%:*}" = "live" ]; then
    case "$liveroot" in
        live:LABEL=*|LABEL=*) \
            root="${root#live:}"
            root="$(echo $root | sed 's,/,\\x2f,g')"
            root="live:/dev/disk/by-label/${root#LABEL=}"
            rootok=1 ;;
        live:CDLABEL=*|CDLABEL=*) \
            root="${root#live:}"
            root="$(echo $root | sed 's,/,\\x2f,g')"
            root="live:/dev/disk/by-label/${root#CDLABEL=}"
            rootok=1 ;;
        live:UUID=*|UUID=*) \
            root="${root#live:}"
            root="live:/dev/disk/by-uuid/${root#UUID=}"
            rootok=1 ;;
        live:/*.[Ii][Ss][Oo]|/*.[Ii][Ss][Oo])
            root="${root#live:}"
            root="liveiso:${root}"
            rootok=1 ;;
        live:/dev/*)
            rootok=1 ;;
        live:/*.[Ii][Mm][Gg]|/*.[Ii][Mm][Gg])
            [ -f "${root#live:}" ] && rootok=1 ;;
    esac
    info "root was $liveroot, is now $root"
elif [ -x ${init_bin} ]; then
    exec ${init_bin}
else
    fatal "Could not find init, dropping to a console."
fi

livedev="${root##*:}"
echo "Waiting for removable media..."
C=0
while true
do
  if [ -e $livedev ]; then
      mkdir -m 0755 -p /run/initramfs/live
      fstype=$(det_img_fs $livedev)
      mount -n -t $fstype -o ${liverw:-ro} $livedev /run/initramfs/live
      if [ "$?" != "0" ]; then
          fatal "Failed to mount block device of live image"
      fi

      if [ -e /run/initramfs/live/${live_dir}/squashfs.img ]; then
          SQUASHED_LOOPDEV=$( losetup -f )
          losetup -r $SQUASHED_LOOPDEV /run/initramfs/live/${live_dir}/squashfs.img
          mkdir -m 0755 -p /run/initramfs/squashfs
	  mount -n -t squashfs -o ro ${SQUASHED_LOOPDEV} /run/initramfs/squashfs

          BASE_LOOPDEV=$( losetup -f )
          if [ -f /run/initramfs/squashfs/${live_dir}/ext3fs.img ]; then
              losetup -r $BASE_LOOPDEV /run/initramfs/squashfs/${live_dir}/ext3fs.img
          elif [ -f /run/initramfs/squashfs/${live_dir}/rootfs.img ]; then
              losetup -r $BASE_LOOPDEV /run/initramfs/squashfs/${live_dir}/rootfs.img
          fi

          umount -l /run/initramfs/squashfs
      else
          BASE_LOOPDEV=$( losetup -f )
          if [ -f /run/initramfs/live/${live_dir}/ext3fs.img ]; then
              losetup -r $BASE_LOOPDEV /run/initramfs/live/${live_dir}/ext3fs.img
          elif [ -f /run/initramfs/live/${live_dir}/rootfs.img ]; then
              losetup -r $BASE_LOOPDEV /run/initramfs/live/${live_dir}/rootfs.img
	  elif [ -f /run/initramfs/live/etc/passwd ]; then
	      umount /run/initramfs/live
              BASE_LOOPDEV=`readlink -f $livedev`
              NO_MOVE_DEV_LOOP=1
	  elif [ -d /run/initramfs/live/Packages ]; then
		if [ -x ${init_bin} ]; then
		    exec ${init_bin}
		    umount /run/initramfs/live
		fi
          fi
      fi
      if [ "$NO_MOVE_DEV_LOOP" = "" ] ; then
          if [ -z "$BASE_LOOPDEV" ] || ! losetup $BASE_LOOPDEV > /dev/null 2>&1 ; then
            fatal "Could not find available root filesystem image on $livedev"
	  fi
      fi
      break
  fi

  # don't wait for more than $shelltimeout seconds, if it's set
  if [ -n "$shelltimeout" ]; then
      echo -n " " $(( $shelltimeout - $C ))
      if [ $C -ge $shelltimeout ]; then
           echo "..."
           echo "Available devices in /dev/disk"
           ls /dev/disk/*
           echo "Available block devices"
           ls /dev/sd*
           fatal "Cannot find specified root device , dropping to a shell "
      fi
      C=$(( C + 1 ))
  fi
  sleep 1
done

do_live_from_base_loop

[ -d $NEWROOT ] || mkdir -p -m 0755 $NEWROOT

if [ -b "$BASE_LOOPDEV" ]; then
    ln -s $BASE_LOOPDEV /run/initramfs/live-baseloop
fi

ln -s /dev/mapper/live-rw /dev/root

if [ -n "$ROOTFLAGS" ]; then
    ROOTFLAGS="-o $ROOTFLAGS"
fi

/bin/mount $ROOTFLAGS /dev/mapper/live-rw $NEWROOT
tune2fs -m 0 /dev/mapper/live-rw

killall udevd 2>/dev/null

# Move the mount points of some filesystems over to
# the corresponding directories under the real root filesystem.
mkdir -m 0555 -p ${NEWROOT}/proc
mount -n --move /proc ${NEWROOT}/proc
mkdir -m 0555 -p ${NEWROOT}/sys
mount -n --move /sys ${NEWROOT}/sys
mkdir -m 0755 -p ${NEWROOT}/dev
mount -n --move /dev ${NEWROOT}/dev

# avoid using the dm snapshot for caches
mkdir -m 0755 -p ${NEWROOT}/var/cache/yum
mount -t tmpfs -o mode=0755 varcacheyum ${NEWROOT}/var/cache/yum
mkdir -m 0777 -p ${NEWROOT}/tmp
mount -t tmpfs tmp ${NEWROOT}/tmp
mkdir -m 0777 -p ${NEWROOT}/var/tmp
mount -t tmpfs vartmp ${NEWROOT}/var/tmp

mkdir -m 0755 -p $NEWROOT/run/initramfs
if [ "$NO_MOVE_DEV_LOOP" != "1" ]; then
    # Move live mount with rootfs over to the real root filesystem
    mkdir -m 0755 -p $NEWROOT/run/initramfs/live
    mount -M /run/initramfs/live $NEWROOT/run/initramfs/live
    if [ "$?" != "0" ]; then
        fatal "Failed to move block device of live image"
    fi
else
    ln -s / $NEWROOT/run/initramfs/live
fi

exec switch_root -c /dev/console $NEWROOT /sbin/init || \
{
    warn "Command:"
    warn "exec switch_root -c /dev/console $NEWROOT /sbin/init"
    warn "failed."
    echo >$CONSOLE
    exec sh
}
