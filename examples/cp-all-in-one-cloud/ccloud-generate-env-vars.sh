#!/bin/bash

###############################################################################
# Overview:
# This code reads the Confluent Cloud configuration in $HOME/.ccloud/config
# and writes the ENV variables used by Docker Compose to a file called 'delta_configs/env.delta'
#
# Reference: https://github.com/confluentinc/quickstart-demos/blob/5.0.0-post/ccloud/ccloud-generate-cp-configs.sh
#
###############################################################################


# Confluent Cloud configuration
CCLOUD_CONFIG=$HOME/.ccloud/config
if [[ ! -e $CCLOUD_CONFIG ]]; then
  echo "'ccloud' is not initialized. Run 'ccloud init' and try again"
  exit 1
fi
PERM=$(stat -c "%a" $HOME/.ccloud/config)

### Glean BOOTSTRAP_SERVERS and SASL_JAAS_CONFIG (key and password) from the Confluent Cloud configuration file
BOOTSTRAP_SERVERS=$( grep "^bootstrap.server" $CCLOUD_CONFIG | awk -F'=' '{print $2;}' )
BOOTSTRAP_SERVERS=${BOOTSTRAP_SERVERS/\\/}
SR_BOOTSTRAP_SERVERS="SASL_SSL://${BOOTSTRAP_SERVERS}"
SR_BOOTSTRAP_SERVERS=${SR_BOOTSTRAP_SERVERS//,/,SASL_SSL:\/\/}
SR_BOOTSTRAP_SERVERS=${SR_BOOTSTRAP_SERVERS/\\/}
SASL_JAAS_CONFIG=$( grep "^sasl.jaas.config" $CCLOUD_CONFIG | cut -d'=' -f2- )
CLOUD_KEY=$( echo $SASL_JAAS_CONFIG | awk '{print $3}' | awk -F'"' '$0=$2' )
CLOUD_SECRET=$( echo $SASL_JAAS_CONFIG | awk '{print $4}' | awk -F'"' '$0=$2' )
#echo "bootstrap.servers: $BOOTSTRAP_SERVERS"
#echo "sasl.jaas.config: $SASL_JAAS_CONFIG"
#echo "key: $CLOUD_KEY"
#echo "secret: $CLOUD_SECRET"

# Destination directory
if [[ ! -z "$1" ]]; then
  DEST=$1
else
  DEST="delta_configs"
fi
rm -fr $DEST
mkdir -p $DEST

REPLICATOR_SASL_JAAS_CONFIG=$SASL_JAAS_CONFIG
REPLICATOR_SASL_JAAS_CONFIG=${REPLICATOR_SASL_JAAS_CONFIG//\\=/=}
REPLICATOR_SASL_JAAS_CONFIG=${REPLICATOR_SASL_JAAS_CONFIG//\"/\\\"}

ENV_CONFIG=$DEST/env.delta
echo "$ENV_CONFIG"

cat <<EOF >> $ENV_CONFIG
export BOOTSTRAP_SERVERS='$BOOTSTRAP_SERVERS'
export SASL_JAAS_CONFIG='$SASL_JAAS_CONFIG'
export SR_BOOTSTRAP_SERVERS='$SR_BOOTSTRAP_SERVERS'
export REPLICATOR_SASL_JAAS_CONFIG='$REPLICATOR_SASL_JAAS_CONFIG'
EOF
chmod $PERM $ENV_CONFIG
