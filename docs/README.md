# Reconfiguration Management Tool

## Overview

A system for dynamic node reconfiguration. The core features include:

- Node registration
- Node ownership management
- Label-based node selection
- User registration and authentication
- Organization management
-  Access control
-   Support for namespaces
-  Configuration storing and versioning
-  Configuration dissemination

## Getting Started

### Prerequisites

 1. [Docker](https://docs.docker.com/engine/install/)
 2. [Docker Compose](https://docs.docker.com/compose/install/)

### Configuration

Configurable parameters can be found end set in the `tools/.env` file. They are listed in the below table:

| Parameter | Description | Default value |
|--|--|--|
| NODES_NUM | The number of nodes to simulate. | 2 |
| MAX_REGISTER_RETRY | The maximum number of registration requests a node agent will attempt. | 5 |
| STAR_PORT | The port number at which the node agent is listening. If there are N node agents running, each of them will be assigned a port number from the range STAR_PORT:STAR_PORT+N-1 | 11000 |

### Running

On Linux:

```bash
# go to tools directory
cd tools

# to start both the control plane and node agents
bash start.sh

# to stop both the control plane and node agents
bash stop.sh
```

On MacOS:

```bash
# go to tools directory
cd tools

brew install findutils

# to start both the control plane and node agents
bash start.sh

# to stop both the control plane and node agents
bash stop.sh
```

On Windows, using [git bash](https://git-scm.com/downloads):

```bash
# go to tools directory
cd tools

# to start both the control plane and node agents
bash start-windows.sh

# to stop both the control plane and node agents
bash stop.sh
```

### Usage

The control plane is available at [http://localhost:5555](http://localhost:5555). It can be accessed via any API testing tool, such as cURL, Postman, Insomnia etc.

The node agents are available on ports specified in the configuration file. The default port number for the first node agent is 11000. As the agents expose a gRPC API, [gRPCurl](https://github.com/fullstorydev/grpcurl) or Postman can be used for interaction.

## Endpoints

### POST /apis/core/v1/user

The endpoint for registering new users.

#### Request headers

None

#### Request body

```json
{
	"email": "pera@gmail.com",
	"name": "pera",
	"org": "org",
	"password": "pera",
	"surname": "peric",
	"username": "pera"
}
```
|property| type  |                    description                      |
|---------|-------|-----------------------------------------------------|
| `email`    | string  | User's email. |
| `username`    | string  | hould be unique. Used later for login. Accepted characters: alphanumeric plus "_", "-", "." |
| `name`    | string  | First name of the user.  |
| `surname`    | string  | Last name of the user.  |
| `password`    | string  | Account password. |
| `org`    | string  | Name of the organization. Should be unique. If not provided, it will be created as username_default |

#### Response - 200 OK

```json
{
	"user": {
		"id": "2435b545-d3e4-11ee-bfa7-0242c0a8700b",
		"name": "pera",
		"surname": "peric",
		"email": "pera@gmail.com"
	}
}
```

|property| type  |                    description                      |
|---------|-------|-----------------------------------------------------|
| `id`    | string  | Unique identifier of the user. |
| `email`    | string  | User's email. |
| `name`    | string  | First name of the user.  |
| `surname`    | string  | Last name of the user.  |

#### Response - 400 Bad Request

 - User already exists
 - Invalid field values

### POST /apis/core/v1/auth

The endpoint for user login.

#### Request headers

None

#### Request body

```json
{
	"password": "pera",
	"username": "pera"
}
```
|property| type  |                    description                      |
|-----|-----|----|
| `username`    | string  | Account username. |
| `password`    | string  | Account password. |

#### Response - 200 OK

```json
{
	"token": "hvs.CAESICIm77HTJaOAzZFMb6EtxkQix0d85P1jFaR7tPadmgK6Gh4KHGh2cy5zTjVSV2NmZnZJV28zdTVXSDhWT24xVGQ"
}
```
|property| type  |                    description                      |
|-----|-----|----|
| `token`    | string  | Authentication token that should be provided in all requests to protected endpoints. |

#### Response - 400 Bad Request

 - Invalid username and/or password

### GET /apis/core/v1/nodes/available

The endpoint for listing all available nodes.

#### Request headers

None

#### Request body

None

#### Response - 200 OK

```json
{
	"nodes": [
		{
			"id": "05ede011-701e-4e9c-b500-f3b6a98a7564",
			"labels": [
				{
					"key": "cpu-cores",
					"value": "8.00"
				},
				{
					"key": "memory-totalGB",
					"value": "16.00"
				}
			]
		}
	]
}
```
|property| type  |  description |
|-----|-----|----|
| `nodes` | array of objects  | A list of nodes not taken by any organization yet. |
| `nodes.id` | string  | The unique identifier of the node. |
| `nodes.labels` | array of objects  | Node's label set. |
| `nodes.labels.key` | string  | Label key. |
| `nodes.labels.value` | string  | Label's stringified value. |

### GET /apis/core/v1/nodes/allocated

The endpoint for listing all nodes owned by an organization.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
	"org": "org",
}
```
|property| type  |                    description                      |
|-----|-----|----|
| `org`    | string  | Organization name. |

#### Response - 200 OK

```json
{
	"nodes": [
		{
			"id": "05ede011-701e-4e9c-b500-f3b6a98a7564",
			"labels": [
				{
					"key": "cpu-cores",
					"value": "8.00"
				},
				{
					"key": "memory-totalGB",
					"value": "16.00"
				}
			]
		}
	]
}
```
|property| type  |  description |
|-----|-----|----|
| `nodes` | array of *Node* objects  | A list of nodes owned by the organization specified in the request body. |
| `nodes.id` | string  | The unique identifier of the node. |
| `nodes.labels` | array of objects  | Node's label set. |
| `nodes.labels.key` | string  | Label key. |
| `nodes.labels.value` | string  | Label's stringified value. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

### GET /apis/core/v1/nodes/available/query_match

The endpoint for querying available nodes.

#### Request headers

None

#### Request body

```json
{
	"query": [
		{
			"labelKey": "label1",
			"shouldBe": ">",
			"value": "20.0"
		}
	]
}
```
|property| type  |  description |
|-----|-----|----|
| `query` | array of objects  | A label-based query selector. For a node to match a query, all selectors must be true. |
| `query.labelKey` | string | Key of the label to compare. |
| `query.shouldBe` | string | The omparison operator. Supported operators are: =, !=, <, >. |
| `query.value` | string | Value that should be compared to the label value. |

#### Response - 200 OK

```json
{
	"nodes": [
		{
			"id": "05ede011-701e-4e9c-b500-f3b6a98a7564",
			"labels": [
				{
					"key": "cpu-cores",
					"value": "8.00"
				},
				{
					"key": "memory-totalGB",
					"value": "16.00"
				}
			]
		}
	]
}
```
|property| type  |  description |
|-----|-----|----|
| `nodes` | array of *Node* objects  | A list of nodes not taken by any organization yet that match the specified query. |
| `nodes.id` | string  | The unique identifier of the node. |
| `nodes.labels` | array of objects  | Node's label set. |
| `nodes.labels.key` | string  | Label key. |
| `nodes.labels.value` | string  | Label's stringified value. |

### GET /apis/core/v1/nodes/allocated/query_match

The endpoint for querying nodes owned by an organization.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
	"org": "org",
	"query": [
		{
			"labelKey": "label1",
			"shouldBe": ">",
			"value": "20.0"
		}
	]
}
```
|property| type  |                    description                      |
|-----|-----|----|
| `org`    | string  | Organization name. |
| `query` | array of objects  | A label-based query selector. For a node to match a query, all selectors must be true. |
| `query.labelKey` | string | Key of the label to compare. |
| `query.shouldBe` | string | The omparison operator. Supported operators are: =, !=, <, >. |
| `query.value` | string | Value that should be compared to the label value. |

#### Response - 200 OK

```json
{
	"nodes": [
		{
			"id": "05ede011-701e-4e9c-b500-f3b6a98a7564",
			"labels": [
				{
					"key": "cpu-cores",
					"value": "8.00"
				},
				{
					"key": "memory-totalGB",
					"value": "16.00"
				}
			]
		}
	]
}
```
|property| type  |  description |
|-----|-----|----|
| `nodes` | array of *Node* objects  | A list of nodes owned by the organization specified in the request body that match the query selector. |
| `nodes.id` | string  | The unique identifier of the node. |
| `nodes.labels` | array of objects  | Node's label set. |
| `nodes.labels.key` | string  | Label key. |
| `nodes.labels.value` | string  | Label's stringified value. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

### PATCH /apis/core/v1/nodes

The endpoint for allocating nodes. The available nodes matched by the query selector will become ownership of the specified organization.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
	"org": "org",
	"query": [
		{
			"labelKey": "label1",
			"shouldBe": ">",
			"value": "20.0"
		}
	]
}
```
|property| type  |                    description                      |
|-----|-----|----|
| `org`    | string  | Organization name. |
| `query` | array of objects  | A label-based query selector. For a node to match a query, all selectors must be true. |
| `query.labelKey` | string | Key of the label to compare. |
| `query.shouldBe` | string | The omparison operator. Supported operators are: =, !=, <, >. |
| `query.value` | string | Value that should be compared to the label value. |

#### Response - 200 OK

```json
{
	"nodes": [
		{
			"id": "05ede011-701e-4e9c-b500-f3b6a98a7564",
			"labels": [
				{
					"key": "cpu-cores",
					"value": "8.00"
				},
				{
					"key": "memory-totalGB",
					"value": "16.00"
				}
			]
		}
	]
}
```
|property| type  |  description |
|-----|-----|----|
| `nodes` | array of *Node* objects  | A list of allocated nodes. |
| `nodes.id` | string  | The unique identifier of the node. |
| `nodes.labels` | array of objects  | Node's label set. |
| `nodes.labels.key` | string  | Label key. |
| `nodes.labels.value` | string  | Label's stringified value. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

### POST /apis/core/v1/labels/float64

The endpoint for upserting a label for the specified node. The label has a float64 value. The node must be owned by the specified organization.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
	"label": {
		"key": "newlabel",
		"value": 25.0
	},
	"nodeId": "05ede011-701e-4e9c-b500-f3b6a98a7564",
	"org": "org"
}
```
|property| type  |                    description                      |
|-----|-----|----|
| `label`    | object  | Label to be added or updated |
| `label.key`    | string  | Label key. |
| `label.value`    | float64  | Label value. |
| `nodeId` | string  | Node's identifier. |
| `org`    | string  | Organization name. |

#### Response - 200 OK

```json
{
	"node": {
		"id": "05ede011-701e-4e9c-b500-f3b6a98a7564",
		"labels": [
			{
				"key": "cpu-cores",
				"value": "8.00"
			},
			{
				"key": "memory-totalGB",
				"value": "16.00"
			},
			{
				"key": "newlabel",
				"value": "25.0"
			}
		]
	}
}
```
|property| type  |  description |
|-----|-----|----|
| `node` | object  | The node updated. |
| `node.id` | string  | The unique identifier of the node. |
| `node.labels` | array of objects  | Node's new label set. |
| `node.labels.key` | string  | Label key. |
| `node.labels.value` | string  | Label's stringified value. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization
 - The node is not owned by the specified organization

### POST /apis/core/v1/labels/bool

The endpoint for upserting a label for the specified node. The label has a boolean value. The node must be owned by the specified organization.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
	"label": {
		"key": "newlabel",
		"value": true
	},
	"nodeId": "05ede011-701e-4e9c-b500-f3b6a98a7564",
	"org": "org"
}
```
|property| type  |                    description                      |
|-----|-----|----|
| `label`    | object  | Label to be added or updated |
| `label.key`    | string  | Label key. |
| `label.value`    | bool  | Label value. |
| `nodeId` | string  | Node's identifier. |
| `org`    | string  | Organization name. |

#### Response - 200 OK

```json
{
	"node": {
		"id": "05ede011-701e-4e9c-b500-f3b6a98a7564",
		"labels": [
			{
				"key": "cpu-cores",
				"value": "8.00"
			},
			{
				"key": "memory-totalGB",
				"value": "16.00"
			},
			{
				"key": "newlabel",
				"value": "true"
			}
		]
	}
}
```
|property| type  |  description |
|-----|-----|----|
| `node` | object  | The node updated. |
| `node.id` | string  | The unique identifier of the node. |
| `node.labels` | array of objects  | Node's new label set. |
| `node.labels.key` | string  | Label key. |
| `node.labels.value` | string  | Label's stringified value. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization
 - The node is not owned by the specified organization

### POST /apis/core/v1/labels/string

The endpoint for upserting a label for the specified node. The label has a string value. The node must be owned by the specified organization.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
	"label": {
		"key": "newlabel",
		"value": "val"
	},
	"nodeId": "05ede011-701e-4e9c-b500-f3b6a98a7564",
	"org": "org"
}
```
|property| type  |                    description                      |
|-----|-----|----|
| `label`    | object  | Label to be added or updated |
| `label.key`    | string  | Label key. |
| `label.value`    | string  | Label value. |
| `nodeId` | string  | Node's identifier. |
| `org`    | string  | Organization name. |

#### Response - 200 OK

```json
{
	"node": {
		"id": "05ede011-701e-4e9c-b500-f3b6a98a7564",
		"labels": [
			{
				"key": "cpu-cores",
				"value": "8.00"
			},
			{
				"key": "memory-totalGB",
				"value": "16.00"
			},
			{
				"key": "newlabel",
				"value": "val"
			}
		]
	}
}
```
|property| type  |  description |
|-----|-----|----|
| `node` | object  | The node updated. |
| `node.id` | string  | The unique identifier of the node. |
| `node.labels` | array of objects  | Node's new label set. |
| `node.labels.key` | string  | Label key. |
| `node.labels.value` | string  | Label's stringified value. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization
 - The node is not owned by the specified organization

### DELETE /apis/core/v1/labels

The endpoint for deleting a label for the specified node. The node must be owned by the specified organization.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
	"labelKey": "newlabel",
	"nodeId": "05ede011-701e-4e9c-b500-f3b6a98a7564",
	"org": "org"
}
```
|property| type  |                    description                      |
|-----|-----|----|
| `labelKey`    | string  | Label key to be deleted. |
| `nodeId` | string  | Node's identifier. |
| `org`    | string  | Organization name. |

#### Response - 200 OK

```json
{
	"node": {
		"id": "05ede011-701e-4e9c-b500-f3b6a98a7564",
		"labels": [
			{
				"key": "cpu-cores",
				"value": "8.00"
			},
			{
				"key": "memory-totalGB",
				"value": "16.00"
			}
		]
	}
}
```
|property| type  |  description |
|-----|-----|----|
| `node` | object  | The node updated. |
| `node.id` | string  | The unique identifier of the node. |
| `node.labels` | array of objects  | Node's new label set. If the label with the specified key couldn't be found, the new and old label sets will be identical. |
| `node.labels.key` | string  | Label key. |
| `node.labels.value` | string  | Label's stringified value. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization
 - The node is not owned by the specified organization

### POST /apis/core/v1/relations

The endpoint for creating security policy inheritance relationships between resources.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
	"from": {
		"id": "dev",
		"kind": "namespace"
	},
	"to": {
		"id": "my-app",
		"kind": "app"
	}
}
```
|property| type  |                    description                      |
|-----|-----|----|
| `from`    | object  | Parent resource. |
| `from.id`    | string  | Parent resource identifier. |
| `from.kind`    | string  | Parent resource kind. |
| `to`    | object  | Child resource. |
| `to.id`    | string  | Child resource identifier. |
| `to.kind`    | string  | Child resource kind. |

#### Response - 200 OK

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user has no permission to manage specified resources.

### POST /apis/core/v1/policies

The endpoint for creating security policies.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
	"objectScope": {
		"id": "dev",
		"kind": "namespace"
	},
	"permission": {
		"condition": {
			"expression": ""
		},
		"kind": "ALLOW",
		"name": "config.get"
	},
	"subjectScope": {
		"id": "my-app",
		"kind": "app"
	}
}
```
|property| type  |                    description                      |
|-----|-----|----|
| `objectScope`    | object  | Object scope resource. |
| `objectScope.id`    | string  | Object scope resource identifier. |
| `objectScope.kind`    | string  | Object scope resource kind. |
| `subjectScope`    | object  | Subject scope resource. |
| `subjectScope.id`    | string  | Subject scope resource identifier. |
| `subjectScope.kind`    | string  | Subject scope resource kind. |
| `permission`    | object  | Permission to be granted. |
| `kind`    | string  | Permission kind. Values can be ALLOW or DENY |
| `name`    | string  | Permission name. |
| `permission.condition.expression`    | string  | Logical expression that activates the policy. |

#### Response - 200 OK

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user has no permission to manage specified resources.

### POST /apis/core/v1/configs

The endpoint for creating new configuration version.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
	"group": {
		"configs": [
			{
				"value": "1234",
				"key": "port"
			}
		],
		"name": "dbconfig",
		"orgId": "org",
		"version": 1
	}
}
```
|property| type  |                    description                      |
|-----|-----|----|
| `group`    | object  | Configuration. |
| `group.configs`    | array of object  | Configuration parameters. |
| `group.configs.key`    | string | Key of the configuration parameter. |
| `group.configs.value`    | string  | Value of the configuration parameter. |
| `group.name`    | string  | Configuration name. |
| `group.orgId`    | string  | Name of the organization that is the owner of the configuration. |
| `group.version`    | int  | Configuration version. If the configuration with the specified name didn't exist, the version must be set to 1. If it did, the version mustn't already exist and there should be a previous version.|

