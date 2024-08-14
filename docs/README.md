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
-  Configuration management and versioning
- Schema management and versioning
- Schema-based configuration validation
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
| MAX_REGISTRATION_RETRIES | The maximum number of registration requests a node agent will attempt. | 5 |
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

Note: to make script executable, run command: chmod +x start.sh 

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

### POST /apis/core/v1/users

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
| `email`    | string  | User's email. Required. Should be unique. |
| `username`    | string  | Used later for login. Accepted characters: alphanumeric plus "_", "-", "." Required. Should be unique. |
| `name`    | string  | First name of the user.  |
| `surname`    | string  | Last name of the user.  |
| `password`    | string  | Account password. Required. |
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
 - Organization already exists
 - Invalid field values
 - Required fields are missing

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

#### Response - 400 Bad Request

 - Invalid query format

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

 #### Response - 400 Bad Request

 - Invalid query format

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

 #### Response - 400 Bad Request

 - Invalid query format

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

 #### Response - 404 Not Found

 - Node doesn't exist

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

  #### Response - 404 Not Found

 - Node doesn't exist

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

  #### Response - 404 Not Found

 - Node doesn't exist

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

  #### Response - 404 Not Found

 - Node doesn't exist

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

 ### POST /apis/core/v1/schemas

 The endpoint for creating new configuration schema version.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
	"schema_details": {
		"organization": "c12s",
		"schema_name": "schema",
		"version": "v1.0.2"
	},
	"schema": "properties:\n  db_config:\n    properties:\n      address:\n        type: string\n      port:\n        type: integer\n    required:\n    - address\n    - port\n    type: object\nrequired:\n- db_config\ntype: object\n"
}
```
| property | type | description |
|-----|-----|----|
| `schema_details`    | object  | Schema info. |
| `schema_details.organization`    | string  | The owner of the schema. |
| `schema_details.schema_name`    | string  | Schema name. |
| `schema_details.version`    | string | Schema version. New schema version will be saved only if it doesn't already exist. |
| `schema`    | string | Schema definition. Must be a valid YAML representation of a JSON schema. |

#### Response - 200 OK

```json
{
	"status": 0,
	"message": "Schema saved successfully!"
}
```
| property | type | description |
|-----|-----|----|
| `status`    | string  | Response status. |
| `message`    | string  | Response message. The value depends on the response status:<br>0 - Schema saved successfully!<br>3 - Provided version is not latest! Please provide a version that succeeds 'v1.0.0'!<br> 3 - schema is invalid<br>3 - Schema details must not contain '/'!<br>3 - Schema version must be a valid SemVer string with 'v' prefix! |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

 ### GET /apis/core/v1/schemas

 The endpoint for getting a specified configuration schema version.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
	"schema_details": {
		"organization": "c12s",
		"schema_name": "schema",
		"version": "v1.0.2"
	}
}
```
| property | type | description |
|-----|-----|----|
| `schema_details`    | object  | Schema info. |
| `schema_details.organization`    | string  | The owner of the schema. |
| `schema_details.schema_name`    | string  | Schema name. |
| `schema_details.version`    | string | Schema version. New schema version will be saved only if it doesn't already exist. |

#### Response - 200 OK

