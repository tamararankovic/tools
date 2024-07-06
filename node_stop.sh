# export configurable env vars
OS_NAME="$(uname -s)"
if [ "$OS_NAME" = "Darwin" ]; then
    echo "Running on MacOS, trying to use xargs"
    export $(grep -v '^#' node.env | gxargs -d '\n')
else
    echo "Running on linux, using xargs"
    export $(grep -v '^#' node.env | xargs -d '\n')
fi

docker compose -f node.yml down -v

# stop star
docker rm $(docker stop $(docker ps -a -q --filter ancestor=star:latest))

# stop starometry
docker rm $(docker stop $(docker ps -a -q --filter ancestor=starometry:latest))