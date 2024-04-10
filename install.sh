cd ..

# todo: switch to c12s repo
git clone https://github.com/c12s/kuiper
git clone https://github.com/c12s/quasar
git clone https://github.com/c12s/magnetar
git clone https://github.com/c12s/star
git clone https://github.com/c12s/apollo
git clone https://github.com/ivana-k/iam-service
git clone https://github.com/c12s/oort
git clone https://github.com/c12s/gravity
find ./gravity/pkg -mindepth 1 -maxdepth 1 ! -name 'api' -exec rm -r {} +
git clone https://github.com/c12s/lunar-gateway
git clone https://github.com/c12s/cockpit
git clone https://github.com/c12s/blackhole

cd ./kuiper
git checkout develop
git pull

#cd ../iam-service
#mv  -v ./iam-service/* ./
