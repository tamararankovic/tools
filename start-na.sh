# export configurable env vars
export $(grep -v '^#' .env | xargs -d '\n')

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
     --network=tools_network \
    -p $(($STAR_PORT + $i - 1)):${STAR_PORT} \
    --hostname "$STAR_HOSTNAME" \
    star:latest
done