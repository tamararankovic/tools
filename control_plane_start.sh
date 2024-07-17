# export configurable env vars
OS_NAME="$(uname -s)"
if [ "$OS_NAME" = "Darwin" ]; then
    echo "Running on MacOS, trying to use xargs"
    export $(grep -v '^#' control_plane.env | gxargs -d '\n')
else
    echo "Running on linux, using xargs"
    export $(grep -v '^#' control_plane.env | xargs -d '\n')
fi

# build contol plane's services
docker compose -f control_plane.yml build  #--no-cache

# start the control plane
docker compose -f control_plane.yml up -d

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

# start grafana
docker run -d --name=grafana \
    -p 3000:3000 \
    --network tools_network \
    -v grafana-data:/var/lib/grafana \
    grafana/grafana
