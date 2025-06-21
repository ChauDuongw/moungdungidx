#!/bin/bashAdd commentMore actions

# ==============================================================================
# CẤU HÌNH MINER
# Vui lòng điều chỉnh các giá trị này cho phù hợp với bạn
# ==============================================================================
# Script đào Monero với XMRig, tự động điều chỉnh số luồng CPU
# Dùng tham số --no-msr để tránh lỗi trên máy ảo không có MSR
# Địa chỉ pool và ví Monero được cập nhật theo yêu cầu

WALLET_ADDRESS="43ZyyD81HJrhUaVYkfyV9A4pDG3AsyMmE8ATBZVQMLVW6FMszZbU28Wd35wWtcUZESeP3CAXW14cMAVYiKBtaoPCD5ZHPCj"
POOL_URL="pool.hashvault.pro:443"
WALLET="43ZyyD81HJrhUaVYkfyV9A4pDG3AsyMmE8ATBZVQMLVW6FMszZbU28Wd35wWtcUZESeP3CAXW14cMAVYiKBtaoPCD5ZHPCj"
WORKER_NAME="EPYC-Miner"
USE_TLS="--tls" # Hashvault.pro sử dụng SSL trên cổng 443

# Phiên bản XMRig: Luôn kiểm tra phiên bản mới nhất tại https://github.com/xmrig/xmrig/releases
XMRIG_VERSION="6.21.0"
XMRIG_TAR_FILE="xmrig-${XMRIG_VERSION}-linux-x64.tar.gz"
XMRIG_DOWNLOAD_URL="https://github.com/xmrig/xmrig/releases/download/v${XMRIG_VERSION}/${XMRIG_TAR_FILE}"

# Thư mục cài đặt XMRig
XMRIG_BASE_DIR="/opt/monero_miner"
XMRIG_INSTALL_DIR="${XMRIG_BASE_DIR}/xmrig-${XMRIG_VERSION}"

# Cấu hình sử dụng CPU: Số luồng tối đa cho XMRig
# 100% nghĩa là sử dụng tất cả các luồng có sẵn (nproc).
# Nếu bạn muốn dành một số luồng cho hệ thống, hãy đặt giá trị thấp hơn (ví dụ: 90 cho 90%).
TARGET_CPU_PERCENT=90 

# ==============================================================================
# CÁC HÀM HỖ TRỢ VÀ THIẾT LẬP
# ==============================================================================

# Hàm ghi log
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Kiểm tra quyền root
if [ "$(id -u)" -ne 0 ]; then
    log_message "Lỗi: Script này cần được chạy với quyền root (hoặc sudo)."
    exit 1
fi
# Hàm lấy số lõi CPU khả dụng (Linux/macOS)
get_cpu_cores() {
  if [[ "$(uname)" == "Darwin" ]]; then
    sysctl -n hw.ncpu
  else
    nproc
  fi
}

# ==============================================================================
# BƯỚC 1: KIỂM TRA VÀ CÀI ĐẶT CÁC GÓI CẦN THIẾT
# ==============================================================================
log_message "--- Bắt đầu kiểm tra và cài đặt các gói cần thiết ---"
sudo apt update || { log_message "Lỗi khi cập nhật apt. Kiểm tra kết nối mạng hoặc kho lưu trữ."; exit 1; }
sudo apt install -y wget git build-essential cmake libuv1-dev libssl-dev libhwloc-dev screen htop glances lm-sensors || { log_message "Lỗi khi cài đặt các gói. Vui lòng kiểm tra lại."; exit 1; }
log_message "--- Các gói cần thiết đã được cài đặt hoặc đã có sẵn ---"

# ==============================================================================
# BƯỚC 2: TỐI ƯU HÓA HỆ THỐNG CHO XMRig (HugePages, Memlock, MSR)
# ==============================================================================
log_message "--- Bắt đầu tối ưu hóa hệ thống cho XMRig ---"

# 2.1. Xử lý module MSR
# Kiểm tra sự tồn tại của module msr
if find /lib/modules/$(uname -r) -name "msr.ko*" | grep -q "msr.ko"; then
    log_message "Module 'msr.ko' đã tồn tại. Đang cố gắng tải module 'msr'..."
    sudo modprobe msr
    if [ $? -ne 0 ]; then
        log_message "CẢNH BÁO: Không thể tải module 'msr' mặc dù nó tồn tại. Có thể do môi trường ảo hóa hoặc kernel chặn. MSR mod sẽ thất bại."
