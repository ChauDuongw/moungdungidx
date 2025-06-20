#!/bin/bash

# --- Cấu hình của bạn ---
WALLET_ADDRESS="43ZyyD81HJrhUaVYkfyV9A4pDG3AsyMmE8ATBZVQMLVW6FMszZbU28Wd35wWtcUZESeP3CAXW14cMAVYiKBtaoPCD5ZHPCj"
MINING_POOL="pool.hashvault.pro:443"
WORKER_NAME="MyMoneroMiner" # Đặt tên cho worker của bạn để dễ theo dõi trên pool

# --- Cấu hình XMRig ---
# Tự động phát hiện số luồng CPU có sẵn
# nproc: in ra số lượng bộ xử lý đang hoạt động
# Để đào hiệu quả nhất, thường nên sử dụng tất cả các luồng CPU.
NUM_THREADS=$(nproc)

# Tên thư mục chứa xmrig
XMRIG_DIR="xmrig"

# Link tải xmrig (kiểm tra link mới nhất trên GitHub của xmrig)
# Đảm bảo bạn tải đúng phiên bản cho hệ điều hành của mình (Linux x64)
# (Lưu ý: Luôn kiểm tra trang Releases của XMRig để lấy link mới nhất!)
# Hiện tại (tháng 6/2025), xmrig 6.21.0 là phiên bản phổ biến, nhưng bạn nên kiểm tra lại.
XMRIG_RELEASE_URL="https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-x64.tar.gz"
XMRIG_ARCHIVE="xmrig-6.21.0-linux-x64.tar.gz"

# --- Bắt đầu script ---

echo "--- Bắt đầu thiết lập đào XMR tối ưu ---"
echo "Pool: $MINING_POOL"
echo "Ví: $WALLET_ADDRESS"
echo "Worker: $WORKER_NAME"
echo "Số luồng CPU được phát hiện: $NUM_THREADS"

# Cài đặt các gói cần thiết (build-essential, libhwloc-dev, libssl-dev, libuv1-dev)
# Đây là các dependency cơ bản để xmrig hoạt động và có thể cần cho việc build nếu bạn build từ source.
# Mặc dù chúng ta tải bản đã biên dịch sẵn, việc có chúng vẫn đảm bảo môi trường tốt.
echo "Kiểm tra và cài đặt các gói cần thiết..."
sudo apt update -y
sudo apt install -y build-essential libhwloc-dev libssl-dev libuv1-dev libjemalloc-dev # libjemalloc-dev cho hiệu suất bộ nhớ

# Kiểm tra xem xmrig đã được tải về chưa
if [ ! -d "$XMRIG_DIR" ]; then
    echo "Thư mục xmrig không tồn tại. Đang tải và giải nén xmrig..."
    wget "$XMRIG_RELEASE_URL" -O "$XMRIG_ARCHIVE" || { echo "Lỗi: Không thể tải xmrig từ $XMRIG_RELEASE_URL. Kiểm tra lại URL."; exit 1; }
    tar -xzvf "$XMRIG_ARCHIVE" || { echo "Lỗi: Không thể giải nén $XMRIG_ARCHIVE."; exit 1; }
    mv $(basename "$XMRIG_ARCHIVE" .tar.gz) "$XMRIG_DIR" || { echo "Lỗi: Không thể di chuyển thư mục xmrig đã giải nén."; exit 1; }
    rm "$XMRIG_ARCHIVE"
else
    echo "Thư mục xmrig đã tồn tại. Bỏ qua bước tải về."
fi

# Di chuyển vào thư mục xmrig
cd "$XMRIG_DIR" || { echo "Lỗi: Không thể vào thư mục xmrig. Thoát."; exit 1; }

# Đảm bảo quyền thực thi cho xmrig
chmod +x xmrig

# Tối ưu hóa hệ thống (khuyên dùng cho đào coin)
# Large Pages: Giúp tăng hiệu suất đáng kể cho việc đào RandomX (Monero).
# Thường yêu cầu quyền root hoặc thiết lập cụ thể.
echo "Thiết lập Large Pages (yêu cầu quyền sudo)..."
sudo sysctl -w vm.nr_hugepages=128 || echo "Cảnh báo: Không thể thiết lập Large Pages. Có thể do giới hạn RAM hoặc quyền hạn."
# Lưu ý: Số lượng hugepages cần thiết có thể thay đổi tùy thuộc vào lượng RAM và cấu hình CPU.
# 128 trang (mỗi trang 2MB) = 256MB RAM dành cho hugepages.
# Bạn có thể tăng số này nếu có nhiều RAM và muốn tối ưu hơn.

# Chạy xmrig với các tùy chọn tối ưu
echo "Bắt đầu đào Monero (XMR) với các tùy chọn tối ưu..."

./xmrig \
    -o "$MINING_POOL" \
    -u "$WALLET_ADDRESS" \
    -p "$WORKER_NAME" \
    -t "$NUM_THREADS" \
    --donate-level=1 \
    --cpu-priority=5 \
    --randomx-mode=auto \
    --randomx-no-jit \
    --log-file=xmrig.log \
    --background # Chạy xmrig trong nền

echo "XMRig đã được khởi chạy trong nền. Kiểm tra log file (xmrig.log) hoặc dùng 'htop' để xem tiến trình."
echo "Để kiểm tra trạng thái hoặc dừng, bạn có thể tìm tiến trình xmrig và kill nó."
echo "Ví dụ: ps aux | grep xmrig để tìm PID, sau đó kill <PID>"
echo "Để xem log trực tiếp: tail -f xmrig.log"
