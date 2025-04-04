[
  {
    "cpu": 512,
    "essential": true,
    "image": "nginx:latest",
    "memory": 1024,
    "name": "nginx-container",
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/nginx",
        "awslogs-region": "ap-northeast-2",
        "awslogs-stream-prefix": "nginx"
      }
    }
  }
]