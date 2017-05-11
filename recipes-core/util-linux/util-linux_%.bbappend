inherit python3native

EXTRA_OECONF_append_wrlinux-installer = " --libdir=${libdir}"
PACKAGECONFIG_append_wrlinux-installer = " pylibmount"
