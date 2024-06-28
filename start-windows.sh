# export configurable env vars
OS_NAME="$(uname -s)"
if [ "$OS_NAME" = "Darwin" ]; then
    echo "Running on MacOS, trying to use xargs"
    export $(grep -v '^#' .env | gxargs -d '\n')
else
    echo "Running on linux, using xargs"
    export $(grep -v '^#' .env | xargs -d '\n')
fi

# export other env vars
export MAGNETAR_PORT=5000
export KUIPER_PORT=9001
export KUIPER_WEBHOOK_PORT=9002
export OORT_PORT=8000
export IAM_PORT=8002
export AGENT_QUEUE_PORT=50052
export NATS_PORT=4222
export ETCD_PORT=2379
export KUIPER_ETCD_PORT=2379
export NEO4J_BOLT_PORT=7687
export NEO4J_HTTP_PORT=7474
export VAULT_HTTP_PORT=8200
export STAROMETRY_HTTP_PORT=8003
export STAROMETRY_GRPC_PORT=50055
export PROMETHEUS_PORT=9090

export STAR_HOSTNAME=star
export MAGNETAR_HOSTNAME=magnetar
export KUIPER_HOSTNAME=kuiper
export OORT_HOSTNAME=oort
export NATS_HOSTNAME=nats
export ETCD_HOSTNAME=etcd
export KUIPER_ETCD_HOSTNAME=kuiper_etcd
export IAM_HOSTNAME=apollo
export AGENT_QUEUE_HOSTNAME=agent_queue
export PROMETHEUS_HOSTNAME=prometheus

export REGISTRATION_TIMEOUT=1000
export REGISTRATION_SUBJECT="register"
export NODE_ID_DIR_PATH="//etc/c12s"
export NODE_ID_FILE_NAME="nodeid"

export NEO4J_HOSTNAME=neo4j
export NEO4J_AUTH_ENABLED=false
export NEO4J_DBNAME=neo4j
export NEO4J_apoc_export_file_enabled=true
export NEO4J_apoc_import_file_enabled=true
export NEO4J_apoc_import_file_use__neo4j__config=true
export NEO4J_PLUGINS="[\"apoc\"]"

export VAULT_HOSTNAME=vault
export VAULT_ADDR=http://0.0.0.0
export VAULT_KEYS_FILE=//etc/apollo/api_key.json

export CASSANDRA_DB=apollo
export CASSANDRA_HOSTNAME=cassandra
export CASSANDRA_DB_USERNAME=user
export CASSANDRA_DB_PASSWORD=apollo

export DB_PASSWORD=c12s_password
export DB_USERNAME=postgres
export DB_NAME=postgres
export DB_HOST=database

export QUASAR_HOSTNAME=quasar
export QUASAR_PORT=9090
export QUASAR_ETCD_HOSTNAME=quasar_etcd
export QUASAR_ETCD_PORT=2379

export SECRET_KEY="secret-key"

export DB_CONSUL="consul"
export DBPORT_CONSUL=8500

# build contol plane's services
docker compose build --stop-on-error

# start the control plane
docker compose up -d

# cassandra init
CONTAINER_NAME="cassandra"
while true; do
    # Get the health status of the container
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME)

    # Check if the container is healthy
    if [ "$HEALTH" = "healthy" ]; then
        echo "Container is healthy, running additional script"
        winpty docker exec -it cassandra //bin/sh -c "cqlsh -f /schema.cql"
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

# Set Serf agent environment variables
# Address for single serf agent
export SERF_BIND_ADDRESS=0.0.0.0
export SERF_BIND_PORT=7946        
# Address to contact to join cluster 
export SERF_CLUSTER_ADDRESS="star_1"
export SERF_CLUSTER_PORT=7946 
# String used to build tags in the serf config
export SERF_GOSSIP_TAG="tag1:type_"

# build the node agent
docker build -f ../star/Dockerfile .. -t star
# start node agents
echo y | rm -r "$(pwd)"/nodeconfig
mkdir "$(pwd)"/nodeconfig
nodes="${NODES_NUM:-2}" 
for ((i=1; i<=nodes; i++))
do
    echo $i
    mkdir "$(pwd)"/nodeconfig/star_"$i"
    docker run -d --name star_"$i" \
    --mount type=bind,source="$(pwd)"/nodeconfig/star_"$i",target="$NODE_ID_DIR_PATH" \
    --env STAR_ADDRESS=:${STAR_PORT} \
    --env OORT_ADDRESS=${OORT_HOSTNAME}:${OORT_PORT} \
    --env NATS_ADDRESS=${NATS_HOSTNAME}:${NATS_PORT} \
    --env REGISTRATION_REQ_TIMEOUT_MILLISECONDS=${REGISTRATION_TIMEOUT} \
    --env MAX_REGISTRATION_RETRIES=${MAX_REGISTER_RETRY} \
    --env NODE_ID_DIR_PATH=${NODE_ID_DIR_PATH} \
    --env NODE_ID_FILE_NAME=${NODE_ID_FILE_NAME} \
    --env BIND_ADDRESS=${SERF_BIND_ADDRESS}\
    --env BIND_PORT=$((SERF_BIND_PORT + i - 1)) \
    --env JOIN_CLUSTER_ADDRESS=${SERF_CLUSTER_ADDRESS} \
    --env JOIN_CLUSTER_PORT=${SERF_CLUSTER_PORT} \
    --env GOSSIP_TAG=${SERF_GOSSIP_TAG}$i",tag2:val2" \
    --env GOSSIP_NODE_NAME=${STAR_HOSTNAME}_$i \
    -p $(($STAR_PORT + $i - 1)):${STAR_PORT} \
    --hostname "$STAR_HOSTNAME" \
    --network=tools_network \
    star:latest
done


docker build -f ../starometry/Dockerfile .. -t starometry

for ((i=1; i<=nodes; i++))
do
docker run -d \
  --name starometry_"$i" \
  --hostname starometry \
  -p $(($STAROMETRY_HTTP_PORT + $i - 1)):${STAROMETRY_HTTP_PORT} \
  -p $(($STAROMETRY_GRPC_PORT + $i - 1)):${STAROMETRY_GRPC_PORT} \
  --restart always \
  --env PROMETHEUS_URL=${PROMETHEUS_HOSTNAME} \
  --env PROMETHEUS_PORT=${PROMETHEUS_PORT} \
  --env APP_PORT=${STAROMETRY_HTTP_PORT} \
  --env NATS_PORT=${NATS_PORT} \
  --env NATS_URL=${NATS_HOSTNAME} \
  --env GRPC_PORT=${STAROMETRY_GRPC_PORT} \
  --mount type=bind,source="$(pwd)"/nodeconfig/star_"$i",target="$NODE_ID_DIR_PATH" \
  --network=tools_network \
  starometry:latest
done

