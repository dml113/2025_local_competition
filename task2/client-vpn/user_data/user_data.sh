#!/bin/bash
yum install -y docker
usermod -a -G docker ec2-user
systemctl enable --now docker