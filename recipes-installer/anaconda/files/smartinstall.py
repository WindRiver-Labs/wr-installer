#
# smartinstall.py
#
# Copyright (C) 2014  Wind River Systems
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

from flags import flags
from errors import *

import ConfigParser
import sys
import os
import os.path
import shutil
import time
import warnings
import types
import locale
import glob
import tempfile
import itertools
import re

import pwd

import anaconda_log

from smart.interface import Interface, getScreenWidth
from smart.util.strtools import sizeToStr, printColumns
from smart.progress import Progress
from smart.const import VERSION, DATADIR, OPTIONAL, ALWAYS
from smart.fetcher import Fetcher
from smart.report import Report
from smart import init, initDistro, initPlugins, initPycurl, initPsyco
from smart.option import OptionParser
from smart import *

from backend import AnacondaBackend
from product import isFinal, productName, productVersion, productStamp
from constants import *
from image import *
from compssort import *
import packages

import gettext
_ = lambda x: gettext.ldgettext("anaconda", x)


import logging
log = logging.getLogger("anaconda")

import iutil
import isys

class AnacondaProgress(Progress):
    def __init__(self, intf):
        self.intf = intf
        self.progressWindow = None
        self.progressSubWindow = None
        self.windowTitle = "smart Package Manager"
        self.subTitle = None
        self.subTopic = None
        Progress.__init__(self)

    def expose(self, topic, percent, subkey, subtopic, subpercent, data, done):
        #log.debug("called smartinstall.AnacondaProgress.expose(%s, %s, subkey, %s, %s, data)" % (topic, percent, subtopic, subpercent))
        if not subtopic:
            self._closeSubProgressWindow()
            if not self.progressWindow:
                #log.debug("new progressWindow(%s, %s, 100)" % (self.windowTitle, topic))
                self.progressWindow = self.intf.progressWindow (self.windowTitle, topic, 100)
            #log.debug("progressWindow(%s)" % (percent))
            self.progressWindow.set(percent)
        else:
            # Topic changes, so clear the window
            if self.progressSubWindow and self.subTitle != topic and self.subTopic != subtopic:
                self._closeSubProgressWindow()

            if not self.progressSubWindow:
                #log.debug("new sub-progressWindow(%s, %s, 100)" % (topic, subtopic))
                self.progressSubWindow = self.intf.progressWindow (self.windowTitle, subtopic, 100)
                self.subTitle = topic
                self.subTopic = subtopic

            #log.debug("sub-progressWindow(%s)" % (subpercent))
            self.progressSubWindow.set(subpercent)

    def setDone(self):
        #log.debug("called smartinstall.AnacondaProgress.setDone")
        Progress.setDone(self)
        self.show()

    def setSubDone(self, subkey):
        #log.debug("called smartinstall.AnacondaProgress.setSubDone")
        Progress.setSubDone(self, subkey)
        self.show()

    def stop(self):
        #log.debug("called smartinstall.AnacondaProgress.stop")
        self._closeSubProgressWindow()
        self._closeProgressWindow()
        Progress.stop(self)

    def _closeProgressWindow(self):
        if self.progressWindow:
            self.progressWindow.pop()
            self.progressWindow = None

    def _closeSubProgressWindow(self):
        if self.progressSubWindow:
            self.progressSubWindow.pop()
            self.progressSubWindow = None
            self.subTopic = None
            self.subTitle = None

