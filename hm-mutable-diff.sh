#!/usr/bin/env bash

set -e

S=${XDG_STATE_HOME:-~/.local/state}
C=${XDG_CONFIG_HOME:-~/.config}

usage() {
	echo "Show mutations since current HM generation"
	echo "-- what has changed since last activation?"
	echo -e "\t$0"
	echo
	echo "Show mutations with respect to given HM flake"
	echo "-- how mutations differ from a generation to be activated?"
	echo -e "\t$0 --base-flake [flake-uri]"
	echo "(if flake-uri is missing, the HM default is used)"
}
if [ "${1:-}" == "--help" ]; then
	usage
	exit 0
fi

if [ "${1:-}" == "--base-flake" ]; then
	base=$(
		T=$(mktemp -d)
		# shellcheck disable=SC2329
		cleanup() { rm -fr "$T"; }
		trap cleanup EXIT
		cd "$T"
		if [ -n "${2:-}" ]; then
			home-manager build --flake "${2}"
		else
			home-manager build
		fi
		readlink -e result/
	)
elif [ -z "${1:-}" ]; then
	base=$(readlink -m "$S"/nix/profiles/home-manager)
else
	echo "ERROR: unexpected argument: $1" >&2
	usage
	exit 1
fi

mutated=0
while IFS= read -r file; do
	if ! diff -Nu "$base/home-files/$file" "$HOME/$file"; then
		mutated=1
	fi
done <"$C"/hm-mutable-files/files

exit $mutated
