# export configurable env vars
#export $(grep -v '^#' .env | xargs -d '\n')
export $(grep -v '^#' .env | gxargs -d '\n')

# export other env vars
export STAR_HOSTNAME=star
export MAGNETAR_HOSTNAME=magnetar
export KUIPER_HOSTNAME=kuiper
export OORT_HOSTNAME=oort
export NATS_HOSTNAME=nats
export ETCD_HOSTNAME=etcd
export IAM_HOSTNAME=iam-service
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

# # build contol plane's services
docker-compose build --no-cache
#docker-compose build
# # start the control plane
docker-compose up -d

# cassandra init
CONTAINER_NAME="cassandra"
while true; do
    # Get the health status of the container
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME)

    # Check if the container is healthy
    if [ "$HEALTH" = "healthy" ]; then
        echo "Container is healthy, running additional script"
        docker exec -it cassandra /bin/sh -c "cqlsh -f /schema.cql"
        break  # Exit the loop when the container is healthy
    else
        echo "Cassandra is not healthy, waiting for 5 seconds before checking again"
        sleep 5
    fi
done

# export other env vars
export STAR_HOSTNAME=star
export OORT_HOSTNAME=oort
export NATS_HOSTNAME=nats

export REGISTRATION_SUBJECT="register"
export NODE_ID_DIR_PATH="/etc/c12s"
export NODE_ID_FILE_NAME="nodeid"

# build the node agent
docker build -f ../star/Dockerfile .. -t star
# start node agents
echo y | rm -r "$(pwd)"/nodeconfig
mkdir "$(pwd)"/nodeconfig
for ((i=1; i<=$NODES_NUM; i++)); do
    echo $i
    mkdir "$(pwd)"/nodeconfig/star_"$i"
    docker run -d --name star_"$i" \
    --mount type=bind,source="$(pwd)"/nodeconfig/star_"$i",target="$NODE_ID_DIR_PATH" \
    --env STAR_ADDRESS=:${STAR_PORT} \
    --env OORT_ADDRESS=${OORT_HOSTNAME}:${OORT_PORT} \
    --env NATS_ADDRESS=${NATS_HOSTNAME}:${NATS_PORT} \
    --env REGISTRATION_REQ_TIMEOUT_MILLISECONDS=${REGISTRATION_REQ_TIMEOUT_MILLISECONDS} \
    --env MAX_REGISTRATION_RETRIES=${MAX_REGISTRATION_RETRIES} \
    --env NODE_ID_DIR_PATH=${NODE_ID_DIR_PATH} \
    --env NODE_ID_FILE_NAME=${NODE_ID_FILE_NAME} \
    -p $(($STAR_PORT + $i - 1)):${STAR_PORT} \
    --hostname "$STAR_HOSTNAME" \
    star:latest
done