#!/usr/bin/env bash
# =====================================================================
# MIDSHIPS
# COPYRIGHT 2022
# This file contains scripts to be executed after creation of MIDSHIPS
# SECRETS MANAGEMENT Kubernetes solution required by Midships Ready To
# Integrate (RTI) solution.
#
# NOTE: Don't check this file into source control with
#       any sensitive hard coded vaules.
#
# Legal Notice: Installation and use of this script is subject to 
# a license agreement with Midships Limited (a company registered 
# in England, under company registration number: 11324587).
# This script cannot be modified or shared with another organisation 
# unless approved in writing by Midships Limited.
# You as a user of this script must review, accept and comply with the 
# license terms of each downloaded/installed package that is referenced 
# by this script. By proceeding with the installation, you are accepting 
# the license terms of each package, and acknowledging that your use of 
# each package will be subject to its respective license terms.
# =====================================================================
set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace # May leak secrets so only enable for debugging

function usage() {
  cat <<EOF >&2
usage: generate-certs.sh  [OPTIONS]

Generates self-signed certificates for use in the Forgerock application for Mutual TLS connections between components.
Certificates will dumped into a sub-directory of the script location called 'generated-certs/' with a sub-directory
for each component, am-cert, us-cert etc.

For every component, a certificate file, a key file and a certificate details file will be generated.

The certificate can be loaded into the trust store of an application that needs to trust that application and the
application itself.

The key file should only be loaded into the component it was created for - it is secret to that application.

The certificate details file is used to create the Certificate Signing Request and is retained for information only.

Certificate Common Names have a hard limit of 64 characters, so if we are generating certificates for branches that
have very long DNS entries, the certificate request will be modified so that the namespace name provided will be used
as a Common Name, and the long DNS entry will be added as a Subject Alternative Name.  Therefore the namespace name is
required to support this logic.

OPTIONS
    -ns1 "namespace-name", --namespace-name-1 "namespace-name"
        The namespace name for the first cluster use in the Common Name if the FQDN of access manager is more than 64 bytes.  Will
        be used automatically in this case.
        Required

    -ns2 "namespace-name", --namespace-name-2 "namespace-name"
        The namespace name for the second cluster use in the Common Name if the FQDN of access manager is more than 64 bytes.  Will
        be used automatically in this case.
        Required

    -amfqdn1 "access-manager-fully-qualified-domain-name", --access-manager-fqdn "access-manager-fully-qualified-domain-name"
        The fully qualified domain name of the first cluster access manager component -
          e.g. am.client.name.com
        Required
    
    -amfqdn2 "access-manager-fully-qualified-domain-name", --access-manager-fqdn "access-manager-fully-qualified-domain-name"
        The fully qualified domain name of the first cluster access manager component -
          e.g. am.client.name.com
        Required

    -svcAM "service-name-access-manager"
        The service name of the access manager component -
          e.g. forgerock-access-manager
        Required

    -svcCS "service-name-config-store"
        The service name of the config store component -
          e.g. forgerock-config-store
        Required

    -svcCS "service-name-user-store"
        The service name of the config store component -
          e.g. forgerock-config-store
        Required

    -svcCS "service-name-token-store"
        The service name of the config store component -
          e.g. forgerock-config-store
        Required

    -svcCS "service-name-relication-server"
        The service name of the config store component -
          e.g. forgerock-config-store
        Required

    -svcIG "service-name-identity-gateway"
        The service name of the identity gateway component -
          e.g. forgerock-identity-gateway
        Required

    -svcIDM "service-name-identity-manager"
        The service name of the identity manager component -
          e.g. forgerock-identity-manager
        Required

EOF
[[ -n "$*" ]] && echo "ERROR: $*" >&2
exit 1
}

fqdn_AM_1=
fqdn_AM_2=
namespace_name_1=
namespace_name_2=
svc_AM=
svc_US=
svc_TS=
svc_CS=
svc_RS=
svc_IG=
svc_IDM=
script_dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
certsLocation="${script_dir}/generated-certs"

