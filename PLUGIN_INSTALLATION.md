# WordPress Plugin Installation Guide

## Tổng quan

Dự án này bao gồm hệ thống tự động cài đặt plugin WordPress từ folder `wp-plugin` sau khi WordPress đã được cài đặt.

## Cấu trúc thư mục

```
your-project/
├── wp-plugin/                    # Chứa các file plugin .zip
│   ├── all-in-one-wp-migration.zip
│   └── all-in-one-wp-migration-unlimited-extension.zip
├── install-wordpress-plugins.sh  # Script cài đặt plugin
├── setup-wp-cli.sh              # Script cài đặt WP-CLI
├── check-services.sh            # Script kiểm tra trạng thái service
└── setup-vps.sh                 # Script setup chính (đã được cập nhật)
```

## Cách sử dụng

### 1. Tự động cài đặt (Khuyến nghị)

Khi chạy `setup-vps.sh`, script sẽ tự động theo thứ tự:

1. **Database (MySQL)** - Khởi động trước
2. **WordPress** - Chờ database sẵn sàng
3. **Cài đặt WP-CLI** - Nếu chưa có
4. **Cài đặt plugin** - Từ folder `wp-plugin`
5. **Xác minh WordPress** - Đảm bảo hoạt động ổn định
6. **NextJS** - Chỉ build và start sau khi WordPress hoàn tất
7. **Nginx** - Start cuối cùng (phụ thuộc cả WordPress và NextJS)

```bash
chmod +x setup-vps.sh
./setup-vps.sh
```

### 2. Cài đặt thủ công

Nếu WordPress đã được cài đặt, bạn có thể chạy riêng script cài đặt plugin:

```bash
chmod +x install-wordpress-plugins.sh
./install-wordpress-plugins.sh
```

### 3. Cài đặt WP-CLI riêng

Nếu chỉ muốn cài đặt WP-CLI:

```bash
chmod +x setup-wp-cli.sh
./setup-wp-cli.sh
```

### 4. Kiểm tra trạng thái service

Để kiểm tra trạng thái tất cả service:

```bash
chmod +x check-services.sh
./check-services.sh
```

## Thêm plugin mới

1. Tải plugin dưới dạng file `.zip`
2. Đặt vào folder `wp-plugin/`
3. Chạy lại script cài đặt plugin

```bash
# Ví dụ: thêm plugin mới
cp /path/to/new-plugin.zip wp-plugin/
./install-wordpress-plugins.sh
```

## Các plugin hiện có

-   **All-in-One WP Migration**: Plugin backup và migrate WordPress
-   **All-in-One WP Migration Unlimited Extension**: Extension để tăng giới hạn upload

## Thứ tự cài đặt plugin

Plugin sẽ được cài đặt theo thứ tự cụ thể để đảm bảo tương thích:

1. **all-in-one-wp-migration** - Plugin chính
2. **all-in-one-wp-migration-unlimited-extension** - Extension (phụ thuộc plugin chính)
3. **Các plugin khác** - Nếu có thêm plugin trong folder

### Tại sao cần thứ tự này?

-   Extension cần plugin chính đã được cài đặt và kích hoạt
-   Plugin chính phải hoạt động ổn định trước khi cài extension
-   Tránh lỗi dependency và conflict

## Backup và Restore

Sau khi cài đặt plugin, script sẽ tự động:

1. **Tải backup** từ URL trong biến `WORDPRESS_BACKUP_URL`
2. **Lưu vào thư mục** `/var/www/html/wp-content/ai1wm-backups/`
3. **Restore backup** bằng lệnh `wp ai1wm restore`
4. **Xác minh** WordPress hoạt động sau restore

### Cấu hình backup

Thêm vào file `.env`:

```bash
WORDPRESS_BACKUP_URL=https://your-domain.com/backup.wpress
```

### Quy trình restore

```bash
# Script tự động thực hiện:
curl -L -o /var/www/html/wp-content/ai1wm-backups/backup.wpress $WORDPRESS_BACKUP_URL
wp ai1wm restore /var/www/html/wp-content/ai1wm-backups/backup.wpress --allow-root
```

## Troubleshooting

### Plugin không cài được

1. Kiểm tra container WordPress có đang chạy không:

```bash
docker ps | grep wordpress
```

2. Kiểm tra logs:

```bash
docker logs wordpress
```

3. Kiểm tra file plugin có hợp lệ không:

```bash
unzip -t wp-plugin/plugin-name.zip
```

### WP-CLI không hoạt động

1. Cài đặt lại WP-CLI:

```bash
./setup-wp-cli.sh
```

2. Kiểm tra phiên bản:

```bash
docker exec wordpress wp --version --allow-root
```

### Plugin đã cài nhưng không active

Kiểm tra danh sách plugin:

```bash
docker exec wordpress wp plugin list --allow-root
```

Kích hoạt plugin thủ công:

```bash
docker exec wordpress wp plugin activate plugin-name --allow-root
```

## Lệnh WP-CLI hữu ích

```bash
# Liệt kê plugin
docker exec wordpress wp plugin list --allow-root

# Cài đặt plugin từ WordPress.org
docker exec wordpress wp plugin install plugin-name --activate --allow-root

# Cập nhật plugin
docker exec wordpress wp plugin update --all --allow-root

# Backup database
docker exec wordpress wp db export backup.sql --allow-root

# Import database
docker exec wordpress wp db import backup.sql --allow-root
```

## Thứ tự cài đặt

Để đảm bảo NextJS hoạt động ổn định, WordPress phải được cài đặt hoàn toàn trước:

1. **Database** → **WordPress** → **Plugins** → **NextJS** → **Nginx**

### Tại sao cần thứ tự này?

-   **NextJS** có thể cần kết nối với WordPress API
-   **Plugin** có thể thay đổi cấu trúc database
-   **Nginx** cần cả WordPress và NextJS để proxy đúng

## Lưu ý

-   Script sẽ tự động kích hoạt plugin sau khi cài đặt
-   Nếu plugin đã tồn tại, script sẽ bỏ qua và không cài lại
-   Tất cả plugin sẽ được cài đặt với quyền admin (--allow-root)
-   Backup database trước khi cài đặt plugin mới là khuyến nghị
-   WordPress sẽ được xác minh hoạt động trước khi start NextJS
