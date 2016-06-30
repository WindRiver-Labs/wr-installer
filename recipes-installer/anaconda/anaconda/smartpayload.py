#
# smartpayload.py
#
# Copyright (C) 2016  Wind River Systems
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
import ConfigParser
import os
import shutil
import sys
import time
from functools import wraps
import glob
import inspect
import tempfile

from smart.interface import Interface
from smart.progress import Progress
from smart import sysconf, iface
from smart import init, initDistro, initPlugins, initPycurl, initPsyco

import logging
log = logging.getLogger("packaging")

from pyanaconda.constants import BASE_REPO_NAME, DRACUT_ISODIR, INSTALL_TREE, ISO_DIR, MOUNT_DIR, \
                                 LOGLVL_LOCK, IPMI_ABORTED
from pyanaconda.flags import flags

from pyanaconda import iutil
from pyanaconda.iutil import ProxyString, ProxyStringError, xprogressive_delay
from pyanaconda.i18n import _
from pyanaconda.nm import nm_is_connected
from pyanaconda.product import isFinal, productName, productVersion
from blivet.size import Size
import blivet.util
import blivet.arch

from pyanaconda.errors import ERROR_RAISE, errorHandler, CmdlineError
from pyanaconda.packaging import DependencyError, MetadataError, NoNetworkError, NoSuchGroup, \
                                 NoSuchPackage, PackagePayload, PayloadError, PayloadInstallError, \
                                 PayloadSetupError
from pyanaconda.progress import progressQ

from pyanaconda.localization import langcode_matches_locale

from pykickstart.constants import GROUP_ALL, GROUP_DEFAULT, KS_MISSING_IGNORE


class AnacondaProgress(Progress):
    def expose(self, topic, percent, subkey, subtopic, subpercent, data, done):
        if subtopic is None:
            return

        msg = "%s %s%%, %s %s%%" % (topic, percent, subtopic, subpercent)
        progressQ.send_message(msg)
        log.debug("expose: %s" % msg)


class AnacondaInterface(Interface):
    def __init__(self, ctrl):
        self._progress = AnacondaProgress()
        Interface.__init__(self, ctrl)

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


class SmartRepoData:
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

    # needed to store nfs: repo url that smart doesn't know
    def _getAnacondaBaseURLs(self):
        return self._anacondaBaseURLs or self.baseurl or [self.mirrorlist]

    def _setAnacondaBaseURLs(self, value):
        log.debug("_setAnacondaBaseURLs = %s" % (self.id, value))
        self._anacondaBaseURLs = value

    anacondaBaseURLs = property(_getAnacondaBaseURLs, _setAnacondaBaseURLs,
                                doc="Emulate anacondaYum entries:")

    def isEnabled(self):
        log.debug("SmartRepoData(%s): isEnabled - %s" % (self.id, ['False','True'][self.enabled]))
        return self.enabled


