# WordPress + Next.js Docker Setup

Docker setup với WordPress CMS (cms.domain.com) và Next.js app (public domains).

## 🚀 Quick Setup

### 1. Clone repository

```bash
git clone <your-repo-url>
cd your-project
```

### 2. Configure environment

```bash
cp env.example .env
# Edit .env with your actual values
```

### 3. Run on VPS

```bash
# Safe setup (recommended)
chmod +x setup-vps.sh
./setup-vps.sh

# Or original setup
chmod +x setup-vps.sh
./setup-vps.sh
```

### 4. If setup fails, use recovery tool

```bash
chmod +x recover-setup.sh
./recover-setup.sh
```

## 📁 Project Structure

```
your-project/
├── docker-compose.yml          # Docker services
├── nginx/
│   └── default.conf           # Nginx config (auto-generated)
├── nextjs-app/
│   └── Dockerfile             # Next.js container
├── wp/                        # WordPress files
├── setup-vps.sh              # VPS setup script
├── setup-vps.sh              # Main VPS setup script
├── recover-setup.sh          # Recovery tool for failed setups
├── validate-config.sh        # Configuration validation
├── generate-nginx-config.sh   # Dynamic nginx config
├── env.example               # Environment template
└── .github/workflows/
    └── deploy-nextjs.yml     # CI/CD pipeline
```

## 🔑 SSH Keys Management

### Quick SSH Keys Setup

Nếu bạn chưa có SSH keys, sử dụng một trong các cách sau:

#### Cách 1: Tự động tạo (Recommended)

```bash
chmod +x get-ssh-keys.sh
./get-ssh-keys.sh --generate
```

#### Cách 2: Menu tương tác

```bash
chmod +x ssh-keys-manager.sh
./ssh-keys-manager.sh
```

#### Cách 3: Script riêng biệt

```bash
chmod +x generate-ssh-keys.sh
./generate-ssh-keys.sh
```

### SSH Keys Scripts

-   `get-ssh-keys.sh` - Kiểm tra và tạo SSH keys
-   `ssh-keys-manager.sh` - Menu quản lý SSH keys tương tác
-   `generate-ssh-keys.sh` - Tạo SSH keys tự động
-   `backup-ssh-keys.sh` - Backup SSH keys
-   `setup-ssh-server.sh` - Cài đặt SSH server và authorized_keys
-   `check-ssh-keys.sh` - Kiểm tra tổng quan SSH keys
-   `test-ssh-connection.sh` - Test SSH connection

### Usage Examples

```bash
# Kiểm tra trạng thái SSH keys
./get-ssh-keys.sh

# Tạo SSH keys nếu chưa có
./get-ssh-keys.sh --generate

# Quản lý SSH keys với menu
./ssh-keys-manager.sh

# Backup SSH keys
./backup-ssh-keys.sh

# Setup SSH server (on target server)
./setup-ssh-server.sh 'your-public-key-here'

# Comprehensive SSH keys check
./check-ssh-keys.sh

# Test SSH connection
./test-ssh-connection.sh user@server.com
```

## 🔧 Configuration

### Environment Variables (.env)

```bash
# Database
MYSQL_ROOT_PASSWORD=your_secure_password
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_PASSWORD=your_secure_password

# Domains
NEXTJS_DOMAINS=domain1.com domain2.com domain3.com
PRIMARY_DOMAIN=domain1.com
CMS_DOMAIN=cms.domain1.com

# SSL
SSL_EMAIL=your@email.com

# Project
PROJECT_NAME=your-project
SSH_USER=ubuntu
```

### GitHub Secrets

-   `SSH_PRIVATE_KEY`: Private SSH key for VPS
-   `SSH_USER`: VPS username
-   `SSH_HOST`: VPS IP/hostname
-   `PROJECT_NAME`: Project directory name

## 🌐 Access

-   **CMS**: `https://cms.domain1.com` (WordPress admin - có SSL)
-   **Next.js**: `https://domain1.com` (public)

## 🔄 CI/CD

Push to `main` branch triggers automatic deployment:

1. Pull latest code
2. Generate nginx config
3. Rebuild Next.js container
4. Restart services

## 🔄 Luồng hoạt động chi tiết

### Quy trình cài đặt tự động (setup-vps.sh)

Script `setup-vps.sh` thực hiện theo thứ tự sau:

#### 1. **Chuẩn bị hệ thống**

```bash
# Cập nhật hệ thống và cài đặt dependencies
sudo apt update
sudo apt install -y docker.io docker-compose git certbot
```

#### 2. **Cấu hình môi trường**

```bash
# Tạo file .env từ template
cp env.example .env

# Tự động generate giá trị mặc định:
- PRIMARY_DOMAIN=example.com
- CMS_DOMAIN=cms.example.com
- SSL_EMAIL=admin@example.com
- MYSQL_ROOT_PASSWORD=<random>
- MYSQL_PASSWORD=<random>
- WORDPRESS_DB_PASSWORD=<random>
- WORDPRESS_BACKUP_URL=https://example.com/backup.wpress
```

