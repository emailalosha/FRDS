#!/bin/bash
deployIDM="${DEPLOY_IDM}"
cs_sidecar_mode="${CS_SIDECAR_MODE}"
secrets_mode="${SECRETS_MODE}"
VAULT_BASE_URL="${VAULT_BASE_URL}"
VAULT_TOKEN="${VAULT_TOKEN}"
DEPLOY_RS="${DEPLOY_RS}"
DEPLOY_TS="${DEPLOY_TS}"
DEPLOY_US="${DEPLOY_US}"
DEPLOY_AM="${DEPLOY_AM}"
DEPLOY_IG="false"
GLOBAL_REPL_ON="false"
GLOBAL_REPL_RS_HOSTNAME1="forgerock-repl-server-0.forgerock-repl-server."${NAMESPACE}".svc.cluster.local"
GLOBAL_REPL_RS_HOSTNAME2="forgerock-repl-server-1.forgerock-repl-server."${NAMESPACE}".svc.cluster.local"


echo "Deployment parameter deployIDM is ${deployIDM}"
echo "Deployment parameter cs_sidecar_mode is ${cs_sidecar_mode}"
echo "Deployment parameter secrets_mode is ${secrets_mode}"
echo "Deployment parameter VAULT_BASE_URL is ${VAULT_BASE_URL}"
echo "Deployment parameter VAULT_TOKEN is ${VAULT_TOKEN}"
echo "Deployment parameter REPLSERVER_VAULT_PATH is ${REPLSERVER_VAULT_PATH}"
echo "Deployment parameter USERSTORE_VAULT_PATH is ${USERSTORE_VAULT_PATH}"
echo "Deployment parameter TOKENSTORE_VAULT_PATH is ${TOKENSTORE_VAULT_PATH}"
echo "Deployment parameter CONFIGSTORE_VAULT_PATH is ${CONFIGSTORE_VAULT_PATH}"
echo "Deployment parameter PODNAME_RS is ${PODNAME_RS}"
echo "Deployment parameter DEPLOY_RS is ${DEPLOY_RS}"
echo "Deployment parameter DEPLOY_TS is ${DEPLOY_TS}"
echo "Deployment parameter DEPLOY_US is ${DEPLOY_US}"
echo "Deployment parameter DEPLOY_AM is ${DEPLOY_AM}"

if [ ${CLUSTER_SUFFIX,,} = "az2" ]; then
  GLOBAL_REPL_ON="true"
  NAMESPACE2="forgerock-az1"
  SVC_RS_IP1="104.199.139.127"
  SVC_RS_IP2="35.185.155.10"
  SVC_US_IP1="34.81.211.179"
  SVC_US_IP2="35.229.187.33"
  SVC_TS_IP1="35.236.135.96"
  SVC_TS_IP2="35.234.55.207"
  GLOBAL_REPL_RS_IP1="34.138.158.174"
  GLOBAL_REPL_RS_IP2="35.227.82.242"
  GLOBAL_REPL_US_IP1="34.73.27.82"
  GLOBAL_REPL_US_IP2="35.229.22.163"
  GLOBAL_REPL_TS_IP1="35.185.100.251"
  GLOBAL_REPL_TS_IP2="34.73.197.166"
fi

if [ "${CS_SIDECAR_MODE,,}" == "true" ]; then
  svcFQDN_CS="localhost"
else
  svcFQDN_CS="forgerock-config-store.${NAMESPACE}.svc.cluster.local"
fi

