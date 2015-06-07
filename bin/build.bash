#!/bin/bash
set -e

cd "$(dirname ${BASH_SOURCE[@]})/.."

build_path="$PWD/build"
usage="Builds temoto.ru website static pages into ${build_path}.
Requires git and Github account.

  commit=0        Just build HTML, skip any git operations."

commit=1
while [[ -n "$1" ]]; do
    case $1 in
    commit=0)
        commit=0
        ;;
    *)
        echo "$usage" >&2
        exit 1
        ;;
    esac
	shift
done

if [[ ! -x venv/bin/pelican ]] ; then
    echo "pelican not found, will install" >&2
    virtualenv venv
    echo '*' >venv/.gitignore
    venv/bin/pip install markdown pelican
fi

if [[ $commit -eq 1 ]] && ! git status >/dev/null; then
	echo "git not found. git and Github account are required to update online documentation." >&2
	echo "Links: http://git-scm.com/ https://github.com/" >&2
	exit 1
fi

echo "1. clean"
rm -rf "${build_path}"
mkdir -p "${build_path}"

echo "2. build static pages"
venv/bin/pelican --settings=./pelicanconf.py --output="${build_path}"

if [[ $commit -eq 1 ]]; then
    echo "3. Updating git branch gh-pages"
    source_name=`git rev-parse --abbrev-ref HEAD`
    source_id=`git rev-parse --short HEAD`
    git branch -D gh-pages
    git checkout --orphan gh-pages
    git reset
    git branch --track gh-pages origin/gh-pages || true
    git ls-files |grep -Ev '^.gitignore$' |xargs rm -f
    rm -rf bin/ src/
    rm -rf "doc"

    mv "${build_path}"/* ./
    touch ".nojekyll"
    echo "temoto.ru" >"CNAME"
    rmdir "${build_path}"

    echo "4. Commit"
    git add -A
    git status

    read -p "Carefully read git status output above, press Enter to continue or Ctrl+C to abort"
    git commit --edit -m "Website built from $source_name $source_id"

    git checkout "${source_name}"

    read -p "Push? [Yn] " yes
    if [[ "$yes" = "y" ]]; then
        git push --all
    fi
fi
