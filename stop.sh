# export configurable env vars
OS_NAME="$(uname -s)"
if [ "$OS_NAME" = "Darwin" ]; then
    echo "Running on MacOS, trying to use xargs"
    export $(grep -v '^#' .env | gxargs -d '\n')
else
    echo "Running on linux, using xargs"
    export $(grep -v '^#' .env | xargs -d '\n')
fi

rm -r ./nodeconfig/*

# stop star
docker rm $(docker stop $(docker ps -a -q --filter ancestor=star:latest))

# stop starometry
docker rm $(docker stop $(docker ps -a -q --filter ancestor=starometry:latest))

# stop grafana
docker rm $(docker stop $(docker ps -a -q --filter ancestor=grafana/grafana))

# stop other
docker compose down -v --remove-orphans