if [ "${DEPLOY_RS,,}" == "true" ]; then
  echo "-> Installing Replication Server"
  echo "   Will wait for it to be ready before installing next components (User and Token Stores)"
  helm upgrade --install --wait --timeout 10m0s \
    --set replserver.image="${CI_REGISTRY_URL}/forgerock-repl-server:${DEPLOY_IMAGES_TAG}" \
    --set replserver.pod_name="$PODNAME_RS" \
    --set replserver.service_name="$SERVICENAME_RS" \
    --set replserver.cluster_domain="cluster.local" \
    --set replserver.replicas="1" \
    --set replserver.env_type="$ENV_TYPE" \
    --set replserver.use_javaProps="false" \
    --set replserver.global_repl_on="${GLOBAL_REPL_ON}" \
    --set replserver.global_repl_fqdns="${GLOBAL_REPL_RS_HOSTNAME1}:8989\,${GLOBAL_REPL_RS_HOSTNAME2}:8989" \
    --set replserver.global_repl_svc_ip1="${SVC_RS_IP1}" \
    --set replserver.global_repl_svc_ip2="${SVC_RS_IP2}" \
    --set replserver.hostAliases_ip_rs_1="${GLOBAL_REPL_RS_IP1}" \
    --set replserver.hostAliases_ip_rs_2="${GLOBAL_REPL_RS_IP2}" \
    --set replserver.hostAliases_ip_us_1="${GLOBAL_REPL_US_IP1}" \
    --set replserver.hostAliases_ip_us_2="${GLOBAL_REPL_US_IP2}" \
    --set replserver.hostAliases_ip_ts_1="${GLOBAL_REPL_TS_IP1}" \
    --set replserver.hostAliases_ip_ts_2="${GLOBAL_REPL_TS_IP2}" \
    --set replserver.hostAliases_hostname_rs_1="${GLOBAL_REPL_RS_HOSTNAME1}" \
    --set replserver.hostAliases_hostname_rs_2="${GLOBAL_REPL_RS_HOSTNAME2}" \
    --set replserver.hostAliases_hostname_us_1="${GLOBAL_REPL_US_HOSTNAME1}" \
    --set replserver.hostAliases_hostname_us_2="${GLOBAL_REPL_US_HOSTNAME2}" \
    --set replserver.hostAliases_hostname_ts_1="${GLOBAL_REPL_TS_HOSTNAME1}" \
    --set replserver.hostAliases_hostname_ts_2="${GLOBAL_REPL_TS_HOSTNAME2}" \
    --set vault.url="https://midships-vault.vault.6ab12ea5-c7af-456f-81b5-e0aaa5c9df5e.aws.hashicorp.cloud:8200" \
    --set vault.token="s.kms8RFodqcEzxmmEHn3MD3GB.MV86d" \
    --set vault.rs_path="${REPLSERVER_VAULT_PATH}" \
    --set vault.us_path="${USERSTORE_VAULT_PATH}" \
    --set vault.ts_path="${TOKENSTORE_VAULT_PATH}" \
    --set vault.cs_path="${CONFIGSTORE_VAULT_PATH}" \
    --set configstore.pod_name="$PODNAME_CS" \
    --set userstore.pod_name="$PODNAME_US" \
    --set tokenstore.pod_name="$PODNAME_TS" \
    --set replserver.secrets_mode="${SECRETS_MODE}" \
    --namespace "$NAMESPACE" \
    $PODNAME_RS child-images/repl-server/
  echo "-- Done"
  echo ""

  echo "-> Manually scaling Replication Server."
  echo "   Only one RS is required to intall reset of DS components"
  kubectl scale statefulsets $PODNAME_RS --replicas=$DS_REPLICAS_RS -n "$NAMESPACE"
  echo "-- Done"
  echo ""
fi 

