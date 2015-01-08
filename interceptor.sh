#!/usr/bin/env bash

INTERCEPTOR_LOG_ROOT=${INTERCEPTOR_LOG_ROOT:-/var/log/interceptor}
INVOKED_SCRIPT_DIR=$(cd "$(dirname $0)"; pwd)
INVOKED_SCRIPT_BASE=$(basename "$0")
INVOKED_SCRIPT_LOGS=${INTERCEPTOR_LOG_ROOT}/${INVOKED_SCRIPT_DIR#/}/${INVOKED_SCRIPT_BASE}.logs

set -o pipefail

die() {
	echo "$*" 1>&2
	exit 1
}

main() {
	cmd=$1
	test $# -gt 0 && shift 1
	case "$cmd" in
	install)
		intercepted=$1
		test -x "$intercepted" || die "$interceptor is not an intercepable command"
		test -e "${intercepted}.intercepted" && die "$intercepted is already intercepted"
		mkdir -p "${INVOKED_SCRIPT_LOGS}" || die "cannot make log directory for interceptor"
		chmod 2755 "${INVOKED_SCRIPT_LOGS}"
		if mv "${intercepted}" "${intercepted}.intercepted"; then
			ln -sf "$INVOKED_SCRIPT_DIR/$INVOKED_SCRIPT_BASE" "${intercepted}" || die "failed to link $INVOKED_SCRIPT_BASE/$INVOKED_SCRIPT_DIR to ${intercepted}"
		else
			die "failed to renae ${intercepted} to ${intercepted}.intercepted"
		fi
	;;
	uninstall)
		intercepted=$1
		if main is-intercepted "$1" >/dev/null; then
			rm "$intercepted" && mv "${intercepted}.intercepted" "$intercepted" || die "uninstallation failed"
		fi
	;;
	intercepted)
		interceptor=$1
		test -x "$interceptor" || die "$interceptor is not an interceptable command"
		echo ${interceptor}.intercepted
	;;
	is-intercepted)
		intercepted=$1
		if test -L $intercepted && test -e ${intercepted}.intercepted; then
			echo true
			true
		else
			echo false
			false
		fi
	;;
	log-root)
		intercepted=$1
		if test -n "$intercepted"; then
			intercepted=$(cd "$(dirname "$1")"; pwd)/$(basename "$1")
		fi
		echo ${INTERCEPTOR_LOG_ROOT}${intercepted:+/}${intercepted#/}${intercepted:+.logs}
	;;
	intercept)
		if intercepted=$(main intercepted "$1") && test -x "$intercepted"; then
			shift 1
			THIS_LOG=${INVOKED_SCRIPT_LOGS}/$(date +%Y%m%dT%H%M%S)
		else
			intercepted=$1
			shift 1
			intercepted="$(cd $(dirname "$intercepted"); pwd)/$(basename "$intercepted")"
			if test "$intercepted" = "$INVOKED_SCRIPT_DIR/$INVOKED_SCRIPT_BASE"; then
				die "avoiding infinite recursion on '$intercepted'"
			fi
			THIS_LOG=${INTERCEPTOR_LOG_ROOT}/${intercepted#/}.logs/$(date +%Y%m%dT%H%M%S)
		fi
		mkdir -p "${THIS_LOG}"
		echo "$intercepted" "$@" > "${THIS_LOG}/cmdline"
		( "$intercepted" "$@" 1>&3 2>&4 ) 3> >(tee -a "${THIS_LOG}/out") 4> >(tee -a "${THIS_LOG}/err" 1>&2)
		rc=$?
		echo $rc > "${THIS_LOG}/exit"
		(exit $rc)
	;;
	*)
		die "usage: $0 intercept {intercepted-cmd}"
	;;
	esac
}

if test "${INVOKED_SCRIPT_BASE}" = "interceptor.sh"; then
	main "$@"
else
	main intercept "$INVOKED_SCRIPT_DIR/$INVOKED_SCRIPT_BASE" "$@"
fi