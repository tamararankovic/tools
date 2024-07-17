# export configurable env vars
OS_NAME="$(uname -s)"
if [ "$OS_NAME" = "Darwin" ]; then
    echo "Running on MacOS, trying to use xargs"
    export $(grep -v '^#' control_plane.env | gxargs -d '\n')
else
    echo "Running on linux, using xargs"
    export $(grep -v '^#' control_plane.env | xargs -d '\n')
fi

# stop grafana
docker rm $(docker stop $(docker ps -a -q --filter ancestor=grafana/grafana))

# stop the control plane
docker-compose -f control_plane.yml down -v --remove-orphans