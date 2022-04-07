# ===========================================================
# COPYRIGHT 2017 MIDSHIPS
# Do not distribute without permission and this
# file is only usable with a valid license.

# Docker file to build ForgeRock Replication Server Directory
# Server (DS) container image.

# For more information visit www.midships.io

# Image recommended name:
#  - forgerock-repl-server-us for replicating user stores
#  - forgerock-repl-server-ts for replicating token stores
# ===========================================================

ARG IMAGE_TAG="stable"
ARG IMAGE_SRC="gcr.io/massive-dynamo-235117/forgerock-ds-base"
FROM ${IMAGE_SRC}:${IMAGE_TAG}

# Setup configuration scripts
# ---------------------------
COPY files/*.sh ${DS_SCRIPTS}/

ENTRYPOINT ["bash", "/opt/ds/scripts/init.sh"]
