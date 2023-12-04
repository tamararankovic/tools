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
export AGENT_QUEUE_HOSTNAME=agent_queue

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

export VAULT_HTTP_PORT=8200
export VAULT_HOSTNAME=vault
export VAULT_DEV_ROOT_TOKEN_ID=hvs.QNCAfGkTP9ADGKceBd4da07k
export VAULT_ADDR=http://0.0.0.0

export CASSANDRA_DB=apollo
export CASSANDRA_HOSTNAME=cassandra
export CASSANDRA_DB_USERNAME=user
export CASSANDRA_DB_PASSWORD=apollo

export DB_PASSWORD=c12s_password
export DB_USERNAME=postgres
export DB_NAME=postgres
export DB_HOST=database

# stop node agents
docker rm $(docker stop $(docker ps -a -q --filter ancestor=star:latest --format="{{.ID}}"))
# stop the control plane
docker-compose down -v --remove-orphans