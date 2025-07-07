
## 🗂️ 構成概要（前提）

* **VPC**：10.0.0.0/16
* **サブネット構成**（AZ a / b で以下を作成）

  * Public（ALB用）
  * Private Web（EC2用）
  * Private DB（RDS用）
  * Privateサブネットは各AZに1つ配置
* **IGWあり、NAT Gatewayあり**
* **EC2からSSMで接続**
* **Apacheインストール & RDS接続までUserDataで自動化**

---

## 🛠️ 手順一覧（ALB → EC2 → RDSの疎通確認）

---

### 🔹 ① VPC・サブネットの作成

| 項目              | 値例                  |
| --------------- | ------------------- |
| VPC             | CIDR: `10.0.0.0/16` |
| Public Subnet A | `10.0.0.0/24`       |
| Public Subnet B | `10.0.1.0/24`       |
| Web Subnet A    | `10.0.10.0/24`      |
| Web Subnet B    | `10.0.11.0/24`      |
| DB Subnet A     | `10.0.20.0/24`      |
| DB Subnet B     | `10.0.21.0/24`      |

---

### 🔹 ② ルートテーブルの作成・関連付け

| ルートテーブル  | 関連付けサブネット         | 設定     |
| -------- | ----------------- | ----------------- |
| PublicRT | Public Subnet A/B | `0.0.0.0/0 → IGW`     |
| PublicRT | Public Subnet A/B | `10.0.0.0/16 → local` |
| PrivateRT| Private Subnet A/B|  `0.0.0.0/0 → NGW`    |
| PrivateRT| Private Subnet A/B| `10.0.0.0/16 → local` |
---

### 🔹 ③ IGWの作成・VPCへのアタッチ

1. IGWを作成
2. 作成したVPCにアタッチ

---

### 🔹 ④ NGWの作成・VPCへのアタッチ

1. NGWを作成
2. 作成したVPCにアタッチ？？？←パブリックサブネットにアタッチ？
3.ElasticIPアドレスアタッチ？

### 🔹 ④ セキュリティグループの作成

🔸 ALBのSG
インバウンド
　＊TCP　80　→0.0.0.0/0
アウトバウンド
　＊すべてのトラフィック　→0.0.0.0/0
🔸 EC2用のセキュリティグループ（EC2-SG）
インバウンド
  * TCP 80 → ALBのSGを指定（Web通信）
アウトバウンド
  * デフォルトのすべて許可（0.0.0.0/0）
🔸 RDS用のセキュリティグループ（RDS-SG）
インバウンド
  * TCP 3306 → EC2-SGを指定（DB疎通）
アウトバウンド
  * デフォルトのすべて許可（0.0.0.0/0）


---

### 🔹 ⑤ EC2の起動（Webサブネットに）

* **AMI**：Amazon Linux 2 / 2023
* **インスタンスタイプ**：t3.micro
* **Subnet**：Private Subnet A と B
* **パブリックIPなし**
* **IAMロール**：`AmazonSSMManagedInstanceCore` をアタッチ
* **UserData例（Apache）**：

```bash
#!/bin/bash
dnf update -y #使用するEC2はAmazon Linux 2023(Amazon Linux 2 の場合は"yum"コマンドを使用する)
dnf install -y httpd mysql　##使用するEC2はAmazon Linux 2023
systemctl start httpd
systemctl enable httpd
echo "Hello from $(hostname)" > /var/www/html/index.html
```

---

### 🔹 ⑥ RDSの作成（DBサブネットグループに）

* **エンジン**：MySQL
* **マルチAZ**：任意
* **DBサブネットグループ**：Private Subnet A/B を指定
* **セキュリティグループ**：RDS-SG を適用
* **パブリックアクセス**：**なし**
* **DB名/ユーザー名/パスワード**：控えておく

---

### 🔹 ⑦ ALBの作成（パブリックサブネット）

* **ターゲットグループ**：EC2インスタンスを登録（ポート80）
* **ALBのSG**：ALB-SG
* **サブネット**：Public Subnet A/B
* **リスナー**：HTTP（ポート80） → ターゲットグループ

---

### 🔹 ⑧ SSMログイン → RDSへの疎通確認

```bash
# SSMでEC2にログイン後
mysql -h <RDSエンドポイント> -u admin -p
SHOW DATABASES;
```

---

### 🔹 ⑨ ALBにアクセス → EC2レスポンス確認

```bash
# ブラウザまたはcurlでアクセス
curl http://<ALB-DNS-Name>
# → Hello from ip-10-0-xx-xx が返ればOK
```

---

## ✅ 最終確認ポイント

| 経路        | 確認方法         | 成功条件                |
| --------- | ------------ | ------------------- |
| ALB → EC2 | curl or ブラウザ | `Hello from` が表示される |
| EC2 → RDS | mysqlコマンド    | DB一覧が表示される          |
