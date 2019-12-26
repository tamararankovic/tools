# To found new version of golang goto https://golang.org/dl/ and search for ARMD
# than change that version with the one that is in var FileName

cd $HOME
FileName='go1.13.4.linux-armv6l.tar.gz'
wget https://dl.google.com/go/$FileName
sudo tar -C /usr/local -xvf $FileName
cat >> ~/.bashrc << 'EOF'
export GOPATH=$HOME/go
export PATH=/usr/local/go/bin:$PATH:$GOPATH/bin
EOF
source ~/.bashrc