while [[ $# -gt 0 ]]
  do
    case "$1" in
      ( -h | --help )
        usage
        ;;
      ( -amfqdn1 | --access-manager-fqdn-1 )
        fqdn_AM_1="$2"
        shift 2
        ;;
      ( -amfqdn2 | --access-manager-fqdn-2 )
        fqdn_AM_2="$2"
        shift 2
        ;;
      ( -ns1 | --namespace-name-1 )
        namespace_name_1="$2"
        shift 2
        ;;
      ( -ns2 | --namespace-name-2 )
        namespace_name_2="$2"
        shift 2
        ;;
      ( -svcAM | --service-access-manager )
        svc_AM="$2"
        shift 2
        ;;
      ( -svcUS | --service-user-store )
        svc_US="$2"
        shift 2
        ;;
      ( -svcTS | --service-token-store )
        svc_TS="$2"
        shift 2
        ;;
      ( -svcCS | --service-config-store )
        svc_CS="$2"
        shift 2
        ;;
      ( -svcRS | --service-replication-server )
        svc_RS="$2"
        shift 2
        ;;
      ( -svcIDM | --service-identity-manager )
        svc_IDM="$2"
        shift 2
        ;;
      ( -svcIG | --service-identity-gateway )
        svc_IG="$2"
        shift 2
        ;;
      *)
        usage "Unknown option passed in"
        ;;
    esac
  done

if [ -z "${fqdn_AM_1}" ]; then
  usage "Required option 'access-manager-fully-qualified-domain-name' is Empty"
fi

if [ -z "${namespace_name_1}" ]; then
  usage "Required option 'namespace-name' is Empty"
fi

createSelfSignedCert () {
  echo "> Entered createSelfSignedCert ()"
  echo ""
  if [ -z "${1+x}" ]; then
    echo "-- {1} is Empty. This should be Certificate Name"
    "${1}"="certName"
    echo "-- {1} Set to ${1}"
    echo ""
  fi

  if [ -z "${2+x}" ]; then
    echo "-- {2} is Empty. This should be Certificate save folder location"
    "${2}"="generated-certs/"
    echo "-- {2} Set to ${2}"
    echo ""
  fi

  if [ -z "${3+x}" ]; then
    echo "-- {3} is Empty. This should be FQDN to be used as Certificate CN (Common Name)"
    echo "-- Exiting ..."
    echo ""
    exit
  fi

  if [ -z "${4+x}" ]; then
    echo "-- {3} is Empty. This should be FQDN to be used as SAN (Subject Alternative Names)"
    echo "-- Exiting ..."
    echo ""
    exit
  fi

  if [ -z "${5+x}" ];then
    echo "-- {5} is Empty. This should be additional FQDN to be used as SAN (Subject Alternative Names)"
    fqdnSAN2="localhost"
    echo "-- {5} Set to ${fqdnSAN2}"
    echo ""
  else 
    fqdnSAN2=${5}
  fi

  if [ -z ${6+x} ]; then
    echo "-- {6} is Empty. This should be additional FQDN to be used as SAN (Subject Alternative Names)"
    fqdnSAN3="ignore"
    echo "-- {6} Set to ${fqdnSAN3}"
    echo ""
  else 
    fqdnSAN3=${6}
  fi

  certName=${1}
  certCN=${3}
  fqdnSAN=${4}

  certSaveFolder="${2}"

  if [ -f "${certSaveFolder}/certdetails.txt" ]; then
    echo "-- Deleting existing file '${certSaveFolder}/certdetails.txt'"
    rm "${certSaveFolder}/certdetails.txt"
    echo "-- Done"
    echo ""
  fi

  echo "-- Creating certificate"
  echo ""
  mkdir -p "${certSaveFolder}"

# Creating self signed cert details file
cat << EOF >> "${certSaveFolder}/certdetails.txt"
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[dn]
C = UK
ST = London
L = London
O = Midships
OU = Midships
emailAddress = admin@Midships.io
CN = ${certCN}

[req_ext]
subjectAltName = @otherCNs

[otherCNs]
DNS.1 = ${fqdnSAN}
DNS.2 = *.${fqdnSAN}
DNS.3 = ${certCN}
DNS.4 = *.${certCN}
DNS.5 = *.${certCN#*.}
DNS.6 = ${fqdnSAN2}
DNS.7 = *.${fqdnSAN2}

EOF

cat << EOF >> "${certSaveFolder}/certdetails_type2.txt"
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[dn]
C = UK
ST = London
L = London
O = Midships
OU = Midships
emailAddress = admin@Midships.io
CN = ${certCN}

[req_ext]
subjectAltName = @otherCNs

[otherCNs]
DNS.1 = ${fqdnSAN}
DNS.2 = *.${fqdnSAN}
DNS.3 = ${certCN}
DNS.4 = *.${certCN}
DNS.5 = *.${certCN#*.}
DNS.6 = ${fqdnSAN2}
DNS.7 = *.${fqdnSAN2}
DNS.8 = ${fqdnSAN3}
DNS.9 = *.${fqdnSAN3}

EOF
  echo "-- Cert created at ${certSaveFolder}"
  echo ""
  echo "-- Cert details:"
  cat "${certSaveFolder}/certdetails.txt"
  echo ""

  if [ -f "${certSaveFolder}/${certName}.pem" ]; then
    echo "-- Deleting existing file '${certSaveFolder}/${certName}.pem'"
    rm -f "${certSaveFolder}/${certName}.pem"
    echo "-- Done"
    echo ""
  fi
  if [ -f "${certSaveFolder}/${certName}-key.pem" ]; then
    echo "-- Deleting existing file '${certSaveFolder}/${certName}-key.pem'"
    rm -f "${certSaveFolder}/${certName}-key.pem"
    echo "-- Done"
    echo ""
  fi

  # Create a Private Key and Certificate Signing Request
#   openssl req \
#     -newkey rsa:2048 \
#     -nodes \
#     -subj "/CN=${certCN}" \
#     -extensions req_ext \
#     -config <( cat "${certSaveFolder}/certdetails.txt" ) \
#     -keyout "${certSaveFolder}/${certName}-key.pem" \
#     -out  "${certSaveFolder}/${certName}-csr.pem"

#   # Create a signed Cert
#   openssl x509 -req \
#     -in "${certSaveFolder}/${certName}-csr.pem" \
#     -CA "${script_dir}/certs/test_ca_cert.pem" -CAkey "${script_dir}/certs/test_ca_cert.key" \
#     -CAcreateserial \
#     -out "${certSaveFolder}/${certName}.pem" \
#     -days 365 \
#     -extfile <(echo "subjectAltName = DNS:${fqdnSAN},DNS:*.${svcSAN},DNS:${svcSAN},DNS:localhost") \
#     -sha256

  if [ "${fqdnSAN3,,}" == "ignore" ];then
    openssl req -newkey rsa:2048 -nodes -keyout "${certSaveFolder}/${certName}-key.pem" -x509 -days 1095 -out "${certSaveFolder}/${certName}.pem" -extensions req_ext -config <( cat "${certSaveFolder}/certdetails.txt" )
    rm "${certSaveFolder}/certdetails_type2.txt"
  else
    openssl req -newkey rsa:2048 -nodes -keyout "${certSaveFolder}/${certName}-key.pem" -x509 -days 1095 -out "${certSaveFolder}/${certName}.pem" -extensions req_ext -config <( cat "${certSaveFolder}/certdetails_type2.txt" )
    rm "${certSaveFolder}/certdetails.txt"
  fi
  cat "${certSaveFolder}/${certName}.pem" | base64 -w 0 > "${certSaveFolder}/${certName}"
  cat "${certSaveFolder}/${certName}-key.pem" | base64 -w 0 > "${certSaveFolder}/${certName}-key"
  echo "-- Exiting function"
  echo ""
}

amCertFolder="${certsLocation}/am-cert"
createSelfSignedCert "access-manager" "${amCertFolder}" "${fqdn_AM_1}" "${svc_AM}.${namespace_name_1}.svc.cluster.local" "${svc_AM}.${namespace_name_2}.svc.cluster.local" "${fqdn_AM_2}"

echo "-- Done"
printf "\n\n\n\n\n\n\n\n"

echo "-> Generating Access Manager(AM) Keystore Certificates"
echo "-- es256test ..."
rootSection="es256test"
openssl req -x509 -nodes -days 1095 -sha1 -newkey ec:<(openssl ecparam -name prime256v1) -keyout "${amCertFolder}/${rootSection}-key.pem" -out "${amCertFolder}/${rootSection}.pem" -subj "/C=GB/ST=London/L=London/O=Midships/OU=IT Department/CN=${rootSection}"
echo "-- es384test ..."
rootSection="es384test"
openssl req -x509 -nodes -days 1095 -sha1 -newkey ec:<(openssl ecparam -name secp384r1) -keyout "${amCertFolder}/${rootSection}-key.pem" -out "${amCertFolder}/${rootSection}.pem" -subj "/C=GB/ST=London/L=London/O=Midships/OU=IT Department/CN=${rootSection}"
echo "-- es512test ..."
rootSection="es512test"
openssl req -x509 -nodes -days 1095 -sha1 -newkey ec:<(openssl ecparam -name secp521r1) -keyout "${amCertFolder}/${rootSection}-key.pem" -out "${amCertFolder}/${rootSection}.pem" -subj "/C=GB/ST=London/L=London/O=Midships/OU=IT Department/CN=${rootSection}"
echo "-- selfserviceenc ..."
rootSection="selfserviceenc"
openssl req -x509 -nodes -days 1095 -new -newkey rsa:2048 -sha256 -out selfserviceenc.pem -keyout "${amCertFolder}/${rootSection}-key.pem" -out "${amCertFolder}/${rootSection}.pem" -subj "/C=GB/ST=London/L=London/O=Midships/OU=IT Department/CN=${rootSection}"
echo "-- rsajwtsign ..."
rootSection="rsajwtsign"
openssl req -x509 -nodes -days 1095 -new -newkey rsa:2048 -sha256 -out rsajwtsign.pem -keyout "${amCertFolder}/${rootSection}-key.pem" -out "${amCertFolder}/${rootSection}.pem" -subj "/C=GB/ST=London/L=London/O=Midships/OU=IT Department/CN=${rootSection}"
echo "-- general ..."
rootSection="general"
openssl req -x509 -nodes -days 1095 -new -newkey rsa:2048 -sha256 -out test.pem -keyout "${amCertFolder}/${rootSection}-key.pem" -out "${amCertFolder}/${rootSection}.pem" -subj "/C=GB/ST=London/L=London/O=Midships/OU=IT Department/CN=${rootSection}"
echo "-- test ..."
rootSection="test"
openssl req -x509 -nodes -days 1095 -new -newkey rsa:2048 -sha256 -out test.pem -keyout "${amCertFolder}/${rootSection}-key.pem" -out "${amCertFolder}/${rootSection}.pem" -subj "/C=GB/ST=London/L=London/O=Midships/OU=IT Department/CN=${rootSection}"
echo "-- Done"
printf "\n\n\n\n\n\n\n\n"
echo ""

echo "-> Creating Config Store Certs"
createSelfSignedCert "config-store" "${certsLocation}/cs-cert" "${svc_CS}.${namespace_name_1}.svc.cluster.local" \
  "${svc_CS}.${namespace_name_2}.svc.cluster.local"
echo "-- Done"
printf "\n\n\n\n\n\n\n\n"

echo "-> Creating Replication Server Certs"
createSelfSignedCert "repl-server" "${certsLocation}/rs-cert-1" "${svc_RS}.${namespace_name_1}.svc.cluster.local" \
   "${svc_RS}.${namespace_name_2}.svc.cluster.local"
createSelfSignedCert "repl-server" "${certsLocation}/rs-cert-2" "${svc_RS}.${namespace_name_2}.svc.cluster.local" \
  "${svc_RS}.${namespace_name_1}.svc.cluster.local"
echo "-- Done"
printf "\n\n\n\n\n\n\n\n"

echo "-> Creating Token Store Certs"
createSelfSignedCert "token-store" "${certsLocation}/ts-cert" "${svc_TS}.${namespace_name_1}.svc.cluster.local" \
 "${svc_TS}.${namespace_name_2}.svc.cluster.local"
echo "-- Done"
printf "\n\n\n\n\n\n\n\n"

echo "-> Creating User Store Certs"
createSelfSignedCert "user-store" "${certsLocation}/us-cert" "${svc_US}.${namespace_name_1}.svc.cluster.local" \
  "${svc_US}.${namespace_name_2}.svc.cluster.local"
echo "-- Done"
printf "\n\n\n\n\n\n\n\n"

echo "-> Creating Identity Gateway Certs"
createSelfSignedCert "identity-gateway" "${certsLocation}/ig-cert" "${svc_IG}.${namespace_name_1}.svc.cluster.local" \
  "${svc_IG}.${namespace_name_2}.svc.cluster.local"
echo "-- Done"
printf "\n\n\n\n\n\n\n\n"

echo "-> Creating Identity Manager Certs"
createSelfSignedCert "identity-manager" "${certsLocation}/idm-cert" "${svc_IDM}.${namespace_name_1}.svc.cluster.local" \
  "${svc_IDM}.${namespace_name_2}.svc.cluster.local"
echo "-- Done"
printf "\n\n\n\n\n\n\n\n"
