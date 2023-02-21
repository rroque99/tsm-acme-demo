# Onboard Cluster to TSM

This scipt uses the TSM API to onboard clusters.  Has been tested on MacOS and Linux.  This scipt is provided as is with no guarentees implied or offered.

## Prerequisites

1. Have jq installed on box where the script is being run from
2. You have an API token for your organization 
3. Edited either the script or the tsm-env file with the correct TSM_URL and TSM_TOKEN

## Use

1. Source the tsm-env file to set TSM_TOKEN and TSM_URL `source ./tsm-env`
2. Set the kube context to the cluster you want to onboard.  The scipt will ask you to validate but doesn't current support changing context during the run
3. Execute onboarding script with cluster friendly name `./tsm-onboard-cluster.sh cluster123`