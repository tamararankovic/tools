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
        echo "scylla is not healthy, waiting for 5 seconds before checking again"
        sleep 5
    fi
done

# start grafana
docker run -d --name=grafana \
    -p 3000:3000 \
    --network tools_network \
    -v ./grafana/dashboard.yaml:/etc/grafana/provisioning/dashboards/main.yaml \
    -v ./grafana/dashboards:/var/lib/grafana/dashboards \
    -v ./grafana/datasources.yaml:/etc/grafana/provisioning/datasources/main.yaml \
    grafana/grafana
