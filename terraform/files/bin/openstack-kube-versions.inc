# Table of kubernetes and openstack versions
# (c) Kurt Garloff <kurt@garloff.de>, 3/2022
# SPDX-License-Identifier: CC-BY-SA-4.0
# Images from https://minio.services.osism.tech/openstack-k8s-capi-images
k8s_versions=("v1.18.20" "v1.19.16" "v1.20.12" "v1.21.12" "v1.22.9" "v1.23.6" "v1.24.0")
# OCCM, CCM-RBAC, Cinder CSI, Cinder-Snapshot (TODO: Manila CSI)
occm_versions=(""         ""       "v1.21.1" "v1.21.1" "v1.22.1" "v1.23.1" "v1.24.0")
#ccmr_versions=(""        ""        ""        ""        "v1.22.1" "v1.23.1" "v1.24.0")
ccmr_versions=(""        ""        "v1.22.1" "v1.22.1" "v1.22.1" "v1.23.1" "v1.24.0")
ccsi_versions=(""        ""        "v1.20.5" "v1.21.1" "v1.22.1" "v1.23.1" "v1.24.0")
min_snapshot_master="v1.21.0"

# Convert vxx.yy.zz to the number xxyyzz. Also works for z.y.z (0x0y0z).
dotversion()
{
	if test "$1" = "latest" -o "$1" = "main" -o "$1" = "master" -o "$1" = "HEAD"; then
		VERSION=999999
		echo $VERSION
		return
	elif test -z "$1"; then
		VERSION=1
		echo $VERSION
		return
	fi
	VERS=${1#v}
	one=${VERS%%.*}
	two=${VERS#*.}
	three=${two#*.}
	if test $three=$two; then three=0; fi
	two=${two%%.*}
	VERSION=$((10000*$one+100*$two+$three))
	unset V one two three
	echo $VERSION
}

# Get versions from arrays
setversions()
{
	OCCM_VERSION=${occm_versions[$1]}
	CCMR_VERSION=${ccmr_versions[$1]}
	CCSI_VERSION=${ccsi_versions[$1]}
}

# Determine which openstack-cloud-provider versions to use
find_openstack_versions()
{
	k8s=${1:-$KUBERNETES_VERSION}
	k8vers=$(dotversion $k8s)
	if test -z "$k8s"; then echo "ERROR: Need to pass k8s version" 1>&2; return 1; fi
	NUMV=${#k8s_versions[*]}
	k8min=$(dotversion ${k8s_versions[0]%.*})
	k8max=$(dotversion ${k8s_versions[$((NUMV-1))]%.*})
	snapmaster=$(dotversion $min_snapshot_master)
	if test $k8vers -lt $snapmaster; then SNAP_VERSION=""; else SNAP_VERSION="master"; fi
	#echo "$k8vers $k8min $k8max"
	if test $k8vers -lt $k8min; then setversions 0; return 0; fi
	if test $k8vers -gt $((k8max+99)); then setversions $((NUMV-1)); return 0; fi
	declare -i idx=0
	for k8 in ${k8s_versions[*]}; do
		k8test=$(dotversion ${k8%.*})
		if test $k8vers -ge $k8test -a $k8vers -le $((k8test+99)); then setversions $idx; return 0; break; fi
		let idx+=1
	done
	return 1
}

# Convert v1.19.x to latest v1.19.$LATEST
set_k8s_latestpatch()
{
	k8s=${1:-$KUBERNETES_VERSION}
	if test "${k8s:$((${#k8s}-1)):1}" != "x"; then KUBERNETES_VERSION=$k8s; return 0; fi
	k8vers=$(dotversion ${k8s%.x})
	for k8 in ${k8s_versions[*]}; do
		k8test=$(dotversion ${k8%.*})
		if test $k8vers -ge $k8test -a $k8vers -le $((k8test+99)); then KUBERNETES_VERSION=$k8; return 0; break; fi
	done
	KUBERNETES_VERSION="${k8s%.x}.0"
	return 1
}
