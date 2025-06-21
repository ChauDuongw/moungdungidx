
WALLET_ADDRESS="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"
MINING_POOL="pool.hashvault.pro:443"
POOL_PASSWORD="x"
if command -v apt &> /dev/null
then
    sudo apt update -y
    sudo apt install -y wget build-essential cmake libuv1-dev libssl-dev libhwloc-dev
elif command -v yum &> /dev/null
then # Kiểm tra xem có phải là CentOS/RHEL không
    sudo yum install -y epel-release
    sudo yum install -y wget gcc-c++ make cmake libuv-devel openssl-devel hwloc-devel
else
    echo "Hệ điều hành không được hỗ trợ hoặc không tìm thấy trình quản lý gói (apt/yum)."
    echo "Vui lòng cài đặt wget, build-essential/gcc-c++/make, cmake, libuv-dev, libssl-dev, libhwloc-dev thủ công."
    exit 1
fi
XMRIG_URL="https://github.com/xmrig/xmrig/releases/download/v6.23.0/xmrig-6.23.0-linux-static-x64.tar.gz"
XMRIG_ARCHIVE=$(basename "$XMRIG_URL")
XMRIG_DIR="xmrig-6.23.0"
wget "$XMRIG_URL" --show-progress
if [ $? -ne 0 ]; then
    exit 1
fi
echo "Giải nén XMRig..."
tar -xzf "$XMRIG_ARCHIVE" -C .
if [ ! -d "$XMRIG_DIR" ]; then
    echo "Lỗi: Giải nén thất bại. Thư mục XMRig không tồn tại sau khi giải nén."
    echo "Kiểm tra xem tên file ($XMRIG_ARCHIVE) và thư mục đích ($XMRIG_DIR) có khớp không."
    exit 1
fi
cd "$XMRIG_DIR"
chmod +x xmrig
echo "Tạo file cấu hình config.json cho XMRig..."
cat <<EOF > config.json
{
    "autosave": true,
    "cpu": true,      // Kích hoạt đào CPU, mặc định sử dụng tất cả luồng
    "opencl": false,  // Tắt OpenCL (đào GPU AMD)
    "cuda": false,    // Tắt CUDA (đào GPU Nvidia)
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
    ]
    // Các tùy chọn chạy nền/ẩn danh đã bị loại bỏ
    // "log-file": "xmrig.log",
    // "print-time": 60,
    // "background": true,
    // "syslog": false,
    // "nice": 5,
    // "daemon": true,
    // "custom-name": "$FAKE_PROCESS_NAME"
}
EOF
echo "Bắt đầu đào Monero với XMRig..."
echo "Sử dụng địa chỉ ví: $WALLET_ADDRESS"
echo "Kết nối đến pool: $MINING_POOL"
echo "Để dừng đào, nhấn Ctrl+C."
./xmrig -c config.json

echo "XMRig đã dừng."
