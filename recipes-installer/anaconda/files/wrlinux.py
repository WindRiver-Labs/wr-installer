#
# wrlinux.py
#
# Copyright (C) 2007  Red Hat, Inc.  All rights reserved.
# Copyright (C) 2013  Wind River Systems,  All rights reserved.
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
from pyanaconda.constants import *
from pyanaconda.product import *
from pyanaconda.flags import flags
from pyanaconda import iutil
from pyanaconda.network import hasActiveNetDev
from pyanaconda import isys

import os, types
import gettext
_ = lambda x: gettext.ldgettext("anaconda", x)

import ConfigParser

from pyanaconda import installmethod
from pyanaconda import smartinstall

class InstallClass(BaseInstallClass):
    # name has underscore used for mnemonics, strip if you dont need it
    id = "wrlinux"
    name = productName
    _description = N_("The default installation of %s includes a set of "
                      "software applicable for general console usage. "
                      "You can optionally select a different set of software "
                      "now.")
    _descriptionFields = (productName,)
    sortPriority = 100000

    tasks = [(N_("None"), [])]

    _l10n_domain = "anaconda"

    def __init__(self):
        BaseInstallClass.__init__(self)

        if not flags.livecdInstall:
            config = ConfigParser.ConfigParser()
            config.read(["/tmp/product/.buildstamp", "/.buildstamp", os.environ.get("PRODBUILDPATH", "")])

            self.image_list = (config.get("Rootfs", "LIST") or "").split()

            self.image = {}
            self.tasks = []

            for image in self.image_list:
                image_summary = config.get(image, "SUMMARY")
                image_description = config.get(image, "DESCRIPTION")
                package_install = config.get(image, "PACKAGE_INSTALL")
                package_install_attemptonly = config.get(image, "PACKAGE_INSTALL_ATTEMPTONLY")
                self.image[image] = (image_summary, image_description, package_install, package_install_attemptonly)

                short_image = image.replace("%s-image-" % self.id, "")

                self.tasks.append(("%s (%s)" % (image_summary, short_image), [image]))
                self.tasks.append(("%s with development files (%s, dev-pkgs, staticdev-pkgs)" % (image_summary, short_image), [image, "dev-pkgs", "staticdev-pkgs"]))
                self.tasks.append(("%s with debug symbols (%s, dbg-pkgs)" % (image_summary, short_image), [image, "dbg-pkgs"]))
                self.tasks.append(("%s with development files and debug symbols (%s, dev-pkgs, staticdev-pkgs, dbg-pkgs)" % (image_summary, short_image), [image, "dev-pkgs", "staticdev-pkgs", "dbg-pkgs"]))

    def getPackagePaths(self, uri):
        if not type(uri) == types.ListType:
            uri = [uri,]

        return {'Wind River Software Repository': uri}

    def configure(self, anaconda):
	BaseInstallClass.configure(self, anaconda)
        BaseInstallClass.setDefaultPartitioning(self,
                                                anaconda.storage,
                                                anaconda.platform)

    def setGroupSelection(self, anaconda):
        BaseInstallClass.setGroupSelection(self, anaconda)
        map(lambda x: anaconda.backend.selectGroup(x), ["image"])

    def getBackend(self):
        if flags.livecdInstall:
            import pyanaconda.livecd
            return pyanaconda.livecd.LiveCDCopyBackend
        else:
            return smartinstall.SmartBackend

    def productMatches(self, oldprod):
        if oldprod is None:
            return False

        if oldprod.startswith(productName):
            return True

        productUpgrades = {
                "Wind River Linux": ("Wind River Linux", )
        }

        if productUpgrades.has_key(productName):
            acceptable = productUpgrades[productName]
        else:
            acceptable = ()

        for p in acceptable:
            if oldprod.startswith(p):
                return True

        return False

    def versionMatches(self, oldver):
        try:
            oldVer = float(oldver)
            # Trim off any "-Alpha" or "-Beta".
            newVer = float(productVersion.split('-')[0])
        except ValueError:
            return True

        # This line means we do not support upgrading from anything older
        # than two versions ago!
        return newVer >= oldVer and newVer - oldVer <= 2

    def setNetworkOnbootDefault(self, network):
        if hasActiveNetDev():
            return

        for devName, dev in network.netdevices.items():
            if (not isys.isWirelessDevice(devName) and
                isys.getLinkStatus(devName)):
                dev.set(('ONBOOT', 'yes'))
                break
