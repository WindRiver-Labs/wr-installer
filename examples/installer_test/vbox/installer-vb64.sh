#!/bin/bash
name=""
iso=""
vrdeport="4444"
sshport="4445"
firmware=""
memsize="1024"
hddsize="4096"
cpunum="1"

usage(){
	echo "Usage: $(basename $0) -n <name> -i <iso_path> [-f efi64] [-h <hddsize>] [-m <memory size>] [-s <ssh port>] [-v <vrde port>] [-c <cpu numbert>]"

}

while getopts "f:h:i:m:n:s:v:c:" OPT; do
	case $OPT in
	f)
		firmware="$OPTARG"
		;;
	h)
		hddsize="$OPTARG"
		;;
	i)
		iso="$OPTARG"
		;;
	m)
		memsize="$OPTARG"
		;;
	n)
		name="$OPTARG"
		;;
	s)
		sshport="$OPTARG"
		;;
	v)
		vrdeport="$OPTARG"
		;;
	c)
		cpunum="$OPTARG"
		;;
	*)
		usage
		;;
	esac
done

fail=false
[ -z $name ] && echo "missing option '-n <name>'" && fail=true

# Run an existed vbox
if [ -z $iso ]; then
	VBoxManage list vms | grep "\"$name\"" -q
	if [ $? -eq 0 ]; then
		VBoxHeadless --startvm $name -e "TCP/Ports=$vrdeport" -vrde on
	fi
	exit 0
fi

[ -n $iso -a ! -e $iso ] && echo "ISO $iso does not exist'" && fail=true
$fail && usage && exit 0

VBoxManage list vms | grep "\"$name\"" -q
if [ $? -eq 0 ]; then
	VBoxManage unregistervm $name --delete
fi

VBoxManage createvm --name $name --register
if [ ! -e "/tmp/$name.vdi" ]; then
	VBoxManage createhd --filename "/tmp/$name.vdi" --size $hddsize
fi

# Linux 64 OS
VBoxManage modifyvm $name --ostype Linux_64
# Allocate the sieze of memory
VBoxManage modifyvm $name --memory $memsize
# Allocate cpu number
VBoxManage modifyvm $name --cpus $cpunum
# Allocate an IDE device, 0 - iso;
VBoxManage storagectl $name --name "IDE" --add ide --controller PIIX4 --bootable on
VBoxManage storageattach $name --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium $iso

# Allocate a SATA device, 0 - hdd;
VBoxManage storagectl $name --name "SATA" --add sata --controller IntelAHCI --bootable on --portcount 1
VBoxManage storageattach $name --storagectl "SATA" --type hdd --port 0 --device 0 --medium "/tmp/$name.vdi"
# [bios|efi|efi32|efi64]
if [ "$firmware" != "" ]; then
	VBoxManage modifyvm $name --firmware $firmware
fi
# NAT net
VBoxManage modifyvm $name  --nic1 nat --nictype1 82540EM
# Mapping sshd port from gust os to host os
VBoxManage modifyvm $name --natpf1 "guestssh,tcp,,$sshport,,22"
# Add serial port
VBoxManage modifyvm $name --uart1 "0x03f8" "4"
VBoxManage modifyvm $name --uartmode1 server "/tmp/$name"

# Start vbox with vrde on
VBoxHeadless --startvm $name -e "TCP/Ports=$vrdeport" -vrde on

