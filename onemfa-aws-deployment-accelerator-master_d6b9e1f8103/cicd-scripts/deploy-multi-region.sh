#!/bin/bash
blue_namespace="${BLUE_DEPLOYMENT_NAMESPACE}"
green_namespace="${GREEN_DEPLOYMENT_NAMESPACE}"
deployIDM="true"
secrets_mode="k8s"
replicas=1
cluster_type=${1}
region1=${region1}
region2=${region2}
DEPLOY_RS="${DEPLOY_RS}"
DEPLOY_TS="${DEPLOY_TS}"
DEPLOY_US="${DEPLOY_US}"
DEPLOY_AM="${DEPLOY_AM}"
DEPLOY_IG="false"
GLOBAL_REPL_ON="true"
GLOBAL_REPL_RS_HOSTNAME1="forgerock-repl-server-0.forgerock-repl-server."${blue_namespace}".svc.cluster.local"
GLOBAL_REPL_RS_HOSTNAME2="forgerock-repl-server-1.forgerock-repl-server."${blue_namespace}".svc.cluster.local"
GLOBAL_REPL_US_HOSTNAME1="forgerock-user-store-0.forgerock-repl-server."${blue_namespace}".svc.cluster.local"
GLOBAL_REPL_US_HOSTNAME2="forgerock-user-store-1.forgerock-repl-server."${blue_namespace}".svc.cluster.local"
cluster_type="${CLUSTER_TYPE}"

echo "first blue LB is: ${hostAliases_ip1}"
echo "second blue LB is: ${hostAliases_ip2}"

if [ "${cluster_type,,}" == "blue" ]; then
    clusterSuffix="blue"
    # echo "-> Updating K8s Secrets and Config Maps"
    # helm upgrade --install --wait --timeout 10m0s \
    # --set configstore.pod_name="forgerock-config-store-${clusterSuffix}" \
    # --set policystore.pod_name="forgerock-policy-store-${clusterSuffix}" \
    # --set userstore.pod_name="forgerock-user-store-${clusterSuffix}" \
    # --set tokenstore.pod_name="forgerock-token-store-${clusterSuffix}" \
    # --set replserver.pod_name="forgerock-repl-server-${clusterSuffix}" \
    # --set am.pod_name="forgerock-access-manager-${clusterSuffix}" \
    # --set idm.pod_name="forgerock-idm-${clusterSuffix}" \
    # --set secrets.namespace="${blue_namespace}" \
    # --namespace "${blue_namespace}" \
    # forgerock-secrets-and-configmaps-${clusterSuffix} secrets-and-configs/kubernetes/
    # echo "-- Done"
    # echo ""

if [ "${DEPLOY_RS,,}" == "true" ]; then
    echo "-> Installing Replication Server"
    echo "   Will wait for it to be ready before installing next components (User and Token Stores)"
    helm install --wait --timeout 10m0s \
    --set replserver.image="${CI_REGISTRY_URL}/forgerock-repl-server:${DEPLOY_IMAGES_TAG}" \
    --set replserver.pod_name="$PODNAME_RS" \
    --set replserver.service_name="$SERVICENAME_RS" \
    --set replserver.cluster_domain="cluster.local" \
    --set replserver.replicas="1" \
    --set replserver.env_type="$ENV_TYPE" \
    --set replserver.use_javaProps="false" \
    --set replserver.global_repl_on="false" \
    --set replserver.global_repl_fqdns="europe-north-1A.forgerock-repl-server.forgerock.svc.cluster.local\,europe-north-1B.forgerock-repl-server.forgerock.svc.cluster.local" \
    --set vault.url="https://midships-vault.vault.6ab12ea5-c7af-456f-81b5-e0aaa5c9df5e.aws.hashicorp.cloud:8200" \
    --set vault.token="s.kms8RFodqcEzxmmEHn3MD3GB.MV86d" \
    --set vault.rs_path="${REPLSERVER_VAULT_PATH}" \
    --set vault.us_path="${USERSTORE_VAULT_PATH}" \
    --set vault.ts_path="${TOKENSTORE_VAULT_PATH}" \
    --set vault.cs_path="${CONFIGSTORE_VAULT_PATH}" \
    --set configstore.pod_name="$PODNAME_CS" \
    --set userstore.pod_name="$PODNAME_US" \
    --set tokenstore.pod_name="$PODNAME_TS" \
    --set replserver.secrets_mode="${secrets_mode}" \
    --namespace "${blue_namespace}" \
    forgerock-repl-server child-images/repl-server/
    echo "-- Done"
    echo ""

    echo "-> Manually scaling Replication Server."
    echo "   Only one RS is required to intall reset of DS components"
    kubectl scale statefulsets $PODNAME_RS --replicas=$DS_REPLICAS_RS -n "${blue_namespace}"
    echo "-- Done"
    echo ""
