FILESEXTRAPATHS_prepend := "${THISDIR}/python-smartpm:"

NOREDIRPATCH = ""
NOREDIRPATCH_class-target = "file://smartpm-noredir.patch"

LIMIT_FREQ_PATCH = ""
LIMIT_FREQ_PATCH_class-target = "file://limit-status-updating-frequency.patch"

SRC_URI += "${NOREDIRPATCH} \
            file://smart-add-query.patch \
            file://smart-enable-proxy-for-rpm-channel.patch \
            file://fix-dbus-failure.patch \
            file://do-not-verify-ssl-certification-by-default.patch \
            ${LIMIT_FREQ_PATCH} \
           "