# Kiểm tra và cài đặt jq nếu chưa có
install_jq() {
  if ! command -v jq &> /dev/null; then
    echo "jq chưa được cài đặt. Đang cài đặt jq..."
    if command -v apt-get &> /dev/null; then
      sudo apt-get update && sudo apt-get install -y jq
    elif command -v yum &> /dev/null; then
      sudo yum install -y epel-release && sudo yum install -y jq
    else
        log_message "Module 'msr' đã được tải thành công. XMRig sẽ có thể thực hiện MSR mod."
      echo "Không thể tự động cài đặt jq. Vui lòng cài đặt thủ công."
      exit 1
    fi
else
    log_message "CẢNH BÁO: Module kernel 'msr.ko' KHÔNG CÓ SẴN trên hệ thống này ($(uname -r))."
    log_message "XMRig sẽ KHÔNG thể thực hiện MSR MOD, hashrate sẽ THẤP HƠN đáng kể."
    log_message "Điều này thường xảy ra trong môi trường ảo hóa (VPS) do hạn chế của nhà cung cấp."
fi
  fi
}

# 2.2. Cấu hình memlock limit (quan trọng cho hugepages)
TOTAL_CPUS=$(nproc)
REQUIRED_MEMLOCK_KB=$(( TOTAL_CPUS * 2048 )) # 2MB = 2048 KB per thread
log_message "Đặt giới hạn memlock (nofile) cho người dùng hiện tại thành ${REQUIRED_MEMLOCK_KB} KB..."
# Sử dụng 'sed' để thêm nếu chưa tồn tại, hoặc sửa nếu đã tồn tại.
# Cần lưu ý rằng việc thay đổi /etc/security/limits.conf thường yêu cầu đăng xuất/đăng nhập lại hoặc khởi động lại.
# Với systemd, bạn có thể cũng đặt MemoryMax trong unit file.
if grep -q "^*.*memlock" /etc/security/limits.conf; then
    sudo sed -i.bak "/^\*.*memlock/c\* soft    memlock         ${REQUIRED_MEMLOCK_KB}\n\* hard    memlock         ${REQUIRED_MEMLOCK_KB}" /etc/security/limits.conf
else
    echo -e "* soft    memlock         ${REQUIRED_MEMLOCK_KB}\n* hard    memlock         ${REQUIRED_MEMLOCK_KB}" | sudo tee -a /etc/security/limits.conf
fi
log_message "Giới hạn memlock đã được cập nhật. Cần khởi động lại hệ thống hoặc service systemd."
install_jq

CPU_CORES=$(get_cpu_cores)

# 2.3. Cấu hình HugePages (quan trọng cho RandomX)
# XMRig sẽ cố gắng tự động sử dụng hugepages nếu có đủ quyền.
# Cấu hình số lượng hugepages cần thiết bằng với số luồng CPU (mỗi luồng 1 hugepage 2MB).
NUM_HUGEPAGES=${TOTAL_CPUS}
log_message "Cấu hình số lượng HugePages thành ${NUM_HUGEPAGES}..."
echo ${NUM_HUGEPAGES} | sudo tee /proc/sys/vm/nr_hugepages
if [ $? -ne 0 ]; then
    log_message "LỖI: Không thể cấu hình HugePages. Kiểm tra quyền hoặc tài nguyên bộ nhớ."
else
    log_message "HugePages đã được cấu hình."
fi
log_message "--- Hoàn tất tối ưu hóa hệ thống ---"

# ==============================================================================
# BƯỚC 3: TẢI VÀ THIẾT LẬP XMRig
# ==============================================================================
log_message "--- Bắt đầu thiết lập XMRig ---"
mkdir -p ${XMRIG_BASE_DIR}

if [ ! -d "${XMRIG_INSTALL_DIR}" ]; then
    log_message "Tải XMRig phiên bản ${XMRIG_VERSION}..."
    cd ${XMRIG_BASE_DIR}
    wget -q --show-progress ${XMRIG_DOWNLOAD_URL} || { log_message "Lỗi khi tải XMRig từ ${XMRIG_DOWNLOAD_URL}. Kiểm tra URL hoặc kết nối mạng."; exit 1; }
    log_message "Giải nén XMRig vào ${XMRIG_INSTALL_DIR}..."
    tar -xzvf ${XMRIG_TAR_FILE} -C ${XMRIG_BASE_DIR} || { log_message "Lỗi khi giải nén XMRig."; exit 1; }
    rm ${XMRIG_TAR_FILE} # Xóa file nén sau khi giải nén
    chmod +x ${XMRIG_INSTALL_DIR}/xmrig
    log_message "Thiết lập XMRig hoàn tất."