fi

if [ "${DEPLOY_US,,}" == "true" ]; then
    echo "-> Installing User Store"
    echo "   Will wait for it to be ready before installing next component (Access Manager)"
    helm upgrade --install --wait --timeout 10m0s \
    --set userstore.image="${CI_REGISTRY_URL}/forgerock-user-store:${DEPLOY_IMAGES_TAG}" \
    --set userstore.pod_name="$PODNAME_US" \
    --set userstore.service_name="$SERVICENAME_US" \
    --set replserver.pod_name="$PODNAME_RS" \
    --set userstore.secrets_mode="${SECRETS_MODE}" \
    --set userstore.replicas="1" \
    --set userstore.cluster_domain="cluster.local" \
    --set userstore.basedn="ou=identities" \
    --set userstore.load_schema="$USERSTORE_LOAD_SCHEMA" \
    --set userstore.load_dsconfig="$USERSTORE_LOAD_DSCONFIG" \
    --set vault.url="https://midships-vault.vault.6ab12ea5-c7af-456f-81b5-e0aaa5c9df5e.aws.hashicorp.cloud:8200" \
    --set vault.token="s.kms8RFodqcEzxmmEHn3MD3GB.MV86d" \
    --set vault.us_path="${USERSTORE_VAULT_PATH}" \
    --set vault.rs_path="${REPLSERVER_VAULT_PATH}" \
    --set userstore.namespace="${blue_namespace}" \
    --set userstore.use_javaProps="false" \
    --set userstore.self_replicate="false" \
    --set userstore.add_idm_repo="${DEPLOY_IDM}" \
    --set userstore.rs_svc="${GLOBAL_REPL_RS_HOSTNAME1}:8989\,${GLOBAL_REPL_RS_HOSTNAME2}:8989" \
    --set userstore.env_type="$ENV_TYPE" \
    --set userstore.disable_insecure_comms="true" \
    --namespace "${blue_namespace}" \
    forgerock-user-store child-images/user-store/
    echo "-- Done"
    echo ""

    echo "-> Manually scaling User Store"
    echo "   Only one US and TS is required to intall Access Manager"
    kubectl scale statefulsets $PODNAME_US --replicas=$DS_REPLICAS_US  -n "${blue_namespace}"
    echo "-- Done"
    echo ""
fi 

    if [ "${deployIDM,,}" == "true" ]; then
    echo "-> Installing IDM"
    helm install \
        --set idm.image="${CI_REGISTRY_URL}/forgerock-idm:${DEPLOY_IMAGES_TAG}" \
        --set idm.pod_name="$PODNAME_IDM" \
        --set userstore.pod_name="$PODNAME_US" \
        --set idm.service_name="$SERVICENAME_IDM" \
        --set idm.secrets_mode="${SECRETS_MODE}" \
        --set idm.replicas="$IDM_REPLICAS" \
        --set idm.ds_hostname_primary="$PODNAME_US-0.forgerock-user-store.${blue_namespace}.svc.cluster.local" \
        --set idm.ds_hostname_secondary="$PODNAME_US-1.forgerock-user-store.${blue_namespace}.svc.cluster.local" \
        --set idm.namespace="${blue_namespace}" \
        --set idm.idm_profile="ds" \
        --set idm.env_type="$ENV_TYPE" \
        --set idm.secrets_mode="k8s" \
        --set vault.url="https://midships-vault.vault.6ab12ea5-c7af-456f-81b5-e0aaa5c9df5e.aws.hashicorp.cloud:8200" \
        --set vault.token="s.kms8RFodqcEzxmmEHn3MD3GB.MV86d" \
        --set vault.idm_path="forgerock/data/fr7/idm" \
        --namespace "${blue_namespace}" \
        forgerock-idm child-images/idm/
    echo "-- Done"
    echo ""
    fi
fi