```json
{
    "message": "Schema retrieved successfully!",
    "schemaData": {
        "schema": "properties:\n  db_config:\n    properties:\n      address:\n        type: string\n      port:\n        type: integer\n    required:\n    - address\n    - port\n    type: object\nrequired:\n- db_config\ntype: object\n",
        "creationTime": "2024-04-10T10:49:29.496643237Z"
    }
}
```
| property | type | description |
|-----|-----|----|
| `message`    | string  | Response message. |
| `schemaData`    | object  | Schema details. |
| `schemaData.schema`    | string  | Schema definition. |
| `schemaData.creationTime`    | string  | Date and time when the schema was created. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

 ### GET /apis/core/v1/schemas/versions

 The endpoint for getting all versions of a specified configuration schema.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
	"schema_details": {
		"organization": "c12s",
		"schema_name": "schema",
	}
}
```
| property | type | description |
|-----|-----|----|
| `schema_details`    | object  | Schema info. |
| `schema_details.organization`    | string  | The owner of the schema. |
| `schema_details.schema_name`    | string  | Schema name. |

#### Response - 200 OK

```json
{
    "message": "Schema versions retrieved successfully!",
    "schemaVersions": [
        {
            "schemaDetails": {
                "schemaName": "schema",
                "version": "v1.0.1",
                "organization": "c12s"
            },
            "schemaData": {
                "schema": "properties:\n  db_config:\n    properties:\n      address:\n        type: string\n      port:\n        type: integer\n    required:\n    - address\n    - port\n    type: object\nrequired:\n- db_config\ntype: object\n",
                "creationTime": "2024-04-10T10:49:29.496643237Z"
            }
        }
    ]
}
```
| property | type | description |
|-----|-----|----|
| `message`    | string  | Response message. |
| `schemaVersions`    | array of objects  | List of schemas. |
| `schemaVersions.schemaDetails`    | object  | Schema info. |
| `schemaVersions.schemaDetails.organization`    | string  | The owner of the schema. |
| `schemaVersions.schemaDetails.schema_name`    | string  | Schema name. |
| `schemaVersions.schemaDetails.version`    | string | Schema version. |
| `schemaVersions.schemaData`    | object  | Schema details. |
| `schemaVersions.schemaData.schema`    | string  | Schema definition. |
| `schemaVersions.schemaData.creationTime`    | string  | Date and time when the schema was created. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

 ### DELETE /apis/core/v1/schemas

 The endpoint for deleting a specified configuration schema version.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
	"schema_details": {
		"organization": "c12s",
		"schema_name": "schema",
		"version": "v1.0.2"
	}
}
```
| property | type | description |
|-----|-----|----|
| `schema_details`    | object  | Schema info. |
| `schema_details.organization`    | string  | The owner of the schema. |
| `schema_details.schema_name`    | string  | Schema name. |
| `schema_details.version`    | string | Schema version. |

#### Response - 200 OK

```json
{
    "message": "Schema deleted successfully!"
}
```
| property | type | description |
|-----|-----|----|
| `message`    | string  | Response message. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

### GET /apis/core/v1/schemas/validations

 The endpoint for validating configuration against a specified configuration schema version.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
  "schema_details": {
    "organization": "c12s",
    "schema_name": "schema",
    "version": "v1.0.1"
  },
  "configuration": "db_config:\n	address: 127.0.0.1\n	port: abc"
}
```
| property | type | description |
|-----|-----|----|
| `schema_details`    | object  | Schema info. |
| `schema_details.organization`    | string  | The owner of the schema. |
| `schema_details.schema_name`    | string  | Schema name. |
| `schema_details.version`    | string | Schema version. |
| `configuration`    | string  | Configuration in YAML format. |

#### Response 1 - 200 OK

```json
{
  "status": 0,
  "message": "The configuration is valid!",
  "is_valid": true
}
```
| property | type | description |
|-----|-----|----|
| `status`    | int  | Response status. |
| `message`    | string  | Response message. |
| `is_valid`    | bool  | Specifies whether the configuration was valid or not. |

#### Response 2 - 200 OK

```json
{
  "status": 0,
  "message": "person.age: Invalid type. Expected: integer, given: string",
  "is_valid": false
}
```
| property | type | description |
|-----|-----|----|
| `status`    | int  | Response status. |
| `message`    | string  | Response message. |
| `is_valid`    | bool  | Specifies whether the configuration was valid or not. |

#### Response 3 - 200 OK

```json
{
  "status": 3,
  "message": "No schema with key 'my_namespace/car_schema/v1.0.0' found!",
  "is_valid": false
}
```
| property | type | description |
|-----|-----|----|
| `status`    | int  | Response status. |
| `message`    | string  | Response message. |
| `is_valid`    | bool  | Specifies whether the configuration was valid or not. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization




### POST /apis/core/v1/configs/standalone

The endpoint for creating new standalone configuration version.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
    "organization": "c12s",
	"name": "nats_config",
	"version": "v1.0.1",
    "paramSet": [
        {
			"key": "port",
            "value": "8884"
        },
		{
            "key": "address",
			"value": "127.0.0.1"
        }
    ],
	"schema": {
		"name": "nats_schema",
		"version": "v2.1.0"
	}
}
```
| property | type | description |
|-----|-----|----|
| `organization`    | string  | Name of the organization that is the owner of the configuration. |
| `name`    | string  | Configuration name. |
| `version`    | string  | Configuration version. |
| `paramSet`    | array of objects | Configuration parameters. |
| `paramSet.key`    | string | Key of the configuration parameter. |
| `paramSet.value`    | string  | Value of the configuration parameter. |
| `schema` | object | **[optional]** Schema against which to validate the new configuration. |
| `schema.name` | string | **[optional]** Schema name. |
| `schema.version` | string | **[optional]** Schema version. |

