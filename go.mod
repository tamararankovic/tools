module github.com/c12s/tools

replace github.com/coreos/go-systemd/journal => ../../coreos/go-systemd/journal

go 1.13

require (
	github.com/c12s/scheme v0.0.0-20191204214602-7126694c68c7
	github.com/coreos/etcd v3.3.18+incompatible
	github.com/coreos/go-systemd/journal v0.0.0-00010101000000-000000000000 // indirect
	github.com/coreos/pkg v0.0.0-20180928190104-399ea9e2e55f // indirect
	github.com/gogo/protobuf v1.3.1 // indirect
	github.com/golang/protobuf v1.3.2
	github.com/google/uuid v1.1.1 // indirect
	github.com/hashicorp/vault/api v1.0.4
	go.uber.org/zap v1.13.0 // indirect
)
