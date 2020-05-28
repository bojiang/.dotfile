#!/bin/sh
for x in $(find . -type d) ; do
    if [ -d "${x}/.git" ] && [ "${x}" != "." ] ; then
        cd "${x}"
        origin="$(git config --get remote.origin.url)"
        cd - 1>/dev/null
        git submodule add "${origin}" "${x}"
    fi
done

