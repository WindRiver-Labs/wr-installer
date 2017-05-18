#
# wrlinux.py
#
# Copyright (C) 2010  Red Hat, Inc.  All rights reserved.
# Copyright (C) 2016  Wind River Systems,  All rights reserved.
# Copyright (C) 2017  Wind River Systems,  All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

from pyanaconda.installclass import BaseInstallClass
from pyanaconda.product import productName
from pyanaconda import network
from pyanaconda import nm
from pyanaconda.flags import flags

import configparser
import os

class WRLinuxBaseInstallClass(BaseInstallClass):
    id = "wrlinux"
    name = productName
    sortPriority = 100000
    defaultFS = "ext4"

    bootloaderTimeoutDefault = 5

    installUpdates = False

    _l10n_domain = "comps"

    efi_dir = "BOOT"

    def setNetworkOnbootDefault(self, ksdata):
        if any(nd.onboot for nd in ksdata.network.network if nd.device):
            return
        # choose first wired device having link
        for dev in nm.nm_devices():
            if nm.nm_device_type_is_wifi(dev):
                continue
            try:
                link_up = nm.nm_device_carrier(dev)
            except (nm.UnknownDeviceError, nm.PropertyNotFoundError):
                continue
            if link_up:
                network.update_onboot_value(dev, True, ksdata=ksdata)
                break

    def __init__(self):
        BaseInstallClass.__init__(self)

    def read_buildstamp(self):
        image = {}
        tasks = {}

        if not flags.livecdInstall:
            config = configparser.ConfigParser()
            config.read(["/tmp/product/.buildstamp", "/.buildstamp", os.environ.get("PRODBUILDPATH", "")])

            image_list = (config.get("Rootfs", "LIST") or "").split()
            for image_name in image_list:
                image_summary = config.get(image_name, "SUMMARY")
                image_description = config.get(image_name, "DESCRIPTION")
                package_install = config.get(image_name, "PACKAGE_INSTALL")
                package_install_attemptonly = config.get(image_name,
                                                         "PACKAGE_INSTALL_ATTEMPTONLY")
                image_linguas = config.get(image_name, "IMAGE_LINGUAS")
                image[image_name] = (image_summary,
                                     image_description,
                                     package_install,
                                     package_install_attemptonly,
                                     image_linguas)

                short_image = image_name.replace("%s-image-" % self.id, "")

                taskid = short_image
                name = image_name
                description = "%s" % image_summary
                group = ""
                tasks[taskid] = (name, description, group)

                taskid = "%s-dev" % short_image
                name = "%s dev-pkgs staticdev-pkgs" % image_name
                description = "%s with development files" % image_summary
                group = "dev-pkgs staticdev-pkgs"
                tasks[taskid] = (name, description, group)

                taskid = "%s-dbg" % short_image
                name = "%s dbg-pkgs" % image_name
                description = "%s with debug symbols" % image_summary
                group = "dbg-pkgs"
                tasks[taskid] = (name, description, group)

                taskid = "%s-dev-dbg" % short_image
                name = "%s dev-pkgs staticdev-pkgs dbg-pkgs" % image_name
                description = "%s with development files and debug symbols" % image_summary
                group = "dev-pkgs staticdev-pkgs dbg-pkgs"
                tasks[taskid] = (name, description, group)

        return image, tasks

