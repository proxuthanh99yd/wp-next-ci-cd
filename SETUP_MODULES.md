# WordPress + NextJS VPS Setup Modules

Dự án này đã được tách thành các module riêng biệt để dễ quản lý và bảo trì.

## Cấu trúc Module

### 1. `setup-vps.sh` (File chính)

-   File điều khiển chính, import và chạy tất cả các module
-   Tự động cấp quyền thực thi cho tất cả script setup
-   Chạy các module theo thứ tự logic

### 2. `setup-env.sh`

-   **Chức năng**: Xử lý environment variables và cấu hình ban đầu
-   **Nhiệm vụ**:
    -   Load file .env
    -   Clone repository
    -   Tạo file .env từ template
    -   Clone NextJS repo (nếu có)
    -   Validate configuration
    -   Generate nginx config

### 3. `setup-docker.sh`

-   **Chức năng**: Cài đặt Docker và Certbot
-   **Nhiệm vụ**:
    -   Cài đặt Docker và Docker Compose
    -   Cài đặt Git
    -   Cài đặt Certbot
    -   Verify installations

### 4. `setup-system.sh`

-   **Chức năng**: Cài đặt system dependencies khác
-   **Nhiệm vụ**:
    -   Update system packages
    -   Cài đặt curl, wget, unzip, net-tools

### 5. `setup-ssl.sh`

-   **Chức năng**: Cấu hình SSL certificates
-   **Nhiệm vụ**:
    -   Generate SSL certificates cho domains
    -   Verify certificates

### 6. `setup-wordpress.sh`

-   **Chức năng**: Cài đặt và cấu hình WordPress
-   **Nhiệm vụ**:
    -   Start WordPress và database containers
    -   Fix permissions
    -   Cài đặt WP-CLI
    -   Wait for WordPress to be ready

### 7. `setup-plugins.sh`

-   **Chức năng**: Cài đặt WordPress plugins
-   **Nhiệm vụ**:
    -   Cài đặt plugins theo thứ tự ưu tiên
    -   Activate plugins
    -   Verify WordPress functionality

### 8. `setup-backup.sh`

-   **Chức năng**: Xử lý backup và restore WordPress
-   **Nhiệm vụ**:
    -   Download backup từ URL (nếu có)
    -   Tìm backup file local
    -   Restore backup sử dụng AI1WM plugin
    -   Fix permissions sau restore

### 9. `setup-nginx-wordpress.sh`

-   **Chức năng**: Cấu hình Nginx cho WordPress
-   **Nhiệm vụ**:
    -   Start Nginx container
    -   Generate nginx config cho WordPress
    -   Import file `wordpress.conf` vào `default.conf`
    -   Verify và reload nginx config

### 10. `setup-nextjs.sh`

-   **Chức năng**: Cài đặt và cấu hình NextJS
-   **Nhiệm vụ**:
    -   Build NextJS container
    -   Start NextJS service
    -   Wait for NextJS to be ready

### 11. `setup-nginx-nextjs.sh`

-   **Chức năng**: Cấu hình Nginx cho NextJS
-   **Nhiệm vụ**:
    -   Import file `nextjs.conf` vào `default.conf`
    -   Enable NextJS nginx configuration
    -   Verify và reload nginx config

### 12. `setup-verification.sh`

-   **Chức năng**: Kiểm tra và hiển thị trạng thái cuối cùng
-   **Nhiệm vụ**:
    -   Check tất cả services
    -   Hiển thị thông tin truy cập
    -   Hiển thị next steps

## Cách sử dụng

### Chạy toàn bộ setup:

```bash
./setup-vps.sh
```

### Chạy từng module riêng lẻ:

```bash
# Setup environment
./setup-env.sh

# Setup Docker and Certbot
./setup-docker.sh

# Setup system dependencies
./setup-system.sh

# Setup SSL
./setup-ssl.sh

# Setup WordPress
./setup-wordpress.sh

# Setup plugins
./setup-plugins.sh

# Setup backup
./setup-backup.sh

# Setup Nginx for WordPress
./setup-nginx-wordpress.sh

# Setup NextJS
./setup-nextjs.sh

# Setup Nginx for NextJS
./setup-nginx-nextjs.sh

# Verification
./setup-verification.sh
```

## Lợi ích của việc tách module

1. **Dễ bảo trì**: Mỗi module có chức năng riêng biệt, dễ sửa đổi
2. **Tái sử dụng**: Có thể chạy từng module độc lập
3. **Debug dễ dàng**: Dễ xác định lỗi ở module nào
4. **Code sạch**: File chính ngắn gọn, dễ đọc
5. **Linh hoạt**: Có thể skip hoặc thay đổi thứ tự các module

## Lưu ý

-   Tất cả module phải được chạy từ thư mục gốc của project
-   Environment variables được load từ file .env
-   Các module phụ thuộc vào nhau theo thứ tự đã định
-   Mỗi module có thông báo completion riêng

## Cấu trúc Nginx Configuration

Dự án sử dụng cấu trúc nginx modular với các file riêng biệt:

### Files nginx:

-   `nginx/default.conf` - File cấu hình chính, import các module khác
-   `nginx/wordpress.conf` - Cấu hình riêng cho WordPress
-   `nginx/nextjs.conf` - Cấu hình riêng cho NextJS

### Cách hoạt động:

1. `default.conf` import `wordpress.conf` ngay từ đầu
2. `nextjs.conf` được import sau khi NextJS sẵn sàng
3. Các file được mount vào container nginx qua docker-compose
4. Không cần copy file thủ công vào container

## Files đã được tối ưu

Sau khi tách module, các file sau đã được xóa để tránh trùng lặp:

-   `setup-vps-safe.sh` - Chức năng đã được tích hợp vào module system
-   `install-wordpress-plugins.sh` - Chức năng đã được tích hợp vào `setup-plugins.sh`
-   `setup-wp-cli.sh` - Chức năng đã được tích hợp vào `setup-wordpress.sh`
-   `setup-nginx.sh` - Đã tách thành 2 module riêng biệt

Các file còn lại:

-   `recover-setup.sh` - Tool recovery riêng biệt, giữ lại
-   `check-services.sh` - Tool kiểm tra services, giữ lại
-   `generate-nginx-config.sh` - Tool generate nginx config, giữ lại
-   `validate-config.sh` - Tool validate config, giữ lại