#### Response - 200 OK

```json
{
    "organization": "c12s",
    "name": "nats_config",
    "version": "v1.0.1",
    "createdAt": "2024-04-10 08:44:12 +0000 UTC",
    "paramSet": [
        {
            "key": "port",
            "value": "8884"
        },
		{
            "key": "address",
			"value": "127.0.0.1"
        }
    ]
}
```
| property | type | description |
|-----|-----|----|
| `organization`    | string  | Name of the organization that is the owner of the configuration. |
| `name`    | string  | Configuration name. |
| `version`    | string  | Configuration version. |
| `createdAt` | string | Date and time when the configuration was created. |
| `paramSet`    | array of objects | Configuration parameters. |
| `paramSet.key`    | string | Key of the configuration parameter. |
| `paramSet.value`    | string  | Value of the configuration parameter. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

#### Response - 400 Bad request

 - Schema validation wasn't successful

### GET /apis/core/v1/configs/standalone/single

The endpoint for getting a specified standalone configuration version.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
    "organization": "c12s",
	"name": "nats_config",
	"version": "v1.0.1"
}
```
| property | type | description |
|-----|-----|----|
| `organization`    | string  | Name of the organization that is the owner of the configuration. |
| `name`    | string  | Configuration name. |
| `version`    | string  | Configuration version. |

#### Response - 200 OK

```json
{
    "organization": "c12s",
    "name": "nats_config",
    "version": "v1.0.1",
    "createdAt": "2024-04-10 08:44:12 +0000 UTC",
    "paramSet": [
        {
            "key": "port",
            "value": "8884"
        },
		{
            "key": "address",
			"value": "127.0.0.1"
        }
    ]
}
```
| property | type | description |
|-----|-----|----|
| `organization`    | string  | Name of the organization that is the owner of the configuration. |
| `name`    | string  | Configuration name. |
| `version`    | string  | Configuration version. |
| `createdAt` | string | Date and time when the configuration was created. |
| `paramSet`    | array of objects | Configuration parameters. |
| `paramSet.key`    | string | Key of the configuration parameter. |
| `paramSet.value`    | string  | Value of the configuration parameter. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

#### Response - 404 Not Found

 - Configuration not found.

 ### GET /apis/core/v1/configs/standalone

The endpoint for listing all standalone configurations inside an organization.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
    "organization": "c12s",
}
```
| property | type | description |
|-----|-----|----|
| `organization`    | string  | Name of the organization that is the owner of the configuration. |

#### Response - 200 OK

```json
{
	"configurations": [
		{
			"organization": "c12s",
			"name": "nats_config",
			"version": "v1.0.1",
			"createdAt": "2024-04-10 08:44:12 +0000 UTC",
			"paramSet": [
				{
					"key": "port",
					"value": "8884"
				},
				{
					"key": "address",
					"value": "127.0.0.1"
				}
			]
		}
	]
}
```
| property | type | description |
|-----|-----|----|
| `configurations`    | array of objects  | List of configurations. |
| `configurations.organization`    | string  | Name of the organization that is the owner of the configuration. |
| `configurations.name`    | string  | Configuration name. |
| `configurations.version`    | string  | Configuration version. |
| `configurations.createdAt` | string | Date and time when the configuration was created. |
| `configurations.paramSet`    | array of objects | Configuration parameters. |
| `configurations.paramSet.key`    | string | Key of the configuration parameter. |
| `configurations.paramSet.value`    | string  | Value of the configuration parameter. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

### DELETE /apis/core/v1/configs/standalone

