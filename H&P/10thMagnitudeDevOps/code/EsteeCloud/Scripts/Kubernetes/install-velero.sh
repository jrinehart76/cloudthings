#!/bin/bash
#  Args are as follows:
#  $1 = AKS Cluster Name
#  $2 = Cluster Resource Group Name
#  $3 = Storage Account ID to be used with Velero
#  $4 = SP Client ID
#  $5 = SP Client Password
#  $6 = Subscription name for backup destination
#  $7 = Resource Group name for backup destination
#  This script will gather information needed for installing Velero in AKS
#  as per the documentation found at https://velero.io/docs/v1.1.0/azure-config/.
#
AZURE_BACKUP_RESOURCE_GROUP="$7"
AZURE_RESOURCE_GROUP=`az aks show -n "$1" -g "$2" --query nodeResourceGroup`
AZURE_STORAGE_ACCOUNT_ID="$3"

AZURE_BACKUP_SUBSCRIPTION_NAME="$6"
AZURE_BACKUP_SUBSCRIPTION_ID=`az account list --all --query="[?name=='$AZURE_BACKUP_SUBSCRIPTION_NAME'].id | [0]" -o tsv`

echo $AZURE_BACKUP_SUBSCRIPTION_ID
echo $AZURE_RESOURCE_GROUP


AZURE_SUBSCRIPTION_ID=`az account list --query '[?isDefault].id' -o tsv`
AZURE_TENANT_ID=`az account list --query '[?isDefault].tenantId' -o tsv`

AZURE_CLIENT_SECRET="$5"
AZURE_CLIENT_ID="$4"

cat << EOF  > ./credentials-velero
AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}
AZURE_TENANT_ID=${AZURE_TENANT_ID}
AZURE_CLIENT_ID=${AZURE_CLIENT_ID}
AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}
AZURE_RESOURCE_GROUP=${AZURE_RESOURCE_GROUP}
AZURE_CLOUD_NAME=AzurePublicCloud
EOF

BLOB_CONTAINER=`echo "$1" | tr '[:upper:]' '[:lower:]'`
# Run only for new storage accounts, assume that the container already exists otherwise
az account set -s "$6"
CONTAINER_OUTPUT=`az storage container show -n "$BLOB_CONTAINER" --account-name "$AZURE_STORAGE_ACCOUNT_ID" 2>&1 >/dev/null | grep -i ContainerNotFound`
echo $CONTAINER_OUTPUT
if [ "$CONTAINER_OUTPUT" != "" ]
then
  echo 'Creating the container as it does not exist'
  az storage container create -n $BLOB_CONTAINER --public-access off --account-name $AZURE_STORAGE_ACCOUNT_ID
fi


velero install \
    --provider azure \
    --plugins velero/velero-plugin-for-microsoft-azure:v1.0.0 \
    --bucket $BLOB_CONTAINER \
    --use-restic \
    --secret-file ./credentials-velero \
    --backup-location-config resourceGroup=$AZURE_BACKUP_RESOURCE_GROUP,storageAccount=$AZURE_STORAGE_ACCOUNT_ID,subscriptionId=$AZURE_BACKUP_SUBSCRIPTION_ID \
    --snapshot-location-config resourceGroup=$AZURE_BACKUP_RESOURCE_GROUP,subscriptionId=$AZURE_BACKUP_SUBSCRIPTION_ID \
    --restic-pod-cpu-limit '1200m' \
    --restic-pod-cpu-request '500m' \
    --restic-pod-mem-limit '512Mi' \
    --restic-pod-mem-request '256Mi'

velero create backup initial -w
velero create schedule dailybackup --schedule "0 3 * * *" 

