SUMMARY = "BSD/OS 5.1 installsw program adapted for Wind River Linux"
DESCRIPTION = "The installsw utility is an interactive program for installing \
        software packages from floppy disk, tape, or CDROM to a filesystem. \
        The floppy disk, tape and CDROM may be either on the local computer \
        or on a remote host.  In addition, installsw can be used to delete \
        software packages that were previously installed."

LICENSE = "BSD-4-Clause"
LIC_FILES_CHKSUM = "file://installsw.c;beginline=2;endline=4;md5=cf47733861c5dd2ab555a7dc0f550633"

SECTION = "installer"

SRC_URI = "\
	git://git.wrs.com/git/users/mhatle/installsw \
	file://gen_installsw_packages \
	file://remove_header.patch \
	file://yp_install \
	"
SRCREV = "b81b4610da02fa990c393cc495475a8f27fcd939"

S = "${WORKDIR}/git"

PR = "r0"

DEPENDS += "ncurses"

RDEPENDS_${PN} += "oe-core-installer"

EXTRA_OEMAKE += "CFLAGS=-DENABLE_YP"

do_install() {
   mkdir -p ${D}/opt/installer/installsw
   install -m 0755 installsw ${D}/opt/installer/installsw/.
   install -m 0755 ${WORKDIR}/gen_installsw_packages ${D}/opt/installer/installsw/.

   wrpylibs=$(dirname `which wrl-gen-image.py`)/wrpylibs
   cp -r ${wrpylibs} ${D}/opt/installer/installsw/.

   install -m 0755 ${WORKDIR}/yp_install ${D}/opt/installer/installsw/.
}

FILES_${PN} = "/opt/installer/installsw"
FILES_${PN}-dbg += "/opt/installer/installsw/.debug"
