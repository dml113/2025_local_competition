#!/bin/bash
yum install -y docker
usermod -a -G docker ec2-user
systemctl enable --now docker

# sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
# echo 'password' | passwd --stdin ec2-user
# echo 'AuthenticationMethods password,publickey' >> /etc/ssh/sshd_config

# sed -i 's/#Port 22/Port 2222/g' /etc/ssh/sshd_config
# systemctl restart sshd

chown -R ec2-user app/

mkdir /home/ec2-user/app

cat <<EOF> /home/ec2-user/app/Dockerfile
FROM golang:alpine
COPY backend .
RUN apk add --no-cache libc6-compat
CMD ["./backend"]
EOF