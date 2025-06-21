# ... (Phần trên của script không thay đổi) ...

# Kiểm tra xem xmrig đã được tải về chưa
if [ ! -d "$XMRIG_DIR" ]; then
    echo "Thư mục xmrig không tồn tại. Đang tải và giải nén xmrig..."
    wget "$XMRIG_RELEASE_URL" -O "$XMRIG_ARCHIVE" || { echo "Lỗi: Không thể tải xmrig từ $XMRIG_RELEASE_URL. Kiểm tra lại URL."; exit 1; }
    tar -xzvf "$XMRIG_ARCHIVE" || { echo "Lỗi: Không thể giải nén $XMRIG_ARCHIVE."; exit 1; }
    # Dòng này đã được sửa
    mv "xmrig-6.21.0" "$XMRIG_DIR" || { echo "Lỗi: Không thể di chuyển thư mục xmrig đã giải nén."; exit 1; }
    rm "$XMRIG_ARCHIVE"
else
    echo "Thư mục xmrig đã tồn tại. Bỏ qua bước tải về."
fi

# ... (Phần dưới của script không thay đổi) ...
