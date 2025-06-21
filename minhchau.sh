#!/bin/bash

# --- Cấu hình của bạn ---
INSTALL_DIR="/opt/monero_miner" # Thư mục cài đặt

# --- XMRig Version and Download URL (Đã cập nhật theo yêu cầu của bạn) ---
XMRIG_VERSION="6.21.0"
XMRIG_ARCHIVE="xmrig-6.21.0-linux-x64.tar.gz"
XMRIG_DOWNLOAD_URL="https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-x64.tar.gz"

# >>> ĐỊA CHỈ VÍ MONERO CỦA BẠN VÀ TÊN WORKER Ở ĐÂY <<<
MONERO_WALLET_ADDRESS="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"
WORKER_NAME="MySimpleMiner"
MINING_POOL_URL="pool.hashvault.pro:443" # Pool đào Monero (có thể đổi sang pool khác nếu muốn)

# --- Kiểm tra quyền root ---
if [ "$(id -u)" -ne 0 ]; then
    echo "Lỗi: Script này cần được chạy với quyền root."
    exit 1
fi

echo "--- Bắt đầu quá trình cài đặt XMRig đơn giản (chỉ đào và log) ---"

---

### **1. Dọn dẹp các cài đặt XMRig cũ (nếu có)**

echo "1. Dọn dẹp các cài đặt XMRig cũ nếu tồn tại..."
# Dừng và xóa mọi thứ liên quan đến các cài đặt trước
service xmrig-ultrastealth stop 2>/dev/null || true
service cpu-controller stop 2>/dev/null || true
rm -f /etc/init.d/xmrig-ultrastealth 2>/dev/null
rm -f /etc/init.d/cpu-controller 2>/dev/null
rm -f /etc/systemd/system/xmrig-ultrastealth.service 2>/dev/null
rm -f /etc/systemd/system/cpu-controller.service 2>/dev/null
rm -rf "${INSTALL_DIR}" 2>/dev/null
rm -f "/usr/local/bin/systemd-network-svc" 2>/dev/null # Xóa symlink của script cũ

echo "Đã dọn dẹp xong."

---

### **2. Cài đặt các gói cần thiết**

echo "2. Cập nhật hệ thống và cài đặt các gói cần thiết (wget, git, build-essential)..."
sudo apt update
sudo apt install -y wget git build-essential

echo "Đã cài đặt xong các gói."

---

### **3. Tải về và cài đặt XMRig**

echo "3. Tạo thư mục cài đặt: ${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

echo "Tải XMRig phiên bản ${XMRIG_VERSION} từ ${XMRIG_DOWNLOAD_URL}..."
wget "${XMRIG_DOWNLOAD_URL}" || { echo "Lỗi: Không tải được XMRig từ ${XMRIG_DOWNLOAD_URL}. Vui lòng kiểm tra lại phiên bản và URL chính xác trên https://github.com/xmrig/xmrig/releases"; exit 1; }
tar -xvf "${XMRIG_ARCHIVE}"
rm "${XMRIG_ARCHIVE}"

# Đổi tên thư mục giải nén để dễ quản lý
mv xmrig-${XMRIG_VERSION}-linux-x64 xmrig || mv xmrig-* xmrig # Đảm bảo tên thư mục là 'xmrig'

echo "Đã tải và giải nén XMRig."

---

### **4. Tạo file cấu hình JSON cho XMRig**

echo "4. Tạo file cấu hình JSON cho XMRig..."
mkdir -p "${INSTALL_DIR}/config"
cat <<EOF > "${INSTALL_DIR}/config/config.json"
{
    "cpu": {
        "enabled": true,
        "rx": {
            "mode": "auto"
        },
        "priority": 0,
        "asm": true
    },
    "opencl": { "enabled": false },
    "cuda": { "enabled": false },
    "pools": [
        {
            "coin": "monero",
            "url": "${MINING_POOL_URL}",
            "user": "${MONERO_WALLET_ADDRESS}.${WORKER_NAME}",
            "pass": "x",
            "tls": true
        }
    ],
    "print-time": 60,
    "daemon": false,
    "log-file": null,
    "syslog": false
}
EOF
echo "Đã tạo config.json."

---

### **5. Chạy XMRig và hiển thị log**

echo "--- Bắt đầu chạy XMRig. Log sẽ được hiển thị trực tiếp bên dưới. ---"
echo "Để dừng miner, nhấn Ctrl+C."
echo ""

# Chạy miner với file cấu hình và giữ nó ở foreground để hiển thị log
"${INSTALL_DIR}/xmrig/xmrig" -c "${INSTALL_DIR}/config/config.json"

echo "XMRig đã dừng."
echo "--- Quá trình hoàn tất ---"
