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

from pyanaconda import installmethod
from pyanaconda import smartinstall

class InstallClass(BaseInstallClass):
    # name has underscore used for mnemonics, strip if you dont need it
    id = "wrlinux"
    name = N_("Wind River Linux")
    _description = N_("The default installation of %s includes a set of "
                      "software applicable for general console usage. "
                      "You can optionally select a different set of software "
                      "now.")
    _descriptionFields = (productName,)
    sortPriority = 100000

    tasks = [(N_("Standard Workstation (glibc-std)"), ["core","base","bsp","console"]),
             (N_("Development Workstation (glibc-std, toolchain, dev tools)"), ["core","base","bsp","console","dev","gdb","debug"])
            ]

    _l10n_domain = "anaconda"

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
        map(lambda x: anaconda.backend.selectGroup(x), ["core"])

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

    def __init__(self):
	BaseInstallClass.__init__(self)
