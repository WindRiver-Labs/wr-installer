FILESEXTRAPATHS_prepend := "${THISDIR}/python-smartpm:"

NOREDIRPATCH = ""
NOREDIRPATCH_class-target = "file://smartpm-noredir.patch"

SRC_URI += "${NOREDIRPATCH} \
      file://smart-add-query.patch"
