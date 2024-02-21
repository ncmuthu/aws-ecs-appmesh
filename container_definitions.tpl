[
    {
        "name": "postgres",
        "image": "${container02_image_name}",
        "cpu": 512,
        "memory": 1024,       
        "essential": true,
        "portMappings": [
        {
            "containerPort": 5432,
            "hostPort": 5432
        }
        ],
        "secrets": [
            {
                "name": "password",
                "valueFrom": "arn:aws:ssm:ap-southeast-1:345082620807:parameter/dbpass"
            }
        ],        
        "environment": [
            {"name": "POSTGRES_PASSWORD", "value": "mysecret01"}
        ],
        "environmentFiles": [
            {
                "value": "arn:aws:s3:::myenvvarsbucket01/app.envvars.env",
                "type": "s3"
            }
        ],        
        "mountPoints": [
            {
                "sourceVolume": "myebsvol02",
                "containerPath": "/data",
                "readOnly": false
            }
        ],        
        "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-create-group": "true",
            "awslogs-group": "${env}-task-logs",
            "awslogs-region": "${region}",
            "awslogs-stream-prefix": "ecs"
            }
        }
    },
    {
        "name": "envoy",
        "image": "840364872350.dkr.ecr.ap-southeast-1.amazonaws.com/aws-appmesh-envoy:v1.27.2.0-prod",
        "essential": true,
        "environment": [
            {
                "name": "APPMESH_RESOURCE_ARN",
                "value": "arn:aws:appmesh:ap-southeast-1:345082620807:mesh/appmesh/virtualNode/postgres-dev-cluster01"
            },
            {
               "name": "ENABLE_ENVOY_XRAY_TRACING",
               "value": "1"
            },
            {
               "name": "ENVOY_LOG_LEVEL",
               "value": "DEBUG"
            },
            {
               "name": "ENABLE_ENVOY_DOG_STATSD",
               "value": "1"
            },
            {
               "name": "APPMESH_METRIC_EXTENSION_VERSION",
               "value": "1"
            }                     
        ],
        "healthCheck": {
            "command": [
                "CMD-SHELL",
                "curl -s http://localhost:9901/server_info | grep state | grep -q LIVE"
            ],
            "startPeriod": 10,
            "interval": 5,
            "timeout": 2,
            "retries": 3
        },
        "user": "1337",
        "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-create-group": "true",
            "awslogs-group": "${env}-task-logs",
            "awslogs-region": "${region}",
            "awslogs-stream-prefix": "ecs"
        }
        }        
    },
    {
        "name" : "xray-daemon",
        "image" : "public.ecr.aws/xray/aws-xray-daemon:3.x",
        "user" : "1337",
        "essential" : true,
        "cpu" : 32,
        "memory" : 256,
        "portMappings" : [
        {
            "containerPort" : 2000,
            "protocol" : "udp"
        }
        ],
        "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-create-group": "true",
            "awslogs-group": "${env}-task-logs",
            "awslogs-region": "${region}",
            "awslogs-stream-prefix": "ecs"
            }
        }        
    },
    {
        "name": "cwagent",
        "image": "public.ecr.aws/cloudwatch-agent/cloudwatch-agent:latest",
        "environment": [
            {
                "name": "CW_CONFIG_CONTENT",
                "value": "{ \"metrics\": { \"namespace\": \"dev-cluster01\", \"metrics_collected\": { \"statsd\": {} } } }"
            }
        ]
    }
]    