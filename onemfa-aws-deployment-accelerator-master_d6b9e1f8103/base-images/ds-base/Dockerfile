# ===========================================================
# COPYRIGHT 2017 MIDSHIPS
# Do not distribute without permission and this
# file is only usable with a valid license.

# Docker file to build ForgeRock Directory Server Base Image.

# For more information visit www.midships.io

# Image name: forgerock-ds-base
# ===========================================================

ARG IMAGE_TAG="stable"
ARG IMAGE_SRC="gcr.io/massive-dynamo-235117/java-base"
FROM ${IMAGE_SRC}:${IMAGE_TAG}

# Arguments
# ---------

# Must be provided for sFTP access
ARG ftp_uname
ARG ftp_pword

# Defaults:
ARG cloud_type="ftp"
ARG ds_version=7.1.2
ARG ds_home=/opt/ds
ARG path_tmp=/tmp/ds
ARG STORAGE_BUCKET_PATH_BIN="ftp://ruhle.drayddns.com"
ARG filename_ds=DS-${ds_version}.zip

# Environment Variables
# ---------------------
ENV DS_HOME="${ds_home}" \
  	DS_APP="${ds_home}/app" \
    DS_INSTANCE="${ds_home}/app/instance" \
    DS_SCRIPTS="${ds_home}/scripts" \
    DS_SECRETS="${ds_home}/secrets" \
    DS_CONFIGMAPS="${ds_home}/configmaps" \
    DS_VERSION="${ds_version}" \
    OPENDJ_JAVA_HOME="${JAVA_HOME}" \
    IMAGE_NAME=forgerock-ds-base \
    AWS_ACCESS_KEY_ID=${aws_access_key_id} \
    AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}

# Setup default shell to Bash
# ---------------------------
SHELL ["/bin/bash", "-c"]

# Copy over scripts
# -----------------
COPY files/forgerock-ds-shared-functions.sh ${DS_SCRIPTS}/
COPY files/setup.sh ${path_tmp}/

# Required for GCP only
# COPY files/gcp-gcs-service-account.json ${path_tmp}/

# Setting up the image
# --------------------
RUN chmod +x ${path_tmp}/setup.sh
RUN chmod +x ${DS_SCRIPTS}/forgerock-ds-shared-functions.sh
RUN ${path_tmp}/setup.sh

EXPOSE 8443 1636 4444