class SmartRepoManager:
    def __init__(self, runSmart):
        self.runSmart = runSmart

    def repos(self):
        channels = sysconf.get("channels") or {}
        return channels.keys()

    def get(self, repoid):
        channels = sysconf.get("channels") or {}
        if repoid in channels:
            # MGH need to add in type, name, baseurl, components, enabled, and cost
            _repo = SmartRepoData(repoid)
            if channels[repoid].get("disabled") == "yes":
                _repo.enabled = False
            else:
                _repo.enabled = True
            _repo.name = channels[repoid].get("name")
            _repo.baseurl = [channels[repoid].get("baseurl")]
            _repo.cost = channels[repoid].get("priority")

            log.debug("get %s" % repoid)
            return _repo
        return None

    # repobj is SmartRepoData object
    def add(self, repoobj):
        channels = sysconf.get("channels") or {}
        if repoobj.id in channels:
            raise ValueError("Repository %s is listed more than once in the configuration" % (repoobj.id))

        # TODO
        if repoobj.mirrorlist:
            pass

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

        self.runSmart('channel', argv)

        repoobj.enabled = True

    def delete(self, repoid):
        channels = sysconf.get("channels") or {}
        if repoid in channels:
            self.runSmart('channel', ['--remove', repoid, "-y"])

    def enable(self, repoid):
        channels = sysconf.get("channels") or {}
        if repoid in channels:
            self.runSmart('channel', ['--enable', repoid])
        self.enabled = True

    def disable(self, repoid):
        channels = sysconf.get("channels") or {}
        if repoid in channels:
            self.runSmart('channel', ['--disable', repoid])
        self.enabled = False

    def update(self, thisrepo = None, fatalerrors = True):
        rc = 0
        argv = []
        if thisrepo:
            argv.append(thisrepo)

        try:
            rc = self.runSmart('update', argv)
        except:
            if fatalerrors:
                raise

        return rc

    def mirrors(self, mirrorlistfile):
        self.runSmart('mirror', ['--add', mirrorlistfile])
        self.runSmart('mirror', ['--sync', mirrorlistfile])

    def rmmirrors(self):
        sysconf.remove("mirrors")

class AnacondaSmart:
    complementary_glob = {}
    complementary_glob['dev-pkgs'] = '-dev'
    complementary_glob['staticdev-pkgs'] = '-staticdev'
    complementary_glob['doc-pkgs'] = '-doc'
    complementary_glob['dbg-pkgs'] = '-dbg'
    complementary_glob['ptest-pkgs'] = '-ptest'

    def __init__(self, data):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))

        self.data = data
        self.repo_manager = None
        self.smart_ctrl = None

        self.sysroot = iutil.getSysroot()
        self.etcrpm_dir = self.sysroot + "/etc/rpm"
        self.librpm_dir = self.sysroot + "/var/lib/rpm"
        self.smart_dir = "/tmp/smart"
        self.wrapper_dir = "/tmp/install"

        self._initSmart()

