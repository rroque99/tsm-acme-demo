###################################
# Provided as-is with no warranty
# Instructions for use
# Requires jq installed.  Tested on Ubuntu and MacOS
# set kube context to the cluster you want to onboard
# create env variable called TSM_TOKEN with your TSM API key and TSM_URL with TSM url (ex prod-2.nsxservicemesh.vmware.com).  Alternately you can uncomment the export TSM_TOKEN and TSM_URL in the script and store it there but understand the risks
# run with ./tsm-onboard-cluster.sh {clustername}  note: clustername is the friendly name of the cluster shown in TSM
###################################

#!/usr/bin/env bash
set -x
set -e

# Export User API Token and Cluster Name
# export TSM_TOKEN="redacted"
# export TSM_URL="https://prod-2.nsxservicemesh.vmware.com"
echo $TSM_TOKEN
echo $TSM_URL
export CLUSTER_NAME=$1
echo "Exchanging API token for access token"
AT=$(curl -s 'https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize' \
            -H 'accept: application/json, text/plain, */*' \
            --data-raw "refresh_token=${TSM_TOKEN}" --compressed | jq -r '.access_token')
echo $AT
echo "Fetching Onboarding URL"
ONBOARD_URL=$(curl https://$TSM_URL/tsm/v1alpha1/clusters/onboard-url \
                  -H "csp-auth-token:$AT" | jq -r '.url')

# Validate kubectl context is correct
echo --------------------------
kubectl config current-context
echo --------------------------
read -p "Is the correct Kubernetes context selected (y/N)"  -n 1 -r
echo

# Install TSM Components
kubectl apply -f $ONBOARD_URL
echo "Getting TSM Token for Secret"
TOKEN=$(curl -X PUT "https://$TSM_URL/tsm/v1alpha1/clusters/${CLUSTER_NAME}?createOnly=true" \
                   -H "csp-auth-token:$AT" \
                   -H 'content-type: application/json' \
                   -d '{"displayName": "'"${CLUSTER_NAME}"'", "description":"Test TKG cluster", "tags":["msp-dc", "vsphere"], "labels":[{"key":"Proxy Location", "value":"aviproxy"}], "autoInstallServiceMesh":true, "enableNamespaceExclusions":true, "enableInternalGateway":true, "namespaceExclusions":[{"type": "EXACT", "match": "vmware-system-tsm"}, {"type": "EXACT", "match": "vmware-system-tmc"}], "autoInstallServiceMeshConfig":{"restrictDefaultExternalAccess":false}}' \
                   | jq -r '.token')
echo "Creating Secret from TSM Token"
kubectl -n vmware-system-tsm create secret generic cluster-token --from-literal=token=$TOKEN
echo "Setting initial state to init"
STATE="INIT"
sleep 60
until [[ $STATE == "Ready" ]]
do
    echo "${CLUSTER_NAME} State = ${STATE}, waiting..."
    sleep 15
    STATE=$(curl -X GET "https://$TSM_URL/tsm/v1alpha1/clusters/$CLUSTER_NAME" \
                   -H "Accept: application/json, text/plain, */*" \
                   -H "csp-auth-token: $AT" | jq -r '.status.state')
done
echo 'Cluster '${CLUSTER_NAME}' has been Onboarded to TSM and is Ready'
