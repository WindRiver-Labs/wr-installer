#!/bin/sh
# Multiple kernel selection script
# Called by initial_setup.sh

KERNEL_DIR=/RPMS/KERNEL
RPM_DIR=/RPMS
TMPRPM_DIR=/tmp/RPMS
TMP_PACKAGES=/tmp/RPMS/PACKAGES
RAW_KERNEL_LIST=(`cd ${KERNEL_DIR}; echo kernel-*.tar | sed -e 's:.tar::g'`)
INSTALLER_CONF_FILE=/etc/installer.conf
INSTALLER_CONF_FILE_NEW=/tmp/installer.conf

mkdir -p ${TMPRPM_DIR} || exit 1

num=0
real=0
while [ ${num} -lt ${#RAW_KERNEL_LIST[@]} ]
do
	if [ -f ${KERNEL_DIR}/${RAW_KERNEL_LIST[${num}]}.tar ]; then
		KERNEL_LIST=(${KERNEL_LIST[@]}  ${RAW_KERNEL_LIST[${num}]})
		echo [${real}] ${KERNEL_LIST[${real}]}
		real=$((${real} + 1))
	fi
	num=$((${num} + 1))
done

result=0
entry_num=$((${#KERNEL_LIST[@]} - 1))
range="0..${entry_num}"

if [ ${#KERNEL_LIST[@]} -eq 0 ]; then
	echo "No kernel in ${KERNEL_DIR} directory"
	exit 1
elif [ ${#KERNEL_LIST[@]} -gt 1 ]; then
	if [ -r $INSTALLER_CONF_FILE ]; then
		def_kernel=`grep "^Kernel_DEFAULT=" $INSTALLER_CONF_FILE | sed 's/^.*=//'`
		install_kernel=`grep "^Kernel_INSTALL=" $INSTALLER_CONF_FILE | sed 's/^.*=//'`
	fi

	echo -n "Input ${range} to select kernel"
	# Let the user see what the default would be:
	if [ "x$def_kernel" = x ]; then
		def_kernel=0
	fi
	echo -n " [${def_kernel}] "

	if [ "x${install_kernel}" != x ]; then
		result=${install_kernel}
		echo ${result}
	else
	    while read a
	    do
		    if [ ! $a ]; then
			    result=${def_kernel}
			    break
		    elif (expr $a + 1 >/dev/null 2>&1) && [ "x${KERNEL_LIST[${a}]}" != "x" ]; then
			    result=$a
			    break
		    else
			    echo -n "Input ${range} to select kernel [${def_kernel}]"
		    fi
	    done
	fi
fi
echo Kernel_DEFAULT=$result >> $INSTALLER_CONF_FILE_NEW

# Make a symbolic link to the kernel package
ln -s -f ${KERNEL_DIR}/${KERNEL_LIST[${result}]}.tar  ${TMPRPM_DIR}/kernel.tar

IFS=- read kernel board_name kernel_type <<EOF
${KERNEL_LIST[${result}]}
EOF

# Create the PACKAGES file.  Put the kernel info first,
# followed by the userspace packages, renumbering them as
# neccessary.  The userspace can have packages that need
# to be last in the list.
(cur_num=0
 while read line
 do
	cur_num=$((${cur_num} + 1))
	echo "${cur_num} ${line}"
 done < ${KERNEL_DIR}/PACKAGES-${board_name}-${kernel_type}
 while read line
 do
	set $line
	shift
	cur_num=$((${cur_num} + 1))
	echo "${cur_num} $*"
 done < ${RPM_DIR}/PACKAGES.userspace
) >${TMP_PACKAGES}

kernel_rpm=`echo ${KERNEL_DIR}/${board_name}-kernel.*.rpm`
ln -s -f ../../RPMS/KERNEL/${kernel_rpm##*/} ${TMPRPM_DIR}/${kernel_rpm##*/}

# Symbolic link the /RPMS/*.rpm
RPMLIST=`cd /RPMS; echo *.rpm`
for i in ${RPMLIST}; do
	ln -s -f ../../RPMS/${i} ${TMPRPM_DIR}/${i} || exit 1
done
