#!/bin/bash

# --- Cấu hình của bạn ---
# Địa chỉ ví Monero của bạn. HÃY THAY THẾ BẰNG ĐỊA CHỈ VÍ THỰC CỦA BẠN!
# Tôi sẽ sử dụng địa chỉ ví thứ hai bạn cung cấp vì nó là một địa chỉ XMR hợp lệ.
WALLET_ADDRESS="43ZyyD81HJrhUaVYkfyV9A4pDG3AsyMmE8ATBZVQMLVW6FMszZbU28Wd35wWtcUZESeP3CAXW14cMAVYiKBtaoPCD5ZHPCj"

# Pool đào Monero (ví dụ: HashVault.pro, bạn có thể thay đổi pool khác nếu muốn)
MINING_POOL="pool.hashvault.pro:443"

# Tên worker của bạn để dễ theo dõi trên pool. Đặt tên bất kỳ bạn thích.
WORKER_NAME="MyMoneroMiner"

# Mật khẩu hoặc tên worker (thường là 'x' hoặc tên bất kỳ)
POOL_PASSWORD="x" # Sử dụng "x" là mặc định cho hầu hết các pool nếu không có mật khẩu cụ thể.

# --- Cấu hình XMRig ---
# Tự động phát hiện số luồng CPU có sẵn để sử dụng tối đa tài nguyên.
NUM_THREADS=$(nproc)

# --- Thông tin XMRig ---
# Link tải xmrig (kiểm tra link mới nhất trên GitHub của xmrig).
# LUÔN KIỂM TRA TRANG RELEASES CỦA XMRIG (https://github.com/xmrig/xmrig/releases)
# ĐỂ LẤY LINK TẢI PHIÊN BẢN MỚI NHẤT VÀ ĐÚNG CHO LINUX X64!
# (Hiện tại là v6.23.0, nhưng bạn có thể cập nhật nếu có phiên bản mới hơn)
XMRIG_VERSION="6.23.0"
XMRIG_ARCHIVE_NAME="xmrig-${XMRIG_VERSION}-linux-static-x64.tar.gz"
XMRIG_URL="https://github.com/xmrig/xmrig/releases/download/v${XMRIG_VERSION}/${XMRIG_ARCHIVE_NAME}"
XMRIG_DIR="xmrig-${XMRIG_VERSION}" # Tên thư mục sau khi giải nén

echo "--- Bắt đầu thiết lập và chạy đào XMR ---"
echo "Pool đào: ${MINING_POOL}"
echo "Địa chỉ ví: ${WALLET_ADDRESS}"
echo "Tên worker: ${WORKER_NAME}"
echo "Số luồng CPU được phát hiện: ${NUM_THREADS}"
echo "Phiên bản XMRig: ${XMRIG_VERSION}"
echo "Tải XMRig từ: ${XMRIG_URL}"
echo ""

# --- 1. Cập nhật hệ thống và cài đặt các gói cần thiết ---
echo "Kiểm tra và cài đặt các gói cần thiết (wget, build-essential/cmake, libuv, libssl, libhwloc, libjemalloc)..."
if command -v apt &> /dev/null; then
    sudo apt update -y
    sudo apt install -y wget build-essential cmake libuv1-dev libssl-dev libhwloc-dev libjemalloc-dev
elif command -v yum &> /dev/null; then
    sudo yum install -y epel-release
    sudo yum install -y wget gcc-c++ make cmake libuv-devel openssl-devel hwloc-devel jemalloc-devel
else
    echo "Lỗi: Hệ điều hành không được hỗ trợ hoặc không tìm thấy trình quản lý gói (apt/yum)."
    echo "Vui lòng cài đặt wget, build-essential/gcc-c++/make, cmake, libuv-dev, libssl-dev, libhwloc-dev, libjemalloc-dev thủ công."
    exit 1
fi

echo ""

# --- 2. Tải về và giải nén XMRig ---
if [ ! -d "$XMRIG_DIR" ]; then
    echo "Tải XMRig phiên bản ${XMRIG_VERSION} cho Linux..."
    wget "${XMRIG_URL}" -O "${XMRIG_ARCHIVE_NAME}" --show-progress
    if [ $? -ne 0 ]; then
        echo "Lỗi: Không thể tải xuống XMRig từ ${XMRIG_URL}. Vui lòng kiểm tra lại URL hoặc kết nối internet."
        exit 1
    fi

    echo "Giải nén XMRig..."
    tar -xzf "${XMRIG_ARCHIVE_NAME}" -C .
    if [ $? -ne 0 ]; then
        echo "Lỗi: Giải nén ${XMRIG_ARCHIVE_NAME} thất bại."
        exit 1
    fi

    # Xóa file nén để giải phóng dung lượng
    echo "Xóa file nén ${XMRIG_ARCHIVE_NAME}..."
    rm "${XMRIG_ARCHIVE_NAME}"
else
    echo "Thư mục ${XMRIG_DIR} đã tồn tại. Bỏ qua bước tải về và giải nén."
fi

echo ""

# --- 3. Di chuyển vào thư mục XMRig và cấp quyền thực thi ---
echo "Di chuyển vào thư mục XMRig và cấp quyền thực thi..."
cd "$XMRIG_DIR" || { echo "Lỗi: Không thể vào thư mục ${XMRIG_DIR}. Thoát."; exit 1; }
chmod +x xmrig

