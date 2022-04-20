#!/bin/sh

# © Copyright EnterpriseDB UK Limited 2019-2022
#
# This file is part of Barman.
#
# Barman is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Barman is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Barman.  If not, see <http://www.gnu.org/licenses/>.

set -eu

BASE="$(dirname $(cd $(dirname "$0"); pwd))"
cd "$BASE"

if [ "$(uname -s)" = "Darwin" ]
then
    date_cmd="gdate"
else
    date_cmd="date"
fi

release_version=$1
if [ -n "${2:-}" ]
then
    release_date=$(LANG=C ${date_cmd} +"%B %-d, %Y" -d "$2")
else
    release_date=$(LANG=C ${date_cmd} +"%B %-d, %Y")
fi
echo $release_date

require_clean_work_tree () {
    git rev-parse --verify HEAD >/dev/null || exit 1
    git update-index -q --ignore-submodules --refresh
    err=0

    if ! git diff-files --quiet --ignore-submodules
    then
        echo >&2 "Cannot $1: You have unstaged changes."
        err=1
    fi

    if ! git diff-index --cached --quiet --ignore-submodules HEAD --
    then
        if [ $err = 0 ]
        then
            echo >&2 "Cannot $1: Your index contains uncommitted changes."
        else
            echo >&2 "Additionally, your index contains uncommitted changes."
        fi
        err=1
    fi

    if [ $err = 1 ]
    then
        # if there is a 2nd argument print it
        test -n "${2+1}" && echo >&2 "$2"
        exit 1
    fi
}

#require_clean_work_tree "set version"

# Test if master branch
#if branch=$(git symbolic-ref --short -q HEAD) && [ $branch = 'master' ]
#then
#    echo "Setting version ${release_version}"
#else
#    echo >&2 "Release is not possible because you are not on 'master' branch ($branch)"
#    exit 1
#fi

sed -i -e "3s/^%.*/% ${release_date}/; 1s/| Version .*/| Version ${release_version}/" \
    doc/barman.1.d/00-header.md \
    doc/barman.5.d/00-header.md \
    doc/barman-wal-archive.1.md \
    doc/barman-wal-restore.1.md \
    doc/barman-cloud-backup.1.md \
    doc/barman-cloud-backup-delete.1.md \
    doc/barman-cloud-backup-keep.1.md \
    doc/barman-cloud-backup-list.1.md \
    doc/barman-cloud-check-wal-archive.1.md \
    doc/barman-cloud-restore.1.md \
    doc/barman-cloud-wal-archive.1.md \
    doc/barman-cloud-wal-restore.1.md
sed -i -e "3s/^%.*/% ${release_date} (${release_version})/" \
    doc/manual/00-head.en.md
sed -i -e "s/__version__ = .*/__version__ = \"${release_version}\"/" \
    barman/version.py

make -C doc

echo "Version set to ${release_version}"