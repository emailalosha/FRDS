# ===========================================================
# COPYRIGHT 2017 MIDSHIPS
# Do not distribute without permission and this
# file is only usable with a valid license.

# Docker file to build ForgeRock User Store Directory Server
# container image.

# For more information visit www.midships.io

# Image recommended name: forgerock-user-store
# ===========================================================

ARG IMAGE_TAG="stable"
ARG IMAGE_SRC="gcr.io/massive-dynamo-235117/forgerock-ds-base"
FROM ${IMAGE_SRC}:${IMAGE_TAG}

# Setup configuration scripts
# ---------------------------
COPY files/*.sh ${DS_SCRIPTS}/

ENTRYPOINT ["bash", "/opt/ds/scripts/init.sh"]