if [ "${cluster_type,,}" == "green" ]; then
    clusterSuffix="green"
    # echo "-> Updating K8s Secrets and Config Maps"
    # helm upgrade --install --wait --timeout 10m0s \
    # --set configstore.pod_name="forgerock-config-store-${clusterSuffix}" \
    # --set policystore.pod_name="forgerock-policy-store-${clusterSuffix}" \
    # --set userstore.pod_name="forgerock-user-store-${clusterSuffix}" \
    # --set tokenstore.pod_name="forgerock-token-store-${clusterSuffix}" \
    # --set replserver.pod_name="forgerock-repl-server-${clusterSuffix}" \
    # --set am.pod_name="forgerock-access-manager-${clusterSuffix}" \
    # --set idm.pod_name="forgerock-idm-${clusterSuffix}" \
    # --set secrets.namespace="${green_namespace}" \
    # --namespace "${green_namespace}" \
    # forgerock-secrets-and-configmaps secrets-and-configs/kubernetes/
    # echo "-- Done"
    # echo ""

if [ "${DEPLOY_RS,,}" == "true" ]; then
    echo "-> Installing Replication Server"
    echo "   Will wait for it to be ready before installing next components (User and oken Stores)"
    helm install --wait --timeout 10m0s \
    --set replserver.image="${CI_REGISTRY_URL}/forgerock-repl-server:${DEPLOY_IMAGES_TAG}" \
    --set replserver.pod_name="$PODNAME_RS" \
    --set replserver.service_name="$SERVICENAME_RS" \
    --set replserver.cluster_domain="cluster.local" \
    --set replserver.replicas="1" \
    --set replserver.env_type="$ENV_TYPE" \
    --set replserver.use_javaProps="false" \
    --set replserver.global_repl_on="true" \
    --set replserver.global_repl_fqdns="${GLOBAL_REPL_RS_HOSTNAME1}:8989\,${GLOBAL_REPL_RS_HOSTNAME2}:8989" \
    --set vault.url="https://midships-vault.vault.6ab12ea5-c7af-456f-81b5-e0aaa5c9df5e.aws.hashicorp.cloud:8200" \
    --set vault.token="s.kms8RFodqcEzxmmEHn3MD3GB.MV86d" \
    --set replserver.global_repl_svc_ip1="${rs_global_repl_svc_ip1}" \
    --set replserver.global_repl_svc_ip2="${rs_global_repl_svc_ip2}" \
    --set replserver.hostAliases_ip_rs_1="${hostAliases_ip_rs_1}" \
    --set replserver.hostAliases_ip_rs_2="${hostAliases_ip_rs_2}" \
    --set replserver.hostAliases_ip_us_1="${hostAliases_ip_us_1}" \
    --set replserver.hostAliases_ip_us_2="${hostAliases_ip_us_1}" \
    --set replserver.hostAliases_hostname_rs_1="${GLOBAL_REPL_RS_HOSTNAME1}" \
    --set replserver.hostAliases_hostname_rs_2="${GLOBAL_REPL_RS_HOSTNAME2}" \
    --set replserver.hostAliases_hostname_us_1="${GLOBAL_REPL_US_HOSTNAME1}" \
    --set replserver.hostAliases_hostname_us_2="${GLOBAL_REPL_US_HOSTNAME2}" \
    --set vault.rs_path="${REPLSERVER_VAULT_PATH}" \
    --set vault.us_path="${USERSTORE_VAULT_PATH}" \
    --set vault.ts_path="${TOKENSTORE_VAULT_PATH}" \
    --set vault.cs_path="${CONFIGSTORE_VAULT_PATH}" \
    --set configstore.pod_name="$PODNAME_CS" \
    --set userstore.pod_name="$PODNAME_US" \
    --set tokenstore.pod_name="$PODNAME_TS" \
    --set replserver.secrets_mode="${secrets_mode}" \
    --namespace "${green_namespace}" \
    forgerock-repl-server child-images/repl-server/
    echo "-- Done"
    echo ""

    echo "-> Manually scaling Replication Server."
    echo "   Only one RS is required to install reset of DS components"
    kubectl scale statefulsets $PODNAME_RS --replicas=$DS_REPLICAS_RS  -n "${green_namespace}"
    echo "-- Done"
    echo ""
fi 

