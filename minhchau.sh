#!/bin/bash

# Thông tin cấu hình đào
POOL_URL="pool.hashvault.pro:443"
WALLET="43ZyyD81HJrhUaVYkfyV9A4pDG3AsyMmE8ATBZVQMLVW6FMszZbU28Wd35wWtcUZESeP3CAXW14cMAVYiKBtaoPCD5ZHPCj"
WORKER_NAME="EPYC-Miner"
USE_TLS="--tls"

# Lựa chọn phiên bản XMRig
XMRIG_VERSION="6.21.0" # Cập nhật nếu có phiên bản mới hơn
XMRIG_TAR_FILE="xmrig-${XMRIG_VERSION}-linux-x64.tar.gz"
XMRIG_DOWNLOAD_URL="https://github.com/xmrig/xmrig/releases/download/v${XMRIG_VERSION}/${XMRIG_TAR_FILE}"
XMRIG_DIR="/opt/monero_miner/xmrig-${XMRIG_VERSION}" # Thay đổi đường dẫn để phù hợp với systemd service

# --- Bắt đầu phần kiểm tra và cài đặt gói cần thiết ---
echo "--- Kiểm tra và cài đặt các gói cần thiết ---"
# Cập nhật danh sách gói
sudo apt update || { echo "Lỗi khi cập nhật apt. Kiểm tra kết nối mạng hoặc kho lưu trữ."; exit 1; }

# Cài đặt các gói cần thiết. -y để tự động đồng ý.
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev screen htop glances lm-sensors || { echo "Lỗi khi cài đặt các gói. Vui lòng kiểm tra lại."; exit 1; }
echo "--- Các gói cần thiết đã được cài đặt hoặc đã có sẵn ---"
# --- Kết thúc phần kiểm tra và cài đặt gói cần thiết ---


# Tạo thư mục và di chuyển vào đó (nếu chưa có)
mkdir -p /opt/monero_miner

# Tải và giải nén XMRig (chỉ thực hiện nếu chưa có)
if [ ! -d "${XMRIG_DIR}" ]; then
    echo "Thiết lập XMRig lần đầu..."
    cd /opt/monero_miner
    wget -q --show-progress ${XMRIG_DOWNLOAD_URL} || { echo "Lỗi khi tải XMRig."; exit 1; }
    tar -xzvf ${XMRIG_TAR_FILE} -C /opt/monero_miner || { echo "Lỗi khi giải nén XMRig."; exit 1; }
    rm ${XMRIG_TAR_FILE} # Xóa file nén sau khi giải nén
    chmod +x ${XMRIG_DIR}/xmrig
    echo "Thiết lập XMRig hoàn tất."
else
    echo "XMRig đã sẵn sàng tại ${XMRIG_DIR}."
fi

# Chuyển đến thư mục XMRig
cd ${XMRIG_DIR}

# Tính toán số luồng cần dùng dựa trên tổng số luồng khả dụng và phần trăm mong muốn.
TOTAL_CPUS=$(nproc)
TARGET_CPU_PERCENT=90 # Giới hạn 90% CPU cores/threads
NUM_THREADS=$(( (TOTAL_CPUS * TARGET_CPU_PERCENT) / 100 ))
if [ "$NUM_THREADS" -lt 1 ]; then
    NUM_THREADS=1
fi
echo "Tổng số luồng CPU khả dụng: ${TOTAL_CPUS}"
echo "Sẽ sử dụng khoảng ${NUM_THREADS} luồng cho XMRig (${TARGET_CPU_PERCENT}%)."

# Chạy XMRig với các tham số đã cấu hình
exec ${XMRIG_DIR}/xmrig -o ${POOL_URL} -u ${WALLET}.${WORKER_NAME} ${USE_TLS} --cpu --randomx-mode=auto --cpu-max-threads-hint=${NUM_THREADS}
