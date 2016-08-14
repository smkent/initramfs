#!/bin/sh

die()
{
    echo "${1}" >&2
    killall dropbear >dev/null 2>&1
    exit 1
}

read_conf()
{
    . /etc/init.conf || die "/etc/init.conf not found"
    if [ -n "${MAPPER_NAME}" ] && [ -b "/dev/mapper/${MAPPER_NAME}" ]; then
        ROOT_DEVICE="/dev/mapper/${MAPPER_NAME}"
    else
        for cmd in $(cat /proc/cmdline); do
            case ${cmd} in
            root=*)
                ROOT_DEVICE="$(echo "${cmd}" | cut -d= -f2)"
                ;;
            esac
        done
        if [ ! -b "${ROOT_DEVICE}" ]; then
            new_root="$(findfs "${ROOT_DEVICE}")"
            if [ -b "${new_root}" ]; then
                ROOT_DEVICE="${new_root}"
            fi
        fi
    fi
}
