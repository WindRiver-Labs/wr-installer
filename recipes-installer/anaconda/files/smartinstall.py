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

import urlgrabber.progress
import urlgrabber.grabber
from urlgrabber.grabber import URLGrabber, URLGrabError

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
#from pyanaconda import network
from smartquery import *

import gettext
_ = lambda x: gettext.ldgettext("anaconda", x)


import logging
log = logging.getLogger("anaconda")

import iutil
import isys

urlgrabber.grabber.default_grabber.opts.user_agent = "%s (anaconda)/%s" %(productName, productVersion)

class AnacondaProgress(Progress):
    def __init__(self, intf):
        self.intf = intf
        self.progressWindow = None
        self.windowTitle = "smart Package Manager"
        self.subTopic = None
        Progress.__init__(self)

    def expose(self, topic, percent, subkey, subtopic, subpercent, data, done):
        #log.debug("called smartinstall.AnacondaProgress.expose(%s, %s, subkey, %s, %s, data)" % (topic, percent, subtopic, subpercent))

        if not self.progressWindow:
            #log.debug("new progressWindow(%s, %s, 100)" % (self.windowTitle, topic))
            self.progressWindow = self.intf.progressWindow (self.windowTitle, topic, 100)

        if subtopic:
            self.subTopic = "%s (%s%%)" % (subtopic, subpercent)

        self.progressWindow.set(percent,
                                topic=topic,
                                subtopic=self.subTopic,
                                percent="Total %s%%" % (percent))

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
        self._closeProgressWindow()
        Progress.stop(self)

    def _closeProgressWindow(self):
        if self.progressWindow:
            self.progressWindow.pop()
            self.progressWindow = None

class AnacondaInterface(Interface):
    def __init__(self, ctrl, anaconda):
        #log.debug("called smartinstall.AnacondaInterface.__init__")
        Interface.__init__(self, ctrl)
        self.anaconda = anaconda
        self._progress = AnacondaProgress(self.anaconda.intf)
        self.statusWindow = None
        self.waitWindow = None

    def eventsPending(self):
        #log.debug("called smartinstall.AnacondaInterface.eventsPending")
        return False

    def processEvents(self):
        #log.debug("called smartinstall.AnacondaInterface.processEvents")
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
        #log.debug("called smartinstall.AnacondaInterface.showOutput(%s)" % output)
        pass

    def getProgress(self, obj, hassub=False):
        #log.debug("called smartinstall.AnacondaInterface.getProgress")
        return self._progress

    def getSubProgress(self, obj):
        #log.debug("called smartinstall.AnacondaInterface.getSubProgress")
        return self._progress

    def askYesNo(self, question, default=False):
        #log.debug("called smartinstall.AnacondaInterface.askYesNo(%s)" % question)
        return True

    def askContCancel(self, question, default=False):
        #log.debug("called smartinstall.AnacondaInterface.askContCanel(%s)" % question)
        return True

    def askOkCancel(self, question, default=False):
        #log.debug("called smartinstall.AnacondaInterface.askOkCancel(%s)" % question)
        return True

    def askInput(self, prompt, message=None, widthchars=None, echo=True):
        #log.debug("called smartinstall.AnacondaInterface.askInput(%s)" % prompt)
        return ""

    def showChangeSet(self, changeset, keep=None, confirm=False):
        #log.debug("called smartinstall.AnacondaInterface.showChangeSet(%s)" % changeset)
        pass

    def confirmChangeSet(self, changeset):
        #log.debug("called smartinstall.AnacondaInterface.confirmChangeSet(%s)" % changeset)
        return True

    def confirmChange(self, oldchangeset, newchangeset):
        #log.debug("called smartinstall.AnacondaInterface.confirmChange")
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