#### Response - 200 OK

```json
{
	"group": {
		"configs": [
			{
				"value": "1234",
				"key": "port"
			}
		],
		"name": "dbconfig",
		"orgId": "org",
		"version": 1
	}
}
```
|property| type  |                    description                      |
|-----|-----|----|
| `group`    | object  | Configuration. |
| `group.configs`    | array of object  | Configuration parameters. |
| `group.configs.key`    | string | Key of the configuration parameter. |
| `group.configs.value`    | string  | Value of the configuration parameter. |
| `group.name`    | string  | Configuration name. |
| `group.orgId`    | string  | Name of the organization that is the owner of the configuration. |
| `group.version`    | int  | Configuration version. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

#### Response - 400 Bad request

 - Invalid configuration version

### POST /apis/core/v1/configs/applications

The endpoint for applying a configuration version to the selected nodes. The configuration will be visible only in the specified namespace.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
	"groupName": "dbconfig",
	"namespace": "dev",
	"orgId": "org",
	"query": [
		{
			"labelKey": "newlabel",
			"shouldBe": ">",
			"value": "20.0"
		}
	],
	"version": 1
}
```
|property| type  |                    description                      |
|-----|-----|----|
| `groupName`    | string  | Configuration name. |
| `namespace`    | string  | Namespace in which the configuration will be visible. |
| `orgId`    | string  | Name of the organization that is the owner of the configuration. |
| `query` | array of objects | A label-based query selector. For a node to match a query, all selectors must be true. |
| `query.labelKey` | string | Key of the label to compare. |
| `query.shouldBe` | string | The omparison operator. Supported operators are: =, !=, <, >. |
| `query.value` | string | Value that should be compared to the label value. |
| `version`    | int  | Configuration version.|

#### Response - 200 OK

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization
 - The user is not allowed to view the specified configuration.
 - The user is not allowed to put config in the specified namespace.

#### Response - 400 Bad request

 - Invalid configuration (name or version don't exist in the organization)

## Example workflow

There is a `demo.json` Postman collection in the `tools` directory. It demonstrates a scenario covering all steps that need to be taken from user registration to getting a sample configuration disseminated to a subset of nodes.

**Note**: Before running the collection, you need to create an environment in Postman and select it.

After running the collection, and assuming default configuration parameters, the response from node agents should be the following:

```bash
grpcurl -plaintext -d '{              
    "groupId": "org/dbconfig/v1",
    "subId": "my-app",
    "subKind": "app"
}' localhost:11001 proto.StarConfig/GetConfigGroup
{
  "group": {
    "id": "org/dbconfig/v1",
    "configs": [
      {
        "key": "port",
        "value": "1234"
      }
    ]
  }
}
```
```bash
grpcurl -plaintext -d '{              
    "groupId": "org/dbconfig/v1",
    "subId": "my-app",
    "subKind": "app"
}' localhost:11000 proto.StarConfig/GetConfigGroup
ERROR:
  Code: NotFound
  Message: not found
```
