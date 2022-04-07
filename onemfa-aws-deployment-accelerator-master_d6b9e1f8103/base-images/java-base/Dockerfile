# ===============================================
# COPYRIGHT 2017 MIDSHIPS

# Do not distribute without permission and this
# file is only usable with a valid license.

# For more information visit www.midships.io

# Image name: java-base
# ===============================================

FROM debian:10.9-slim

# Arguments
# ---------

# Must be provided for sFTP access
ARG ftp_uname
ARG ftp_pword

# Defaults:
ARG cloud_type="ftp"
ARG STORAGE_BUCKET_PATH_BIN="ftp://ruhle.drayddns.com"
ARG path_tmp=/tmp/java
ARG midships_scripts_path="/opt/midships/scripts"
ARG java_version_major=11
ARG java_version_minor=11
ARG filename_java=jdk-${java_version_major}.0.${java_version_minor}_linux-x64_bin.tar.gz

# Environment Variables
# ---------------------
ENV JAVA_VERSION_MAJOR=${java_version_major} \
    JAVA_VERSION_MINOR=${java_version_minor} \
    MIDSHIPS_SCRIPTS=${midships_scripts_path} \
    AWS_ACCESS_KEY_ID=${aws_access_key_id} \
    AWS_SECRET_ACCESS_KEY=${aws_secret_access_key} \
    JVM_PATH=/usr/lib/jvm
ENV JAVA_HOME=${JVM_PATH}/jdk-${java_version_major}.0.${java_version_minor}
ENV PATH="$JAVA_HOME/bin:$PATH" \
    JAVA_CACERTS=${JAVA_HOME}/lib/security/cacerts

# Setup default shell to Bash
# ---------------------------
SHELL ["/bin/bash", "-c"]

# Copy required files
# -------------------
COPY files/midshipscore.sh ${MIDSHIPS_SCRIPTS}/
COPY files/setup.sh ${path_tmp}/

# Required for GCP only
# COPY files/gcp-gcs-service-account.json ${path_tmp}/

# Setting up the base image
# -------------------------
RUN chmod +x ${path_tmp}/setup.sh
RUN chmod +x ${MIDSHIPS_SCRIPTS}/midshipscore.sh
RUN ${path_tmp}/setup.sh

CMD ["java","-version"]
