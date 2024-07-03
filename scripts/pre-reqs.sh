#!/bin/bash

set -e  # Exit on error
set -u  # Treat unset variables as an error
set -o pipefail  # Ensure pipelines fail properly

# Define directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD_DIR="$SCRIPT_DIR/../grafana-infra/dashboards"
# Replace the placeholder in the JSON files
PLACEHOLDER="\${DS_PROMETHEUS}"
REPLACEMENT="Managed_Prometheus_aks-prometheus-istio-wkspace"
# terraform remote backend state resource group name and deployment location 
resource_group_name="tfmstate-rg"
resource_group_location="WestEurope"
# storage_acc_name="zcitakstfmacc" - this is the original name, but for hpe hybrid labs deployment, needed a unique name 
# required me to adjust remote backend config in all provider blocks in aks-infra, grafana-infra and istio-infra (only when deploying in hybrid labs)
storage_acc_name="zcitakstfmacc2"
container_name="tfstate"
# location latest istio grafana dashboards are stored 
grafana_dash_loc="../grafana-infra/dashboards"
kube_config_dir="~/.kube"
download_dir=~/Downloads
# Microsoft.Monitor azure resource provisioner namespace
namespace="Microsoft.Monitor"


# register Microsot.Monitor resource provider namespace
registrationState=$(az provider show --namespace $namespace --query "registrationState" --output tsv)

echo "State of the Azure $namespace namespace:" $registrationState

if [$registrationState != "Registered"]; then
    echo "Registering $namespace namespace..."
    az provider register --namespace $namespace
    # Wait for the namespace to be registered
    while [$registrationState != "Registered"]; do
        sleep 7
        registrationState=$(az provider show --namespace $namespace --query "registrationState" --output tsv)
        echo "Current state of the $namespace namespace: $registrationState"
    done
else
    echo "$namespace namespace is already registered. Proceeding with the next steps..." 
fi

# ceate storage account for remote backend 
echo "Creating remote backend's resource group..."
az group create --name $resource_group_name --location $resource_group_location

echo "Creating storage account..."
az storage account create \
  --name $storage_acc_name \
  --resource-group $resource_group_name \
  --location $resource_group_location \
  --sku Standard_LRS

storageAccountKey=$(az storage account keys list --resource-group $resource_group_name --account-name $storage_acc_name --query '[0].value' --output tsv)

echo "Creating container..."
az storage container create \
  --name $container_name \
  --account-name $storage_acc_name \
  --account-key $storageAccountKey


# Create ~/Downloads directory, if non-existant
sudo mkdir -p $download_dir
# create kubernetes config directory if non-existant and set current user to owner of the directory
sudo mkdir -p ~/.kube
sudo chown $USER:$USER ~/.kube

# install jq
sudo apt-get update
sudo apt-get install jq -y

# download latest istio grafana json dashboards and replace the prometheus data source placeholder to the managed prometheus workspace instance name
# List of dashboard IDs
IDS=(7645 7639 7636 7630 13277)

# Clear existing JSON files in the dashboards directory
rm -f "$DASHBOARD_DIR"/*.json || { echo "Failed to remove existing JSON files"; exit 1; }

# Function to download and process each JSON file
download_and_process_json() {
    local dashboard_id=$1
    local url="https://grafana.com/api/dashboards/${dashboard_id}/revisions/latest/download"
    local response
    response=$(curl -s -w "%{http_code}" -o "$DASHBOARD_DIR/${dashboard_id}.json" "$url") || { echo "Failed to download dashboard ${dashboard_id}"; return 1; }
    local status_code=${response: -3}
    
    if [[ $status_code -eq 200 ]]; then
        local tmp_path="$DASHBOARD_DIR/${dashboard_id}.tmp"
        mv "$DASHBOARD_DIR/${dashboard_id}.json" "$tmp_path" || { echo "Failed to move file for dashboard ${dashboard_id}"; return 1; }
        
        jq '.' "$tmp_path" > "$DASHBOARD_DIR/${dashboard_id}.json" || { echo "Failed to process JSON for dashboard ${dashboard_id}"; return 1; }
        rm "$tmp_path" || { echo "Failed to remove temporary file for dashboard ${dashboard_id}"; return 1; }
    else
        echo "Failed to download dashboard ${dashboard_id}: ${status_code}"
    fi
}

# Loop through each ID and download the JSON files
for dashboard_id in "${IDS[@]}"; do
    download_and_process_json $dashboard_id || echo "Error processing dashboard ${dashboard_id}"
done

for json_file in "$DASHBOARD_DIR"/*.json; do
    sed -i "s|$PLACEHOLDER|$REPLACEMENT|g" "$json_file" || { echo "Failed to replace placeholder in $json_file"; exit 1; }
done

echo "All dashboards processed successfully."

# where does this fit in the CI/CD flow once integrate with Azure DevOps
sudo chmod 755 ../istio-infra/istiod-kustomize/kustomize.sh
sudo chmod 755 ../istio-infra/gateway-kustomize/kustomize.sh

# install kubectl (latest release) and validate binary w/ sha256 checksum
cd $download_dir
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client --output=yaml

# install Terraform: Add HashiCorp's GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
# add HashiCorp's APT repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
# update the package list and install/upgrade Terraform
sudo apt update && sudo apt install --only-upgrade terraform -y


# download istioctl and move into package directory
curl -L -v https://istio.io/downloadIstio | sh - && cd istio-*
# Update PATH to include istioctl 
export PATH=$PWD/bin:$PATH
# run prechecks, desired output: connection refused (because no kubernetes config file has been created yet)
istioctl x precheck

echo "Deployment complete!"