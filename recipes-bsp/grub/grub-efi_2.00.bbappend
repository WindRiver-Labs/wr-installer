FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

PXE_UEFI_GRUB_CONF ?= "grub.cfg"
PXE_UEFI_GRUB_IMAGE ?= "bootx64-pxe.efi"

SRC_URI += "file://grub.cfg"

do_mkpxeimage() {
    install -d boot/grub
    if [ -e ${PXE_UEFI_GRUB_CONF} ]; then
        # Use customer's
        install -m 755 ${PXE_UEFI_GRUB_CONF} boot/grub/grub.cfg
    else
        install -m 755 ${WORKDIR}/grub.cfg boot/grub/grub.cfg
        # Use default
        sed -i -e "s/@MACHINE@/${MACHINE}/g" \
               -e "s/@INITRAMFS_FSTYPES@/${INITRAMFS_FSTYPES}/g" \
               -e "s/@KERNEL_IMAGETYPE@/${KERNEL_IMAGETYPE}/g" boot/grub/grub.cfg
    fi
    cp ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE} .
    cp ${DEPLOY_DIR_IMAGE}/wrlinux-image-installer-initramfs-${MACHINE}.${INITRAMFS_FSTYPES} .

    ./grub-mkstandalone -d ./grub-core --modules="${GRUB_BUILDIN}" \
       -O ${GRUB_TARGET}-efi -o ./${PXE_UEFI_GRUB_IMAGE} \
       boot/grub/grub.cfg \
       ${KERNEL_IMAGETYPE} \
       wrlinux-image-installer-initramfs-${MACHINE}.${INITRAMFS_FSTYPES}

    install -m 644 ${PXE_UEFI_GRUB_IMAGE} ${DEPLOY_DIR_IMAGE}
    rm ${KERNEL_IMAGETYPE} wrlinux-image-installer-initramfs-${MACHINE}.${INITRAMFS_FSTYPES}
}

addtask do_mkpxeimage after do_install
