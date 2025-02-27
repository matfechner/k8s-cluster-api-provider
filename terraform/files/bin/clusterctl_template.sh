#!/usr/bin/env bash
# Fill in OPENSTACK_CLOUD_YAML_B64, OPENSTACK_CLOUD_PROVIDER_CONF_B64,
#  OPENSTACK_CLOUD_CACERT_B64 into clusterctl.yaml

# yq installation done by bootstrap.sh
#sudo snap install yq

# Encode clouds.yaml
# Using application credentials, we don't need project_id, and openstackclient is
# even confused (asking for scoped tokens which fails). However, the cluster-api-provider-openstack
# does not consider the AuthInfo to be valid of there is no projectID. It knows how to derive it
# from the name, but not how to derive it from an application credential. (Not sure gophercloud
# even has the needed helpers.)
PROJECTID=$(grep 'tenant.id=' ~/cluster-defaults/cloud.conf | sed 's/^[^=]*=//')
CLOUD_YAML_ENC=$( (cat ~/.config/openstack/clouds.yaml; echo "      project_id: $PROJECTID") | base64 -w 0)
echo $CLOUD_YAML_ENC

# Encode cloud.conf
CLOUD_CONF_ENC=$(base64 -w 0 ~/cluster-defaults/cloud.conf)
echo $CLOUD_CONF_ENC

#Get CA and Encode CA
cloud_provider=$(yq eval '.OPENSTACK_CLOUD' ~/cluster-defaults/clusterctl.yaml)
# Snaps are broken - can not access ~/.config/openstack/clouds.yaml
AUTH_URL=$(cat ~/.config/openstack/clouds.yaml | yq eval .clouds.${cloud_provider}.auth.auth_url -)
#AUTH_URL=$(grep -A12 "${cloud_provider}" ~/.config/openstack/clouds.yaml | grep auth_url | head -n1 | sed -e 's/^ *auth_url: //' -e 's/"//g')
AUTH_URL_SHORT=$(echo "$AUTH_URL" | sed s'/https:\/\///' | sed s'/\/.*$//')
CERT_CERT=$(openssl s_client -connect "$AUTH_URL_SHORT" </dev/null 2>&1 | head -n 1 | sed s'/.*CN\ =\ //' | sed s'/\ /_/g' | sed s'/$/.pem/')
CLOUD_CA_ENC=$(base64 -w 0 /etc/ssl/certs/"$CERT_CERT")

yq eval '.OPENSTACK_CLOUD_YAML_B64 = "'"$CLOUD_YAML_ENC"'"' -i ~/cluster-defaults/clusterctl.yaml
yq eval '.OPENSTACK_CLOUD_PROVIDER_CONF_B64 = "'"$CLOUD_CONF_ENC"'"' -i ~/cluster-defaults/clusterctl.yaml
yq eval '.OPENSTACK_CLOUD_CACERT_B64 = "'"$CLOUD_CA_ENC"'"' -i ~/cluster-defaults/clusterctl.yaml
# Generate SET_MTU_B64
#MTU=`yq eval '.MTU_VALUE' ~/cluster-defaults/clusterctl.yaml`
# Fix up nameserver list (trailing comma -- cosmetic)
sed '/OPENSTACK_DNS_NAMESERVERS:/s@, \]"@ ]"@' -i ~/cluster-defaults/clusterctl.yaml
