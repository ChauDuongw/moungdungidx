# --- Cấu hình của bạn ---
# ĐỊA CHỈ VÍ MONERO CỦA BẠNAdd commentMore actions
WALLET_ADDRESS="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"

# POOL ĐÀO MONERO (HashVault.pro là một ví dụ tốt)
MINING_POOL="pool.hashvault.pro:443"

# MẬT KHẨU HOẶC TÊN WORKER (thường là 'x' hoặc tên bất kỳ)
POOL_PASSWORD="x"

# --- Bắt đầu Script ---

echo "Bắt đầu thiết lập và chạy XMRig để đào Monero (chế độ bình thường)..."

# 1. Cập nhật hệ thống và cài đặt các gói cần thiết
echo "Cập nhật hệ thống và cài đặt các gói cần thiết (wget, build-essential/cmake, libuv, libssl, libhwloc)..."
# Kiểm tra xem có phải là Debian/Ubuntu không
if command -v apt &> /dev/null
then
    sudo apt update -y
@@ -30,39 +15,22 @@ else
    echo "Vui lòng cài đặt wget, build-essential/gcc-c++/make, cmake, libuv-dev, libssl-dev, libhwloc-dev thủ công."
    exit 1
fi

# 2. Tải XMRig
echo "Tải XMRig phiên bản mới nhất cho Linux..."
# URL XMRig mới nhất cho Linux x64 static
XMRIG_URL="https://github.com/xmrig/xmrig/releases/download/v6.23.0/xmrig-6.23.0-linux-static-x64.tar.gz"

XMRIG_ARCHIVE=$(basename "$XMRIG_URL")
XMRIG_DIR="xmrig-6.23.0"

echo "Tải XMRig từ: $XMRIG_URL"
wget "$XMRIG_URL" --show-progress # Bỏ -q để thấy tiến trình tải

# Kiểm tra xem tải xuống có thành công không
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
    echo "Kiểm tra xem tên file ($XMRIG_ARCHIVE) và thư mục đích ($XMRIG_DIR) có khớp không."
    exit 1
fi

# 4. Di chuyển vào thư mục XMRig và cấp quyền thực thi
echo "Di chuyển vào thư mục XMRig và cấp quyền thực thi..."
cd "$XMRIG_DIR"
chmod +x xmrig

# 5. Tạo file cấu hình JSON (XMRig sẽ sử dụng tất cả CPU mặc định)
echo "Tạo file cấu hình config.json cho XMRig..."
cat <<EOF > config.json
{
@@ -98,14 +66,10 @@ cat <<EOF > config.json
    // "custom-name": "$FAKE_PROCESS_NAME"
}
EOF

# 6. Chạy XMRig trực tiếp
echo "Bắt đầu đào Monero với XMRig..."
echo "Sử dụng địa chỉ ví: $WALLET_ADDRESS"
echo "Kết nối đến pool: $MINING_POOL"
echo "Để dừng đào, nhấn Ctrl+C."

# Chạy xmrig bằng file cấu hình trực tiếp trong terminal
./xmrig -c config.json

echo "XMRig đã dừng."