class SmartRepo:
    def __init__(self, repoid):
        self.id = repoid
        self.type = "rpm-md"
        self.name = repoid
        self.baseurl = None
        self.components = None

        # Really priority (default to 100 like YUM)
        self.cost = 100

        self.enabled = False

        self.mirrorlist = None
        self.mirrorrepos = []

        self._anacondaBaseURLs = []

        # MGH: TBD proxy setup
        self.proxy = False
        self.proxy_username = None
        self.proxy_password = None

    # needed to store nfs: repo url that yum doesn't know
    def _getAnacondaBaseURLs(self):
        return self._anacondaBaseURLs or self.baseurl or [self.mirrorlist]

    def _setAnacondaBaseURLs(self, value):
        log.debug("AnacondaSmartRepo(%s):_setAnacondaBaseURLs = %s" % (self.id, value))
        self._anacondaBaseURLs = value

    anacondaBaseURLs = property(_getAnacondaBaseURLs, _setAnacondaBaseURLs,
                                doc="Emulate anacondaYum entries:")

    def isEnabled(self):
        log.debug("SmartRepo(%s): isEnabled - %s" % (self.id, ['False','True'][self.enabled]))
        return self.enabled

    def needsNetwork(self):
        # MGH: Fix up later by inspecting the baseurl...
        return False

class AnacondaSmartRepo(SmartRepo):
    def __init__(self, repoid, anaconda=None):
        SmartRepo.__init__(self, repoid)
        self.anaconda = anaconda
        self.enablegroups = True

        self.repos = self

    def items(self):
        item_list = []
        channels = sysconf.get("channels") or {}
        log.debug("AnacondaSmartRepo(%s):items() = %s" % (self.id, channels))
        for channel in channels:
            reponame = channel

            # MGH need to add in type, name, baseurl, components, enabled, and cost
            repo = SmartRepo(channel)
            repo.enabled = True
            repo.name = channels[channel].get("name")
            repo.baseurl = [channels[channel].get("baseurl")]
            repo.cost = channels[channel].get("priority")

            item_list.append((reponame, repo))

        log.debug("AnacondaSmartRepo(%s):items() = %s" % (self.id, item_list))
        return item_list

    def fetchMirrorlist(self, repoobj):
        output = '/tmp/%s' % repoobj.id
        try:
            os.unlink(output)
        except:
            pass

        try:
            with open(output, 'w') as f:
                import pycurl

                curl = pycurl.Curl()
                curl.setopt(curl.URL, repoobj.mirrorlist)
                curl.setopt(curl.WRITEDATA, f)
                if repoobj.proxy:
                    curl.setopt(curl.PROXY, repoobj.proxy)
                    if repoobj.proxy_username:
                        curl.setopt(curl.PROXYUSERPWD, '%s:%s'
                                     % (repoobj.proxy_username, repoobj.proxy_password or ''))
                curl.perform()
                curl.close()
            return True
        except:
            log.debug("Failed to fetch repository mirrorlist %s" % repoobj.id)
            return False

    def add(self, repoobj):
        log.debug("AnacondaSmartRepo(%s):add() = %s" % (self.id, repoobj.id))
        channels = sysconf.get("channels") or {}
        if repoobj.id in channels:
            raise ValueError("Repository %s is listed more than once in the configuration" % (repoobj.id))

        if repoobj.mirrorlist:
            try:
                if not self.fetchMirrorlist(repoobj):
                    raise ValueError("Failed to fetch repository mirrorlist %s" % repoobj.id)

                import ConfigParser
                config = ConfigParser.ConfigParser()
                config.read('/tmp/%s' % repoobj.id)
                for reponame in config.sections():
                    newrepoobj = AnacondaSmartRepo(reponame.replace(' ', ''), repoobj.anaconda)
                    if config.has_option(reponame, 'type'):
                        newrepoobj.type = config.get(reponame, 'type')
                    if config.has_option(reponame, 'priority'):
                        newrepoobj.cost = config.getint(reponame, 'priority')
                    if config.has_option(reponame, 'baseurl'):
                        newrepoobj.baseurl = [config.get(reponame, 'baseurl')]
                    if config.has_option(reponame, 'name'):
                        newrepoobj.name = config.get(reponame, 'name')
                    if repoobj.proxy:
                        newrepoobj.proxy = repoobj.proxy
                        newrepoobj.proxy_username = repoobj.proxy_username
                        newrepoobj.proxy_password = repoobj.proxy_password
                    self.add(newrepoobj)
                    repoobj.mirrorrepos.append(newrepoobj)

                return None
            except:
                raise ValueError("Invalid repository mirror list %s" % repoobj.id)

        if not repoobj.baseurl:
            raise ValueError("Repository %s does not have the baseurl set" % (repoobj.id))

        argv = []
        argv.append('--add')
        argv.append('%s' % repoobj.id)
        argv.append('type=%s' % repoobj.type)
        if repoobj.baseurl[0]:
            argv.append('baseurl=%s' % repoobj.baseurl[0])
        if repoobj.name:
            argv.append('name=%s' % repoobj.name)
        if repoobj.cost:
            argv.append('priority=%s' % repoobj.cost)
        if repoobj.components:
            argv.append('components=%s' % repoobj.components)
        if repoobj.proxy:
            argv.append('proxy=%s' % repoobj.proxy)
            if repoobj.proxy_username:
                argv.append('proxy-username=%s' % repoobj.proxy_username)
                if repoobj.proxy_password:
                    argv.append('proxy-password=%s' % repoobj.proxy_password)
        argv.append('-y')

        self.anaconda.backend.asmart.runSmart('channel', argv)

        repoobj.enabled = True

    def delete(self, repoid):
        log.debug("AnacondaSmartRepo(%s):delete() = %s" % (self.id, repoid))
        channels = sysconf.get("channels") or {}
        if repoid in channels:
            self.anaconda.backend.asmart.runSmart('channel',
                                   ['--remove', repoid, "-y"])

    def enable(self, repoid):
        log.debug("AnacondaSmartRepo(%s):enable() = %s" % (self.id, repoid))
        channels = sysconf.get("channels") or {}
        if repoid in channels:
            self.anaconda.backend.asmart.runSmart('channel',
                                   ['--enable', repoid])
        self.enabled = True

    def disable(self, repoid):
        log.debug("AnacondaSmartRepo(%s):disable() = %s" % (self.id, repoid))
        channels = sysconf.get("channels") or {}
        if repoid in channels:
            self.anaconda.backend.asmart.runSmart('channel',
                                   ['--disable', repoid])
        self.enabled = False

    def close(self):
        pass


