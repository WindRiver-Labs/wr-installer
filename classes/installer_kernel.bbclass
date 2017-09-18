FILESEXTRAPATHS_prepend := "${LAYER_PATH_meta-installer}/recipes-kernel/linux/files/:"
SRC_URI_append = " \
    file://dmthin.scc \
    file://crypt.scc \
    file://liveinstall.scc \
    file://efivars.scc \
    file://multipath.scc \
    file://ide.scc \
"

KERNEL_FEATURES_append = " \
    features/overlayfs/overlayfs.scc \
    cfg/systemd.scc \
"
