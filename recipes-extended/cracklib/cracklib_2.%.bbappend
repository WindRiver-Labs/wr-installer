DEPENDS += "python"
RDEPEND_${PN}-python += "python"

PACKAGES += "${PN}-python"

EXTRA_OECONF_remove = "--without-python"
EXTRA_OECONF_append = " --with-python"
inherit pythonnative python-dir

do_install_append() {
	src_dir="${D}${base_libdir}/${PYTHON_DIR}/site-packages"
	rm -f $src_dir/test_cracklib.py*

	if [ "${base_libdir}" != "${libdir}" ] ; then
		# Move python files from ${base_libdir} to ${libdir} since used --libdir=${base_libdir}
		install -d -m 0755 ${D}${PYTHON_SITEPACKAGES_DIR}/
		mv $src_dir/* ${D}${PYTHON_SITEPACKAGES_DIR}
		rm -fr ${D}${base_libdir}/${PYTHON_DIR}
	fi
}

FILES_${PN}-python = "${PYTHON_SITEPACKAGES_DIR}/cracklib.py* \
                      ${PYTHON_SITEPACKAGES_DIR}/_cracklib.* \
"

FILES_${PN}-staticdev += "${PYTHON_SITEPACKAGES_DIR}/_cracklib.a"

