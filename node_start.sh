# export configurable env vars
OS_NAME="$(uname -s)"
if [ "$OS_NAME" = "Darwin" ]; then
    echo "Running on MacOS, trying to use xargs"
    export $(grep -v '^#' node.env | gxargs -d '\n')
else
    echo "Running on linux, using xargs"
    export $(grep -v '^#' node.env | xargs -d '\n')
fi

docker compose build -f node.yaml
docker compose up -f node.yml

# build the star agent
docker build -f ../star/Dockerfile .. -t star
# start the star agent
echo y | rm -r "$(pwd)"/nodeconfig
mkdir -p "$(pwd)"/nodeconfig/star
docker run -d --name star \
    --mount type=bind,source="$(pwd)"/nodeconfig/star,target="$NODE_ID_DIR_PATH" \
    --env STAR_ADDRESS=:${STAR_PORT} \
    --env NATS_ADDRESS=${NATS_HOSTNAME}:${NATS_PORT} \
    --env REGISTRATION_REQ_TIMEOUT_MILLISECONDS=${REGISTRATION_TIMEOUT} \
    --env MAX_REGISTRATION_RETRIES=${MAX_REGISTER_RETRY} \
    --env NODE_ID_DIR_PATH=${NODE_ID_DIR_PATH} \
    --env NODE_ID_FILE_NAME=${NODE_ID_FILE_NAME} \
    --env BIND_ADDRESS=${SERF_BIND_ADDRESS}\
    --env BIND_PORT=${SERF_BIND_PORT} \
    --env JOIN_CLUSTER_ADDRESS=${SERF_CLUSTER_ADDRESS} \
    --env JOIN_CLUSTER_PORT=${SERF_CLUSTER_PORT} \
    --env GOSSIP_TAG=${SERF_GOSSIP_TAG}",tag2:val2" \
    --env GOSSIP_NODE_NAME=${GOSSIP_NODE_NAME} \
    -p ${STAR_PORT}:${STAR_PORT} \
    -p ${SERF_CLUSTER_PORT}:${SERF_CLUSTER_PORT} \
    --hostname "$STAR_HOSTNAME" \
    --network=tools_network \
    star:latest

docker build -f ../starometry/Dockerfile .. -t starometry

docker run -d \
  --name starometry \
  --hostname starometry \
  -p ${$STAROMETRY_HTTP_PORT}:${STAROMETRY_HTTP_PORT} \
  -p ${$STAROMETRY_GRPC_PORT}:${STAROMETRY_GRPC_PORT} \
  --restart always \
  --env PROMETHEUS_URL=${PROMETHEUS_HOSTNAME} \
  --env PROMETHEUS_PORT=${PROMETHEUS_PORT} \
  --env APP_PORT=${STAROMETRY_HTTP_PORT} \
  --env NATS_PORT=${NATS_PORT} \
  --env NATS_URL=${NATS_HOSTNAME} \
  --env GRPC_PORT=${STAROMETRY_GRPC_PORT} \
  --mount type=bind,source="$(pwd)"/nodeconfig/star,target="$NODE_ID_DIR_PATH" \
  --network=tools_network \
  starometry:latest