if [ "${DEPLOY_TS,,}" == "true" ]; then
  echo "-> Installing Token Store"
  helm upgrade --install \
    --set tokenstore.image="${CI_REGISTRY_URL}/forgerock-token-store:${DEPLOY_IMAGES_TAG}" \
    --set tokenstore.service_name="$SERVICENAME_TS" \
    --set tokenstore.pod_name="$PODNAME_TS" \
    --set replserver.pod_name="$PODNAME_RS" \
    --set tokenstore.secrets_mode="${SECRETS_MODE}" \
    --set tokenstore.cluster_domain="cluster.local" \
    --set tokenstore.replicas="$DS_REPLICAS_TS" \
    --set tokenstore.basedn="ou=tokens" \
    --set tokenstore.self_replicate="false" \
    --set tokenstore.use_javaProps="false" \
    --set tokenstore.env_type="$ENV_TYPE" \
    --set tokenstore.disable_insecure_comms="false" \
    --set vault.url="https://midships-vault.vault.6ab12ea5-c7af-456f-81b5-e0aaa5c9df5e.aws.hashicorp.cloud:8200" \
    --set vault.token="s.kms8RFodqcEzxmmEHn3MD3GB.MV86d" \
    --set vault.ts_path="${TOKENSTORE_VAULT_PATH}" \
    --set vault.rs_path="${REPLSERVER_VAULT_PATH}" \
    --set tokenstore.rs_svc="${GLOBAL_REPL_RS_HOSTNAME1}:8989\,${GLOBAL_REPL_RS_HOSTNAME2}:8989" \
    --set tokenstore.global_repl_svc_ip1="${SVC_TS_IP1}" \
    --set tokenstore.global_repl_svc_ip2="${SVC_TS_IP2}" \
    --set replserver.hostAliases_ip_rs_1="${GLOBAL_REPL_RS_IP1}" \
    --set replserver.hostAliases_ip_rs_2="${GLOBAL_REPL_RS_IP2}" \
    --set replserver.hostAliases_ip_us_1="${GLOBAL_REPL_US_IP1}" \
    --set replserver.hostAliases_ip_us_2="${GLOBAL_REPL_US_IP2}" \
    --set replserver.hostAliases_ip_ts_1="${GLOBAL_REPL_TS_IP1}" \
    --set replserver.hostAliases_ip_ts_2="${GLOBAL_REPL_TS_IP2}" \
    --set replserver.hostAliases_hostname_rs_1="${GLOBAL_REPL_RS_HOSTNAME1}" \
    --set replserver.hostAliases_hostname_rs_2="${GLOBAL_REPL_RS_HOSTNAME2}" \
    --set replserver.hostAliases_hostname_us_1="${GLOBAL_REPL_US_HOSTNAME1}" \
    --set replserver.hostAliases_hostname_us_2="${GLOBAL_REPL_US_HOSTNAME2}" \
    --set replserver.hostAliases_hostname_ts_1="${GLOBAL_REPL_TS_HOSTNAME1}" \
    --set replserver.hostAliases_hostname_ts_2="${GLOBAL_REPL_TS_HOSTNAME2}" \
    --namespace "$NAMESPACE" \
    $PODNAME_TS child-images/token-store/
  echo "-- Done"
  echo ""
fi 

if [ "${CS_SIDECAR_MODE,,}" == "false" ]; then
  echo "-> Installing Config Store"
  helm upgrade --install \
    --set configstore.image="${CI_REGISTRY_URL}/forgerock-config-store:${DEPLOY_IMAGES_TAG}" \
    --set configstore.pod_name="${PODNAME_CS}" \
    --set replserver.pod_name="$PODNAME_RS" \
    --set configstore.secrets_mode="${SECRETS_MODE}" \
    --set configstore.sidecar_mode="${CS_SIDECAR_MODE}" \
    --set configstore.service_name="forgerock-config-store" \
    --set configstore.replicas="${DS_REPLICAS_CS}" \
    --set configstore.cluster_domain="cluster.local" \
    --set configstore.basedn="ou=am-config" \
    --set vault.url="https://midships-vault.vault.6ab12ea5-c7af-456f-81b5-e0aaa5c9df5e.aws.hashicorp.cloud:8200" \
    --set vault.token="s.kms8RFodqcEzxmmEHn3MD3GB.MV86d" \
    --set vault.cs_path="${CONFIGSTORE_VAULT_PATH}" \
    --set vault.rs_path="${REPLSERVER_VAULT_PATH}" \
    --set configstore.namespace="$NAMESPACE" \
    --set configstore.use_javaProps="false" \
    --set configstore.self_replicate="false" \
    --set configstore.rs_svc='forgerock-repl-server-0.forgerock-repl-server.'"${NAMESPACE}"'.svc.cluster.local:8989\,forgerock-repl-server-1.forgerock-repl-server.'"${NAMESPACE}"'.svc.cluster.local:8989' \
    --set configstore.env_type="$ENV_TYPE" \
    --set configstore.disable_insecure_comms="true" \
    --namespace "${NAMESPACE}" \
    forgerock-config-store child-images/config-store/
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
    --set userstore.basedn="dc=pru\,dc=com" \
    --set userstore.load_schema="$USERSTORE_LOAD_SCHEMA" \
    --set userstore.load_dsconfig="$USERSTORE_LOAD_DSCONFIG" \
    --set vault.url="https://midships-vault.vault.6ab12ea5-c7af-456f-81b5-e0aaa5c9df5e.aws.hashicorp.cloud:8200" \
    --set vault.token="s.kms8RFodqcEzxmmEHn3MD3GB.MV86d" \
    --set vault.us_path="${USERSTORE_VAULT_PATH}" \
    --set vault.rs_path="${REPLSERVER_VAULT_PATH}" \
    --set userstore.namespace="${NAMESPACE}" \
    --set userstore.use_javaProps="false" \
    --set userstore.self_replicate="false" \
    --set userstore.add_idm_repo="${DEPLOY_IDM}" \
    --set userstore.rs_svc="${GLOBAL_REPL_RS_HOSTNAME1}:8989\,${GLOBAL_REPL_RS_HOSTNAME2}:8989" \
    --set userstore.global_repl_svc_ip1="${SVC_US_IP1}" \
    --set userstore.global_repl_svc_ip2="${SVC_US_IP2}" \
    --set replserver.hostAliases_ip_rs_1="${GLOBAL_REPL_RS_IP1}" \
    --set replserver.hostAliases_ip_rs_2="${GLOBAL_REPL_RS_IP2}" \
    --set replserver.hostAliases_ip_us_1="${GLOBAL_REPL_US_IP1}" \
    --set replserver.hostAliases_ip_us_2="${GLOBAL_REPL_US_IP2}" \
    --set replserver.hostAliases_ip_ts_1="${GLOBAL_REPL_TS_IP1}" \
    --set replserver.hostAliases_ip_ts_2="${GLOBAL_REPL_TS_IP2}" \
    --set replserver.hostAliases_hostname_rs_1="${GLOBAL_REPL_RS_HOSTNAME1}" \
    --set replserver.hostAliases_hostname_rs_2="${GLOBAL_REPL_RS_HOSTNAME2}" \
    --set replserver.hostAliases_hostname_us_1="${GLOBAL_REPL_US_HOSTNAME1}" \
    --set replserver.hostAliases_hostname_us_2="${GLOBAL_REPL_US_HOSTNAME2}" \
    --set replserver.hostAliases_hostname_ts_1="${GLOBAL_REPL_TS_HOSTNAME1}" \
    --set replserver.hostAliases_hostname_ts_2="${GLOBAL_REPL_TS_HOSTNAME2}" \
    --set userstore.env_type="$ENV_TYPE" \
    --set userstore.disable_insecure_comms="true" \
    --namespace "$NAMESPACE" \
    $PODNAME_US child-images/user-store/
  echo "-- Done"
  echo ""

  echo "-> Manually scaling User Store"
  echo "   Only one US and TS is required to intall Access Manager"
  kubectl scale statefulsets $PODNAME_US --replicas=$DS_REPLICAS_US -n "$NAMESPACE"
  echo "-- Done"
  echo ""
