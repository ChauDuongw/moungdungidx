#!/bin/bash

# --- Cấu hình CỦA BẠN (Đã cập nhật) ---
WALLET_ADDRESS="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"
MINING_POOL="pool.hashvault.pro:443"
POOL_PASSWORD="x" # Mật khẩu pool (thường là 'x' hoặc trống)

# --- Cấu hình Đường dẫn & Tên file (Có thể thay đổi nếu cần) ---
MINER_DIR="/opt/xmrig_miner"          # Thư mục cài đặt miner
MINER_BINARY_NAME="xmrig"             # Tên file nhị phân của XMRig

# --- Cấu hình XMRig để Tối ưu hóa hiệu suất CPU ---
# "rx": null => Tự động phát hiện và sử dụng tất cả các luồng CPU tối ưu
# "nice": 0 => Đặt ưu tiên tiến trình cao nhất để có nhiều tài nguyên CPU
# "log-file": null => Không ghi log của XMRig ra file riêng
OPTIMIZED_XMRIG_CONFIG_CONTENT='
{
    "autosave": false,
    "cpu": {
        "enabled": true,
        "rx": null,
        "cctp": null,
        "asm": true
    },
    "opencl": false,
    "cuda": false,
    "pools": [
        {
            "algo": null,
            "coin": null,
            "url": "'"$MINING_POOL"'",
            "user": "'"$WALLET_ADDRESS"'",
            "pass": "'"$POOL_PASSWORD"'",
            "rig-id": null,
            "nicehash": false,
            "keepalive": true,
            "tls": true,
            "tls-fingerprint": null,
            "daemon": false,
            "socks5": null,
            "self-select": null,
            "log-in": null
        }
    ],
    "log-file": null,
    "print-time": 120,
    "background": true,
    "syslog": false,
    "nice": 0,
    "daemon": true,
    "custom-name": "xmrig"
}
'

# --- Tên service Systemd để tự khởi động và duy trì miner ---
SYSTEMD_SERVICE_NAME="xmrig-miner-service"

echo "Bắt đầu cài đặt XMRig và tối ưu hóa tốc độ đào Monero (chỉ đào)..."
echo "--------------------------------------------------------"
echo ">>> ĐỊA CHỈ VÍ VÀ POOL ĐÃ ĐƯỢC CẬP NHẬT TRONG SCRIPT! <<<"
echo "--------------------------------------------------------"
echo ""
echo "Script này sẽ cài đặt XMRig, cấu hình để đào tối đa CPU, và thiết lập một service để"
echo "nó tự động chạy và khởi động lại sau mỗi lần khởi động lại hệ thống."
echo "Không có tính năng ẩn giấu hay giả mạo tiến trình phức tạp."
sleep 5

# --- Cập nhật hệ thống và cài đặt các gói cần thiết ---
echo "1. Cập nhật hệ thống và cài đặt các gói cần thiết..."
if command -v apt &> /dev/null
then
    sudo apt update -y > /dev/null 2>&1
    sudo apt install -y wget build-essential libuv1-dev libssl-dev libhwloc-dev curl procps > /dev/null 2>&1
elif command -v yum &> /dev/null
then
    sudo yum install -y epel-release > /dev/null 2>&1
    sudo yum install -y wget gcc-c++ make cmake libuv-devel openssl-devel hwloc-devel curl procps > /dev/null 2>&1
else
    echo "Lỗi: Hệ điều hành không được hỗ trợ (chỉ hỗ trợ Debian/Ubuntu hoặc CentOS/RHEL). Vui lòng cài đặt thủ công các gói: wget, build-essential/gcc-c++, cmake, libuv-dev, libssl-dev, libhwloc-dev, curl, procps."
    exit 1
fi
echo "   Các gói cần thiết đã được cài đặt."

# --- Tạo thư mục miner ---
echo "2. Tạo thư mục miner tại $MINER_DIR..."
sudo mkdir -p "$MINER_DIR"
# Cấp quyền cho người dùng hiện tại để làm việc trong thư mục
sudo chown "$USER":"$USER" "$MINER_DIR"
cd "$MINER_DIR" || { echo "Lỗi: Không thể vào thư mục $MINER_DIR. Thoát."; exit 1; }
echo "   Đã vào thư mục $MINER_DIR."

# --- Tải XMRig ---
echo "3. Tải XMRig phiên bản mới nhất cho Linux (static build)..."
XMRIG_URL="https://github.com/xmrig/xmrig/releases/download/v6.23.0/xmrig-6.23.0-linux-static-x64.tar.gz"
XMRIG_ARCHIVE=$(basename "$XMRIG_URL")