# Emulate some of the ayum items.
class AnacondaSmart:
    complementary_glob = {}
    complementary_glob['dev-pkgs'] = '-dev'
    complementary_glob['staticdev-pkgs'] = '-staticdev'
    complementary_glob['doc-pkgs'] = '-doc'
    complementary_glob['dbg-pkgs'] = '-dbg'
    complementary_glob['ptest-pkgs'] = '-ptest'

    def __init__(self, anaconda):
        self.anaconda = anaconda

        self.repoIDcounter = itertools.count()

        # Only needed for hard drive and nfsiso installs.
        self.isodir = None

        # Only needed for media installs.
        self.mediagrabber = None

        # Where is the source media mounted?  This is the directory
        # where Packages/ is located.
        self.tree = "/mnt/install/source"

        # Parse proxy values from anaconda
        self.proxy = None
        self.proxy_url = None
        self.proxy_username = None
        self.proxy_password = None
        if self.anaconda.proxy:
            self.setProxy(self.anaconda, self)

        self.repos = None

        self.smart_ctrl = None

        self.etcrpm_dir = self.anaconda.backend.instPath + "/etc/rpm"
        self.librpm_dir = self.anaconda.backend.instPath + "/var/lib/rpm"
        self.smart_dir = self.anaconda.backend.instPath + "/var/lib/smart"

    # Remove the local repos that we added during the install
    def removeWrlLoclRepo(self):
        channels = sysconf.get("channels") or {}
        for channel in channels:
            if channel.startswith('media_'):
                name = channels[channel]["name"]
                baseurl = [channels[channel]["baseurl"]]
                if len(baseurl) == 0:
                    # Should never reach here
                    baseurl = [""]
                # Only remove the local repo since the network repo maybe available.
                if name.startswith("Install Media feed for") and \
                        baseurl[0].startswith("file:///Packages/"):
                    log.debug("AnacondaSmart: remove channel: %s" % channel)
                    self.runSmart('channel', ['--remove', channel, '-y'])

