#!/bin/bash

# --- Cấu hình của bạn ---
# ĐỊA CHỈ VÍ MONERO CỦA BẠN
WALLET_ADDRESS="43ZyyD81HJrhUaVYkfyV9A4pDG3AsyMmE8ATBZVQMLVW6FMszZbU28Wd35wWtcUZESeP3CAXW14cMAVYiKBtaoPCD5ZHPCj"

# POOL ĐÀO MONERO
MINING_POOL="pool.hashvault.pro:443"

# MẬT KHẨU HOẶC TÊN WORKER (thường là 'x' hoặc tên bất kỳ)
POOL_PASSWORD="x"

# --- Bắt đầu Script ---

echo "Bắt đầu thiết lập và chạy XMRig với công suất tối đa và tối ưu hóa..."

# 1. Cập nhật hệ thống và cài đặt các gói cần thiết
echo "Cập nhật hệ thống và cài đặt các gói cần thiết (wget, build-essential/cmake, libuv, libssl, libhwloc)..."
if command -v apt &> /dev/null
then
    sudo apt update -y
    sudo apt install -y wget build-essential cmake libuv1-dev libssl-dev libhwloc-dev
elif command -v yum &> /dev/null
then
    sudo yum install -y epel-release
    sudo yum install -y wget gcc-c++ make cmake libuv-devel openssl-devel hwloc-devel
else
    echo "Hệ điều hành không được hỗ trợ hoặc không tìm thấy trình quản lý gói (apt/yum)."
    echo "Vui lòng cài đặt wget, build-essential/gcc-c++/make, cmake, libuv-dev, libssl-dev, libhwloc-dev thủ công."
    exit 1
fi

# 2. Tải XMRig
echo "Tải XMRig phiên bản mới nhất cho Linux..."
XMRIG_URL="https://github.com/xmrig/xmrig/releases/download/v6.23.0/xmrig-6.23.0-linux-static-x64.tar.gz"

XMRIG_ARCHIVE=$(basename "$XMRIG_URL")
XMRIG_DIR="xmrig-6.23.0"

echo "Tải XMRig từ: $XMRIG_URL"
wget "$XMRIG_URL" --show-progress

if [ $? -ne 0 ]; then
    echo "Lỗi: Không thể tải xuống XMRig từ $XMRIG_URL. Vui lòng kiểm tra lại URL hoặc kết nối internet."
    exit 1
fi

# 3. Giải nén XMRig
echo "Giải nén XMRig..."
tar -xzf "$XMRIG_ARCHIVE" -C .
if [ ! -d "$XMRIG_DIR" ]; then
    echo "Lỗi: Giải nén thất bại. Thư mục XMRig không tồn tại sau khi giải nén."
    exit 1
fi

# 4. Di chuyển vào thư mục XMRig và cấp quyền thực thi
echo "Di chuyển vào thư mục XMRig và cấp quyền thực thi..."
cd "$XMRIG_DIR"
chmod +x xmrig

# 5. Cài đặt MSR mod (nếu có thể)
# MSR mod giúp tối ưu hóa hiệu suất CPU cho RandomX.
# Yêu cầu quyền root và module kernel msr.
echo "Cố gắng tải module msr và cấp quyền truy cập để tối ưu hóa hiệu suất..."
sudo modprobe msr
sudo chmod 666 /dev/cpu/*/msr
if [ $? -ne 0 ]; then
    echo "Cảnh báo: Không thể áp dụng MSR mod. Hasrate có thể thấp hơn."
fi


# 6. Tạo file cấu hình JSON cho hiệu suất tối đa
echo "Tạo file cấu hình config.json cho XMRig (tối ưu hóa tối đa)..."
cat <<EOF > config.json
{
    "autosave": true,
    "cpu": {
        "enabled": true,
        "rx": null,     // Sử dụng 'null' để XMRig tự động sử dụng tất cả luồng khả dụng
        "cctp": null,
        "asm": true     // Tối ưu hóa assembly
    },
    "opencl": false,
    "cuda": false,
    "pools": [
        {
            "algo": null,
            "coin": null,
            "url": "$MINING_POOL",
            "user": "$WALLET_ADDRESS",
            "pass": "$POOL_PASSWORD",
            "rig-id": null,
            "nicehash": false,
            "keepalive": true,
            "tls": false,
            "tls-fingerprint": null,
            "daemon": false,
            "socks5": null,
            "self-select": null,
            "log-in": null
        }
    ],
    "nice": 0,          // Đặt nice value là 0 để ưu tiên CPU cao nhất cho XMRig
    "print-time": 5,    // In hashrate mỗi 5 giây (mặc định) để theo dõi liên tục
    "log-file": null,   // Không ghi log ra file, in trực tiếp ra console
    "background": false, // Không chạy nền
    "daemon": false      // Không chạy như daemon
}
EOF

# 7. Chạy XMRig với độ ưu tiên cao nhất
echo "Bắt đầu đào Monero với XMRig với công suất tối đa..."
echo "Sử dụng địa chỉ ví: $WALLET_ADDRESS"
echo "Kết nối đến pool: $MINING_POOL"
echo "Để dừng đào, nhấn Ctrl+C."

# Sử dụng 'ionice -c 1 -n 0' để đặt độ ưu tiên I/O (nếu có thể)
# Sử dụng 'taskset -c 0-N-1' để ghim vào các lõi CPU (tùy chọn nâng cao)
# Sử dụng 'numactl --interleave=all' để tối ưu NUMA (nếu có)
# Tuy nhiên, chỉ đơn giản chạy './xmrig -c config.json' là đủ để đạt gần tối đa.

./xmrig -c config.json

echo "XMRig đã dừng."
