# AWS_otamesi_alb_ec2_rds
# AWS ALB-EC2-RDS構成（ポートフォリオ用）

## 📌 構成概要

ALB → EC2(Apache) → RDS（MySQL）の3層アーキテクチャをAWS上に構築。

## 📐 ネットワーク設計

- VPC: 10.0.0.0/16
- Public Subnet: 10.0.0.0/24, 10.0.1.0/24（ALB用）
- Private Web Subnet: 10.0.10.0/24, 10.0.11.0/24（EC2用）
- Private DB Subnet: 10.0.20.0/24, 10.0.21.0/24（RDS用）

## 🔒 セキュリティ設計

- ALB: HTTP 80 → 全許可
- EC2: ALB SGのみ許可
- RDS: EC2 SGのみ許可

## ⚙️ UserDataスクリプト（EC2）

```bash
#!/bin/bash
yum update -y
yum install -y httpd mysql
systemctl start httpd
systemctl enable httpd
echo "Hello from $(hostname)" > /var/www/html/index.html