### Configure smart for a cross-install, and the install wrapper
    def setup(self, command=None, argv=None):
        iutil.mkdirChain(self.smart_dir)
        iutil.mkdirChain(self.anaconda.backend.instPath + "/install/tmp")

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
""" % (self.anaconda.backend.instPath)

        fd = open(self.anaconda.backend.instPath + "/install/scriptlet_wrapper", "w")
        fd.write(buf)
        fd.close()
        os.chmod(self.anaconda.backend.instPath + "/install/scriptlet_wrapper", 0755)

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

        sysconf.set("rpm-root", self.anaconda.backend.instPath, soft=True)
        sysconf.set("rpm-extra-macros._tmppath", "/install/tmp", soft=True)
        sysconf.set("rpm-extra-macros._cross_scriptlet_wrapper", self.anaconda.backend.instPath + "/install/scriptlet_wrapper", soft=True)

        sysconf.set("rpm-nolinktos", "1")
        sysconf.set("rpm-noparentdirs", "1")

        if self.anaconda.upgrade:
            # Note:
            # This is a fix, we didn't remove the channels that we added in
            # previous installs, so remove them here.
            #FIXME: Do we need disable user's channels ?
            self.removeWrlLoclRepo()

            # Enable the installed RPM DB
            channels = sysconf.get("channels") or {}
            if 'rpmsys' not in channels:
                self.runSmart('channel', ['--add', 'rpmsys', 'type=rpm-sys', '-y'])
                iface.object.hideStatus()
        else:
            # Ensure we start with a blank channel set...
            sysconf.remove("channels")

        self.repos = AnacondaSmartRepo("anaconda-config", self.anaconda)

        # Setup repository
        for localpath in ["/mnt/install/source", "/mnt/install/cdimage", "/mnt/install/isodir", ""]:
            if os.path.isdir("%s/Packages" % localpath) and os.access("%s/Packages/.feedpriority" % localpath, os.R_OK):
                f = open("%s/Packages/.feedpriority" % localpath)
                for line in f:
                    (priority, feed) = line.split()
                    if os.path.isdir("%s/Packages/%s/repodata" % (localpath, feed)):
                        repo = SmartRepo("media_%s" % feed)
                        repo.name = "Install Media feed for %s" % feed
                        repo.cost = priority
                        repo.baseurl = ["file://%s/Packages/%s" % (localpath, feed)]
                        self.repos.add(repo)
                f.close()

        if self.anaconda.ksdata:
            for ksrepo in self.anaconda.ksdata.repo.repoList:
                # If no location was given, this must be a repo pre-configured
                # repo that we just want to enable.
                if not ksrepo.baseurl and not ksrepo.mirrorlist:
                    self.repos.enable(ksrepo.name)
                    continue

                anacondaBaseURLs = [ksrepo.baseurl]

                # smart doesn't understand nfs:// and doesn't want to. We need
                # to first do the mount, then translate it into a file:// that
                # smart does understand.
                # "nfs:" and "nfs://" prefixes are accepted in ks_repo --baseurl
                if ksrepo.baseurl and ksrepo.baseurl.startswith("nfs:"):
                    #if not network.hasActiveNetDev() and not self.anaconda.intf.enableNetwork():
                    #    self.anaconda.intf.messageWindow(_("No Network Available"),
                    #        _("Some of your software repositories require "
                    #          "networking, but there was an error enabling the "
                    #          "network on your system."),
                    #        type="custom", custom_icon="error",
                    #        custom_buttons=[_("_Exit installer")])
                    #    sys.exit(1)

                    dest = tempfile.mkdtemp("", ksrepo.name.replace(" ", ""), "/mnt")

                    # handle "nfs://" prefix
                    if ksrepo.baseurl[4:6] == '//':
                        ksrepo.baseurl = ksrepo.baseurl.replace('//', '', 1)
                        anacondaBaseURLs = [ksrepo.baseurl]
                    try:
                        isys.mount(ksrepo.baseurl[4:], dest, "nfs")
                    except Exception as e:
                        log.error("error mounting NFS repo: %s" % e)

                    ksrepo.baseurl = "file://%s" % dest

                repo = SmartRepo(ksrepo.name)
                repo.mirrorlist = ksrepo.mirrorlist
                repo.name = ksrepo.name

                if not ksrepo.baseurl:
                    repo.baseurl = []
                else:
                    repo.baseurl = [ ksrepo.baseurl ]
                repo.anacondaBaseURLs = anacondaBaseURLs

                if ksrepo.cost:
                    repo.cost = ksrepo.cost

                if ksrepo.excludepkgs:
                    repo.exclude = ksrepo.excludepkgs

                if ksrepo.includepkgs:
                    repo.includepkgs = ksrepo.includepkgs

                if ksrepo.noverifyssl:
                    repo.sslverify = False

                if ksrepo.proxy:
                    self.setProxy(ksrepo, repo)

                self.repos.add(repo)

        self.smart_ctrl.saveSysConf()
        self.smart_ctrl.restoreMediaState()
        self.doRepoSetup(self.anaconda)

### Run smart commands directly
    def runSmart(self, command=None, argv=None):
        log.debug("runSmart(%s, %s)" % (command, argv))
        rc = iface.run(command, argv)
        if rc is None:
            rc = 0
        self.smart_ctrl.saveSysConf()
        self.smart_ctrl.restoreMediaState()

        return rc

    def doGroupSetup(self, anaconda):
        log.debug("doGroupSetup ...")
        pass

    def doRepoSetup(self, anaconda, thisrepo = None, fatalerrors = True):
        #iface.object._progress.windowTitle = "Repository Update"
        #iface.object.showStatus("Updating package feed cache...")

        rc = 0
        argv = []
        if thisrepo:
            argv.append(thisrepo)

        try:
            rc = self.runSmart('update', argv)
        except:
            if fatalerrors:
                raise
        #finally:
        #    iface.object.hideStatus()

        return rc

    def doSackSetup(self, anaconda, thisrepo = None, fatalerrors = True):
        # Do nothing...
        pass

    def mediaHandler(self, *args, **kwargs):
        relative = kwargs["relative"]

        ug = URLGrabber(checkfunc=kwargs["checkfunc"])
        ug.urlgrab("%s/%s" % (self.tree, kwargs["relative"]), kwargs["local"],
                   text=kwargs["text"], range=kwargs["range"], copy_local=1)
        return kwargs["local"]

    def avail_groups(self):
        groups = []
        for name in self.anaconda.instClass.image_list:
            groups.append(name)
        for name in self.complementary_glob:
            groups.append(name)
        return ' '.join(groups)

    def group_exists(self, group):
        if group in self.complementary_glob or group in self.anaconda.instClass.image_list:
            return True
        else:
            return False

    def complementary_globs(self, groups):
        globs = []
        for name, glob in self.complementary_glob.items():
            if name in groups:
                globs.append(glob)
        return ' '.join(globs)

    def PackagesObj(self):
        log.debug("called smartinstall.SmartBackend.PackagesObj")

        import StringIO

        ## Create a obj contian all available packagegroups with infos
        stdout = sys.stdout
        sys.stdout = myout = StringIO.StringIO()
        self.runSmart("query", ["--show-all",
                                "--show-format=$name $version $description\n"])
        sys.stdout = stdout
        iface.object.hideStatus()
        myout.seek(0)
        return ParseSmartQuery(myout)


class SmartBackend(AnacondaBackend):
    def __init__ (self, anaconda):
        AnacondaBackend.__init__(self, anaconda)

        self.supportsUpgrades = True
        self.supportsPackageSelection = True

        self.anaconda = anaconda

        self.task_to_install = None
        self.required_pkgs = ['base-files', 'base-passwd', 'kernel-image', 'grub']

        bl_pkgs = anaconda.bootloader.packages
        if bl_pkgs:
            log.debug("smartinstall.SmartBackend: added %s to required_pkgs" % ' '.join(bl_pkgs))
            self.required_pkgs.extend(bl_pkgs)

        self.pkgs_to_install = self.required_pkgs
        self.pkgs_to_attempt = ['--attempt']
        self.grps_to_install = []
        self.feeds = {}

        self.asmart = None

    def doBackendSetup(self, anaconda):
        log.debug("called smartinstall.SmartBackend.doBackendSetup")

        if anaconda.dir == DISPATCH_BACK:
            rc = anaconda.intf.messageWindow(_("Warning"),
                    _("Filesystems have already been activated.  You "
                      "cannot go back past this point.\n\nWould you like to "
                      "continue with the installation?"),
                    type="custom", custom_icon=["error","error"],
                    custom_buttons=[_("_Exit installer"), _("_Continue")])

            if rc == 0:
                sys.exit(0)
            anaconda.dir = DISPATCH_FORWARD
            return DISPATCH_FORWARD

        if anaconda.upgrade:
            # make sure that the rpmdb doesn't have stale locks
            iutil.resetRpmDb(anaconda.rootPath)
        else:
            self._initRPM()

        self.asmart = AnacondaSmart(anaconda)
        self.asmart.setup()

        # Parse and configure the local repos
        iface.object._progress.windowTitle = "Package Feeds"
        iface.object.showStatus("Configuring package feeds")

        # Configure proxy
        if anaconda.proxy:
            # Setup proxy == anaconda.proxy
            pass

            if anaconda.proxyUsername:
                # Setup username using anaconda.proxyUsername
                pass

            if anaconda.proxyPassword:
                # Setup password using anaconda.proxyPassword
                pass

        iface.object.hideStatus()

    def resetPackageSelections(self):
        log.debug("called smartinstall.SmartBackend.resetPackageSelections")
        self.pkgs_to_install = self.required_pkgs
        self.pkgs_to_attempt = ['--attempt']

    def selectPackage(self, pkg, *args):
        log.debug("called smartinstall.SmartBackend.selectPackage %s" % pkg)
        self.pkgs_to_install.append(pkg)
        # Return the number of the selected packages
        return 1

    def deselectPackage(self, pkg, *args):
        log.debug("called smartinstall.SmartBackend.deselectPackage %s" % pkg)
        self.pkgs_to_install.remove(pkg)

    def groupListExists(self, grps):
        """Returns bool of whether all of the given groups exist."""
        log.debug("called smartinstall.SmartBackend.groupListExists: %s" % grps)
        rc = True
        for group in grps:
            if group == 'image':
                continue
            rc = self.asmart.group_exists(group)
            if not rc:
                break
        return rc

    def groupListDefault(self, grps):
        """Returns bool of whether all of the given groups are default"""
        log.debug("called smartinstall.SmartBackend.groupListDefault: %s" % grps)
        return True

    def selectGroup(self, group, *args):
        log.debug("called smartinstall.SmartBackend.selectGroup(%s, %s)" % (group, args))
        if group == 'image' or self.asmart.group_exists(group):
            self.grps_to_install.append(group)

    def deselectGroup(self, group, *args):
        log.debug("called smartinstall.SmartBackend.deselectGroup")
        self.grps_to_install.remove(group)

    def resetGroup(self):
        log.debug("called smartinstall.SmartBackend.resetGroup")
        self.grps_to_install = []

    def getDefaultGroups(self, anaconda):
        log.debug("called smartinstall.SmartBackend.getDefaultGroups")
        if self.task_to_install:
            (task, grps) = self.task_to_install
            return grps
        return ['image']

    def doPostSelection(self, anaconda):
        log.debug("called smartinstall.SmartBackend.doPostSelection")

        # Only solve dependencies on the way through the installer, not the way back.
        if anaconda.dir == DISPATCH_BACK:
            return

        log.debug("Adding task specific groups")
        if self.task_to_install:
            (task, grps) = self.task_to_install
            for group in grps:
                self.selectGroup(group)

        # figure out which image this is
        package_install = None
        image_to_install = None
        for image in self.grps_to_install:
            if image in self.anaconda.instClass.image_list:
                image_to_install = image
                break

        if image_to_install:
            (image_summary, image_description, package_install, package_install_attemptonly) = anaconda.instClass.image[image_to_install]

        for group in self.grps_to_install:
            if group == 'image':
                for pkg in package_install.split():
                    self.pkgs_to_install.append(pkg)
                for pkg in package_install_attemptonly.split():
                    self.pkgs_to_attempt.append(pkg)
                continue

        log.debug("Selected image:    %s" % image_to_install)
        log.debug("Selected packages: %s (%s)" % (' '.join(self.pkgs_to_install), ' '.join(self.pkgs_to_attempt)))
        log.debug("Selected globs:    %s" % self.asmart.complementary_globs(self.grps_to_install))

        # Verify that the right minimum things are still set..
        # i.e. see yum, select kernel, platform packages, bootloader, FS packages, and installer needed

        # Validation transaction w/o installing?

        # Verify disk space, download packages, etc..

    def doPreInstall(self, anaconda):
        log.debug("called smartinstall.SmartBackend.doPreInstall")

        # See yum configuration...
        AnacondaBackend.doPreInstall(self, anaconda)

    # Add a plus(+) prefix for the element
    def addPlusPrefix(self, pkg_list):
        new_list = []
        for p in pkg_list:
            # Skip --attempt
            if p.startswith('--'):
                continue
            new_list.append('+' + p)

        return new_list

    def doInstall(self, anaconda):
        log.debug("called smartinstall.SmartBackend.doInstall")

        # setup status bars

        if anaconda.upgrade:
            # perform the upgrade
            iface.object._progress.windowTitle = "Upgrade Packages"

            # Do the upgrade for the installed packages
            self.anaconda.backend.asmart.runSmart('upgrade')

            # Maybe we have new pkgs to install so we need install the
            # self.pkgs_to_install again
            # The addPlusPrefix() adds a plus(+) prefix for the pkg so
            # that the upgrade would install it if it isn't installed
            self.anaconda.backend.asmart.runSmart('upgrade', self.addPlusPrefix(self.pkgs_to_install))
        else:
            # perform the install
            iface.object._progress.windowTitle = "Install Packages"
            self.anaconda.backend.asmart.runSmart('install', self.pkgs_to_install)
            # Enable the installed RPM DB
            self.anaconda.backend.asmart.runSmart('channel', ['--add', 'rpmsys', 'type=rpm-sys', '-y'])
            iface.object.hideStatus()

        if len(self.pkgs_to_attempt) > 1:
            if anaconda.upgrade:
                # Maybe we have new pkgs to install so we need install
                # the self.pkgs_to_attempt again
                self.anaconda.backend.asmart.runSmart('upgrade', self.addPlusPrefix(self.pkgs_to_attempt))
            else:
                self.anaconda.backend.asmart.runSmart('install', self.pkgs_to_attempt)

        iface.object.hideStatus()

        # Do complementary packages here...
        availpkgs_src = {}
        availpkgs_pkg = {}
        comp_pkgs_to_attempt = ['--attempt']

        import StringIO

        ## Get a list of all available packages...
        stdout = sys.stdout
        sys.stdout = myout = StringIO.StringIO()
        self.anaconda.backend.asmart.runSmart('query', [
                '--show-format=$source $name $version\n'])
        sys.stdout = stdout
        iface.object.hideStatus()
        myout.seek(0)
        for line in myout:
            lines = line.split()
            if not lines:
                continue
            (src, pkg, ver_arch) = lines
            (ver, arch) = ver_arch.split('@')
            if "%s@%s" % (src, arch) in availpkgs_src:
                availpkgs_src["%s@%s" % (src, arch)].append("%s@%s" % (pkg, arch))
            else:
                availpkgs_src["%s@%s" % (src, arch)] = ["%s@%s" % (pkg, arch)]

            if "%s@%s" % (pkg, arch) in availpkgs_pkg:
                availpkgs_pkg["%s@%s" % (pkg, arch)].append("%s@%s" % (src, arch))
            else:
                availpkgs_pkg["%s@%s" % (pkg, arch)] = ["%s@%s" % (src, arch)]

        ## Get a list of what was installed...
        sys.stdout = myout = StringIO.StringIO()
        self.anaconda.backend.asmart.runSmart('query', ['--installed',
                '--show-format=$source $name $version\n'])
        sys.stdout = stdout
        iface.object.hideStatus()
        myout.seek(0)
        for line in myout:
            lines = line.split()
            if not lines:
                continue
            (src, pkg, ver_arch) = lines
            (ver, arch) = ver_arch.split('@')

            for glob in self.asmart.complementary_globs(self.grps_to_install).split():
                if "%s%s@%s" % (pkg, glob, arch) in availpkgs_pkg:
                    comp_pkgs_to_attempt.append("%s%s@%s" % (pkg, glob, arch))
                    continue
                for pkg_name in availpkgs_src[availpkgs_pkg["%s@%s" % (pkg, arch)][0]]:
                    if pkg_name.endswith(glob):
                        comp_pkgs_to_attempt.append("%s@%s" % (pkg_name, arch))
                        break

        log.debug('Complementary package install: %s' % (comp_pkgs_to_attempt))
        if len(comp_pkgs_to_attempt) > 1:
            if anaconda.upgrade:
                self.anaconda.backend.asmart.runSmart('upgrade', self.addPlusPrefix(comp_pkgs_to_attempt))
            else:
                self.anaconda.backend.asmart.runSmart('install', comp_pkgs_to_attempt)

        iface.object.hideStatus()

    def doPostInstall(self, anaconda):
        log.debug("called smartinstall.SmartBackend.doPostInstall")

        # Run the depmod as we do in image.bbclass
        for (ver, arch, tag) in self.kernelVersionList(anaconda.rootPath):
            args = ["-a", ver]
            rc = iutil.execWithRedirect("depmod", args,
                            stdout="/dev/tty5", stderr="/dev/tty5",
                            root=anaconda.rootPath)

        # Write out the "real" fstab and mtab
        anaconda.storage.write(anaconda.rootPath)

        packages.rpmSetupGraphicalSystem(anaconda)

        # See yum configuration...
        AnacondaBackend.doPostInstall(self, anaconda)

    def postAction(self, anaconda):
        log.debug("called smartinstall.SmartBackend.postAction")

        # The kernel-image can't handle the bootloader's config well, so update
        # the config.
        if anaconda.upgrade:
            anaconda.bootloader.write_config(anaconda.rootPath)

    def kernelVersionList(self, rootPath="/"):
        log.debug("called smartinstall.SmartBackend.kernelVersionList")
        # FIXME: using rpm here is a little lame, but otherwise, we'd
        # be pulling in filelists
        return packages.rpmKernelVersionList(rootPath)

    def writeKS(self, f):
        for reponame, repo in self.asmart.repos.items():
            # Do not write local repo to ks
            if repo.name is None or repo.name.startswith("Install Media feed for"):
                continue

            line = "repo --name=\"%s\" " % (repo.name or repo.repoid)

            if repo.baseurl:
                line += " --baseurl=%s" % repo.anacondaBaseURLs[0]
            else:
                line += " --mirrorlist=%s" % repo.mirrorlist

            if repo.proxy:
                line += " --proxy=\"%s\"" % repo.proxy

            if repo.cost:
                line += " --cost=%s" % repo.cost

            # if repo.includepkgs:
            #     line += " --includepkgs=\"%s\"" % ",".join(repo.includepkgs)

            # if repo.exclude:
            #     line += " --excludepkgs=\"%s\"" % ",".join(repo.exclude)

            # if not repo.sslverify:
            #    line += " --noverifyssl"

            line += "\n"

            f.write(line)

    def writePackagesKS(self, f, anaconda):
        log.debug("called smartinstall.SmartBackend.writePackageKS")

        import StringIO

        ## Get a list of all available packages...
        instpkgs = ""
        stdout = sys.stdout
        sys.stdout = myout = StringIO.StringIO()
        self.anaconda.backend.asmart.runSmart('query', ['--installed',
                '--show-format=$name\n'])
        sys.stdout = stdout
        iface.object.hideStatus()
        myout.seek(0)
        for line in myout:
            log.debug("writePackagesKS: %s" % line)
            if line == '\n':
                continue
            else:
                instpkgs += line

        f.write("\n%packages\n")
        f.write(instpkgs)
        f.write("%end\n")

    def writeConfiguration(self):
        log.debug("called smartinstall.SmartBackend.writeConfigurations")

    def complete(self, anaconda):
        log.debug("called smartinstall.SmartBackend.complete")

        # Remove the local repos that we added for install, they would not
        # available any more after install.
        self.asmart.removeWrlLoclRepo()

        # clean up rpmdb locks so that kickstart %post scripts aren't
        # unhappy (#496961)
        iutil.resetRpmDb(self.instPath)

    def doRepoSetup(self, anaconda, thisrepo = None, fatalerrors = True):
        return self.asmart.doRepoSetup(anaconda, thisrepo, fatalerrors)

    def doSackSetup(self, anaconda, thisrepo = None, fatalerrors = True):
        # Do nothing, not needed
        pass

### Configure RPM, and related files
    def _initRPM(self):
        self.etcrpm_dir = self.instPath + "/etc/rpm"
        self.librpm_dir = self.instPath + "/var/lib/rpm"

        # Configure /etc/rpm
        iutil.mkdirChain(self.etcrpm_dir)

        # Setup /etc/rpm/platform
        shutil.copy("/etc/rpm/platform", self.etcrpm_dir)

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


