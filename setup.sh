#!/bin/bash

echo "📦 Đang cập nhật và cài Python + pip (nếu cần)..."
pkg update -y && pkg install python -y

echo "📦 Đang cài các thư viện Python cần thiết..."
pip install --upgrade pip
pip install pyautogui pyperclip requests

echo "🚀 Đang chạy script Python tự động mở IDX..."
python auto_idx.py