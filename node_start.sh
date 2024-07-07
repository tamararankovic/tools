# export configurable env vars
OS_NAME="$(uname -s)"
if [ "$OS_NAME" = "Darwin" ]; then
    echo "Running on MacOS, trying to use xargs"
    export $(grep -v '^#' node.env | gxargs -d '\n')
else
    echo "Running on linux, using xargs"
    export $(grep -v '^#' node.env | xargs -d '\n')
fi

docker compose -f node.yml build
docker compose -f node.yml up -d

docker build -f ../starometry/Dockerfile .. -t starometry

docker run -d \
  --name starometry \
  --hostname starometry \
  -p ${STAROMETRY_HTTP_PORT}:${STAROMETRY_HTTP_PORT} \
  -p ${STAROMETRY_GRPC_PORT}:${STAROMETRY_GRPC_PORT} \
  --restart always \
  --env PROMETHEUS_URL=${PROMETHEUS_HOSTNAME} \
  --env PROMETHEUS_PORT=${PROMETHEUS_PORT} \
  --env APP_PORT=${STAROMETRY_HTTP_PORT} \
  --env NATS_PORT=${NATS_PORT} \
  --env NATS_URL=${NATS_HOSTNAME} \
  --env GRPC_PORT=${STAROMETRY_GRPC_PORT} \
  --mount type=bind,source=/etc/c12s,target="$NODE_ID_DIR_PATH" \
  --network=tools_network \
  starometry:latest

sudo rm -rf /etc/c12s
sudo mkdir -p /etc/c12s

export STAR_ADDRESS=:${STAR_PORT}
export NATS_ADDRESS=${NATS_HOSTNAME}:${NATS_PORT}
export REGISTRATION_REQ_TIMEOUT_MILLISECONDS=${REGISTRATION_TIMEOUT}
export MAX_REGISTRATION_RETRIES=${MAX_REGISTER_RETRY}
export NODE_ID_DIR_PATH=${NODE_ID_DIR_PATH}
export NODE_ID_FILE_NAME=nodeid
export BIND_ADDRESS=${SERF_BIND_ADDRESS}
export BIND_PORT=${SERF_BIND_PORT}
export JOIN_CLUSTER_ADDRESS=${SERF_CLUSTER_ADDRESS}
export JOIN_CLUSTER_PORT=${SERF_CLUSTER_PORT}
export GOSSIP_TAG=${SERF_GOSSIP_TAG}",tag2:val2"
export GOSSIP_NODE_NAME=${GOSSIP_NODE_NAME}

cd ../star/cmd
go build -o star
./star