if [ "${DEPLOY_US,,}" == "true" ]; then
    echo "-> Installing User Store"
    echo "   Will wait for it to be ready before installing next component (Access Manager)"
    helm upgrade --install --wait --timeout 10m0s \
    --set userstore.image="${CI_REGISTRY_URL}/forgerock-user-store:${DEPLOY_IMAGES_TAG}" \
    --set userstore.pod_name="$PODNAME_US" \
    --set userstore.service_name="$SERVICENAME_US" \
    --set replserver.pod_name="$PODNAME_RS" \
    --set userstore.secrets_mode="${secrets_mode}" \
    --set userstore.replicas="1" \
    --set userstore.cluster_domain="cluster.local" \
    --set userstore.basedn="ou=identities" \
    --set userstore.load_schema="$USERSTORE_LOAD_SCHEMA" \
    --set userstore.load_dsconfig="$USERSTORE_LOAD_DSCONFIG" \
    --set vault.url="https://midships-vault.vault.6ab12ea5-c7af-456f-81b5-e0aaa5c9df5e.aws.hashicorp.cloud:8200" \
    --set vault.token="s.kms8RFodqcEzxmmEHn3MD3GB.MV86d" \
    --set vault.us_path="${USERSTORE_VAULT_PATH}" \
    --set vault.rs_path="${REPLSERVER_VAULT_PATH}" \
    --set userstore.namespace="${green_namespace}" \
    --set userstore.use_javaProps="false" \
    --set userstore.self_replicate="false" \
    --set userstore.add_idm_repo="${deployIDM}" \
    --set userstore.rs_svc="${GLOBAL_REPL_RS_HOSTNAME1}:8989\,${GLOBAL_REPL_RS_HOSTNAME2}:8989" \
    --set userstore.global_repl_svc_ip1="${us_global_repl_svc_ip1}" \
    --set userstore.global_repl_svc_ip2="${us_global_repl_svc_ip1}" \
    --set replserver.hostAliases_ip_rs_1="${hostAliases_ip_rs_1}" \
    --set replserver.hostAliases_ip_rs_2="${hostAliases_ip_rs_2}" \
    --set replserver.hostAliases_ip_us_1="${hostAliases_ip_us_1}" \
    --set replserver.hostAliases_ip_us_2="${hostAliases_ip_us_1}" \
    --set replserver.hostAliases_hostname_rs_1="${GLOBAL_REPL_RS_HOSTNAME1}" \
    --set replserver.hostAliases_hostname_rs_2="${GLOBAL_REPL_RS_HOSTNAME2}" \
    --set replserver.hostAliases_hostname_us_1="${GLOBAL_REPL_US_HOSTNAME1}" \
    --set replserver.hostAliases_hostname_us_2="${GLOBAL_REPL_US_HOSTNAME2}" \
    --set userstore.env_type="$ENV_TYPE" \
    --set userstore.disable_insecure_comms="true" \
    --namespace "${green_namespace}" \
    forgerock-user-store child-images/user-store/
    echo "-- Done"
    echo ""

    echo "-> Manually scaling User Store"
    echo "   Only one US and TS is required to install Access Manager"
    kubectl scale statefulsets $PODNAME_US --replicas=$DS_REPLICAS_US  -n "${green_namespace}"
    echo "-- Done"
    echo ""
fi 

    if [ "${deployIDM,,}" == "true" ]; then
    echo "-> Installing IDM"
    helm install \
        --set idm.image="${CI_REGISTRY_URL}/forgerock-idm:${DEPLOY_IMAGES_TAG}" \
        --set idm.pod_name="$PODNAME_IDM" \
        --set userstore.pod_name="$PODNAME_US" \
        --set idm.service_name="$SERVICENAME_IDM" \
        --set idm.secrets_mode="${secrets_mode}" \
        --set idm.replicas="$IDM_REPLICAS" \
        --set idm.ds_hostname_primary="$PODNAME_US-0.forgerock-user-store.${green_namespace}.svc.cluster.local" \
        --set idm.ds_hostname_secondary="$PODNAME_US-1.forgerock-user-store.${green_namespace}.svc.cluster.local" \
        --set idm.namespace="${green_namespace}" \
        --set idm.ds_port=1636 \
        --set idm.idm_profile="ds" \
        --set idm.env_type="$ENV_TYPE" \
        --set idm.secrets_mode="k8s" \
        --set vault.url="https://midships-vault.vault.6ab12ea5-c7af-456f-81b5-e0aaa5c9df5e.aws.hashicorp.cloud:8200" \
        --set vault.token="s.kms8RFodqcEzxmmEHn3MD3GB.MV86d" \
        --set vault.idm_path="forgerock/data/fr7/idm" \
        --namespace "${green_namespace}" \
        forgerock-idm-${clusterSuffix} child-images/idm/
    echo "-- Done"
    echo ""
    fi
fi