The endpoint for deleting a specified standalone configuration version.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
    "organization": "c12s",
	"name": "nats_config",
	"version": "v1.0.1"
}
```
| property | type | description |
|-----|-----|----|
| `organization`    | string  | Name of the organization that is the owner of the configuration. |
| `name`    | string  | Configuration name. |
| `version`    | string | Configuration version. |

#### Response - 200 OK

```json
{
    "organization": "c12s",
    "name": "nats_config",
    "version": "v1.0.1",
    "createdAt": "2024-04-10 08:44:12 +0000 UTC",
    "paramSet": [
        {
            "key": "port",
            "value": "8884"
        },
		{
            "key": "address",
			"value": "127.0.0.1"
        }
    ]
}
```
| property | type | description |
|-----|-----|----|
| `organization`    | string  | Name of the organization that is the owner of the configuration. |
| `name`    | string  | Configuration name. |
| `version`    | string  | Configuration version. |
| `createdAt` | string | Date and time when the configuration was created. |
| `paramSet`    | array of objects | Configuration parameters. |
| `paramSet.key`    | string | Key of the configuration parameter. |
| `paramSet.value`    | string  | Value of the configuration parameter. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

#### Response - 404 Not Found

 - Configuration not found.

 ### GET /apis/core/v1/configs/standalone/diff

The endpoint for getting a diff between two standalone configuration versions.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
    "reference": {
        "name": "nats_config",
        "organization": "c12s",
        "version": "v1.0.0"
    },
    "diff": {
        "name": "nats_config",
        "organization": "c12s",
        "version": "v1.0.1"
    }
}
```
| property | type | description |
|-----|-----|----|
| `reference`    | object  | Reference configuration for calculating diff. |
| `reference.organization`    | string  | Name of the organization that is the owner of the configuration. |
| `reference.name`    | string  | Configuration name. |
| `reference.version`    | string  | Configuration version. |
| `diff`    | object  | Configuration whose diffs should be taken into account. |
| `diff.organization`    | string  | Name of the organization that is the owner of the configuration. |
| `diff.name`    | string  | Configuration name. |
| `diff.version`    | string  | Configuration version. |

#### Response - 200 OK

```json
{
    "diffs": [
        {
            "type": "replacement",
            "diff": {
                "key": "port",
                "new_value": "8884",
                "old_value": "1111"
            }
        },
        {
            "type": "deletion",
            "diff": {
                "key": "address",
                "value": "127.0.0.1"
            }
        }
    ]
}
```
| property | type | description |
|-----|-----|----|
| `diffs`    | array of objects  | List of diffs between two configurations. |
| `diffs.type`    | string  | Diff type. Possible values are: *addition, deletion, replacement* |
| `diffs.diff`    | map<string, string> | Diff info. Fields present depend on the diff type. <br>**addition**: key, value <br>**deletion**: key, value <br>**replacement**: key, old_value, new_value |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

#### Response - 404 Not Found

- Configuration not found

### POST /apis/core/v1/configs/standalone/placements

The endpoint for disseminating a standalone configuration version to the query-selected nodes.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
    "config": {
        "name": "app_config",
        "organization": "c12s",
        "version": "v1.0.0"
    },
    "namespace": "dev",
    "query": [
        {
            "labelKey": "newlabel",
            "shouldBe": ">",
            "value": "20.0"
        }
    ]
}
```
| property | type | description |
|-----|-----|----|
| `config.organization`    | string  | Name of the organization that is the owner of the configuration as well as nodes for dissemination. |
| `config.name`    | string  | Configuration name. |
| `config.version`    | string  | Configuration version. |
| `namespace`    | string | Namespace in which the configuration will be visible. |
| `query` | array of objects | A label-based query selector. For a node to match a query, all selectors must be true. |
| `query.labelKey` | string | Key of the label to compare. |
| `query.shouldBe` | string | The omparison operator. Supported operators are: =, !=, <, >. |
| `query.value` | string | Value that should be compared to the label value. |

#### Response - 200 OK

```json
{
    "tasks": [
        {
            "id": "eb333bc8-4d7e-4149-bacc-8feb60a94dc3",
            "node": "a4b242c1-bc6e-417e-9708-f164e618d0c2",
            "namespace": "dev",
            "status": "Accepted",
            "acceptedAt": "2024-04-10 10:14:22 +0000 UTC",
            "resolvedAt": "2024-04-10 10:14:22 +0000 UTC"
        }
    ]
}
```
| property | type | description |
|-----|-----|----|
| `tasks`    | array of objects  | List of placement tasks. There will be one for each node. |
| `tasks.id`    | string  | Task ID. |
| `tasks.node`    | string  | ID of the node that will receive configuration. |
| `tasks.namespace` | string | The namespace in which the configuration will be visible. |
| `tasks.status`    | string | Task status. Possible values: *Accepted, Placed, Failed* |
| `tasks.acceptedAt`    | string | Date and time when task was accepted. |
| `tasks.resolvedAt`    | string | Date and time when task status was resolved to either Placed of Failed. If the current status is Accepted, this value can be ignored. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

#### Response - 400 Bad Request

 - Query format invalid.

 #### Response - 404 Not Found

 - Configuration not found.

 ### GET /apis/core/v1/configs/standalone/placements

The endpoint for listing placement task statuses for the specified configuration.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
    "name": "app_config",
	"organization": "c12s",
	"version": "v1.0.0"
}
```
| property | type | description |
|-----|-----|----|
| `organization`    | string  | Name of the organization that is the owner of the configuration. |
| `name`    | string  | Configuration name. |
| `version`    | string  | Configuration version. |

