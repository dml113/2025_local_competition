1. VPC 파일부터 빠르게 적고 apply
2. apply 되는 동안 Bastion, ECR, DynamoDB, ECS 요구사항에 맞게 설정
3. VPC가 전부 apply 되면 위의 2 ~ 5번까지 apply
4. apply 되는 동안 bastion에 접근하여 Dockerfile 작성 및 ECR에 image push
5. 완료했다면 container-definitions.json.tpl 파일을 수정 후 apply