class AnacondaInterface(Interface):
    def __init__(self, ctrl, anaconda):
        #log.debug("called smartinstall.AnacondaInterface.__init__")
        Interface.__init__(self, ctrl)
        self.anaconda = anaconda
        self._progress = AnacondaProgress(self.anaconda.intf)
        self.statusWindow = None
        self.waitWindow = None

    def eventsPending(self):
        log.debug("called smartinstall.AnacondaInterface.eventsPending")
        return False

    def processEvents(self):
        log.debug("called smartinstall.AnacondaInterface.processEvents")
        pass

    def showStatus(self, msg):
        if self.statusWindow:
            self.statusWindow.pop()
        self.statusWindow = self.anaconda.intf.progressWindow(self._progress.windowTitle, msg, 100, pulse=True)

    def hideStatus(self):
        #log.debug("called smartinstall.AnacondaInterface.hideStatus")
        if self.statusWindow:
            self.statusWindow.pop()
            self.statusWindow = None

    def showOutput(self, output):
        log.debug("called smartinstall.AnacondaInterface.showOutput(%s)" % output)
        pass

    def getProgress(self, obj, hassub=False):
        #log.debug("called smartinstall.AnacondaInterface.getProgress")
        return self._progress

    def getSubProgress(self, obj):
        #log.debug("called smartinstall.AnacondaInterface.getSubProgress")
        return self._progress

    def askYesNo(self, question, default=False):
        log.debug("called smartinstall.AnacondaInterface.askYesNo(%s)" % question)
        return True

    def askContCancel(self, question, default=False):
        log.debug("called smartinstall.AnacondaInterface.askContCanel(%s)" % question)
        return True

    def askOkCancel(self, question, default=False):
        log.debug("called smartinstall.AnacondaInterface.askOkCancel(%s)" % question)
        return True

    def askInput(self, prompt, message=None, widthchars=None, echo=True):
        log.debug("called smartinstall.AnacondaInterface.askInput(%s)" % prompt)
        return ""

    def showChangeSet(self, changeset, keep=None, confirm=False):
        log.debug("called smartinstall.AnacondaInterface.showChangeSet(%s)" % changeset)
        pass

    def confirmChangeSet(self, changeset):
        log.debug("called smartinstall.AnacondaInterface.confirmChangeSet(%s)" % changeset)
        return True

    def confirmChange(self, oldchangeset, newchangeset):
        log.debug("called smartinstall.AnacondaInterface.confirmChange")
        return True

    def error(self, msg):
        log.error("smart: %s" % msg)

    def warning(self, msg):
        log.warning("smart: %s" % msg)

    def info(self, msg):
        log.info("smart: %s" % msg)

    def debug(self, msg):
        log.debug("smart: %s" % msg)

    def message(self, level, msg):
        if level == ERROR:
            self.error(msg)
        elif level == WARNING:
            self.warning(msg)
        elif level == DEBUG:
            self.debug(msg)
        else:
            self.info(msg)

