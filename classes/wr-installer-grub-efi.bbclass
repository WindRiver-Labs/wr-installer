python __anonymous () {
    import re
    target = d.getVar('TARGET_ARCH', True)
    if target == "x86_64":
        grubtarget = 'x86_64'
    elif re.match('i.86', target):
        grubtarget = 'i386'
    else:
        raise bb.parse.SkipPackage("grub-efi is incompatible with target %s" % target)
    d.setVar("GRUB_TARGET", grubtarget)
}

efi_populate_append() {
	cd ${DEST}${EFIDIR} && echo "wrlinux-installer" > ./wrlinux-installer.version
	cp -r ${DEPLOY_DIR_IMAGE}/${GRUB_TARGET}-efi ${DEST}${EFIDIR}
}

efi_iso_populate() {
	iso_dir=$1
	efi_populate $iso_dir
	# Build a EFI directory to create efi.img
	mkdir -p ${EFIIMGDIR}/${EFIDIR}
	cp -r $iso_dir/${EFIDIR}/* ${EFIIMGDIR}${EFIDIR}
	cp $iso_dir/vmlinuz ${EFIIMGDIR}
	EFIPATH=$(echo "${EFIDIR}" | sed 's/\//\\/g')
	echo "fs0:${EFIPATH}\\${GRUB_IMAGE}" > ${EFIIMGDIR}/startup.nsh
	if [ -f "$iso_dir/initrd" ] ; then
		cp $iso_dir/initrd ${EFIIMGDIR}
	fi
}
