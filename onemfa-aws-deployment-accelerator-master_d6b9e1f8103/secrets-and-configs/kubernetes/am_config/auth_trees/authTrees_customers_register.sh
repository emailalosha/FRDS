#!/bin/bash
AM_URL=$1
AM_PWD=$2
COOKIE_NAME=$3
echo "01 ---- > AM_URL is ${AM_URL}"
echo "02 ---- > AM_PWD length is ${#AM_PWD}"
echo "03 ---- > COOKIE_NAME is ${COOKIE_NAME}"
#Generate random uids for nodes
INPUT_NODE_MAIL=$(uuidgen)
INPUT_NODE_PHONE=$(uuidgen)
INPUT_NODE_CUSTOMERID=$(uuidgen)
PAGE_NODE=$(uuidgen)
SEARCH_USER_NODE_MAIL=$(uuidgen)
SEARCH_USER_NODE_CUSTID=$(uuidgen)
SEARCH_USER_NODE_PHONE=$(uuidgen)
HOTP_GEN_NODE=$(uuidgen)
OTP_SEND_NODE=$(uuidgen)
OTP_COLLECTOR_NODE=$(uuidgen)
RETRY_NODE=$(uuidgen)
USER_REG_NODE=$(uuidgen)
ERROR_MSG_NODE_SEARCH=$(uuidgen)
ERROR_MSG_NODE_REG=$(uuidgen)
ERROR_MSG_NODE_OTP=$(uuidgen)
#FIXED VALUES FOR SUCCESS AND FAILED NODES
FAILURE_NODE=e301438c-0bd0-429c-ab0c-66126501069a
SUCCESS_NODE=70e691a5-1e33-4ac3-a356-e7b6d60d92e0
#Get admin token
tokenId=$(curl -s -k -X POST  ${AM_URL}/json/realms/root/authenticate  -H 'Accept-API-Version: resource=2.1' -H 'Content-Type: application/json' -H "X-OpenAM-Password: $AM_PWD" -H 'X-OpenAM-Username: amadmin' | jq '.tokenId' | tr -d \")
#InputCollectorNodes
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"useTransient":false,"variable":"email","prompt":"Email","isPassword":false,"_id":"'${INPUT_NODE_MAIL}'","_type":{"_id":"InputCollectorNode","name":"Input Collector Node"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/InputCollectorNode/${INPUT_NODE_MAIL}
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"useTransient":false,"variable":"telephoneNumber","prompt":"Phone Number","isPassword":false,"_id":"'${INPUT_NODE_PHONE}'","_type":{"_id":"InputCollectorNode","name":"Input Collector Node"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/InputCollectorNode/${INPUT_NODE_PHONE}
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"useTransient":false,"variable":"customerId","prompt":"Customer ID","isPassword":false,"_id":"'${INPUT_NODE_CUSTOMERID}'","_type":{"_id":"InputCollectorNode","name":"Input Collector Node"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/InputCollectorNode/${INPUT_NODE_CUSTOMERID}
#Page Node
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"_id":"'${PAGE_NODE}'","nodes":[{"_id":"'$INPUT_NODE_MAIL'","nodeType":"InputCollectorNode","displayName":"Input Collector Node"},{"_id":"'$INPUT_NODE_PHONE'","nodeType":"InputCollectorNode","displayName":"Input Collector Node"},{"_id":"'$INPUT_NODE_CUSTOMERID'","nodeType":"InputCollectorNode","displayName":"Input Collector Node"}],"_type":{"_id":"PageNode","name":"Page Node"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/PageNode/${PAGE_NODE}
#Search for User
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"datastoreAttributes":["mail"],"sharedStateAttribute":"email","_id":"'${SEARCH_USER_NODE_MAIL}'","_type":{"_id":"SearchForUserNode","name":"Search For User"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/SearchForUserNode/${SEARCH_USER_NODE_MAIL}
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"datastoreAttributes":["customerId"],"sharedStateAttribute":"customerId","_id":"'${SEARCH_USER_NODE_CUSTID}'","_type":{"_id":"SearchForUserNode","name":"Search For User"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/SearchForUserNode/${SEARCH_USER_NODE_CUSTID}
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"datastoreAttributes":["telephoneNumber"],"sharedStateAttribute":"telephoneNumber","_id":"'${SEARCH_USER_NODE_PHONE}'","_type":{"_id":"SearchForUserNode","name":"Search For User"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/SearchForUserNode/${SEARCH_USER_NODE_PHONE}
#HOTP Generator
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"length":6,"_id":"'$HOTP_GEN_NODE'","_type":{"_id":"OneTimePasswordGeneratorNode","name":"HOTP Generator"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/OneTimePasswordGeneratorNode/${HOTP_GEN_NODE}
#OTP SMS sender
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"APIUrl":"http://dev-tyk-elb-1740058556.ap-southeast-1.elb.amazonaws.com:8080/registrations/send-otp/sms","authorization":"5dbfcb5e1da99600012d6797739a683b47bf4c1b9b2e13b10465b22c","otpExpiry":5,"sharedStateAttribute":"telephoneNumber","_id":"'$OTP_SEND_NODE'","_type":{"_id":"SMSOTPNode","name":"SMS OTP "}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/SMSOTPNode/${OTP_SEND_NODE}
#OTP Collector
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"passwordExpiryTime":5,"_id":"'$OTP_COLLECTOR_NODE'","_type":{"_id":"OneTimePasswordCollectorDecisionNode","name":"OTP Collector Decision"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/OneTimePasswordCollectorDecisionNode/${OTP_COLLECTOR_NODE}
#Retry Limit
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"retryLimit":3,"_id":"'$RETRY_NODE'","_type":{"_id":"RetryLimitDecisionNode","name":"Retry Limit Decision"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/RetryLimitDecisionNode/${RETRY_NODE}
#Failure Message Nodes
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"_id":"'$ERROR_MSG_NODE_SEARCH'","UseSharedState":false,"FailureMessage":"FR-001","_type":{"_id":"FailureMessageAuthNode","name":"Failure Message Node"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/FailureMessageAuthNode/${ERROR_MSG_NODE_SEARCH}
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"_id":"'$ERROR_MSG_NODE_OTP'","UseSharedState":false,"FailureMessage":"FR-012","_type":{"_id":"FailureMessageAuthNode","name":"Failure Message Node"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/FailureMessageAuthNode/${ERROR_MSG_NODE_OTP}
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"_id":"'$ERROR_MSG_NODE_REG'","UseSharedState":false,"FailureMessage":"FR-004","_type":{"_id":"FailureMessageAuthNode","name":"Failure Message Node"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/FailureMessageAuthNode/${ERROR_MSG_NODE_REG}
#User reg nodes
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"_id":"'$USER_REG_NODE'","_type":{"_id":"UserRegistrationNode","name":"User registration"}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/nodes/UserRegistrationNode/${USER_REG_NODE}
#Post Auth Tree
curl -s -k -X PUT -H "${COOKIE_NAME}: ${tokenId}" -H "Content-Type: application/json" -H "Accept-API-Version: resource=1.0" -H "If-None-Match: *" -d '{"entryNodeId":"'$PAGE_NODE'","nodes":{"'$USER_REG_NODE'":{"displayName":"User registration","nodeType":"UserRegistrationNode","connections":{"failure":"'$ERROR_MSG_NODE_REG'","success":"'$SUCCESS_NODE'"}},"'$PAGE_NODE'":{"displayName":"Page Node","nodeType":"PageNode","connections":{"outcome":"'$SEARCH_USER_NODE_MAIL'"}},"'$HOTP_GEN_NODE'":{"displayName":"HOTP Generator","nodeType":"OneTimePasswordGeneratorNode","connections":{"outcome":"'$OTP_SEND_NODE'"}},"'$OTP_SEND_NODE'":{"displayName":"SMS OTP ","nodeType":"SMSOTPNode","connections":{"Success":"'$OTP_COLLECTOR_NODE'","Failure":"'$ERROR_MSG_NODE_OTP'"}},"'$OTP_COLLECTOR_NODE'":{"displayName":"OTP Collector Decision","nodeType":"OneTimePasswordCollectorDecisionNode","connections":{"true":"'$USER_REG_NODE'","false":"'$RETRY_NODE'"}},"'$RETRY_NODE'":{"displayName":"Retry Limit Decision","nodeType":"RetryLimitDecisionNode","connections":{"Retry":"'$HOTP_GEN_NODE'","Reject":"'$FAILURE_NODE'"}},"'$SEARCH_USER_NODE_MAIL'":{"displayName":"Search For User","nodeType":"SearchForUserNode","connections":{"notFound":"'$SEARCH_USER_NODE_PHONE'","ambiguous":"'$ERROR_MSG_NODE_SEARCH'","found":"'$ERROR_MSG_NODE_SEARCH'"}},"'$SEARCH_USER_NODE_PHONE'":{"displayName":"Search For User","nodeType":"SearchForUserNode","connections":{"notFound":"'$SEARCH_USER_NODE_CUSTID'","found":"'$ERROR_MSG_NODE_SEARCH'","ambiguous":"'$ERROR_MSG_NODE_SEARCH'"}},"'$SEARCH_USER_NODE_CUSTID'":{"displayName":"Search For User","nodeType":"SearchForUserNode","connections":{"found":"'$ERROR_MSG_NODE_SEARCH'","ambiguous":"'$ERROR_MSG_NODE_SEARCH'","notFound":"'$HOTP_GEN_NODE'"}},"'$ERROR_MSG_NODE_SEARCH'":{"displayName":"Failure Message Node","nodeType":"FailureMessageAuthNode","connections":{"outcome":"'$FAILURE_NODE'"}},"'$ERROR_MSG_NODE_REG'":{"displayName":"Failure Message Node","nodeType":"FailureMessageAuthNode","connections":{"outcome":"'$FAILURE_NODE'"}},"'$ERROR_MSG_NODE_OTP'":{"displayName":"Failure Message Node","nodeType":"FailureMessageAuthNode","connections":{"outcome":"'$FAILURE_NODE'"}}}}' ${AM_URL}/json/realms/root/realms/customers/realm-config/authentication/authenticationtrees/trees/register