#### 3. **Tạo SSL certificates**

```bash
# Tạo SSL cho domain chính và CMS
sudo certbot certonly --standalone -m $SSL_EMAIL -d $PRIMARY_DOMAIN -d $CMS_DOMAIN
```

#### 4. **Khởi động Database**

```bash
# Start MySQL container trước
docker-compose up -d db
# Chờ 20s để database sẵn sàng
```

#### 5. **Khởi động WordPress**

```bash
# Start WordPress container
docker-compose up -d wordpress

# Chờ WordPress hoàn toàn sẵn sàng (tối đa 30 lần thử, mỗi lần 10s)
while [ $attempt -le $max_attempts ]; do
    if docker exec wordpress wp core is-installed --allow-root; then
        break
    fi
    sleep 10
done
```

#### 6. **Cài đặt WP-CLI**

```bash
# Tải và cài đặt WP-CLI vào WordPress container
docker exec wordpress curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
docker exec wordpress chmod +x wp-cli.phar
docker exec wordpress mv wp-cli.phar /usr/local/bin/wp
```

#### 7. **Cài đặt plugin theo thứ tự**

```bash
# Thứ tự cài đặt cụ thể:
1. all-in-one-wp-migration (plugin chính)
   - Copy file zip vào container
   - Cài đặt và kích hoạt
   - Chờ 5s để plugin hoàn tất

2. all-in-one-wp-migration-unlimited-extension (extension)
   - Copy file zip vào container
   - Cài đặt và kích hoạt
   - Chờ 5s để plugin hoàn tất

3. Các plugin khác (nếu có)
```

#### 8. **Tải và restore backup (nếu có)**

```bash
# Kiểm tra WORDPRESS_BACKUP_URL trong .env
if [ ! -z "$WORDPRESS_BACKUP_URL" ]; then
    # Tạo thư mục ai1wm-backups
    docker exec wordpress mkdir -p /var/www/html/wp-content/ai1wm-backups

    # Tải backup bằng curl
docker exec wordpress curl -L -o "/var/www/html/wp-content/ai1wm-backups/backup.wpress" "$WORDPRESS_BACKUP_URL"

    # Restore backup
    docker exec wordpress wp ai1wm restore "/var/www/html/wp-content/ai1wm-backups/backup.wpress" --allow-root

    # Chờ 10s để restore hoàn tất
    # Xác minh WordPress vẫn hoạt động
fi
```

#### 9. **Xác minh WordPress**

```bash
# Kiểm tra WordPress hoạt động ổn định sau khi cài plugin và restore
if docker exec wordpress wp core is-installed --allow-root; then
    echo "✅ WordPress is fully ready with plugins installed!"
else
    echo "❌ WordPress verification failed!"
    exit 1
fi
```

#### 10. **Build và start NextJS**

```bash
# Chỉ build và start NextJS sau khi WordPress hoàn tất
docker-compose build nextjs
docker-compose up -d nextjs

# Chờ 20s để NextJS sẵn sàng
```

#### 11. **Start Nginx**

```bash
# Start nginx cuối cùng (phụ thuộc cả WordPress và NextJS)
docker-compose up -d nginx
```

#### 12. **Kiểm tra cuối cùng**

```bash
# Kiểm tra tất cả service đang chạy
- Database (MySQL) ✅
- WordPress ✅
- NextJS ✅
- Nginx ✅

# Hiển thị thông tin truy cập
- WordPress Admin: http://localhost/wp-admin
- NextJS App: http://localhost:3000
- Nginx: http://localhost
```

### Tại sao cần thứ tự này?

1. **Database trước** - WordPress cần database để hoạt động
2. **WordPress trước NextJS** - NextJS có thể cần kết nối WordPress API
3. **Plugin trước backup** - Backup cần plugin để restore
4. **Plugin chính trước extension** - Extension phụ thuộc plugin chính
5. **Nginx cuối cùng** - Cần cả WordPress và NextJS để proxy đúng

### Xử lý lỗi

-   **SSL fail** → Tiếp tục (bình thường cho development)
-   **Plugin fail** → Tiếp tục với plugin khác
-   **Backup fail** → Tiếp tục (không bắt buộc)
-   **WordPress không sẵn sàng** → Thử lại tối đa 30 lần
-   **NextJS build fail** → Hiển thị lỗi và dừng

## 📝 Notes

-   CMS accessible qua domain với SSL tự động
-   Next.js domains có SSL tự động
-   Database data persistent qua volumes
-   Hot reload cho development
-   Plugin được cài đặt theo thứ tự cụ thể để tránh conflict
-   Backup được restore tự động nếu có URL trong .env
-   Tất cả quy trình hoàn toàn tự động, không cần tương tác thủ công
