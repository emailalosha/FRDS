#!/bin/bash
# =====================================================================
# MIDSHIPS
# COPYRIGHT 2020
# This file contains scripts to configure the base Java image required
# by the Midships ForgeRock Accelerator solution.
#
# NOTE: Don't check this file into source control with
#       any sensitive hard coded vaules.
# ---------------------------------------------------------------------

source ${MIDSHIPS_SCRIPTS}/midshipscore.sh;

echo "-> Creating required folders";
mkdir -p ${MIDSHIPS_SCRIPTS} ${path_tmp} ${JVM_PATH}
echo "-- Done";
echo "";

echo "-> Key Variables";
echo "PATH is $PATH"
echo "JAVA_HOME is $JAVA_HOME"
echo "-- Done";
echo "";

echo "-> Updating all installed packages on OS";
apt-get -y update
echo "-- Done";
echo "";

echo "-> Installing required tools";
apt-get -y install openssl openssh-server curl unzip jq sed iputils-ping uuid-runtime;
echo "-- Done";
echo "";

echo "-> Making copied scripts executable";
chmod 751 ${MIDSHIPS_SCRIPTS}/*.sh ${path_tmp}/*.sh;
echo "-- Done";
echo "";

installCloudClient ${cloud_type,,} ${path_tmp};
downloadPath_JDK="${STORAGE_BUCKET_PATH_BIN}/oracle/jdk/${filename_java}";

if [ -n "${downloadPath_JDK}" ] && [ -n "${path_tmp}" ] && [ -n "${filename_java}" ]; then
  if [ "${cloud_type,,}" = "gcp" ]; then
    echo "-> Downloading JDK (${downloadPath_JDK}) from GCP";
    gsutil cp "${downloadPath_JDK}" "${path_tmp}/${filename_java}";
    echo "-- Done";
    echo "";
  elif [ "${cloud_type,,}" = "aws" ]; then
    echo "-> Downloading JDK (${downloadPath_JDK}) from AWS";
    aws s3 cp "${downloadPath_JDK}" "${path_tmp}/${filename_java}";
    echo "-- Done";
    echo "";
  elif [ "${cloud_type,,}" = "ftp" ]; then
    echo "-> Downloading JDK (${downloadPath_JDK}) from FTP";
    if [ -n "${ftp_uname}" ] && [ -n "${ftp_pword}" ]; then
      curl -u ${ftp_uname}:${ftp_pword} "${downloadPath_JDK}" -o "${path_tmp}/${filename_java}"
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

echo "-> Installing Java";
tar -xf ${path_tmp}/${filename_java} -C ${JVM_PATH}/
echo "-- Done";
echo "";

echo "-> Checking Java";
echo "-- JAVA_HOME is set to ${JAVA_HOME}";
java -version;
echo "-- Done";
echo ""

if (( ${JAVA_VERSION_MAJOR} <= 8 )); then
  echo "-> Removing vulnerable jetty-server (v8.1.14) to resolve CVE-2017-7657";
  find  ${JAVA_HOME}/lib/missioncontrol/plugins/ -name 'org.eclipse.jetty.*' -exec rm {} \;
  echo "-- Done";
  echo "";
fi

echo "-> Cleaning up";
rm -rf ${path_tmp};
echo "-- Done";
echo "";