#### Response - 200 OK

```json
{
    "tasks": [
        {
            "id": "eb333bc8-4d7e-4149-bacc-8feb60a94dc3",
            "node": "a4b242c1-bc6e-417e-9708-f164e618d0c2",
            "namespace": "dev",
            "status": "Placed",
            "acceptedAt": "2024-04-10 10:14:22 +0000 UTC",
            "resolvedAt": "2024-04-10 10:14:22 +0000 UTC"
        }
    ]
}
```
| property | type | description |
|-----|-----|----|
| `tasks`    | array of objects  | List of placement tasks. There will be one for each node. |
| `tasks.id`    | string  | Task ID. |
| `tasks.node`    | string  | ID of the node that will receive configuration. |
| `tasks.namespace` | string | The namespace in which the configuration will be visible. |
| `tasks.status`    | string | Task status. Possible values: *Accepted, Placed, Failed* |
| `tasks.acceptedAt`    | string | Date and time when task was accepted. |
| `tasks.resolvedAt`    | string | Date and time when task status was resolved to either Placed of Failed. If the current status is Accepted, this value can be ignored. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

 #### Response - 404 Not Found

 - Configuration not found.

### POST /apis/core/v1/configs/groups

The endpoint for creating new configuration group version.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
    "organization": "c12s",
	"name": "app_config",
	"version": "v1.0.0",
    "paramSets": [
        {
			"name": "db_config",
            "paramSet": [
                {
                    "key": "port",
					"value": "1234"
                }
            ]
        }
    ],
	"schema": {
		"name": "nats_schema",
		"version": "v2.1.0"
	}
}
```
| property | type | description |
|-----|-----|----|
| `organization`    | string  | Name of the organization that is the owner of the configuration. |
| `name`    | string  | Configuration name. |
| `version`    | string  | Configuration version. |
| `paramSets`    | array of objects | List of named configurations in the group. |
| `paramSets.name`    | string | Name of the configuration. |
| `paramSets.paramSet`    | array of objects | List of configuration parameters inside the configuration. |
| `paramSets.paramSet.key`    | string | Key of the configuration parameter. |
| `paramSets.paramSet.value`    | string  | Value of the configuration parameter. |
| `schema` | object | **[optional]** Schema against which to validate the new configuration. |
| `schema.name` | string | **[optional]** Schema name. |
| `schema.version` | string | **[optional]** Schema version. |

#### Response - 200 OK

```json
{
    "organization": "c12s",
	"name": "app_config",
	"version": "v1.0.0",
    "createdAt": "2024-04-10 08:44:12 +0000 UTC",
    "paramSets": [
        {
			"name": "db_config",
            "paramSet": [
                {
                    "key": "port",
					"value": "1234"
                }
            ]
        }
    ]
}
```
| property | type | description |
|-----|-----|----|
| `organization`    | string  | Name of the organization that is the owner of the configuration. |
| `name`    | string  | Configuration name. |
| `version`    | string  | Configuration version. |
| `createdAt` | string | Date and time when the configuration was created. |
| `paramSets`    | array of objects | List of named configurations in the group. |
| `paramSets.name`    | string | Name of the configuration. |
| `paramSets.paramSet`    | array of objects | List of configuration parameters inside the configuration. |
| `paramSets.paramSet.key`    | string | Key of the configuration parameter. |
| `paramSets.paramSet.value`    | string  | Value of the configuration parameter. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

#### Response - 400 Bad request

 - Schema validation wasn't successful

 ### GET /apis/core/v1/configs/groups/single

The endpoint for getting a specified configuration group version.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
    "organization": "c12s",
	"name": "app_config",
	"version": "v1.0.0"
}
```
| property | type | description |
|-----|-----|----|
| `organization`    | string  | Name of the organization that is the owner of the configuration. |
| `name`    | string  | Configuration name. |
| `version`    | string  | Configuration version. |

