# export configurable env vars
OS_NAME="$(uname -s)"
if [ "$OS_NAME" = "Darwin" ]; then
    echo "Running on MacOS, trying to use xargs"
    export $(grep -v '^#' node.env | gxargs -d '\n')
else
    echo "Running on linux, using xargs"
    export $(grep -v '^#' node.env | xargs -d '\n')
fi

sudo rm -rf /etc/c12s
sudo mkdir -p /etc/c12s
sudo chmod 0777 /etc/c12s

docker compose -f node.yml build
docker compose -f node.yml up -d

cd ../star/cmd
go build -o star
./star