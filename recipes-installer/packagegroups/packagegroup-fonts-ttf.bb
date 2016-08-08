SUMMARY = "Install ttf fonts for anaconda"
SECTION = "fonts"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/LICENSE;md5=4d92cd373abda3937c2bc47fbc49d690 \
                    file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

inherit packagegroup allarch

RDEPENDS_${PN} = "\
    ttf-abyssinica \
    ttf-dejavu-common \
    ttf-dejavu-sans \
    ttf-dejavu-sans-mono \
    ttf-lklug \
    ttf-lohit \
    ttf-sazanami-gothic \
    ttf-sazanami-mincho \
    ttf-wqy-zenhei \
    ttf-tlwg \
"