#### Response - 200 OK

```json
{
    "organization": "c12s",
	"name": "app_config",
	"version": "v1.0.0",
    "createdAt": "2024-04-10 08:44:12 +0000 UTC",
    "paramSets": [
        {
			"name": "db_config",
            "paramSet": [
                {
                    "key": "port",
					"value": "1234"
                }
            ]
        }
    ]
}
```
| property | type | description |
|-----|-----|----|
| `organization`    | string  | Name of the organization that is the owner of the configuration. |
| `name`    | string  | Configuration name. |
| `version`    | string  | Configuration version. |
| `createdAt` | string | Date and time when the configuration was created. |
| `paramSets`    | array of objects | List of named configurations in the group. |
| `paramSets.name`    | string | Name of the configuration. |
| `paramSets.paramSet`    | array of objects | List of configuration parameters inside the configuration. |
| `paramSets.paramSet.key`    | string | Key of the configuration parameter. |
| `paramSets.paramSet.value`    | string  | Value of the configuration parameter. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

#### Response - 404 Not Found

- Configuration not found

### GET /apis/core/v1/configs/groups

The endpoint for listing all configuration groups inside an organization.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
    "organization": "c12s"
}
```
| property | type | description |
|-----|-----|----|
| `organization`    | string  | Name of the organization that is the owner of the configuration. |

#### Response - 200 OK

```json
{
	"groups": [
		{
			"organization": "c12s",
			"name": "app_config",
			"version": "v1.0.0",
			"createdAt": "2024-04-10 08:44:12 +0000 UTC",
			"paramSets": [
				{
					"name": "db_config",
					"paramSet": [
						{
							"key": "port",
							"value": "1234"
						}
					]
				}
			]
		}
	]
}
```
| property | type | description |
|-----|-----|----|
| `groups`    | array of objects  | List of configurations. |
| `groups.organization`    | string  | Name of the organization that is the owner of the configuration. |
| `groups.name`    | string  | Configuration name. |
| `groups.version`    | string  | Configuration version. |
| `groups.createdAt` | string | Date and time when the configuration was created. |
| `groups.paramSets`    | array of objects | List of named configurations in the group. |
| `groups.paramSets.name`    | string | Name of the configuration. |
| `groups.paramSets.paramSet`    | array of objects | List of configuration parameters inside the configuration. |
| `groups.paramSets.paramSet.key`    | string | Key of the configuration parameter. |
| `groups.paramSets.paramSet.value`    | string  | Value of the configuration parameter. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

 ### DELETE /apis/core/v1/configs/groups

The endpoint for deleting a specified configuration group version.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
    "organization": "c12s",
	"name": "app_config",
	"version": "v1.0.0"
}
```
| property | type | description |
|-----|-----|----|
| `organization`    | string  | Name of the organization that is the owner of the configuration. |
| `name`    | string  | Configuration name. |
| `version`    | string  | Configuration version. |

#### Response - 200 OK

```json
{
    "organization": "c12s",
	"name": "app_config",
	"version": "v1.0.0",
    "createdAt": "2024-04-10 08:44:12 +0000 UTC",
    "paramSets": [
        {
			"name": "db_config",
            "paramSet": [
                {
                    "key": "port",
					"value": "1234"
                }
            ]
        }
    ]
}
```
| property | type | description |
|-----|-----|----|
| `organization`    | string  | Name of the organization that is the owner of the configuration. |
| `name`    | string  | Configuration name. |
| `version`    | string  | Configuration version. |
| `createdAt` | string | Date and time when the configuration was created. |
| `paramSets`    | array of objects | List of named configurations in the group. |
| `paramSets.name`    | string | Name of the configuration. |
| `paramSets.paramSet`    | array of objects | List of configuration parameters inside the configuration. |
| `paramSets.paramSet.key`    | string | Key of the configuration parameter. |
| `paramSets.paramSet.value`    | string  | Value of the configuration parameter. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