fi 

if [ "${DEPLOY_IDM,,}" == "true" ]; then
  echo "-> Installing IDM"
  helm upgrade --install \
    --set idm.image="${CI_REGISTRY_URL}/forgerock-idm:${DEPLOY_IMAGES_TAG}" \
    --set idm.pod_name="$PODNAME_IDM" \
    --set userstore.pod_name="$PODNAME_US" \
    --set idm.service_name="$SERVICENAME_IDM" \
    --set idm.secrets_mode="${SECRETS_MODE}" \
    --set idm.replicas="$IDM_REPLICAS" \
    --set idm.ds_hostname_primary="$PODNAME_US-0.forgerock-user-store.${NAMESPACE}.svc.cluster.local" \
    --set idm.ds_hostname_secondary="$PODNAME_US-1.forgerock-user-store.${NAMESPACE}.svc.cluster.local" \
    --set idm.namespace="${NAMESPACE}" \
    --set idm.idm_profile="ds" \
    --set idm.env_type="fr7" \
    --set vault.url="https://midships-vault.vault.6ab12ea5-c7af-456f-81b5-e0aaa5c9df5e.aws.hashicorp.cloud:8200" \
    --set vault.token="s.kms8RFodqcEzxmmEHn3MD3GB.MV86d" \
    --set vault.idm_path="forgerock/data/fr7/idm" \
    --namespace "$NAMESPACE" \
    $PODNAME_IDM child-images/idm/
  echo "-- Done"
  echo ""
fi

