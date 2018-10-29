package main

import (
	"context"
	"fmt"
	rPb "github.com/c12s/scheme/core"
	"github.com/coreos/etcd/clientv3"
	"github.com/golang/protobuf/proto"
	"github.com/hashicorp/vault/api"
	"time"
)

var (
	dialTimeout    = 2 * time.Second
	requestTimeout = 10 * time.Second
)

const (
	nodes = "topology/%s/%s/nodes"

	//labels  = "topology/%s/%s/labels/%s"  //topology/regionid/clusterid/labels/nodeid

	labels  = "topology/labels/%s/%s/%s"  //topology/labels/regionid/clusterid/nodeid
	nodeid  = "topology/%s/%s/nodes/%s"   //topology/regionid/clusterid/nodes/nodeid
	undone  = "topology/%s/%s/%s/undone"  //topology/regionid/clusterid/nodeid/undone
	configs = "topology/%s/%s/%s/configs" //topology/regionid/clusterid/nodeid/configs

	l1 = "l1:v1,l2:v2"
	l2 = "l1:v1,l2:v2,l3:v3"
	l3 = "l1:v1,l2:v2,l3:v3,l4:v4"
)

func c() string {
	configs := &rPb.KV{Extras: map[string]string{}}
	cData, err := proto.Marshal(configs)
	if err != nil {
		fmt.Println(err)
		return ""
	}
	return string(cData)
}

func u() string {
	undone := &rPb.UndoneKV{}
	uData, err := proto.Marshal(undone)
	if err != nil {
		fmt.Println(err)
		return ""
	}

	return string(uData)
}

func key(rid, cid, nid, template string) string {
	return fmt.Sprintf(template, rid, cid, nid)
}

func init_values() {
	ctx, _ := context.WithTimeout(context.Background(), requestTimeout)
	cli, _ := clientv3.New(clientv3.Config{
		DialTimeout: dialTimeout,
		Endpoints:   []string{"0.0.0.0:2379"},
	})
	defer cli.Close()
	kv := clientv3.NewKV(cli)

	// Setup regions clusters and nodes
	kv.Put(ctx, key("novisad", "grbavica", "node1", nodeid), "node1")
	kv.Put(ctx, key("novisad", "grbavica", "node2", nodeid), "node2")
	kv.Put(ctx, key("novisad", "grbavica", "node3", nodeid), "node3")

	kv.Put(ctx, key("novisad", "liman3", "node1", nodeid), "node1")
	kv.Put(ctx, key("novisad", "liman3", "node2", nodeid), "node2")
	kv.Put(ctx, key("novisad", "liman3", "node3", nodeid), "node3")

	// Setup labels for nodes
	kv.Put(ctx, key("novisad", "grbavica", "node1", labels), l1)
	kv.Put(ctx, key("novisad", "grbavica", "node2", labels), l1)
	kv.Put(ctx, key("novisad", "grbavica", "node3", labels), l2)

	kv.Put(ctx, key("novisad", "liman3", "node1", labels), l1)
	kv.Put(ctx, key("novisad", "liman3", "node2", labels), l2)
	kv.Put(ctx, key("novisad", "liman3", "node3", labels), l3)

	// Setup configs for nodes
	kv.Put(ctx, key("novisad", "grbavica", "node1", configs), c())
	kv.Put(ctx, key("novisad", "grbavica", "node2", configs), c())
	kv.Put(ctx, key("novisad", "grbavica", "node3", configs), c())

	kv.Put(ctx, key("novisad", "liman3", "node1", configs), c())
	kv.Put(ctx, key("novisad", "liman3", "node2", configs), c())
	kv.Put(ctx, key("novisad", "liman3", "node3", configs), c())

	// Setup undone for nodes
	kv.Put(ctx, key("novisad", "grbavica", "node1", undone), u())
	kv.Put(ctx, key("novisad", "grbavica", "node2", undone), u())
	kv.Put(ctx, key("novisad", "grbavica", "node3", undone), u())

	kv.Put(ctx, key("novisad", "liman3", "node1", undone), u())
	kv.Put(ctx, key("novisad", "liman3", "node2", undone), u())
	kv.Put(ctx, key("novisad", "liman3", "node3", undone), u())
}

