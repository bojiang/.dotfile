#!/bin/sh
for x in $(find . -type d) ; do
    if [ -e "${x}/.git" ] ; then
        echo $x
        if [ "${x}" != "." ] ; then
            cd "${x}"
            origin="$(git config --get remote.origin.url)"
            cd - 1>/dev/null
            echo git submodule add "${origin}" "${x}"
            git submodule add "${origin}" "${x}"
        fi
    fi
done

