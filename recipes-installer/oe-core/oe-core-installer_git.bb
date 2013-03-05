SUMMARY = "OpenEmbedded-Core build system infrastructure and metadata."
DESCRIPTION = "Pieces of the OpenEmbedded-Core build system infrastructure and metadata required to generate a rootfs.  This version is specific to the creation of root filesystem image."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=3f40d7994397109285ec7b81fdeb3b58"

SECTION = "installer"

# The following code finds the corebranch file in the wrlcompat layer,
# reads it and then returns the branch value
def get_wr_oecore_branch(d):
    bconfigpath = bb.which(d.getVar('BBPATH', True), "scripts/config/corebranch")
    if not bconfigpath:
        bb.fatal("%s: Unable to find scripts/config/corebranch in BBPATH." % d.getVar('PN', True))
        return ""
    bf = file(bconfigpath, 'r')
    bconfig = bf.readline().strip()
    bf.close()
    return bconfig

SRC_URI := "git://${WRL_TOP_BUILD_DIR}/git/oe-core;protocol=file;branch=${@get_wr_oecore_branch(d)}"

SRCREV = "${AUTOREV}"

SRC_URI += " \
	file://oe-core-fixes.patch \
	file://oe-core-skip-createrepo.patch \
	file://oe-core-query.patch \
	file://oe-core-rpmlock.patch \
	file://oe-core-manifest.patch \
	file://oe-core-wrap.patch \
	file://oe-core-no-rm.patch \
	file://oe-core-depmodwrapper.patch \
	file://bb_install \
	file://bb_query \
	file://gen_rpmfeed_pkgdata \
	file://image-rootfs.bb \
        file://depmodwrapper \
	"

PV = "git${SRCPV}"
PR = "r2"

S = "${WORKDIR}/git"

RDEPENDS_${PN} = "bitbake coreutils util-linux smartpm rpm createrepo bash"
RDEPENDS_${PN} += "eglibc-utils"

do_install() {
  mkdir -p ${D}/opt/installer/oe-core
  cp -dpR ${S}/LICENSE ${D}/opt/installer/oe-core/.

  mkdir -p ${D}/opt/installer/oe-core/meta
  cp -dpR ${S}/meta/classes ${D}/opt/installer/oe-core/meta/.
  # We should likely subset this....

  mkdir -p ${D}/opt/installer/oe-core/meta/conf
  cp -dpR ${S}/meta/conf/abi_version.conf ${D}/opt/installer/oe-core/meta/conf/.
  cp -dpR ${S}/meta/conf/bitbake.conf ${D}/opt/installer/oe-core/meta/conf/.
  cp -dpR ${S}/meta/conf/layer.conf ${D}/opt/installer/oe-core/meta/conf/.
  cp -dpR ${S}/meta/conf/sanity.conf ${D}/opt/installer/oe-core/meta/conf/.

  cp -dpR ${S}/meta/COPYING.MIT ${D}/opt/installer/oe-core/meta/.

  mkdir -p ${D}/opt/installer/oe-core/meta/files
  cp -dpR ${S}/meta/files/deploydir_readme.txt ${D}/opt/installer/oe-core/meta/files/.

  cp -dpR ${S}/meta/lib ${D}/opt/installer/oe-core/meta/.

  mkdir -p ${D}/opt/installer/oe-core/scripts
  cp -dpR ${S}/scripts/oe-pkgdata-util ${D}/opt/installer/oe-core/scripts/.

  # Setup generic rootfs generation recipe...
  install -m 0755 ${WORKDIR}/bb_install ${D}/opt/installer/oe-core/scripts/.
  install -m 0755 ${WORKDIR}/bb_query ${D}/opt/installer/oe-core/scripts/.
  install -m 0755 ${WORKDIR}/gen_rpmfeed_pkgdata ${D}/opt/installer/oe-core/scripts/.
  install -m 0755 ${WORKDIR}/depmodwrapper ${D}/opt/installer/oe-core/scripts/.

  # Add image-rootfs recipe...
  mkdir -p ${D}/opt/installer/oe-core/meta/recipes-installer/rootfs
  install -m 0644 ${WORKDIR}/image-rootfs.bb ${D}/opt/installer/oe-core/meta/recipes-installer/rootfs

  # Install dummy gcc, g++, make to fool the sanity checker
  touch ${D}/opt/installer/oe-core/scripts/make ${D}/opt/installer/oe-core/scripts/gcc ${D}/opt/installer/oe-core/scripts/g++
  chmod 0755 ${D}/opt/installer/oe-core/scripts/make ${D}/opt/installer/oe-core/scripts/gcc ${D}/opt/installer/oe-core/scripts/g++

  # Install a dummy machine file
  mkdir -p ${D}/opt/installer/oe-core/meta/conf/machine
  touch ${D}/opt/installer/oe-core/meta/conf/machine/no_machine.conf
}

FILES_${PN} = "/opt/installer/oe-core"
