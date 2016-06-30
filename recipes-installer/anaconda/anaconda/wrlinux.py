#
# wrlinux.py
#
# Copyright (C) 2010  Red Hat, Inc.  All rights reserved.
# Copyright (C) 2016  Wind River Systems,  All rights reserved.
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
from pyanaconda.kickstart import getAvailableDiskSpace
from blivet.partspec import PartSpec
from blivet.platform import platform
from blivet.devicelibs import swap
from blivet.size import Size

from pyanaconda.packaging.smartpayload import SmartPayload
from pyanaconda.flags import flags
import ConfigParser
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

    def configure(self, anaconda):
        BaseInstallClass.configure(self, anaconda)
        self.setDefaultPartitioning(anaconda.storage)

    def setNetworkOnbootDefault(self, ksdata):
        if network.has_some_wired_autoconnect_device():
            return
        # choose the device used during installation
        # (ie for majority of cases the one having the default route)
        dev = network.default_route_device() \
              or network.default_route_device(family="inet6")
        if not dev:
            return
        # ignore wireless (its ifcfgs would need to be handled differently)
        if nm.nm_device_type_is_wifi(dev):
            return
        network.update_onboot_value(dev, "yes", ksdata)

    def __init__(self):
        BaseInstallClass.__init__(self)

    def getBackend(self):
        return SmartPayload

    def read_buildstamp(self):
        image = {}
        tasks = {}

        if not flags.livecdInstall:
            config = ConfigParser.ConfigParser()
            config.read(["/tmp/product/.buildstamp", "/.buildstamp", os.environ.get("PRODBUILDPATH", "")])

            image_list = (config.get("Rootfs", "LIST") or "").split()
            for image_name in image_list:
                image_summary = config.get(image_name, "SUMMARY")
                image_description = config.get(image_name, "DESCRIPTION")
                package_install = config.get(image_name, "PACKAGE_INSTALL")
                package_install_attemptonly = config.get(image_name,
                                                         "PACKAGE_INSTALL_ATTEMPTONLY")
                image[image_name] = (image_summary,
                                     image_description,
                                     package_install,
                                     package_install_attemptonly)

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