#### Response - 404 Not Found

- Configuration not found

 ### GET /apis/core/v1/configs/groups/diff

The endpoint for getting a diff between two configuration group versions.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
    "reference": {
        "name": "nats_config",
        "organization": "c12s",
        "version": "v1.0.0"
    },
    "diff": {
        "name": "nats_config",
        "organization": "c12s",
        "version": "v1.0.1"
    }
}
```
| property | type | description |
|-----|-----|----|
| `reference`    | object  | Reference configuration for calculating diff. |
| `reference.organization`    | string  | Name of the organization that is the owner of the configuration. |
| `reference.name`    | string  | Configuration name. |
| `reference.version`    | string  | Configuration version. |
| `diff`    | object  | Configuration whose diffs should be taken into account. |
| `diff.organization`    | string  | Name of the organization that is the owner of the configuration. |
| `diff.name`    | string  | Configuration name. |
| `diff.version`    | string  | Configuration version. |

#### Response - 200 OK

```json
{
    "diffs": {
        "db_config": {
            "diffs": [
                {
                    "type": "replacement",
                    "diff": {
                        "key": "port",
                        "new_value": "1234",
                        "old_value": "4444"
                    }
                }
            ]
        },
        "media_path_config": {
            "diffs": [
                {
                    "type": "deletion",
                    "diff": {
                        "key": "path",
                        "value": "/media"
                    }
                }
            ]
        }
    }
}
```
| property | type | description |
|-----|-----|----|
| `diffs`    | map<string, object>  | Map of diffs by configuration |
| `diffs[key].diffs.type`    | string  | Diff type. Possible values are: *addition, deletion, replacement* |
| `diffs[key].diffs.diff`    | map<string, string>  | Diff info. Fields present depend on the diff type. <br>**addition**: key, value <br>**deletion**: key, value <br>**replacement**: key, old_value, new_value |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

#### Response - 404 Not Found

- Configuration not found

### POST /apis/core/v1/configs/groups/placements

The endpoint for disseminating a configuration group version to the query-selected nodes.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
    "config": {
        "name": "app_config",
        "organization": "c12s",
        "version": "v1.0.0"
    },
    "namespace": "dev",
    "query": [
        {
            "labelKey": "newlabel",
            "shouldBe": ">",
            "value": "20.0"
        }
    ]
}
```
| property | type | description |
|-----|-----|----|
| `config.organization`    | string  | Name of the organization that is the owner of the configuration as well as nodes for dissemination. |
| `config.name`    | string  | Configuration name. |
| `config.version`    | string  | Configuration version. |
| `namespace`    | string | Namespace in which the configuration will be visible. |
| `query` | array of objects | A label-based query selector. For a node to match a query, all selectors must be true. |
| `query.labelKey` | string | Key of the label to compare. |
| `query.shouldBe` | string | The omparison operator. Supported operators are: =, !=, <, >. |
| `query.value` | string | Value that should be compared to the label value. |

#### Response - 200 OK

```json
{
    "tasks": [
        {
            "id": "eb333bc8-4d7e-4149-bacc-8feb60a94dc3",
            "node": "a4b242c1-bc6e-417e-9708-f164e618d0c2",
            "namespace": "dev",
            "status": "Accepted",
            "acceptedAt": "2024-04-10 10:14:22 +0000 UTC",
            "resolvedAt": "2024-04-10 10:14:22 +0000 UTC"
        }
    ]
}
```
| property | type | description |
|-----|-----|----|
| `tasks`    | array of objects  | List of placement tasks. There will be one for each node. |
| `tasks.id`    | string  | Task ID. |
| `tasks.node`    | string  | ID of the node that will receive configuration. |
| `tasks.namespace` | string | The namespace in which the configuration will be visible. |
| `tasks.status`    | string | Task status. Possible values: *Accepted, Placed, Failed* |
| `tasks.acceptedAt`    | string | Date and time when task was accepted. |
| `tasks.resolvedAt`    | string | Date and time when task status was resolved to either Placed of Failed. If the current status is Accepted, this value can be ignored. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

#### Response - 400 Bad Request

 - Query format invalid.

 #### Response - 404 Not Found

 - Configuration not found.

 ### GET /apis/core/v1/configs/groups/placements

