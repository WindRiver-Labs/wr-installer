SUMMARY = "A simple tool for the execution of tasks."
DESCRIPTION = "BitBake is a simple tool for the execution of tasks. It is derived from Portage, which is the package management system used by the Gentoo Linux distribution. It is most commonly used to build packages, as it can easily use its rudimentary inheritance to abstract common operations, such as fetching sources, unpacking them, patching them, compiling them, and so on."
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=751419260aa954499f7abaabaa882bbe"

SECTION = "installer"

SRC_URI = " \
	git://git.wrs.com/git/bitbake \
	file://no-parent-deps.patch \
	file://enable-logtail.patch \
	"
SRCREV = "de7d423525c6796f2bd1f1d222d04a501ccf16f6"
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