### Configure smart for a cross-install, and the install wrapper
    def _initSmart(self, command=None, argv=None):
        iutil.mkdirChain(self.smart_dir)
        iutil.mkdirChain(self.wrapper_dir)

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
""" % (self.sysroot)

        fd = open(self.wrapper_dir + "/scriptlet_wrapper", "w")
        fd.write(buf)
        fd.close()
        os.chmod(self.wrapper_dir + "/scriptlet_wrapper", 0755)

        self.smart_ctrl = init(command, argv=argv,
                               datadir=self.smart_dir, configfile=None,
                               gui=False, shell=False, quiet=True,
                               interface=None, forcelocks=False,
                               loglevel=None)

        # Override the dummy interface with the locally defined one
        iface.object = AnacondaInterface(self.smart_ctrl)

        initDistro(self.smart_ctrl)
        initPlugins()
        initPycurl()
        initPsyco()

        sysconf.set("rpm-root", self.sysroot, soft=True)
        sysconf.set("rpm-extra-macros._tmppath", "/install/tmp", soft=True)
        sysconf.set("rpm-extra-macros._cross_scriptlet_wrapper", self.wrapper_dir + "/scriptlet_wrapper", soft=True)
        sysconf.set("rpm-nolinktos", "1")
        sysconf.set("rpm-noparentdirs", "1")

        sysconf.remove("channels")

        self.repo_manager = SmartRepoManager(self.runSmart)

    def createDefaultRepo(self, repourl, proxy=None):
        # Setup repository
        repo = None

        if repourl.startswith("file://"):
            repodir = repourl[len("file://"):]
            if os.path.isdir("%s/repodata" % (repodir)):
                repoid = repodir.replace("/", "_")
                repo = SmartRepoData(repoid)
                repo.baseurl = [repourl]
        elif repourl.startswith("http://") or repourl.startswith("https://"):
            repoid = repourl.replace(":/", "").replace("/", "_")
            repo = SmartRepoData(repoid)
            log.info("proxy %s" % proxy)
            if proxy:
                repo.proxy = proxy.noauth_url
                repo.proxy_username = proxy.username
                repo.proxy_password = proxy.password
        elif repourl.startswith("ftp://"):
            repoid = repourl.replace(":/", "").replace("/", "_")
            repo = SmartRepoData(repoid)

        if repo:
            if repoid not in self.repo_manager.repos():
                repo.name = "Install %s feed" % repoid
                repo.baseurl = [repourl]
                self.repo_manager.add(repo)
            else:
                self.repo_manager.enable(repoid)


        # TODO: Add repo from kickstart

        self.repo_manager.update()

    def _initTargetRPM(self):
        self.etcrpm_dir = iutil.getSysroot() + "/etc/rpm"
        self.librpm_dir = iutil.getSysroot() + "/var/lib/rpm"

        # Configure /etc/rpm
        iutil.mkdirChain(self.etcrpm_dir)

        # For rpm-extra-macros._tmppath
        iutil.mkdirChain(iutil.getSysroot() + "/install/tmp")

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


### Run smart commands directly
    def runSmart(self, command=None, argv=None):
        log.debug("runSmart(%s, %s)" % (command, argv))
        rc = iface.run(command, argv)
        if rc is None:
            rc = 0
        self.smart_ctrl.saveSysConf()
        self.smart_ctrl.restoreMediaState()

        return rc

    def complementary_globs(self, groups):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))

        globs = []
        for name, glob in self.complementary_glob.items():
            if name in groups:
                globs.append(glob)
        return ' '.join(globs)


    def install(self, argv):
        log.debug("install %s" % " ".join(argv))
        res = self.runSmart('install', argv)
        log.debug("-->%s" % res)

    def install_group(self, group):
        log.debug("group %s" % group)
        if group == []:
            return

        globs = self.complementary_globs(group).split()

        available_list = self.query(['--show-format=$source $name $version\n'])
        log.debug("available %d" % len(available_list))

        installed_list = self.query(['--installed', '--show-format=$source $name $version\n'])
        log.debug("installed %d" % len(installed_list))
        comp_pkgs = []
        for installed in installed_list:
            (installed_src, installed_pkg, installed_ver) = installed.split()
            for glob in globs:
                complementary = "%s %s%s %s" % (installed_src, installed_pkg, glob, installed_ver)
                if complementary in available_list:
                    comp_pkgs.append("%s%s-%s" % (installed_pkg, glob, installed_ver))

        self.install(['--attempt'] + comp_pkgs)
        installed_list = self.query(['--installed', '--show-format=$source $name $version\n'])
        log.debug("installed with group %d" % len(installed_list))

    def query(self, argv):
        log.debug("query %s" % argv)
        query_list = []
        fd, _filename = tempfile.mkstemp()
        argv.append("--output=%s" % _filename)
        res = self.runSmart('query', argv)
        output = os.fdopen(fd, "r")
        for line in output:
            line = line.rstrip("\n")
            if not line:
                continue
            query_list.append(line)

        return query_list


# TODO
BASE_REPO_NAMES = [BASE_REPO_NAME] + PackagePayload.DEFAULT_REPOS

import threading
_private_smart_lock = threading.RLock()

class SmartLock(object):
    def __enter__(self):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))

        if isFinal:
            _private_smart_lock.acquire()
            return _private_smart_lock

        frame = inspect.stack()[2]
        threadName = threading.currentThread().name

        log.log(LOGLVL_LOCK, "about to acquire _smart_lock: for %s at %s:%s (%s)", threadName, frame[1], frame[2], frame[3])
        _private_smart_lock.acquire()
        log.log(LOGLVL_LOCK, "have _smart_lock: for %s", threadName)
        return _private_smart_lock

    def __exit__(self, exc_type, exc_val, exc_tb):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))

        _private_smart_lock.release()

        if not isFinal:
            log.log(LOGLVL_LOCK, "gave up _smart_lock: for %s", threading.currentThread().name)

def refresh_base_repo(cond_fn=None):
    """
    Function returning decorator for methods that invalidate base repo.
    After the method has been run the base repo will be refreshed

    :param cond_fn: condition function telling if base repo should be
                    invalidated or not (HAS TO TAKE THE SAME ARGUMENTS AS THE
                    DECORATED FUNCTION)

    While the method runs the base_repo is set to None.
    """
    def decorator(method):
        """
        Decorator for methods that invalidate base repo cache.

        :param method: decorated method of the SmartPayload class

        """
        @wraps(method)
        def inner_method(smart_payload, *args, **kwargs):
            if cond_fn is None or cond_fn(smart_payload, *args, **kwargs):
                with smart_payload._base_repo_lock:
                    smart_payload._base_repo = None

            ret = method(smart_payload, *args, **kwargs)

            if cond_fn is None or cond_fn(smart_payload, *args, **kwargs):
                smart_payload._refreshBaseRepo()
            return ret

        return inner_method

    return decorator

_smart_lock = SmartLock()

class SmartPayload(PackagePayload):
    """ A SmartPayload installs packages onto the target system using smart.

        User-defined (aka: addon) repos exist both in ksdata and in smart. They
        are the only repos in ksdata.repo. The repos we find in the smart config
        only exist in smart. Lastly, the base repo exists in smart and in
        ksdata.method.
    """
    def __init__(self, data):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))

        PackagePayload.__init__(self, data)

        self._smart = AnacondaSmart(data)
        self._setup = False

        self.requiredPackages += ['base-files', 'base-passwd', 'shadow']
        # Support grub-mkconfig
        self.requiredPackages += ['sed', 'coreutils', 'busybox']
        # The extra packages make sure lvm initramfs generation
        self.requiredPackages += ['ldd', 'gzip', 'iputils']
        # Support create new user
        self.requiredPackages += ['shadow']

        # base repo caching
        self._base_repo = None
        self._base_repo_lock = threading.RLock()

        # WRlinux specific
        self.image = {}
        self.tasks = {}
        self.taskid = None

        self.reset()


    def reset(self, root=None, releasever=None):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))

        """ Reset this instance to its initial (unconfigured) state. """

        super(SmartPayload, self).reset()
        # This value comes from a default install of the x86_64 Fedora 18.  It
        # is meant as a best first guess only.  Once package metadata is
        # available we can use that as a better value.
        self._space_required = Size("3000 MB")

        self._groups = None
        self._packages = []

        for repoid in self._smart.repo_manager.repos():
            self._smart.repo_manager.delete(repoid)

        self._smart.repo_manager.rmmirrors()

    def setup(self, storage, instClass):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))

        self.reset()
        self.image, self.tasks = instClass.read_buildstamp()

        super(SmartPayload, self).setup(storage, instClass)
        self._setup = True

        return

    def unsetup(self):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))

        super(SmartPayload, self).unsetup()
        self._setup = False

        # WRlinux specific
        self.image = {}
        self.tasks = {}


    # YUMFIXME: there should be a way to reset package sacks without all this
    #           knowledge of the smart internals or, better yet, some convenience
    #           functions for multi-threaded applications
    def release(self):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))

    def preStorage(self):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))
        self.release()

    ###
    ### METHODS FOR WORKING WITH REPOSITORIES
    ###
    @property
    def repos(self):
        return self._smart.repo_manager.repos()

    @property
    def baseRepo(self):
        """ Return the current base repo id
            :returns: repo id or None

            Methods that change (or could change) the base_repo
            need to be decorated with @refresh_base_repo
        """
        return self._base_repo

    def _refreshBaseRepo(self):
        """ Examine the enabled repos and update _base_repo
        """
        with _smart_lock:
            # TODO
            self._base_repo = self._smart.repo_manager.repos()

    @property
    def mirrorEnabled(self):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))
        # TODO
        return False

    def getRepo(self, repo_id):
        """ Return the smart repo object. """
        with _smart_lock:
            repo = self._smart.repo_manager.get(repo_id)

        return repo

    def isRepoEnabled(self, repo_id):
        """ Return True if repo is enabled. """
        try:
            return self.getRepo(repo_id).enabled
        except:
            return super(SmartPayload, self).isRepoEnabled(repo_id)

    @refresh_base_repo()
    def _configureAddOnRepo(self, repo):
        """ Configure a single ksdata repo. """
        if repo.mirrorlist:
            log.info("mirrorlist %s" % repo.mirrorlist)
            self._smart.repo_manager.mirrors(repo.mirrorlist)
            return

        url = repo.baseurl
        if url and url.startswith("nfs://"):
            # Let the assignment throw ValueError for bad NFS urls from kickstart
            (server, path) = url[6:].split(":", 1)
            mountpoint = "%s/%s.nfs" % (os.path.dirname(MOUNT_DIR), repo.name)
            self._setupNFS(mountpoint, server, path, None)

            url = "file://" + mountpoint

        if self._repoNeedsNetwork(repo) and not nm_is_connected():
            raise NoNetworkError

        repoid = "Addon_%s" % repo.name
        repodata = SmartRepoData(repoid)
        if repo.proxy:
            proxy = ProxyString(repo.proxy)
            repodata.proxy = proxy.noauth_url
            repodata.proxy_username = proxy.username
            repodata.proxy_password = proxy.password
        else:
            proxy = None

        if repoid not in self._smart.repo_manager.repos():
            repodata.name = repo.name
            repodata.baseurl = [url]
            self._smart.repo_manager.add(repodata)
        else:
            self._smart.repo_manager.enable(repoid)

        self._smart.repo_manager.update()

    @refresh_base_repo()
    def updateBaseRepo(self, fallback=True, root=None, checkmount=True):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))

        """ Update the base repo based on self.data.method.

            - Tear down any previous base repo devices, symlinks, &c.
            - Reset the YumBase instance.
            - Try to convert the new method to a base repo.
            - If that fails, we'll use whatever repos smart finds in the config.
            - Set up addon repos.
            - Filter out repos that don't make sense to have around.
            - Get metadata for all enabled repos, disabling those for which the
              retrieval fails.
        """
        log.info("configuring base repo")

        try:
            log.debug("method %s" % self.data.method.method)
            url, mirrorlist, sslverify = self._setupInstallDevice(self.storage, checkmount)
            log.debug("method %s, url %s, mirrorlist %s, sslverify %s" % (self.data.method.method, url, mirrorlist, sslverify))
        except PayloadSetupError:
            self.data.method.method = None
            log.debug("PayloadSetupError")

        releasever = None
        method = self.data.method
        if method.method:
            try:
                releasever = self._getReleaseVersion(url)
                log.debug("releasever from %s is %s", url, releasever)
            except ConfigParser.MissingSectionHeaderError as e:
                log.error("couldn't set releasever from base repo (%s): %s",
                          method.method, e)

        # Create default repository
        if method.method == "cdrom" and url.startswith("file://"):
            self._smart.createDefaultRepo(url)
        elif method.method == "url" and (url.startswith("http://") or url.startswith("https://")):
            if method.proxy:
                proxy = ProxyString(method.proxy)
            else:
                proxy = None
            self._smart.createDefaultRepo(url, proxy)
        elif method.method == "url" and url.startswith("ftp://"):
            self._smart.createDefaultRepo(url)
        elif method.method == "nfs" and url.startswith("file://"):
            self._smart.createDefaultRepo(url)

        # set up addon repos
        for repo in self.data.repo.dataList():
            log.info("repo %s" % repo)
            if not repo.enabled:
                continue
            try:
                self._configureAddOnRepo(repo)
                log.info("enable repo %s" % repo)
            except NoNetworkError as e:
                log.error("repo %s needs an active network connection", repo.name)
                self.disableRepo(repo.name)
            except PayloadError as e:
                log.error("repo %s setup failed: %s", repo.name, e)
                self.disableRepo(repo.name)

        # TODO
        return

    @refresh_base_repo()
    def gatherRepoMetadata(self):
        log.info("gathering repo metadata")
        # Make sure environmentAddon information is current
        self._refreshEnvironmentAddons()

        # now go through and get metadata for all enabled repos
        # TODO
        log.info("metadata retrieval complete")

    @property
    def ISOImage(self):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))
        if not self.data.method.method == "harddrive":
            return None
        # This could either be mounted to INSTALL_TREE or on
        # DRACUT_ISODIR if dracut did the mount.
        dev = blivet.util.get_mount_device(INSTALL_TREE)
        if dev:
            return dev[len(ISO_DIR)+1:]
        dev = blivet.util.get_mount_device(DRACUT_ISODIR)
        if dev:
            return dev[len(DRACUT_ISODIR)+1:]
        return None

    @refresh_base_repo(lambda s, r_id: r_id.name in BASE_REPO_NAMES)
    def addRepo(self, newrepo):
        """ Add a ksdata repo. """
        log.debug("adding new repo %s", newrepo.name)
        super(SmartPayload, self).addRepo(newrepo)
        # TODO

    @refresh_base_repo(lambda s, r_id: r_id in BASE_REPO_NAMES)
    def removeRepo(self, repo_id):
        """ Remove a repo as specified by id. """
        log.debug("removing repo %s", repo_id)
        # TODO

    @refresh_base_repo(lambda s, r_id: r_id in BASE_REPO_NAMES)
    def enableRepo(self, repo_id):
        """ Enable a repo as specified by id. """
        log.debug("enabling repo %s", repo_id)
        super(SmartPayload, self).enableRepo(repo_id)
        # TODO

    @refresh_base_repo(lambda s, r_id: r_id in BASE_REPO_NAMES)
    def disableRepo(self, repo_id):
        """ Disable a repo as specified by id. """
        log.debug("disabling repo %s", repo_id)
        super(SmartPayload, self).disableRepo(repo_id)
        # TODO

    ###
    ### METHODS FOR WORKING WITH ENVIRONMENTS
    ###
    @property
    def environments(self):
        """ List of environment ids. """
        log.info("%s %s: %s" % (self.__class__.__name__, inspect.stack()[0][3], self.tasks.keys()))
        return sorted(self.tasks.keys())

    def environmentSelected(self, environmentid):
        log.info("%s %s, environmentid %s" % (self.__class__.__name__, inspect.stack()[0][3], environmentid))

        if environmentid in self.tasks:
            self.taskid = environmentid
            return True

        return False

    def environmentHasOption(self, environmentid, grpid):
        log.info("%s %s, %s, %s" % (self.__class__.__name__, inspect.stack()[0][3], environmentid, grpid))
        # TODO
        return True

    def environmentOptionIsDefault(self, environmentid, grpid):
        log.info("%s %s, %s, %s" % (self.__class__.__name__, inspect.stack()[0][3], environmentid, grpid))
        # TODO
        return True

    def environmentDescription(self, environmentid):
        log.info("%s %s, %s" % (self.__class__.__name__, inspect.stack()[0][3], environmentid))

        if environmentid not in self.tasks:
                raise NoSuchGroup(environmentid)

        if environmentid in self.tasks:
            log.info("environmentDescription %s" % self.tasks)
            (name, description, group) = self.tasks[environmentid]

            return (name, description)
        return (environmentid, environmentid)

    def environmentId(self, environment):
        """ Return environment id for the environment specified by id or name."""
        log.info("%s %s, environment %s" % (self.__class__.__name__, inspect.stack()[0][3], environment))
        # TODO
        return environment

    def selectEnvironment(self, environmentid):
        log.info("%s %s: %s" % (self.__class__.__name__, inspect.stack()[0][3], environmentid))

        if environmentid in self.tasks:
            self.taskid = environmentid

    def deselectEnvironment(self, environmentid):
        log.info("%s %s: %s" % (self.__class__.__name__, inspect.stack()[0][3], environmentid))
        if self.taskid == environmentid:
            self.taskid = None

    def environmentGroups(self, environmentid):
        log.info("%s %s, %s" % (self.__class__.__name__, inspect.stack()[0][3], environmentid))
        return [environmentid]

    ###
    ### METHODS FOR WORKING WITH GROUPS
    ###

    @property
    def groups(self):
        """ List of group ids. """
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))
        return sorted(self.tasks.keys())

    def languageGroups(self):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))
        # TODO
        return []

    def groupDescription(self, groupid):
        """ Return name/description tuple for the group specified by id. """
        log.info("%s %s, %s" % (self.__class__.__name__, inspect.stack()[0][3], groupid))
        (name, description, group) = self.tasks[groupid]
        return (name, description)

    def _isGroupVisible(self, groupid):
        log.info("%s %s, %s" % (self.__class__.__name__, inspect.stack()[0][3], groupid))
        # TODO
        return True

    def _groupHasInstallableMembers(self, groupid):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))
        # TODO
        return False

    def _selectSmartGroup(self, groupid, default=True, optional=False, required=False):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))
        # TODO


    def _deselectSmartGroup(self, groupid):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))
        # TODO

    ###
    ### METHODS FOR WORKING WITH PACKAGES
    ###
    @property
    def packages(self):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))
        with _smart_lock:
            if not self._packages:
                if self.needsNetwork and not nm_is_connected():
                    raise NoNetworkError

                try:
                    (name, description, group) = self.tasks[self.taskid]
                    image_name = name.split()[0]
                    (summary, des, package_install, package_install_attemptonly) = self.image[image_name]
                    self._packages = package_install.split()
                except RepoError as e:
                    log.error("failed to get package list: %s", e)

            return self._packages

    def _selectSmartPackage(self, pkgid, required=False):
        """Mark a package for installation.

           pkgid - The name of a package to be installed.  This could include
                   a version or architecture component.
        """
        log.debug("select package %s", pkgid)
        # TODO

    def _deselectSmartPackage(self, pkgid):
        """Mark a package to be excluded from installation.

           pkgid - The name of a package to be excluded.  This could include
                   a version or architecture component.
        """
        log.debug("deselect package %s", pkgid)
        # TODO

    ###
    ### METHODS FOR QUERYING STATE
    ###
    @property
    def spaceRequired(self):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))

        """ The total disk space (Size) required for the current selection. """
        return self._space_required

    ###
    ### METHODS FOR INSTALLING THE PAYLOAD
    ###
    def _handleMissing(self, exn):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))
        if self.data.packages.handleMissing == KS_MISSING_IGNORE:
            return

        # If we're doing non-interactive ks install, raise CmdlineError,
        # otherwise the system will just reboot automatically
        if flags.automatedInstall and not flags.ksprompt:
            errtxt = _("CmdlineError: Missing package: %s") % str(exn)
            log.error(errtxt)
            raise CmdlineError(errtxt)
        elif errorHandler.cb(exn) == ERROR_RAISE:
            # The progress bar polls kind of slowly, thus installation could
            # still continue for a bit before the quit message is processed.
            # Let's sleep forever to prevent any further actions and wait for
            # the main thread to quit the process.
            progressQ.send_quit(1)
            while True:
                time.sleep(100000)

    def _applySmartSelections(self):
        """ Apply the selections in ksdata to smart.

            This follows the same ordering/pattern as kickstart.py.
        """
        if self.data.packages.nocore:
            log.info("skipping core group due to %%packages --nocore; system may not be complete")
        else:
            self._selectSmartGroup("core")

        env = None

        if self.data.packages.default and self.environments:
            env = self.environments[0]
        elif self.data.packages.environment:
            env = self.data.packages.environment

        if env:
            try:
                self.selectEnvironment(env)
            except NoSuchGroup as e:
                self._handleMissing(e)

        for group in self.data.packages.groupList:
            default = False
            optional = False
            if group.include == GROUP_DEFAULT:
                default = True
            elif group.include == GROUP_ALL:
                default = True
                optional = True

            try:
                self._selectSmartGroup(group.name, default=default, optional=optional)
            except NoSuchGroup as e:
                self._handleMissing(e)

        for package in self.data.packages.packageList:
            try:
                self._selectSmartPackage(package)
            except NoSuchPackage as e:
                self._handleMissing(e)

        for package in self.data.packages.excludedList:
            self._deselectSmartPackage(package)

        for group in self.data.packages.excludedGroupList:
            try:
                self._deselectSmartGroup(group.name)
            except NoSuchGroup as e:
                self._handleMissing(e)

    def checkSoftwareSelection(self):
        log.info("checking software selection")

        self.release()

        self._applySmartSelections()

        with _smart_lock:
            # doPostSelection
            # select kernel packages
            # select packages needed for storage, bootloader

            # check dependencies
            log.info("checking dependencies")

        with _smart_lock:
            log.info("selected totalling %s", self.spaceRequired)

    def preInstall(self, packages=None, groups=None):
        """ Perform pre-installation tasks. """
        super(SmartPayload, self).preInstall(packages, groups)
        progressQ.send_message(_("Starting package installation process"))

        log.info("%s %s, %s" % (self.__class__.__name__, inspect.stack()[0][3], self.image))
        log.info("%s %s, %s" % (self.__class__.__name__, inspect.stack()[0][3], self.tasks))

        if packages:
            self.requiredPackages += packages
        self.requiredGroups = groups

        if self.install_device:
            self._setupMedia(self.install_device)

        self.checkSoftwareSelection()


    def install(self):
        packages = self.requiredPackages + self.packages + self.kernelPackages
        log.info("%s %s: %s" % (self.__class__.__name__, inspect.stack()[0][3], packages))
        self._smart.install(packages)

        self._smart.runSmart('channel', ['--add', 'rpmsys', 'type=rpm-sys', '-y'])

        log.info("taskid %s, %s" % (self.taskid, self.tasks[self.taskid]))
        (name, description, group) = self.tasks[self.taskid]
        self._smart.install_group(group.split())

    def postInstall(self):
        log.info("%s %s" % (self.__class__.__name__, inspect.stack()[0][3]))
        super(SmartPayload, self).postInstall()


# For testing
if __name__ == "__main__":
    import logging
    from pyanaconda import anaconda_log
    anaconda_log.init()
    anaconda_log.logger.setupVirtio()

    log = logging.getLogger("anaconda")


    from pykickstart.version import makeVersion
    # set some things specially since we're just testing
    flags.testing = True

    # set up ksdata
    ksdata = makeVersion()

    ksdata.method.method = "url"
    ksdata.method.url = "http://husky/install/f17/os/"
    ksdata.method.url = "http://dl.fedoraproject.org/pub/fedora/linux/development/17/x86_64/os/"
    smart = AnacondaSmart(ksdata)
    smart.createDefaultRepo("file:///Packages")
    smart._initTargetRPM()
    log.debug("==============")
    pkgs = "base-files base-passwd shadow sed coreutils busybox ldd gzip iputils shadow systemd e2fsprogs grub kernel-image"
    smart.install(pkgs.split())

    smart.runSmart('channel', ['--add', 'rpmsys', 'type=rpm-sys', '-y'])

    group = "dbg-pkgs staticdev-pkgs"
    smart.install_group(group.split())

    sys.exit(0)