The endpoint for listing placement task statuses for the specified configuration.

#### Request headers

 - **Authorization**: User's authentication token received upon login

#### Request body

```json
{
    "name": "app_config",
	"organization": "c12s",
	"version": "v1.0.0"
}
```
| property | type | description |
|-----|-----|----|
| `organization`    | string  | Name of the organization that is the owner of the configuration. |
| `name`    | string  | Configuration name. |
| `version`    | string  | Configuration version. |

#### Response - 200 OK

```json
{
    "tasks": [
        {
            "id": "eb333bc8-4d7e-4149-bacc-8feb60a94dc3",
            "node": "a4b242c1-bc6e-417e-9708-f164e618d0c2",
            "namespace": "dev",
            "status": "Placed",
            "acceptedAt": "2024-04-10 10:14:22 +0000 UTC",
            "resolvedAt": "2024-04-10 10:14:22 +0000 UTC"
        }
    ]
}
```
| property | type | description |
|-----|-----|----|
| `tasks`    | array of objects  | List of placement tasks. There will be one for each node. |
| `tasks.id`    | string  | Task ID. |
| `tasks.node`    | string  | ID of the node that will receive configuration. |
| `tasks.namespace` | string | The namespace in which the configuration will be visible. |
| `tasks.status`    | string | Task status. Possible values: *Accepted, Placed, Failed* |
| `tasks.acceptedAt`    | string | Date and time when task was accepted. |
| `tasks.resolvedAt`    | string | Date and time when task status was resolved to either Placed of Failed. If the current status is Accepted, this value can be ignored. |

#### Response - 401 Unauthorized

 - Invalid authentication token

#### Response - 403 Forbidden

 - The user is not a member of the specified organization

 #### Response - 404 Not Found

 - Configuration not found.


## Example workflow

There is a `demo.json` Postman collection in the `tools` directory. It demonstrates a scenario covering all steps that need to be taken from user registration to getting a sample configuration disseminated to a subset of nodes.

After running the collection, and assuming default configuration parameters, the response from node agents should be the following:

```bash
 grpcurl -plaintext -d '{
    "name": "app_config",
    "org": "c12s",
    "version": "v1.0.0",
    "namespace": "dev"
}' localhost:11000 proto.StarConfig/GetConfigGroup
{
  "organization": "c12s",
  "name": "app_config",
  "version": "v1.0.0",
  "createdAt": "2024-04-10 10:12:32 +0000 UTC",
  "paramSets": [
    {
      "name": "db_config",
      "paramSet": [
        {
          "key": "port",
          "value": "4444"
        }
      ]
    },
    {
      "name": "media_path_config",
      "paramSet": [
        {
          "key": "path",
          "value": "/media"
        }
      ]
    }
  ]
}
```

```bash
grpcurl -plaintext -d '{
    "name": "app_config",
    "org": "c12s",
    "version": "v1.0.0",
    "namespace": "dev"
}' localhost:11001 proto.StarConfig/GetConfigGroup
ERROR:
  Code: NotFound
  Message: config group (org: c12s, name: app_config, version: v1.0.0) not found in namespace dev
```

```bash
 grpcurl -plaintext -d '{
    "name": "db_config",
    "org": "c12s",
    "version": "v1.0.0",
    "namespace": "dev"
}' localhost:11000 proto.StarConfig/GetStandaloneConfig
{
  "organization": "c12s",
  "name": "db_config",
  "version": "v1.0.0",
  "createdAt": "2024-04-10 10:12:32 +0000 UTC",
  "paramSet": [
	{
		"value": "1234",
		"key": "port"
	},
	{
		"key": "address",
		"value": "127.0.0.1"
	}
  ],
}
```

```bash
 grpcurl -plaintext -d '{
    "name": "db_config",
    "org": "c12s",
    "version": "v1.0.0",
    "namespace": "dev"
}' localhost:11001 proto.StarConfig/GetStandaloneConfig
{
  "organization": "c12s",
  "name": "db_config",
  "version": "v1.0.0",
  "createdAt": "2024-04-10 10:12:32 +0000 UTC",
  "paramSet": [
	{
		"value": "1234",
		"key": "port"
	},
	{
		"key": "address",
		"value": "127.0.0.1"
	}
  ],
}
```
