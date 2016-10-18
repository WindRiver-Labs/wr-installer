#
# smartquery.py
#
# Copyright (C) 2015  Wind River Systems
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

import re

import logging
log = logging.getLogger("anaconda")

package_pat = re.compile(r'(?P<pkg>^\S+) (?P<ver>\S+)@(?P<arch>[\S]+) (?P<des>.*)')
attribute_pat = re.compile(r'^  (?P<attribute>\S+):')
value_pat = re.compile(r'^    (?P<value>\S+)')

class ParseSmartQuery:
    def __init__(self, fd):
        self.archs = []
        self.packages = dict()

        cur_key = ""
        cur_attribute = ""
        for line in fd.read().split('\n'):
            m = package_pat.match(line)
            if m:
                if m.group('arch') not in self.archs:
                    self.archs.append(m.group('arch'))

                pkg, arch, ver = m.group('pkg'), m.group('arch'), m.group('ver')
                if pkg not in self.packages:
                    self.packages[pkg] = dict()
                if arch not in self.packages[pkg]:
                    self.packages[pkg][arch] = dict()

                des = m.group('des')
                self.packages[pkg][arch][ver] = {'des':des, 'selected': False}
                continue

            m = attribute_pat.match(line)
            if m:
                cur_attribute = m.group('attribute')
                self.packages[pkg][arch][ver][cur_attribute] = []
                continue

            m = value_pat.match(line)
            if m:
                self.packages[pkg][arch][ver][cur_attribute].append(m.group('value'))
                continue

        #for pkg in self.packages:
        #    log.debug('%s %s' % (pkg, self.packages[pkg]))

    def get_selected(self, pkg, arch, ver):
        #log.info("get_selected: pkg %s, arch %s, ver %s" % (pkg, arch, ver))
        package = self.get_package(pkg, arch, ver)
        if not package:
            return None

        return package['selected']

    def set_selected(self, pkg, arch, ver, selected):
        #log.info("set_selected: pkg %s, arch %s, ver %s, selected %s" %
        #         (pkg, arch, ver, selected))
        package = self.get_package(pkg, arch, ver)
        if not package:
            return None

        pkg, arch, ver = package['pkg'], package['arch'], package['ver']
        self.packages[pkg][arch][ver]['selected'] = selected

        return selected

    # Set packages with arch selected, if arch=None,
    # it means set all packages (all archs)
    def set_arch_selected(self, selected, arch=None):
        #log.info("set_arch_selected %s, %s" % (arch, selected))
        if arch is None:
            packages = self.get_packages()
        else:
            packages = self.get_arch_packages(arch)

        for package in packages:
            pkg, arch, ver = package['pkg'], package['arch'], package['ver']
            self.packages[pkg][arch][ver]['selected'] = selected

        return selected

    # Set packagegroup selected including its Requires and Recommends's
    # selected. If packagegroup=None, it means set all packagegroup packages.
    def set_packagegroup_selected(self, selected, packagegroup=None):
        #log.info("set_packagegroups_selected %s %s" % (packagegroup, selected))
        if packagegroup is None:
            packagegroups = self.get_packagegroup_packages()
        else:
            packagegroups = [packagegroup]

        requires = []
        recommends = []
        for package in packagegroups:
            pkg, arch, ver = package['pkg'], package['arch'], package['ver']
            self.packages[pkg][arch][ver]['selected'] = selected

            if 'Requires' in package:
                requires.extend(package['Requires'])

            if 'Recommends' in package:
                recommends.extend(package['Recommends'])

        for package in self.get_packages():
            pkg, arch, ver = package['pkg'], package['arch'], package['ver']
            if pkg in set(requires + recommends):
                self.packages[pkg][arch][ver]['selected'] = selected
                continue

            for provide in package['Provides'] or []:
                if provide in set(requires + recommends):
                    self.packages[pkg][arch][ver]['selected'] = selected
                    break
        return

    # While multiple version available, return the newest
    def get_newest_version(self, pkg, arch):
        #log.info("get_newest_version: pkg %s, arch %s" % (pkg, arch))
        if pkg is None or arch is None:
            return None

        packages = self.get_available_package(pkg, arch)
        if packages:
            newest_ver = max([p['ver'] for p in packages])
            log.info("get_newest_package %s" % newest_ver)
            return newest_ver

        return None

    def get_package(self, pkg, arch, ver):
        #log.info("get_package: pkg %s, arch %s, ver %s" % (pkg, arch, ver))
        if pkg is None or arch is None or ver is None:
            return None

        if pkg in self.packages and arch in self.packages[pkg] and \
           ver in self.packages[pkg][arch]:
            return self._format_package(pkg, arch, ver)

        for package in self.get_available_package(pkg):
            if ver == package['ver'] and arch == package['arch']:
                #log.info("get_package: %s" % package)
                return self._format_package(pkg, arch, ver)

        return None

    def _format_package(self, pkg, arch, ver):
        if pkg is None or arch is None or ver is None:
            return None

        ret = {'pkg':pkg, 'arch':arch, 'ver':ver}
        package = self.packages[pkg][arch][ver]
        for attr in self.packages[pkg][arch][ver]:
            ret[attr] = self.packages[pkg][arch][ver][attr]

        return ret

    # While multiple version/arch available, return a list of the available
    def get_available_package(self, pkg, arch=None):
        #log.info("get_available_package: pkg %s" % (pkg))
        if pkg is None:
            return []

        ret = []
        if pkg in self.packages:
            for cur_arch in self.packages[pkg]:
                for cur_ver in self.packages[pkg][cur_arch]:
                    package = self._format_package(pkg, cur_arch, cur_ver)
                    ret.append(package)
        else:
            for package in self.get_packages():
                if 'Provides' in package and pkg in package['Provides']:
                    ret.append(package)

        if arch:
            ret = [p for p in ret if arch == p['arch']]

        #log.info("get_available_package: ret %s" % ret)
        return sorted(ret, key=lambda ret : ret['pkg'])

    # List all available packages with the same arch
    def get_arch_packages(self, arch):
        ret = []
        for pkg in self.packages:
            if arch in self.packages[pkg]:
                for ver in self.packages[pkg][arch]:
                    package = self._format_package(pkg, arch, ver)
                    ret.append(package)

        return sorted(ret, key=lambda ret : ret['pkg'])

    # List all packagegroup packages
    def get_packagegroup_packages(self):
        ret = []
        for pkg in self.packages:
            if pkg.startswith("packagegroup-"):
                for arch in self.packages[pkg]:
                    for ver in self.packages[pkg][arch]:
                        package = self._format_package(pkg, arch, ver)
                        ret.append(package)

        return sorted(ret, key=lambda ret : ret['pkg'])

    # List all selected packages
    def get_selected_packages(self):
        ret = []
        for pkg in self.packages:
            for arch in self.packages[pkg]:
                for ver in self.packages[pkg][arch]:
                    if self.packages[pkg][arch][ver]['selected']:
                        package = self._format_package(pkg, arch, ver)
                        ret.append(package)

        return sorted(ret, key=lambda ret : ret['pkg'])

    def get_archs(self):
        #log.info("get_arch %s" % self.archs)
        return self.archs

    def get_packages(self):
        ret = []
        for pkg in self.packages:
            for arch in self.packages[pkg]:
                for ver in self.packages[pkg][arch]:
                    package = self._format_package(pkg, arch, ver)
                    ret.append(package)

        return sorted(ret, key=lambda ret : ret['pkg'])

if __name__ == "__main__":
    with open("test", "r") as fd:
        obj = ParseSmartQuery(fd)