echo ""

# --- 4. Cài đặt MSR mod (nếu có thể) ---
# MSR mod giúp tối ưu hóa hiệu suất CPU cho RandomX.
# Yêu cầu quyền root và module kernel msr.
echo "Cố gắng tải module msr và cấp quyền truy cập để tối ưu hóa hiệu suất..."
sudo modprobe msr
sudo chmod 666 /dev/cpu/*/msr
if [ $? -ne 0 ]; then
    echo "Cảnh báo: Không thể áp dụng MSR mod. Hasrate có thể thấp hơn."
fi

echo ""

# --- 5. Tạo file cấu hình JSON cho hiệu suất tối đa ---
# Xóa bỏ các tùy chọn không cần thiết hoặc trùng lặp để tối ưu
echo "Tạo file cấu hình config.json cho XMRig (tối ưu hóa tối đa)..."
cat <<EOF > config.json
{
    "autosave": true,
    "cpu": {
        "enabled": true,
        "rx": [0,1,2,3,4,5,6,7],
        "cctp": null,
        "asm": true
    },
    "opencl": false,
    "cuda": false,
    "pools": [
        {
            "algo": "rx/0",
            "coin": "monero",
            "url": "$MINING_POOL",
            "user": "$WALLET_ADDRESS",
            "pass": "$POOL_PASSWORD",
            "rig-id": "$WORKER_NAME",
            "nicehash": false,
            "keepalive": true,
            "tls": true,
            "daemon": false
        }
    ],
    "nice": 0,
    "print-time": 60,
    "background": true,
    "log-file": "xmrig.log"
}
EOF
# Giải thích về tùy chọn "rx": [0,1,2,3,4,5,6,7]
# Đây là ví dụ sử dụng 8 luồng CPU. Bạn nên điều chỉnh nó dựa trên NUM_THREADS
# hoặc để "rx": null để XMRig tự động quyết định.
# Tuy nhiên, việc chỉ định rõ các luồng thường tốt hơn cho hiệu suất ổn định.
# Ví dụ: if NUM_THREADS=4, bạn có thể đặt "rx": [0,1,2,3]
# Trong script này, tôi để nó thành một ví dụ cố định, bạn có thể thay đổi hoặc để null.
# Để XMRig tự động dùng tất cả luồng, bạn có thể dùng "rx": null.
# Để tạo danh sách các luồng tự động:
# RX_THREADS=""
# for i in $(seq 0 $((NUM_THREADS - 1))); do
#     RX_THREADS+="${i},"
# done
# RX_THREADS="[${RX_THREADS%,}]"
# Và sử dụng "$RX_THREADS" trong config.json. Tuy nhiên, để đơn giản, tôi sẽ để null.

# Sửa lại block JSON để tối ưu cho việc tự động phát hiện luồng
cat <<EOF > config.json
{
    "autosave": true,
    "cpu": {
        "enabled": true,
        "rx": null,     // Để XMRig tự động sử dụng tất cả luồng khả dụng
        "cctp": null,
        "asm": true
    },
    "opencl": false,
    "cuda": false,
    "pools": [
        {
            "algo": "rx/0",
            "coin": "monero",
            "url": "$MINING_POOL",
            "user": "$WALLET_ADDRESS",
            "pass": "$POOL_PASSWORD",
            "rig-id": "$WORKER_NAME",
            "nicehash": false,
            "keepalive": true,
            "tls": true,
            "daemon": false
        }
    ],
    "nice": 0,
    "print-time": 60,
    "background": true,
    "log-file": "xmrig.log"
}
EOF

echo ""

# --- 6. Chạy XMRig với độ ưu tiên cao nhất ---
echo "Bắt đầu đào Monero với XMRig với công suất tối đa..."
echo "Sử dụng địa chỉ ví: ${WALLET_ADDRESS}"
echo "Kết nối đến pool: ${MINING_POOL}"
echo "Logs sẽ được ghi vào file: ${XMRIG_DIR}/xmrig.log"
echo "XMRig sẽ chạy trong nền."
echo "Để kiểm tra trạng thái hoạt động, bạn có thể dùng: tail -f xmrig.log"
echo "Để kiểm tra tiến trình đang chạy: ps aux | grep xmrig"
echo "Để dừng quá trình đào: Tìm PID của xmrig từ lệnh 'ps aux | grep xmrig', sau đó chạy: sudo kill <PID>"

# Chạy XMRig sử dụng file config.json
# Sử dụng nice -n -20 để đặt độ ưu tiên CPU cao nhất (chỉ root có thể đặt -20)
# Hoặc sử dụng nice -n 0 để ưu tiên mặc định.
# Vì config.json đã có "nice": 0, việc dùng 'nice -n' bên ngoài có thể không cần thiết nếu bạn đã chạy với sudo.
# Tuy nhiên, để đảm bảo, tôi sẽ thêm 'sudo' khi chạy nếu bạn muốn ưu tiên cao nhất.
sudo ./xmrig -c config.json

echo ""
echo "--- XMRig đã được khởi chạy trong nền ---"
echo "Script đã hoàn thành."
