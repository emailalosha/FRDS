#!/bin/bash
# =====================================================================
# MIDSHIPS
# COPYRIGHT 2020
# This file contains scripts to configure the ForgeRock Identity Manager
# (IDM) image required by the Midships ForgeRock Accelerator.
#
# NOTE: Don't check this file into source control with
#       any sensitive hard coded vaules.
# ---------------------------------------------------------------------

source "${MIDSHIPS_SCRIPTS}/midshipscore.sh"

echo "-> Checking key ENV Variables";
echo "-- IDM_HOME is ${IDM_HOME}"
echo "-- IDM_PROJECTS is ${IDM_PROJECTS}"
echo "-- STORAGE_BUCKET_PATH_BIN is ${STORAGE_BUCKET_PATH_BIN}"
echo "-- filename_idm is ${filename_idm}"
echo "-- path_tmp is ${path_tmp}"
echo "-- Done";
echo "";

echo "-> Creating required folders";
mkdir -p ${IDM_HOME}/scripts;
mkdir -p ${IDM_PROJECTS};
mkdir -p ${path_tmp};
echo "-- Done";
echo "";

installCloudClient ${cloud_type,,} ${path_tmp};
downloadPath_IDM="${STORAGE_BUCKET_PATH_BIN}/forgerock/idm/${filename_idm}";

if [ "${cloud_type,,}" = "gcp" ]; then
  echo "-> Downloading components from GCP storage bucket";
  gsutil cp "${downloadPath_IDM}" "${path_tmp}/${filename_idm}";
  echo "-- Done";
  echo "";
elif [ "${cloud_type,,}" = "aws" ]; then
  echo "-> Downloading components from AWS storage bucket";
  aws s3 cp "${downloadPath_IDM}" "${path_tmp}/${filename_idm}";
  echo "-- Done";
  echo "";
elif [ "${cloud_type,,}" = "ftp" ]; then
  echo "-> Downloading IDM (${downloadPath_IDM}) from sftp";
  if [ -n "${ftp_uname}" ] && [ -n "${ftp_pword}" ]; then
    curl -u ${ftp_uname}:${ftp_pword} "${downloadPath_IDM}" -o "${path_tmp}/${filename_idm}"
  else
    echo "-- ERROR: Download SKIPPED due to missing parameters."
    echo "   Please correct and retry. Exiting ..."
    exit 1
  fi
fi

removeCloudClient ${cloud_type,,} ${path_tmp};

echo "-> Creating User and Group";
groupadd -g 10002 idm;
useradd -s /bin/nologin -g idm -u 10002 -g 10002 -m -d /home/idm idm;
echo "-- Done";
echo "";

echo "-> Extracting IDM";
unzip "${path_tmp}/${filename_idm}" -d "${IDM_HOME}"
cp -R "${IDM_HOME}/openidm/." "${IDM_HOME}"
rm -rf "${IDM_HOME}/openidm"
echo "-- Done";
echo "";

echo "-> Setting permission(s)";
chown -R idm:idm "${IDM_HOME}" "${MIDSHIPS_SCRIPTS}" "${JAVA_CACERTS}" "${path_tmp}"
chmod -R u=rwx,g=rx,o=r "${IDM_HOME}" "${JAVA_CACERTS}";
echo "-- Done";
echo "";

echo "-> Cleaning up";
rm -rf "${path_tmp}";
echo "-- Done";
echo "";
