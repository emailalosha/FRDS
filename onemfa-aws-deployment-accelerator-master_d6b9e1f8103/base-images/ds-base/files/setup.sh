#!/bin/bash
# =====================================================================
# MIDSHIPS
# COPYRIGHT 2020
# This file contains scripts to configure the base ForgeRock Directory
# Services (DS) image required by the Midships ForgeRock Accelerator.
#
# NOTE: Don't check this file into source control with
#       any sensitive hard coded vaules.
# ---------------------------------------------------------------------

source ${MIDSHIPS_SCRIPTS}/midshipscore.sh

installCloudClient ${cloud_type,,} ${path_tmp};
downloadPath_DS="${STORAGE_BUCKET_PATH_BIN}/forgerock/directory-services/${filename_ds}";

if [ -n "${downloadPath_DS}" ] && [ -n "${path_tmp}" ] && [ -n "${filename_ds}" ]; then
  if [ "${cloud_type,,}" = "gcp" ]; then
    echo "-> Downloading DS (${downloadPath_DS}) from GCP";
    gsutil cp ${downloadPath_DS} ${path_tmp}/${filename_ds};
  elif [ "${cloud_type,,}" = "aws" ]; then
    echo "-> Downloading DS (${downloadPath_DS}) from AWS";
    aws s3 cp ${downloadPath_DS} ${path_tmp}/${filename_ds};
  elif [ "${cloud_type,,}" = "ftp" ]; then
    echo "-> Downloading DS (${downloadPath_DS}) from FTP";
    if [ -n "${ftp_uname}" ] && [ -n "${ftp_pword}" ]; then
      curl -u ${ftp_uname}:${ftp_pword} "${downloadPath_DS}" -o "${path_tmp}/${filename_ds}"
    else
      echo "-- ERROR: Download SKIPPED due to missing parameters."
      echo "   Please correct and retry. Exiting ..."
      exit 1
    fi
  fi
  echo "-- Done";
  echo "";
else
  echo "-- ERROR: Required parameters NOT provided. Exiting ..."
  exit 1
fi

removeCloudClient ${cloud_type,,} ${path_tmp};

echo "-> Creating User and Group";
groupadd -g 10002 ds;
useradd -m -s /bin/nologin -m -d /home/ds -u 10002 -g 10002 ds
echo "-- Done";
echo "";

echo "-> Creating required folders";
mkdir -p ${DS_APP} ${DS_INSTANCE} ${DS_SCRIPTS} ${path_tmp}
echo "-- Done";
echo "";

echo "-> Copying DS setup files";
unzip ${path_tmp}/${filename_ds} -d ${DS_HOME}
echo "-- Done";
echo "";

echo "-> Creating 'setupFiles' folder";
mv -f "${DS_HOME}/opendj" "${DS_HOME}/setupFiles"
echo "-- Files in ${DS_HOME}/setupFiles"
ls -A "${DS_HOME}/setupFiles"
echo "-- Done";
echo "";

echo "-> Setting permission(s)";
chown -R ds:ds ${MIDSHIPS_SCRIPTS} ${DS_HOME} ${JAVA_CACERTS} ${path_tmp};
chmod -R u=rwx,g=rx,o=r ${DS_HOME}/setupFiles;
echo "-- Done";
echo "";

echo "-> Cleaning up";
rm -rf ${path_tmp};
echo "-- Done";
echo "";
