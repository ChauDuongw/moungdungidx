import webbrowser
import time
import pyautogui
import pyperclip

# URL IDX
IDX_URL = "https://idx.google.com/may5-38897659"
webbrowser.open(IDX_URL)
print("🔗 Đang mở máy ảo IDX...")

time.sleep(30)

pyautogui.click(x=303, y=271)
time.sleep(5)
pyautogui.hotkey('ctrl', 'alt', 't')
print("📂 Đã mở Terminal.")
time.sleep(20)

command = "bash <(curl -sSL https://raw.githubusercontent.com/DucManh206/rawtext/main/worker/setup.sh)"
pyperclip.copy(command)
pyautogui.hotkey('ctrl', 'shift', 'v')
time.sleep(1)
pyautogui.press("enter")
print("🚀 Đã gửi lệnh.")