func get(key string) {
	ctx, _ := context.WithTimeout(context.Background(), requestTimeout)
	cli, _ := clientv3.New(clientv3.Config{
		DialTimeout: dialTimeout,
		Endpoints:   []string{"0.0.0.0:2379"},
	})
	defer cli.Close()
	kv := clientv3.NewKV(cli)

	opts := []clientv3.OpOption{
		clientv3.WithPrefix(),
		clientv3.WithSort(clientv3.SortByKey, clientv3.SortAscend),
		// clientv3.WithLimit(1),
	}
	gr, err := kv.Get(ctx, key, opts...)
	if err != nil {
		fmt.Println(err)
		return
	}
	for _, item := range gr.Kvs {
		fmt.Println(string(item.Key))
		fmt.Println(string(item.Value))
	}
}

func del(key string) {
	ctx, _ := context.WithTimeout(context.Background(), requestTimeout)
	cli, _ := clientv3.New(clientv3.Config{
		DialTimeout: dialTimeout,
		Endpoints:   []string{"0.0.0.0:2379"},
	})
	defer cli.Close()
	kv := clientv3.NewKV(cli)

	dresp, err := kv.Delete(ctx, key, clientv3.WithPrefix())
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println(dresp.Deleted)
}

func q() {
	ctx, _ := context.WithTimeout(context.Background(), requestTimeout)
	cli, _ := clientv3.New(clientv3.Config{
		DialTimeout: dialTimeout,
		Endpoints:   []string{"0.0.0.0:2379"},
	})
	defer cli.Close()
	kv := clientv3.NewKV(cli)

	del := false
	if del {
		dresp, err := kv.Delete(ctx, "namespaces", clientv3.WithPrefix())
		if err != nil {
			fmt.Println(err)
		}
		fmt.Println(dresp.Deleted)
	} else {
		opts := []clientv3.OpOption{
			clientv3.WithPrefix(),
			clientv3.WithSort(clientv3.SortByKey, clientv3.SortAscend),
			// clientv3.WithLimit(1),
		}
		gr, err := kv.Get(ctx, "namespaces", opts...)
		if err != nil {
			fmt.Println("err")
			fmt.Println(err)
			return
		}

		for _, item := range gr.Kvs {
			fmt.Println(string(item.Key), string(item.Value))
		}
		fmt.Println(len(gr.Kvs))
	}

}

func v() {
	c, err := api.NewClient(&api.Config{
		Address: "0.0.0.0:8200",
	})
	if err != nil {
		fmt.Printf("Client: Failed to create Vault client: %v\n", err)
		return
	}

	c.SetToken("myroot")
	secretData := map[string]interface{}{
		"value1": "world",
		"foo1":   "bar",
	}
	resp, err1 := c.Logical().Write("mykv/data/mysecret3", secretData)
	if err1 != nil {
		fmt.Printf("Write: Failed to create Vault client: %v\n", err1)
		return
	}
	fmt.Println(resp)

	secretValues, err := c.Logical().Read("mykv/data/mysecret")
	if err != nil {
		fmt.Printf("Read: Failed to create Vault client: %v\n", err)
		return
	}
	for propName, propValue := range secretValues.Data {
		fmt.Printf(" - %s -> %v\n", propName, propValue)
	}
}

func main() {
	// get("topology/novisad/grbavica/node3/actions")
	// get("topology/novisad/liman3/node2/actions")

	// del("topology/novisad/grbavica/node3/actions")
	// del("topology/novisad/liman3/node2/actions")

	// del("topology/novisad/liman3/node2/actions")
	v()
}
