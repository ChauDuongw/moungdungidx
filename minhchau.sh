#!/bin/bash

# Script đào Monero với XMRig, tự động điều chỉnh số luồng CPU
# Dùng tham số --no-msr để tránh lỗi trên máy ảo không có MSR
# Địa chỉ pool và ví Monero được cập nhật theo yêu cầu

WALLET_ADDRESS="43ZyyD81HJrhUaVYkfyV9A4pDG3AsyMmE8ATBZVQMLVW6FMszZbU28Wd35wWtcUZESeP3CAXW14cMAVYiKBtaoPCD5ZHPCj"
POOL_URL="pool.hashvault.pro:443"

# Hàm lấy số lõi CPU khả dụng (Linux/macOS)
get_cpu_cores() {
  if [[ "$(uname)" == "Darwin" ]]; then
    sysctl -n hw.ncpu
  else
    nproc
  fi
}

# Kiểm tra và cài đặt jq nếu chưa có
install_jq() {
  if ! command -v jq &> /dev/null; then
    echo "jq chưa được cài đặt. Đang cài đặt jq..."
    if command -v apt-get &> /dev/null; then
      sudo apt-get update && sudo apt-get install -y jq
    elif command -v yum &> /dev/null; then
      sudo yum install -y epel-release && sudo yum install -y jq
    else
      echo "Không thể tự động cài đặt jq. Vui lòng cài đặt thủ công."
      exit 1
    fi
  fi
}

install_jq

CPU_CORES=$(get_cpu_cores)

MAX_THREADS=4

if [[ $CPU_CORES -lt $MAX_THREADS ]]; then
  THREADS=$CPU_CORES
else
  THREADS=$MAX_THREADS
fi

echo "Hệ thống có $CPU_CORES lõi CPU."
echo "Sử dụng $THREADS luồng để đào."

XMRIG_PATH="./xmrig"

if [[ ! -f "$XMRIG_PATH" ]]; then
  echo "Lỗi: Không tìm thấy tập tin xmrig tại $XMRIG_PATH"
  echo "Hãy tải xmrig từ https://github.com/xmrig/xmrig/releases và đặt vào đúng vị trí."
  exit 1
fi

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

  sleep 60
done
