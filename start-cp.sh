# export configurable env vars
export $(grep -v '^#' .env | xargs -d '\n')

# export other env vars
export STAR_HOSTNAME=star
export MAGNETAR_HOSTNAME=magnetar
export KUIPER_HOSTNAME=kuiper
export OORT_HOSTNAME=oort
export NATS_HOSTNAME=nats
export ETCD_HOSTNAME=etcd
export IAM_HOSTNAME=iam-service
export BLACKHOLE_HOSTNAME=queue

export REGISTRATION_SUBJECT="register"
export NODE_ID_DIR_PATH="/etc/c12s"
export NODE_ID_FILE_NAME="nodeid"

export NEO4J_HOSTNAME=neo4j
export NEO4J_AUTH_ENABLED=false
export NEO4J_DBNAME=neo4j
export NEO4J_apoc_export_file_enabled=true
export NEO4J_apoc_import_file_enabled=true
export NEO4J_apoc_import_file_use__neo4j__config=true
export NEO4J_PLUGINS="[\"apoc\"]"

export VAULT_HOSTNAME=vault
export VAULT_DEV_ROOT_TOKEN_ID="hvs.AgFuGkVXvJFFg00PYpiXLyZX"

export DB_PASSWORD=c12s_password
export DB_USERNAME=postgres
export DB_NAME=postgres
export DB_HOST=database

# build contol plane's services
docker-compose build
# start the control plane
docker-compose up