class SmartBackend(AnacondaBackend):
    def __init__ (self, anaconda):
        AnacondaBackend.__init__(self, anaconda)

        self.supportsUpgrades = True
        self.supportsPackageSelection = True

        self.anaconda = anaconda
        self.smart_ctrl = None

        self.etcrpm_dir = self.instPath + "/etc/rpm"
        self.librpm_dir = self.instPath + "/var/lib/rpm"
        self.smart_dir = self.instPath + "/var/lib/smart"

        self.pkgs_to_install = None
        self.feeds = {}

    def doBackendSetup(self, anaconda):
	log.debug("called smartinstall.SmartBackend.doBackendSetup")

        if anaconda.dir == DISPATCH_BACK:
            return DISPATH_BACK

        if anaconda.upgrade:
            # make sure that the rpmdb doesn't have stale locks
            iutil.resetRpmDb(anaconda.rootPath)
        else:
            self._initRPM()

        self._initSmart()

	# Parse and configure the local repos
        iface.object._progress.windowTitle = "Package Feeds"
        iface.object.showStatus("Configuring package feeds")

        if os.path.isdir("/pkgfeed") and os.access("/pkgfeed/.feedpriority", os.R_OK):
            f = open("/pkgfeed/.feedpriority")
            for line in f:
                (priority, feed) = line.split()
                self.feeds[feed] = priority
            f.close()

            for feed in self.feeds:
                if os.path.isdir("/pkgfeed/%s/repodata" % feed):
                    priority=self.feeds[feed]
                    self._runSmart('channel', 
                                   ['--add', feed, 'type=rpm-md', 
                                    'priority=%s' % self.feeds[feed],
                                    'baseurl=/pkgfeed/%s' % feed,
                                    '-y'])

            self._runSmart('update', None)

        iface.object.hideStatus()


    def resetPackageSelections(self):
	log.debug("called smartinstall.SmartBackend.resetPackageSelections")
        self.pkgs_to_install = ""

    def selectPackage(self, pkg, *args):
	log.debug("called smartinstall.SmartBackend.selectPackage")

    def deselectPackage(self, pkg, *args):
	log.debug("called smartinstall.SmartBackend.deselectPackage")

    def groupListExists(self, grps):
        """Returns bool of whether all of the given groups exist."""
	log.debug("called smartinstall.SmartBackend.groupListExists")
        return True

    def groupListDefault(self, grps):
        """Returns bool of whether all of the given groups exist."""
	log.debug("called smartinstall.SmartBackend.groupListDefault")
        return True

    def selectGroup(self, group, *args):
	log.debug("called smartinstall.SmartBackend.selectGroup(%s, %s)" % (group, args))

    def deselectGroup(self, group, *args):
	log.debug("called smartinstall.SmartBackend.deselectGroup")

    def getDefaultGroups(self, anaconda):
        log.debug("called smartinstall.SmartBackend.getDefaultGroups")
        return ['core', 'base', 'bsp', 'console', 'dev']

    def doPostSelection(self, anaconda):
	log.debug("called smartinstall.SmartBackend.doPostSelection")

        # Only solve dependencies on the way through the installer, not the way back.
        if anaconda.dir == DISPATCH_BACK:
            return

        self.pkgs_to_install = "packagegroup-core-boot@qemux86_64 kernel-image-3.10.19-wr6.0.0.0-standard@qemux86_64"

        log.debug("Selected packages %s", self.pkgs_to_install)

        # Verify that the right minimum things are still set..
        # i.e. see yum, select kernel, platform packages, bootloader, FS packages, and installer needed

        # Validation transaction w/o installing?

        # Verify disk space, download packages, etc..

    def doPreInstall(self, anaconda):
	log.debug("called smartinstall.SmartBackend.doPreInstall")

        # See yum configuration...
        AnacondaBackend.doPreInstall(self, anaconda)

    def doInstall(self, anaconda):
	log.debug("called smartinstall.SmartBackend.doInstall")

        # setup status bars
        # perform the install
        iface.object._progress.windowTitle = "Install Packages"
        self._runSmart('install', self.pkgs_to_install.split())

    def doPostInstall(self, anaconda):
	log.debug("called smartinstall.SmartBackend.doPostInstall")

        # See yum configuration...
        AnacondaBackend.doPostInstall(self, anaconda)



    def postAction(self, anaconda):
	log.debug("called smartinstall.SmartBackend.postAction")

    def kernelVersionList(self, rootPath="/"):
	log.debug("called smartinstall.SmartBackend.kernelVersionList")

        # Look at Yum, query RPM for installed kernel(s)?
        return []

    def writePackageKS(self, f, anaconda):
        log.debug("called smartinstall.SmartBackend.writePackageKS")

    def writeConfigurations(self):
        log.debug("called smartinstall.SmartBackend.writeConfigurations")

    def complete(self, anaconda):
        log.debug("called smartinstall.SmartBackend.complete")
        # clean up rpmdb locks so that kickstart %post scripts aren't
        # unhappy (#496961)
        iutil.resetRpmDb(self.instPath)


