#!/bin/bash

# --- Cấu hình của bạn ---
# Địa chỉ ví Monero của bạn. HÃY THAY THẾ BẰNG ĐỊA CHỈ VÍ THỰC CỦA BẠN!
WALLET_ADDRESS="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"

# Pool đào Monero (ví dụ: HashVault.pro, bạn có thể thay đổi pool khác nếu muốn)
MINING_POOL="pool.hashvault.pro:443"

# Tên worker của bạn để dễ theo dõi trên pool. Đặt tên bất kỳ bạn thích.
WORKER_NAME="MyMoneroMinerNoHugePages"

# --- Cấu hình XMRig ---
# Tự động phát hiện số luồng CPU có sẵn để sử dụng tối đa tài nguyên.
NUM_THREADS=$(nproc)

# Tên thư mục mà xmrig sẽ được giải nén vào.
XMRIG_DIR="xmrig"

# Link tải xmrig (kiểm tra link mới nhất trên GitHub của xmrig).
# TẠI THỜI ĐIỂM HIỆN TẠI (Tháng 6/2025), v6.21.0 là phiên bản phổ biến.
# LUÔN KIỂM TRA TRANG RELEASES CỦA XMRIG (https://github.com/xmrig/xmrig/releases)
# ĐỂ LẤY LINK TẢI PHIÊN BẢN MỚI NHẤT VÀ ĐÚNG CHO LINUX X64!
XMRIG_RELEASE_URL="https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-x64.tar.gz"
XMRIG_ARCHIVE="xmrig-6.21.0-linux-x64.tar.gz"

# Tên thư mục gốc sau khi giải nén file .tar.gz (đã sửa từ lỗi trước)
# Dựa vào output bạn cung cấp, nó là "xmrig-6.21.0"
EXTRACTED_DIR_NAME="xmrig-6.21.0"

# --- Bắt đầu script ---

echo "--- Bắt đầu thiết lập và chạy đào XMR (Không dùng Large Pages) ---"
echo "Pool đào: ${MINING_POOL}"
echo "Địa chỉ ví: ${WALLET_ADDRESS}"
echo "Tên worker: ${WORKER_NAME}"
echo "Số luồng CPU được phát hiện: ${NUM_THREADS}"

# --- Cài đặt các gói cần thiết ---
echo "Kiểm tra và cài đặt các gói cần thiết..."
# Cập nhật danh sách gói.
sudo apt update -y
# Cài đặt các gói cơ bản cần thiết cho xmrig và tối ưu bộ nhớ (libjemalloc-dev).
sudo apt install -y build-essential libhwloc-dev libssl-dev libuv1-dev libjemalloc-dev

# --- Tải về và giải nén XMRig ---
if [ ! -d "$XMRIG_DIR" ]; then
    echo "Thư mục ${XMRIG_DIR} không tồn tại. Đang tải và giải nén xmrig..."
    # Tải file nén xmrig
    wget "${XMRIG_RELEASE_URL}" -O "${XMRIG_ARCHIVE}" || { echo "Lỗi: Không thể tải xmrig từ ${XMRIG_RELEASE_URL}. Kiểm tra lại URL."; exit 1; }
    
    # Giải nén file đã tải về
    tar -xzvf "${XMRIG_ARCHIVE}" || { echo "Lỗi: Không thể giải nén ${XMRIG_ARCHIVE}."; exit 1; }
    
    # Di chuyển thư mục đã giải nén vào thư mục mong muốn
    # Đã sửa lỗi: sử dụng đúng tên thư mục sau khi giải nén
    mv "${EXTRACTED_DIR_NAME}" "${XMRIG_DIR}" || { echo "Lỗi: Không thể di chuyển thư mục xmrig đã giải nén (${EXTRACTED_DIR_NAME})."; exit 1; }
    
    # Xóa file nén để giải phóng dung lượng
    rm "${XMRIG_ARCHIVE}"
else
    echo "Thư mục ${XMRIG_DIR} đã tồn tại. Bỏ qua bước tải về."
fi

# Di chuyển vào thư mục xmrig để chạy miner
cd "${XMRIG_DIR}" || { echo "Lỗi: Không thể vào thư mục ${XMRIG_DIR}. Thoát."; exit 1; }

# Đảm bảo file xmrig có quyền thực thi
chmod +x xmrig

# --- Chạy XMRig ---
echo "Bắt đầu đào Monero (XMR) với các tùy chọn tối ưu..."
echo "Lưu ý: xmrig sẽ chạy trong nền."

./xmrig \
    -o "${MINING_POOL}" \
    -u "${WALLET_ADDRESS}" \
    -p "${WORKER_NAME}" \
    -t "${NUM_THREADS}" \
    --donate-level=1 \
    --cpu-priority=5 \
    --randomx-mode=auto \
    --log-file=xmrig.log \
    --background

echo "--- XMRig đã được khởi chạy trong nền ---"
echo "Bạn có thể kiểm tra trạng thái hoạt động bằng cách xem file log:"
echo "  tail -f xmrig.log"
echo "Để kiểm tra tiến trình đang chạy:"
echo "  ps aux | grep xmrig"
echo "Để dừng quá trình đào:"
echo "  Tìm PID của xmrig từ lệnh 'ps aux | grep xmrig', sau đó chạy: kill <PID>"
echo "Script đã hoàn thành."
