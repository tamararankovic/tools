# export configurable env vars
OS_NAME="$(uname -s)"
if [ "$OS_NAME" = "Darwin" ]; then
    echo "Running on MacOS, trying to use xargs"
    export $(grep -v '^#' .env | gxargs -d '\n')
else
    echo "Running on linux, using xargs"
    export $(grep -v '^#' .env | xargs -d '\n')
fi

# build contol plane's services
docker compose build  #--no-cache

# start the control plane
docker compose up -d

# scylla init
CONTAINER_NAME="scylla"
while true; do
    # Get the health status of the container
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME)

    # Check if the container is healthy
    if [ "$HEALTH" = "healthy" ]; then
        echo "Container is healthy, running additional script"
        docker exec -it scylla /bin/sh -c "cqlsh -f /scylla_schema.cql"
        break  # Exit the loop when the container is healthy
    else
        echo "Scylla is not healthy, waiting for 5 seconds before checking again"
        sleep 5
    fi
done

# start grafana
docker run -d --name=grafana \
    -p 3000:3000 \
    --network tools_network \
    -v grafana-data:/var/lib/grafana \
    grafana/grafana

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
    --env STAR_HOSTNAME=star_"$i" \
    --env STAR_PORT=${STAR_PORT} \
    --env STAR_ADDRESS=${STAR_ADDRESS} \
    --env NATS_HOSTNAME=${NATS_HOSTNAME} \
    --env NATS_PORT=${NATS_PORT} \
    --env NATS_ADDRESS=${NATS_ADDRESS} \
    --env REGISTRATION_REQ_TIMEOUT_MILLISECONDS=${REGISTRATION_REQ_TIMEOUT_MILLISECONDS} \
    --env MAX_REGISTRATION_RETRIES=${MAX_REGISTRATION_RETRIES} \
    --env NODE_ID_DIR_PATH=${NODE_ID_DIR_PATH} \
    --env NODE_ID_FILE_NAME=${NODE_ID_FILE_NAME} \
    --env BIND_ADDRESS=10.5.0.$(($i+2)) \
    --env BIND_PORT=${BIND_PORT} \
    -p $(($STAR_PORT + $i - 1)):${STAR_PORT} \
    --hostname star_"$i" \
    --network=tools_network \
    --ip 10.5.0.$(($i+2)) \
    star:latest
done

docker build -f ../starometry/Dockerfile .. -t starometry

for ((i=1; i<=nodes; i++))
do
  docker create \
    --name starometry_"$i" \
    --hostname starometry_"$i" \
    -p $(($STAROMETRY_HTTP_PORT + $i - 1)):${STAROMETRY_HTTP_PORT} \
    -p $(($STAROMETRY_GRPC_PORT + $i - 1)):${STAROMETRY_GRPC_PORT} \
    --restart always \
    --env NODE_EXPORTER_URL=${NODE_EXPORTER_ADDRESS} \
    --env NODE_EXPORTER_PORT=${NODE_EXPORTER_PORT} \
    --env CADVISOR_URL=${CADVISOR_ADDRESS} \
    --env CADVISOR_PORT=${CADVISOR_PORT} \
    --env APP_PORT=${STAROMETRY_HTTP_PORT} \
    --env NATS_PORT=${NATS_PORT} \
    --env NATS_URL=${NATS_HOSTNAME} \
    --env GRPC_PORT=${STAROMETRY_GRPC_PORT} \
    --mount type=bind,source="$(pwd)"/nodeconfig/star_"$i",target="$NODE_ID_DIR_PATH" \
    --network tools_network \
    --ip 10.5.1.$(($i+2)) \
    starometry:latest 
  docker start starometry_"$i"
done