wget "$XMRIG_URL" -q --show-progress
if [ $? -ne 0 ]; then
    echo "Lỗi: Không thể tải xuống XMRig. Thoát."
    exit 1
fi
echo "   Đã tải xuống XMRig."

# --- Giải nén XMRig và xóa file tải về ---
echo "4. Giải nén XMRig và chuẩn bị file nhị phân..."
tar -xzf "$XMRIG_ARCHIVE" --strip-components=1 -C .
mv xmrig "$MINER_BINARY_NAME"
chmod +x "$MINER_BINARY_NAME"
rm -f "$XMRIG_ARCHIVE"
echo "   Đã giải nén và chuẩn bị XMRig."

# --- Tạo file cấu hình XMRig ---
echo "5. Tạo file cấu hình XMRig (config.json) với các cài đặt tối ưu..."
echo "$OPTIMIZED_XMRIG_CONFIG_CONTENT" > config.json
echo "   Đã tạo config.json."

# --- Tạo script khởi động cho Systemd ---
echo "6. Tạo script khởi động cho XMRig miner (start_miner.sh)..."
cat <<EOF > start_miner.sh
#!/bin/bash
# Script khởi động XMRig
cd "$MINER_DIR"
exec "./$MINER_BINARY_NAME" -c config.json --daemon
EOF
chmod +x start_miner.sh
echo "   Đã tạo start_miner.sh."

# --- Cấu hình Systemd service để tự khởi động và duy trì ---
echo "7. Cấu hình Systemd service để tự động chạy và duy trì miner..."
SYSTEMD_UNIT_FILE="/etc/systemd/system/$SYSTEMD_SERVICE_NAME.service"
sudo bash -c "cat <<EOF_SERVICE > \"$SYSTEMD_UNIT_FILE\"
[Unit]
Description=XMRig Monero Miner Service
After=network.target

[Service]
ExecStart=$MINER_DIR/start_miner.sh
Restart=always
RestartSec=5
User=$USER
WorkingDirectory=$MINER_DIR
LimitNOFILE=1000000
CPUWeight=1000 # Đặt ưu tiên CPU cao

[Install]
WantedBy=multi-user.target
EOF_SERVICE"

sudo systemctl daemon-reload
sudo systemctl enable "$SYSTEMD_SERVICE_NAME" > /dev/null 2>&1
echo "   Đã cấu hình Systemd service: $SYSTEMD_SERVICE_NAME."

echo ""
echo "--------------------------------------------------------"
echo "CÀI ĐẶT ĐÃ HOÀN TẤT."
echo "--------------------------------------------------------"
echo "Để **KHỞI ĐỘNG** miner ngay bây giờ:"
echo "  sudo systemctl start $SYSTEMD_SERVICE_NAME"
echo ""
echo "Để **KIỂM TRA TRẠNG THÁI** của miner:"
echo "  sudo systemctl status $SYSTEMD_SERVICE_NAME"
echo ""
echo "Để **XEM LOG** của miner (để kiểm tra hoạt động):"
echo "  journalctl -u $SYSTEMD_SERVICE_NAME -f"
echo ""
echo "Để **DỪNG** miner:"
echo "  sudo systemctl stop $SYSTEMD_SERVICE_NAME"
echo ""
echo "Để **VÔ HIỆU HÓA** miner (ngừng tự khởi động và dừng):"
echo "  sudo systemctl disable $SYSTEMD_SERVICE_NAME && sudo systemctl stop $SYSTEMD_SERVICE_NAME"
echo ""
echo "Miner sẽ tự động khởi động sau mỗi lần hệ thống được khởi động lại."
echo "Vui lòng kiểm tra địa chỉ ví của bạn trên pool đào (hashvault.pro) sau vài phút để xác nhận hoạt động."
echo "Bạn có muốn khởi động miner ngay bây giờ không? (y/n)"
read -r START_NOW

if [[ "$START_NOW" =~ ^[Yy]$ ]]; then
    sudo systemctl start "$SYSTEMD_SERVICE_NAME"
    echo "Miner đã được khởi động. Vui lòng kiểm tra trạng thái và log."
    echo "Để xem log, gõ: journalctl -u $SYSTEMD_SERVICE_NAME -f"
else
    echo "Miner sẽ không được khởi động ngay. Bạn có thể khởi động thủ công bằng lệnh trên."
fi