### Configure RPM, and related files
    def _initRPM(self):
        # Configure /etc/rpm
        iutil.mkdirChain(self.etcrpm_dir)

        # Setup /etc/rpm/platform

        # Setup /etc/rpm/sysinfo/Dirnames
        iutil.mkdirChain(self.etcrpm_dir + "/sysinfo")
        fd = open(self.etcrpm_dir + "/sysinfo/Dirnames", "w")
        fd.write("/\n")
        fd.close()

        # Setup provides if needed

        # Setup /var/lib/rpm
        iutil.mkdirChain(self.librpm_dir)
        iutil.mkdirChain(self.librpm_dir + "/log")

        # Touch the log file
        fd = open(self.librpm_dir + "/log/log.0000000001", "w")
        fd.close()

        # Configure the DB_CONFIG
        buf = """
# ================ Environment
set_data_dir .
set_create_dir .
set_lg_dir ./log
set_tmp_dir ./tmp
set_flags db_log_autoremove on

# -- thread_count must be >= 8
set_thread_count 64

# ================ Logging

# ================ Memory Pool
set_cachesize 0 1048576 0
set_mp_mmapsize 268435456

# ================ Locking
set_lk_max_locks 16384
set_lk_max_lockers 16384
set_lk_max_objects 16384
 mutex_set_max 163840

# ================ Replication
"""
        fd = open(self.librpm_dir + "/DB_CONFIG", "w")
        fd.write(buf)
        fd.close()


### Configure smart for a cross-install, and the install wrapper
    def _initSmart(self, command=None, argv=None):
        iutil.mkdirChain(self.smart_dir)
        iutil.mkdirChain(self.instPath + "/install/tmp")

        buf = """#!/bin/bash

export PATH="${PATH}"
export D="%s"
export OFFLINE_ROOT="$D"
export IPKG_OFFLINE_ROOT="$D"
export OPKG_OFFLINE_ROOT="$D"
export INTERCEPT_DIR="/"
export NATIVE_ROOT="/"

exec 1>>/tmp/scriptlet.log 2>&1 

echo $2 $1/$3 $4
if [ $2 = "/bin/sh" ]; then
  $2 -x $1/$3 $4
else
  $2 $1/$3 $4
fi
if [ $? -ne 0 ]; then
  if [ $4 -eq 1 ]; then
    mkdir -p $1/etc/rpm-postinsts
    num=100
    while [ -e $1/etc/rpm-postinsts/${num}-* ]; do num=$((num + 1)); done
    name=`head -1 $1/$3 | cut -d' ' -f 2`
    echo "#!$2" > $1/etc/rpm-postinsts/${num}-${name}
    echo "# Arg: $4" >> $1/etc/rpm-postinsts/${num}-${name}
    cat $1/$3 >> $1/etc/rpm-postinsts/${num}-${name}
    chmod +x $1/etc/rpm-postinsts/${num}-${name}
  else
    echo "Error: pre/post remove scriptlet failed"
  fi
fi
""" % (self.instPath)

        fd = open(self.instPath + "/install/scriptlet_wrapper", "w")
        fd.write(buf)
        fd.close()
        os.chmod(self.instPath + "/install/scriptlet_wrapper", 0755)

        self.smart_ctrl = init(command, argv=argv,
                               datadir=self.smart_dir, configfile=None,
                               gui=False, shell=False, quiet=True,
                               interface=None, forcelocks=False,
                               loglevel=None)

        # Override the dummy interface with the locally defined one
	iface.object = AnacondaInterface(self.smart_ctrl, self.anaconda)

        initDistro(self.smart_ctrl)
        initPlugins()
        initPycurl()
        initPsyco()

        sysconf.set("rpm-root", self.instPath, soft=True)
        sysconf.set("rpm-extra-macros._tmppath", "/install/tmp", soft=True)
        sysconf.set("rpm-extra-macros._cross_scriptlet_wrapper", self.instPath + "/install/scriptlet_wrapper", soft=True)

        sysconf.set("rpm-nolinktos", "1")
        sysconf.set("rpm-noparentdirs", "1")

        # Ensure we start with a blank channel set...
        sysconf.remove("channels")

        self.smart_ctrl.saveSysConf()
        self.smart_ctrl.restoreMediaState()


### Run smart commands directly
    def _runSmart(self, command=None, argv=None):
        rc = iface.run(command, argv)
        if rc is None:
            rc = 0
        self.smart_ctrl.saveSysConf()
        self.smart_ctrl.restoreMediaState()
