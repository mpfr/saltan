#!/bin/ksh
#
# Copyright (c) 2021 Matthias Pressfreund
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

usage()
{
	echo "usage: ${0##*/} [-c file]" >&2
	exit 1
}

err()
{
	echo "${0##*/}: $1" >&2
	exit 1
}

check_module()
{
	[[ -r $1 ]] || err "module '$1' does not exist"
	[[ $(stat -f '%Su' $1) = 'root' ]] || \
	    err "module '$1' is not owned by root"
	[[ $(stat -f '%Sp' $1) = '-'??-?'--'?'--' ]] || \
	    err "module '$1' does not have -??-?--?-- permissions"
}

notify_send()
{
	[[ -x ${PFTBLD} ]] || return
	echo -n "$2" | ${PFTBLD} -p $1 1>/dev/null
}

run_module()
{
	local _mod=$1 _sock=$2 _msg
	shift 2
	_msg=$(eval "${_mod}" $*)
	if (($? == 0)); then
		[[ -n "${_msg}" ]] && notify_send ${_sock} "${_msg}"
		return 0
	fi
	return 1
}

while getopts c: arg; do
	case ${arg} in
	c)	CONFFILE=$OPTARG;;
	*)	usage;;
	esac
done

[[ -n ${CONFFILE} ]] || CONFFILE='/etc/saltan/saltan.conf'

while read line; do
	[[ ${line} = '#'* ]] && continue
	set -- ${line}
	(($# > 0)) || continue
	case $1 in
	'logfile')	LOGFILE=$2;;
	'pftbld')	PFTBLD=$2;;
	'acceptsock')	ACCEPTSOCK=$2;;
	'acceptdir')	ACCEPTDIR=$2;;
	'acceptmods')	shift; ACCEPTMODS=$*;;
	'rejectsock')	REJECTSOCK=$2;;
	'rejectdir')	REJECTDIR=$2;;
	'rejectmods')	shift; REJECTMODS=$*;;
	*)		err "invalid configuration parameter: $1"
	esac
done <${CONFFILE}

[[ -n ${LOGFILE} ]] || LOGFILE='/var/log/authlog'
[[ -r ${LOGFILE} ]] || err 'log file not found'

[[ -n ${PFTBLD} ]] || PFTBLD='/usr/local/sbin/pftbld'
[[ -x ${PFTBLD} ]] || err 'pftbld binary not found'

[[ -n ${REJECTSOCK} || -n ${ACCEPTSOCK} ]] || err 'no socket specified'

[[ -n ${ACCEPTDIR} ]] || ACCEPTDIR='/etc/saltan/accept'
[[ ${ACCEPTDIR} = 'none' ]] && ACCEPTDIR=''
[[ -d ${ACCEPTDIR} || -z ${ACCEPTDIR} ]] || \
    err 'accept modules directory not found'

[[ -n ${REJECTDIR} ]] || REJECTDIR='/etc/saltan/reject'
[[ ${REJECTDIR} = 'none' ]] && REJECTDIR=''
[[ -d ${REJECTDIR} || -z ${REJECTDIR} ]] || \
    err 'reject modules directory not found'

set -A modaccept
[[ -n ${ACCEPTDIR} ]] && for mod in ${ACCEPTMODS}; do
	check_module ${ACCEPTDIR}/${mod}
	modaccept[((${#modaccept[@]}+1))]=$(cat ${ACCEPTDIR}/${mod})
done
set -A modreject
[[ -n ${REJECTDIR} ]] && for mod in ${REJECTMODS}; do
	check_module ${REJECTDIR}/${mod}
	modreject[((${#modreject[@]}+1))]=$(cat ${REJECTDIR}/${mod})
done

tail -n0 -f ${LOGFILE} | while read -r line; do
	set -- ${line}
	shift 4
	[[ $1 = 'sshd['* ]] || continue
	shift
	ret=1
	[[ -S ${REJECTSOCK} ]] && for mod in "${modreject[@]}"; do
		run_module "${mod}" ${REJECTSOCK} $*
		ret=$?
		((ret == 0)) && break
	done
	((ret == 0)) && continue
	[[ -S ${ACCEPTSOCK} ]] && for mod in "${modaccept[@]}"; do
		run_module "${mod}" ${ACCEPTSOCK} $*
		(($? == 0)) && break
	done
done