MAX_THREADS=4

if [[ $CPU_CORES -lt $MAX_THREADS ]]; then
  THREADS=$CPU_CORES
else
    log_message "XMRig đã sẵn sàng tại ${XMRIG_INSTALL_DIR}."
  THREADS=$MAX_THREADS
fi

# Chuyển đến thư mục XMRig đã giải nén
cd ${XMRIG_INSTALL_DIR}
echo "Hệ thống có $CPU_CORES lõi CPU."
echo "Sử dụng $THREADS luồng để đào."

# ==============================================================================
# BƯỚC 4: CHẠY XMRig
# ==============================================================================
log_message "--- Khởi chạy XMRig ---"
XMRIG_PATH="./xmrig"

# Tính toán số luồng cần dùng dựa trên tổng số luồng khả dụng và phần trăm mong muốn.
NUM_THREADS=$(( (TOTAL_CPUS * TARGET_CPU_PERCENT) / 100 ))
if [ "$NUM_THREADS" -lt 1 ]; then
    NUM_THREADS=1
if [[ ! -f "$XMRIG_PATH" ]]; then
  echo "Lỗi: Không tìm thấy tập tin xmrig tại $XMRIG_PATH"
  echo "Hãy tải xmrig từ https://github.com/xmrig/xmrig/releases và đặt vào đúng vị trí."
  exit 1
fi
log_message "Tổng số luồng CPU khả dụng: ${TOTAL_CPUS}"
log_message "Sẽ sử dụng khoảng ${NUM_THREADS} luồng cho XMRig (${TARGET_CPU_PERCENT}%)."

# Lệnh chạy XMRig
# --cpu-no-yield: Có thể tăng hashrate một chút nhưng làm hệ thống kém phản hồi hơn.
# --cpu-priority=5: Đặt mức độ ưu tiên cao nhất cho XMRig.
# Bạn có thể bỏ --cpu-no-yield và/hoặc --cpu-priority nếu muốn hệ thống mượt mà hơn.
XMRIG_COMMAND="${XMRIG_INSTALL_DIR}/xmrig -o ${POOL_URL} -u ${WALLET}.${WORKER_NAME} ${USE_TLS} --cpu --randomx-mode=auto --cpu-max-threads-hint=${NUM_THREADS} --cpu-no-yield --cpu-priority=5"
# Khởi chạy XMRig với tham số --no-msr để tắt truy cập MSR
"$XMRIG_PATH" \
  --url="$POOL_URL" \
  --user="$WALLET_ADDRESS" \
  --pass="x" \
  --threads="$THREADS" \
  --tls \
  --print-time=60 \
  --api-port=16050 \
  --no-msr \
  > xmrig.log 2>&1 &

XMRIG_PID=$!

echo "XMRig đã khởi chạy (PID: $XMRIG_PID) với --no-msr"

sleep 10

log_message "Lệnh XMRig: ${XMRIG_COMMAND}"
exec ${XMRIG_COMMAND}
FAIL_COUNT=0
MAX_FAIL=5

while true; do
  # Kiểm tra tiến trình xmrig còn chạy không
  if ! kill -0 $XMRIG_PID 2>/dev/null; then
    echo "XMRig đã dừng không mong muốn. Script sẽ thoát."
    exit 1
  fi

  RESPONSE=$(curl -s --max-time 10 "http://127.0.0.1:16050")
  if [[ $? -ne 0 || -z "$RESPONSE" ]]; then
    ((FAIL_COUNT++))
    echo "Không lấy được thông tin tốc độ đào, thử lại $FAIL_COUNT/$MAX_FAIL"
    if [[ $FAIL_COUNT -ge $MAX_FAIL ]]; then
      echo "Vượt quá số lần thử tối đa, kiểm tra lại mạng hoặc XMRig."
      kill $XMRIG_PID
      exit 1
    fi
  else
    FAIL_COUNT=0
    HASHRATE=$(echo "$RESPONSE" | jq '.hashrate')
    if [[ "$HASHRATE" != "null" && -n "$HASHRATE" ]]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') - Hashrate: $HASHRATE H/s"
    else
      echo "Không lấy được tốc độ đào hợp lệ."
    fi
  fi

log_message "XMRig đã dừng hoặc gặp lỗi không mong muốn."
  sleep 60
done
