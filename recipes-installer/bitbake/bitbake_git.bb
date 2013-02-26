SUMMARY = "A simple tool for the execution of tasks."
DESCRIPTION = "BitBake is a simple tool for the execution of tasks. It is derived from Portage, which is the package management system used by the Gentoo Linux distribution. It is most commonly used to build packages, as it can easily use its rudimentary inheritance to abstract common operations, such as fetching sources, unpacking them, patching them, compiling them, and so on."
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=751419260aa954499f7abaabaa882bbe"

SECTION = "installer"

# The following code finds the corebranch file in the wrlcompat layer,
# reads it and then returns the branch value
def get_wr_bitbake_branch(d):
    bconfigpath = bb.which(d.getVar('BBPATH', True), "scripts/config/corebranch")
    if not bconfigpath:
        bb.fatal("%s: Unable to find scripts/config/corebranch in BBPATH." % d.getVar('PN', True))
        return ""
    bf = file(bconfigpath, 'r')
    bconfig = bf.readline().strip()
    bf.close()
    return bconfig

SRC_URI := "git://${WRL_TOP_BUILD_DIR}/git/bitbake;protocol=file;branch=${@get_wr_bitbake_branch(d)}"

SRCREV = "${AUTOREV}"

SRC_URI += " \
	file://enable-logtail.patch \
	"

PV = "git${SRCPV}"
PR = "r0"

S = "${WORKDIR}/git"

RDEPENDS_${PN} = "python \
    python-compile \
    python-compiler \
    python-compression \
    python-core \
    python-curses \
    python-datetime \
    python-distutils \
    python-elementtree \
    python-email \
    python-fcntl \
    python-logging \
    python-misc \
    python-multiprocessing \
    python-netclient \
    python-netserver \
    python-pickle \
    python-pkgutil \
    python-re \
    python-rpm \
    python-shell \
    python-sqlite3 \
    python-subprocess \
    python-textutils \
    python-unixadmin \
    python-xmlrpc \
"

do_install() {
  mkdir -p ${D}/opt/installer/bitbake
  cp -a ${S}/bin ${D}/opt/installer/bitbake/.
  cp -a ${S}/lib ${D}/opt/installer/bitbake/.
}

FILES_${PN} = "/opt/installer"
