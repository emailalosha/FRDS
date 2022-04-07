#!/bin/bash
AM_URL=$1
AM_PWD=$2
COOKIE_NAME=$3
#Generate random uids for nodes
USERNAME_COLLECTOR=$(uuidgen)
SEARCH_USER_NODE=$(uuidgen)
PAGE_NODE_1=$(uuidgen)
INPUT_COLLECTOR_DEVICE_INFO=$(uuidgen)
INPUT_COLLECTOR_BENEFICIARY=$(uuidgen)
INPUT_COLLECTOR_SIGNED_DEVICEID=$(uuidgen)
ERROR_MSG_NODE_1=$(uuidgen)
ERROR_MSG_NODE_2=$(uuidgen)
ERROR_MSG_NODE_3=$(uuidgen)
ERROR_MSG_NODE_4=$(uuidgen)
LOGIN_NODE=$(uuidgen)
#FIXED VALUES FOR SUCCESS AND FAILED NODES
SUCCESS="70e691a5-1e33-4ac3-a356-e7b6d60d92e0"
FAILURE="e301438c-0bd0-429c-ab0c-66126501069a"
#Get admin token
tokenId=$(curl -s -k -X POST  ${AM_URL}/json/realms/root/authenticate  -H 'Accept-API-Version: resource=2.1' -H 'Content-Type: application/json' -H "X-OpenAM-Password: $AM_PWD" -H 'X-OpenAM-Username: amadmin' | jq '.tokenId' | tr -d \")
#Input collectors
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"useTransient":false,"variable":"username","prompt":"Email/PhoneNumber/username/customerId","isPassword":false,"_id":"'${USERNAME_COLLECTOR}'","_type":{"_id":"InputCollectorNode","name":"Input Collector Node"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/InputCollectorNode/${USERNAME_COLLECTOR}
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"useTransient":false,"variable":"device_info","prompt":"Device info (JSON)","isPassword":false,"_id":"'${INPUT_COLLECTOR_DEVICE_INFO}'","_type":{"_id":"InputCollectorNode","name":"Input Collector Node"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/InputCollectorNode/${INPUT_COLLECTOR_DEVICE_INFO}
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"useTransient":false,"variable":"signed_deviceId","prompt":"Signed DeviceId","isPassword":false,"_id":"'${INPUT_COLLECTOR_SIGNED_DEVICEID}'","_type":{"_id":"InputCollectorNode","name":"Input Collector Node"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/InputCollectorNode/${INPUT_COLLECTOR_SIGNED_DEVICEID}
#Failure message Nodes
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"_id":"'$ERROR_MSG_NODE_1'","UseSharedState":false,"FailureMessage":"FR-006","_type":{"_id":"FailureMessageAuthNode","name":"Failure Message Node"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/FailureMessageAuthNode/${ERROR_MSG_NODE_1}
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"_id":"'$ERROR_MSG_NODE_2'","UseSharedState":false,"FailureMessage":"FR-018","_type":{"_id":"FailureMessageAuthNode","name":"Failure Message Node"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/FailureMessageAuthNode/${ERROR_MSG_NODE_2}
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"_id":"'$ERROR_MSG_NODE_3'","UseSharedState":false,"FailureMessage":"FR-017","_type":{"_id":"FailureMessageAuthNode","name":"Failure Message Node"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/FailureMessageAuthNode/${ERROR_MSG_NODE_3}
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"_id":"'$ERROR_MSG_NODE_4'","UseSharedState":false,"FailureMessage":"FR-019","_type":{"_id":"FailureMessageAuthNode","name":"Failure Message Node"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/FailureMessageAuthNode/${ERROR_MSG_NODE_4}
#Search user
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"sharedStateAttribute":"username","datastoreAttributes":["mail","telephoneNumber","uid","customerId"],"_id":"'$SEARCH_USER_NODE'","_type":{"_id":"SearchForUserNode","name":"Search For User"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/SearchForUserNode/${SEARCH_USER_NODE}
#Page nodes
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"_id":"'${PAGE_NODE_1}'","nodes":[{"_id":"'$INPUT_COLLECTOR_DEVICE_INFO'","nodeType":"InputCollectorNode","displayName":"Input Collector Node"},{"_id":"'$INPUT_COLLECTOR_SIGNED_DEVICEID'","nodeType":"InputCollectorNode","displayName":"Input Collector Node"}],"_type":{"_id":"PageNode","name":"Page Node"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/PageNode/${PAGE_NODE_1}
#Login node
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"_id":"'${LOGIN_NODE}'","deviceAttr":"device","uniqueIdAttr":"DeviceId","publicKeyAttr":"public_key","signingAlgorithm":"SHA256withRSA","sharedStateDeviceAttr":"device_info","sharedStateSignedDeviceIdChallenge":"signed_deviceId","algorithm":"RSA","_type":{"_id":"LoginAuthenticationNode","name":"Device login authentication"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/LoginAuthenticationNode/${LOGIN_NODE}
#Post Auth Tree
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"entryNodeId":"'$USERNAME_COLLECTOR'","nodes":{"'$SEARCH_USER_NODE'":{"displayName":"Search For User","nodeType":"SearchForUserNode","connections":{"notFound":"'$ERROR_MSG_NODE_1'","ambiguous":"'$ERROR_MSG_NODE_1'","found":"'$PAGE_NODE_1'"}},"'$LOGIN_NODE'":{"displayName":"Device login authentication","nodeType":"LoginAuthenticationNode","connections":{"no_device_match":"'$ERROR_MSG_NODE_3'","error":"'$ERROR_MSG_NODE_2'","failure":"'$ERROR_MSG_NODE_4'","success":"'$SUCCESS'"}},"'$PAGE_NODE_1'":{"displayName":"Page Node","nodeType":"PageNode","connections":{"outcome":"'$LOGIN_NODE'"}},"'$ERROR_MSG_NODE_3'":{"displayName":"Failure Message Node","nodeType":"FailureMessageAuthNode","connections":{"outcome":"'$FAILURE'"}},"'$ERROR_MSG_NODE_2'":{"displayName":"Failure Message Node","nodeType":"FailureMessageAuthNode","connections":{"outcome":"'$FAILURE'"}},"'$ERROR_MSG_NODE_4'":{"displayName":"Failure Message Node","nodeType":"FailureMessageAuthNode","connections":{"outcome":"'$FAILURE'"}},"'$USERNAME_COLLECTOR'":{"displayName":"Input Collector Node","nodeType":"InputCollectorNode","connections":{"outcome":"'$SEARCH_USER_NODE'"}},"'$ERROR_MSG_NODE_1'":{"displayName":"Failure Message Node","nodeType":"FailureMessageAuthNode","connections":{"outcome":"'$FAILURE'"}}}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/trees/login_tree
