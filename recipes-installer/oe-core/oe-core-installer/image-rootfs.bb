DESCRIPTION = "Generic rootfs generator."

LICENSE = "MIT"

inherit core-image

RPROVIDES  = "${IMAGE_INSTALL} ${LINGUAS_INSTALL} ${NORMAL_FEATURE_INSTALL} ${ROOTFS_BOOTSTRAP_INSTALL}"
RPROVIDES += "${TOOLCHAIN_HOST_TASK} ${TOOLCHAIN_TARGET_TASK}"

do_package_write_rpm_setscene[noexec] = '1'

do_package_setscene() {
  :
}

do_package_write_rpm_setscene() {
  :
}

addtask do_query

do_query() {
  echo "---QUERY START---" > ${QUERY_LOG}
  list_installed_packages >> ${QUERY_LOG}
  echo "---QUERY STOP---" >> ${QUERY_LOG}
}

