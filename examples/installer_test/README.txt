How to use docker + virtualbox to do installation test

1. The test case try to resolve:
1) On ubuntu host, use virtualbox with commands to boot from
   iso to do anaconda installation.

2) If ubuntu host is a server that could not install the newest
   virtualbox (permission limits), and use docker to create an
   image with virtualbox intalled.

2. Prerequisites
1) The host is ubuntu (such as pek-lpggp1 is ubuntu 14.04)
2) The host supports docker, and have rights to use it.
3) The host could connect internet

3. Build docker image
1) Create dir docker_ubuntu/ which has Dockerfile provided by
   the case.

2) Copy installer-vb64.sh to docker_ubuntu/

3) Record host code name to docker_ubuntu/host_ubuntu.
   Run 'lsb_release -sc > docker_ubuntu/host_ubuntu' in host.

4) Build docker image with tag ubuntu-vb (you could name your
   own) for the image:
   docker build -t ubuntu-vb docker_ubuntu/
   -) The ubuntu image is from docker hub, the official xenial (16.04)
      https://hub.docker.com/r/library/ubuntu/tags/xenial/

   -) The version of virtualbox is 5.0.20

4. Run container
1) Map two ports
   - One (such as 4444) is used for virtualbox vrdeport, user
     could use rdesktop to display virtualbox graphic window
     from remote.(such as "rdesktop pek-lpggp1:4444")

   - Another (such as 4445) is used for ssh client to connect
     target installer.
     (such as "ssh -p 4445 root@pek-lpggp1")

2) Bind mount two volumes
   - One is used for virtualbox, it reuses host kernel module.
     "-v /lib/modules/:/lib/modules/"

   - Another is used for including iso image. It should be mapped
     to "/mnt"
     "-v path-has-iso/:/mnt"

3) Option '--privileged' is required

4) Execute installer-vb64.sh to start testing
   - Set vm name with '-n <name>'

   - Set iso image whit '-i <path-to-iso>'

   - Optional set firmware type '-f [bios|efi|efi32|efi64]'

   - Vbox generates one hdd image for testing, optional set
     its size with "-h <hddsize>", default is 4096(MB)

   - Optional set memory size with '-m <memsize>', default
     is 1024(MB)

   - Set vrdeport with "-v <vrdeport>", default is 4444,
     it should be the same with container port map

   - Set ssh map port with "-s <sshport>", default is 4445
     it should be the same with container port map

5) Example
   - On host pek-lpggp1, run container with image ubuntu-vb.
     sudo docker run -it --rm  -p 4444:4444 -p 4445:4445 --privileged \
         -v /path-to-build-topdir/:/mnt \
         -v /lib/modules/:/lib/modules/ ubuntu-vb \
         /usr/sbin/installer-vb64.sh -n installer_test \
         -i /mnt/export/images/wrlinux-image-installer-intel-x86-64.iso

   - On remote, connect virtualbox vrdeport:
     rdesktop pek-lpggp1:4444

   - On remote, connect target installer ssh server:
     ssh -p 4445 root@pek-lpggp1