if [ "${DEPLOY_AM,,}" == "true" ]; then
  echo "-> Installing Access Manager"
  helm upgrade --install \
    --set am.replicas="$AM_REPLICAS" \
    --set am.pod_name="$PODNAME_AM" \
    --set am.service_name="$SERVICENAME_AM" \
    --set configstore.pod_name="$PODNAME_CS" \
    --set configstore.use_javaProps="false" \
    --set configstore.self_replicate="true" \
    --set configstore.env_type="$ENV_TYPE" \
    --set configstore.cluster_domain="cluster.local" \
    --set configstore.basedn="ou=am-config" \
    --set configstore.disable_insecure_comms="false" \
    --set configstore.rs_svc='' \
    --set am.secrets_mode="${SECRETS_MODE}" \
    --set am.cs_sidecar_mode="${CS_SIDECAR_MODE}" \
    --set userstore.pod_name="$PODNAME_US" \
    --set tokenstore.pod_name="$PODNAME_TS" \
    --set replserver.pod_name="$PODNAME_RS" \
    --set configstore.image="${CI_REGISTRY_URL}/forgerock-config-store:${DEPLOY_IMAGES_TAG}" \
    --set am.image="${CI_REGISTRY_URL}/forgerock-access-manager:${DEPLOY_IMAGES_TAG}" \
    --set vault.url="https://midships-vault.vault.6ab12ea5-c7af-456f-81b5-e0aaa5c9df5e.aws.hashicorp.cloud:8200" \
    --set vault.token="s.kms8RFodqcEzxmmEHn3MD3GB.MV86d" \
    --set vault.am_path="forgerock/data/fr7/access-manager" \
    --set vault.cs_path="${CONFIGSTORE_VAULT_PATH}" \
    --set vault.ts_path="${TOKENSTORE_VAULT_PATH}" \
    --set vault.us_path="${USERSTORE_VAULT_PATH}" \
    --set vault.rs_path="${REPLSERVER_VAULT_PATH}" \
    --set am.namespace="$NAMESPACE" \
    --set am.env_type="$ENV_TYPE" \
    --set am.cookie_name="$AM_COOKIE_NAME" \
    --set am.lb_domain="$AM_LB_DOMAIN" \
    --set am.vault_client_path_runtime_am="forgerock/data/fr7/runtime/access-manager" \
    --set am.cs_k8s_svc_url="${svcFQDN_CS}" \
    --set am.us_k8s_svc_url="forgerock-user-store."${NAMESPACE}".svc.cluster.local" \
    --set am.ts_k8s_svc_url="forgerock-token-store."${NAMESPACE}".svc.cluster.local" \
    --set am.goto_urls='"https://url1.com/*"' \
    --set am.us_connstring_affinity='"forgerock-user-store-0.forgerock-user-store.'"${NAMESPACE}"'.svc.cluster.local:1636"\,"forgerock-user-store-1.forgerock-user-store.'"${NAMESPACE}"'.svc.cluster.local:1636"' \
    --set am.ps_connstring_affinity='forgerock-policy-store.'"${NAMESPACE}"'.svc.cluster.local:1636' \
    --set am.ts_connstring_affinity='forgerock-token-store-0.forgerock-token-store.'"${NAMESPACE}"'.svc.cluster.local:1636\,forgerock-token-store-1.forgerock-token-store.'"${NAMESPACE}"'.svc.cluster.local:1636' \
    --set am.amster_files="$AM_AMSTER_FILES" \
    --set am.auth_trees="$AM_AUTH_TREES" \
    --namespace "$NAMESPACE" \
    $PODNAME_AM child-images/access-manager/
  echo "-- Done"
  echo ""
fi 

if [ "${DEPLOY_IG,,}" == "true" ]; then
  echo "-> Installing Identity Gateway"
  helm upgrade --install \
    --set ig.replicas="$IG_REPLICAS" \
    --set ig.pod_name="$PODNAME_IG" \
    --set ig.service_name="$SERVICENAME_IG" \
    --set ig.secrets_mode="${SECRETS_MODE}" \
    --set ig.image="${CI_REGISTRY_URL}/forgerock-ig:${DEPLOY_IMAGES_TAG}" \
    --set vault.url="https://midships-vault.vault.6ab12ea5-c7af-456f-81b5-e0aaa5c9df5e.aws.hashicorp.cloud:8200" \
    --set vault.token="s.kms8RFodqcEzxmmEHn3MD3GB.MV86d" \
    --set vault.am_path="forgerock/data/fr7/identity-gateway" \
    --set ig.namespace="$NAMESPACE" \
    --set ig.env_type="$ENV_TYPE" \
    --set ig.lb_domain="$IG_LB_DOMAIN" \
    --set ig.routes="$IG_ROUTES" \
    --namespace "$NAMESPACE" \
    $PODNAME_IG child-images/ig/
  echo "-- Done"
  echo ""
fi
