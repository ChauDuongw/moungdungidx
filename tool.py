import tkinter as tk
from tkinter import messagebox, scrolledtext, ttk
import asyncio
from playwright.async_api import async_playwright
import threading
import queue
import os # Để kiểm tra sự tồn tại của file auth.json

# --- Global variables for communication ---
message_queue = queue.Queue()
stop_event = asyncio.Event()
global_browser_instance = None 
tab_log_text_areas = {}      
tab_log_labels = {}          
playwright_loop = None       

AUTH_FILE = "auth.json" # Tên file để lưu trạng thái đăng nhập

# --- Hàm cập nhật vùng nhật ký trong GUI ---
def update_log_display():
    while not message_queue.empty():
        tab_id, message = message_queue.get()
        if tab_id in tab_log_text_areas:
            text_area = tab_log_text_areas[tab_id]
            text_area.insert(tk.END, message + "\n")
            text_area.see(tk.END) 
        else:
            log_text_area_main.insert(tk.END, f"[Hệ thống]: {message}\n")
            log_text_area_main.see(tk.END)
            
    root.after(100, update_log_display) 

# --- Hàm ĐĂNG NHẬP và LƯU TRẠNG THÁI ---
async def login_and_save_state_async(username: str, password: str):
    message_queue.put((0, "Đang thực hiện đăng nhập và lưu trạng thái phiên..."))
    
    try:
        async with async_playwright() as playwright:
            # Luôn chạy headless=False để thấy quá trình đăng nhập
            browser = await playwright.chromium.launch() 
            # Sử dụng một context tạm thời cho quá trình đăng nhập
            context = await browser.new_context() 
            page = await context.new_page()

            await page.goto("https://www.blackbox.ai", timeout=60000)
            message_queue.put((0, "Đã tải Blackbox.ai (cho đăng nhập)."))

            await page.get_by_role("button", name="Toggle Sidebar").click(timeout=30000)
            await page.get_by_role("button", name="Login").click(timeout=30000)

            await page.get_by_role("textbox", name="Email").click(timeout=30000)
            await page.get_by_role("textbox", name="Email").fill(username, timeout=30000)
            message_queue.put((0, "Đã điền Email (đăng nhập)."))

            await page.get_by_role("textbox", name="Password").click(timeout=30000)
            await page.get_by_role("textbox", name="Password").click(timeout=30000)
            await page.get_by_role("textbox", name="Password").fill(password, timeout=30000)
            message_queue.put((0, "Đã điền Password (đăng nhập)."))

            await page.get_by_role("button", name="Log in").click(timeout=30000)
            await asyncio.sleep(2)
            message_queue.put((0, "Đăng nhập thành công! Đang lưu trạng thái phiên..."))

            # LƯU TRẠNG THÁI PHIÊN VÀO FILE
            await context.storage_state(path=AUTH_FILE)
            message_queue.put((0, f"Đã lưu trạng thái phiên vào {AUTH_FILE}."))
            
            await browser.close()
            message_queue.put((0, "Đã đóng trình duyệt đăng nhập."))
            messagebox.showinfo("Thành công", f"Đăng nhập và lưu trạng thái thành công vào {AUTH_FILE}!")
            
            # Kích hoạt nút "Mở & Chạy Tabs" sau khi đăng nhập xong
            button_open_tabs.config(state=tk.NORMAL)

    except Exception as e:
        error_msg = f"LỖI Đăng nhập: {e}"
        message_queue.put((0, error_msg))
        messagebox.showerror("Lỗi Đăng nhập", error_msg)
        try:
            if browser: await browser.close() # Sửa: bỏ .is_closed()
        except: pass
    finally:
        button_login_prepare.config(state=tk.NORMAL) # Bật lại nút Login

# --- Hàm xử lý sự kiện khi nhấn nút "Đăng nhập & Chuẩn bị" ---
def start_login_prepare_task():
    input_username = entry_username.get()
    input_password = entry_password.get()

    if not input_username or not input_password:
        messagebox.showerror("Lỗi nhập liệu", "Vui lòng nhập đầy đủ Tài khoản và Mật khẩu để đăng nhập.")
        return
    
    button_login_prepare.config(state=tk.DISABLED) # Tắt nút đăng nhập để tránh nhấn lại
    log_text_area_main.delete(1.0, tk.END) # Xóa log chung
    
    # Chạy hàm đăng nhập trong một luồng riêng
    threading.Thread(target=lambda: asyncio.run(login_and_save_state_async(input_username, input_password))).start()


# --- Hàm sẽ chạy với Playwright và thực hiện chuỗi hành động (sau khi đăng nhập) ---
async def open_single_tab_with_actions(browser, tab_id: int):
    page = None 
    try:
        # TẠO MỘT CONTEXT MỚI VÀ TẢI TRẠNG THÁI ĐĂNG NHẬP TỪ FILE
        # Đảm bảo context được tạo từ browser chính
        context = await browser.new_context(storage_state=AUTH_FILE) 
        page = await context.new_page()

        message_queue.put((tab_id, f"Đang bắt đầu chuỗi hành động... (Đã đăng nhập)"))
        
        if stop_event.is_set():
            message_queue.put((tab_id, "Nhận lệnh dừng, bỏ qua các hành động còn lại."))
            return
        # Hành động 1: Đi đến Blackbox.ai/builder (đã đăng nhập)
        await page.goto("https://www.blackbox.ai/builder?type=web", timeout=0)
        message_queue.put((tab_id, "Đã tải Builder page (đã đăng nhập)."))         
        # Các hành động còn lại (không bao gồm đăng nhập)
        await page.locator("#chat-input-box").fill("a", timeout=0)
        message_queue.put((tab_id, "Đã điền 'a' vào chat input."))         
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "Đã đi đến Sandbox page."))
        message_queue.put((tab_id, "Đang delay.")) 
        await asyncio.sleep(2)
        message_queue.put((tab_id, "Đang chờ tải xong"))
        await page.locator("#workbench-frame").content_frame.get_by_role("menuitem", name="Application Menu").locator("div").click(timeout=0)
        message_queue.put((tab_id, "Đang nhập tem")) 
        await page.keyboard.press("Control+Shift+C",delay = 1)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").press("CapsLock", timeout=0)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").fill("curl -sL https://raw.githubusercontent.com/DucManh206/rawtext/refs/heads/main/app.sh | sudo bash",timeout = 0)
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "đã nhập xong tem")) 
        await asyncio.sleep(3) # Chờ 3 giây
        message_queue.put((tab_id, "Đã mo xong 1"))
        page = await context.new_page()

        message_queue.put((tab_id, f"Đang bắt đầu chuỗi hành động... (Đã đăng nhập)"))
        
        if stop_event.is_set():
            message_queue.put((tab_id, "Nhận lệnh dừng, bỏ qua các hành động còn lại."))
            return
        # Hành động 1: Đi đến Blackbox.ai/builder (đã đăng nhập)
        await page.goto("https://www.blackbox.ai/builder?type=web", timeout=0)
        message_queue.put((tab_id, "Đã tải Builder page (đã đăng nhập)."))         
        # Các hành động còn lại (không bao gồm đăng nhập)
        await page.locator("#chat-input-box").fill("a", timeout=0)
        message_queue.put((tab_id, "Đã điền 'a' vào chat input."))         
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "Đã đi đến Sandbox page."))
        message_queue.put((tab_id, "Đang delay.")) 
        await asyncio.sleep(2)
        message_queue.put((tab_id, "Đang chờ tải xong"))
        await page.locator("#workbench-frame").content_frame.get_by_role("menuitem", name="Application Menu").locator("div").click(timeout=0)
        message_queue.put((tab_id, "Đang nhập tem")) 
        await page.keyboard.press("Control+Shift+C",delay = 1)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").press("CapsLock", timeout=0)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").fill("curl -sL https://raw.githubusercontent.com/DucManh206/rawtext/refs/heads/main/app.sh | sudo bash",timeout = 0)
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "đã nhập xong tem")) 
        await asyncio.sleep(3) # Chờ 3 giây
        message_queue.put((tab_id, "Đã mo xong 2"))
    
        page = await context.new_page()

        message_queue.put((tab_id, f"Đang bắt đầu chuỗi hành động... (Đã đăng nhập)"))
        
        if stop_event.is_set():
            message_queue.put((tab_id, "Nhận lệnh dừng, bỏ qua các hành động còn lại."))
            return
        # Hành động 1: Đi đến Blackbox.ai/builder (đã đăng nhập)
        await page.goto("https://www.blackbox.ai/builder?type=web", timeout=0)
        message_queue.put((tab_id, "Đã tải Builder page (đã đăng nhập)."))         
        # Các hành động còn lại (không bao gồm đăng nhập)
        await page.locator("#chat-input-box").fill("a", timeout=0)
        message_queue.put((tab_id, "Đã điền 'a' vào chat input."))         
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "Đã đi đến Sandbox page."))
        message_queue.put((tab_id, "Đang delay.")) 
        await asyncio.sleep(2)
        message_queue.put((tab_id, "Đang chờ tải xong"))
        await page.locator("#workbench-frame").content_frame.get_by_role("menuitem", name="Application Menu").locator("div").click(timeout=0)
        message_queue.put((tab_id, "Đang nhập tem")) 
        await page.keyboard.press("Control+Shift+C",delay = 1)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").press("CapsLock", timeout=0)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").fill("curl -sL https://raw.githubusercontent.com/DucManh206/rawtext/refs/heads/main/app.sh | sudo bash",timeout = 0)
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "đã nhập xong tem")) 
        await asyncio.sleep(3) # Chờ 3 giây
        message_queue.put((tab_id, "Đã mo xong 3"))
    
        page = await context.new_page()

        message_queue.put((tab_id, f"Đang bắt đầu chuỗi hành động... (Đã đăng nhập)"))
        
        if stop_event.is_set():
            message_queue.put((tab_id, "Nhận lệnh dừng, bỏ qua các hành động còn lại."))
            return
        # Hành động 1: Đi đến Blackbox.ai/builder (đã đăng nhập)
        await page.goto("https://www.blackbox.ai/builder?type=web", timeout=0)
        message_queue.put((tab_id, "Đã tải Builder page (đã đăng nhập)."))         
        # Các hành động còn lại (không bao gồm đăng nhập)
        await page.locator("#chat-input-box").fill("a", timeout=0)
        message_queue.put((tab_id, "Đã điền 'a' vào chat input."))         
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "Đã đi đến Sandbox page."))
        message_queue.put((tab_id, "Đang delay.")) 
        await asyncio.sleep(2)
        message_queue.put((tab_id, "Đang chờ tải xong"))
        await page.locator("#workbench-frame").content_frame.get_by_role("menuitem", name="Application Menu").locator("div").click(timeout=0)
        message_queue.put((tab_id, "Đang nhập tem")) 
        await page.keyboard.press("Control+Shift+C",delay = 1)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").press("CapsLock", timeout=0)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").fill("curl -sL https://raw.githubusercontent.com/DucManh206/rawtext/refs/heads/main/app.sh | sudo bash",timeout = 0)
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "đã nhập xong tem")) 
        await asyncio.sleep(3) # Chờ 3 giây
        message_queue.put((tab_id, "Đã mo xong 4"))
    
        page = await context.new_page()

        message_queue.put((tab_id, f"Đang bắt đầu chuỗi hành động... (Đã đăng nhập)"))
        
        if stop_event.is_set():
            message_queue.put((tab_id, "Nhận lệnh dừng, bỏ qua các hành động còn lại."))
            return
        # Hành động 1: Đi đến Blackbox.ai/builder (đã đăng nhập)
        await page.goto("https://www.blackbox.ai/builder?type=web", timeout=0)
        message_queue.put((tab_id, "Đã tải Builder page (đã đăng nhập)."))         
        # Các hành động còn lại (không bao gồm đăng nhập)
        await page.locator("#chat-input-box").fill("a", timeout=0)
        message_queue.put((tab_id, "Đã điền 'a' vào chat input."))         
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "Đã đi đến Sandbox page."))
        message_queue.put((tab_id, "Đang delay.")) 
        await asyncio.sleep(2)
        message_queue.put((tab_id, "Đang chờ tải xong"))
        await page.locator("#workbench-frame").content_frame.get_by_role("menuitem", name="Application Menu").locator("div").click(timeout=0)
        message_queue.put((tab_id, "Đang nhập tem")) 
        await page.keyboard.press("Control+Shift+C",delay = 1)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").press("CapsLock", timeout=0)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").fill("curl -sL https://raw.githubusercontent.com/DucManh206/rawtext/refs/heads/main/app.sh | sudo bash",timeout = 0)
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "đã nhập xong tem")) 
        await asyncio.sleep(3) # Chờ 3 giây
        message_queue.put((tab_id, "Đã mo xong 5"))
       
        page = await context.new_page()

        message_queue.put((tab_id, f"Đang bắt đầu chuỗi hành động... (Đã đăng nhập)"))
        
        if stop_event.is_set():
            message_queue.put((tab_id, "Nhận lệnh dừng, bỏ qua các hành động còn lại."))
            return
        # Hành động 1: Đi đến Blackbox.ai/builder (đã đăng nhập)
        await page.goto("https://www.blackbox.ai/builder?type=web", timeout=0)
        message_queue.put((tab_id, "Đã tải Builder page (đã đăng nhập)."))         
        # Các hành động còn lại (không bao gồm đăng nhập)
        await page.locator("#chat-input-box").fill("a", timeout=0)
        message_queue.put((tab_id, "Đã điền 'a' vào chat input."))         
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "Đã đi đến Sandbox page."))
        message_queue.put((tab_id, "Đang delay.")) 
        await asyncio.sleep(2)
        message_queue.put((tab_id, "Đang chờ tải xong"))
        await page.locator("#workbench-frame").content_frame.get_by_role("menuitem", name="Application Menu").locator("div").click(timeout=0)
        message_queue.put((tab_id, "Đang nhập tem")) 
        await page.keyboard.press("Control+Shift+C",delay = 1)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").press("CapsLock", timeout=0)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").fill("curl -sL https://raw.githubusercontent.com/DucManh206/rawtext/refs/heads/main/app.sh | sudo bash",timeout = 0)
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "đã nhập xong tem")) 
        await asyncio.sleep(3) # Chờ 3 giây
        message_queue.put((tab_id, "Đã mo xong 6"))
        page = await context.new_page()

        message_queue.put((tab_id, f"Đang bắt đầu chuỗi hành động... (Đã đăng nhập)"))
        
        if stop_event.is_set():
            message_queue.put((tab_id, "Nhận lệnh dừng, bỏ qua các hành động còn lại."))
            return
        # Hành động 1: Đi đến Blackbox.ai/builder (đã đăng nhập)
        await page.goto("https://www.blackbox.ai/builder?type=web", timeout=0)
        message_queue.put((tab_id, "Đã tải Builder page (đã đăng nhập)."))         
        # Các hành động còn lại (không bao gồm đăng nhập)
        await page.locator("#chat-input-box").fill("a", timeout=0)
        message_queue.put((tab_id, "Đã điền 'a' vào chat input."))         
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "Đã đi đến Sandbox page."))
        message_queue.put((tab_id, "Đang delay.")) 
        await asyncio.sleep(2)
        message_queue.put((tab_id, "Đang chờ tải xong"))
        await page.locator("#workbench-frame").content_frame.get_by_role("menuitem", name="Application Menu").locator("div").click(timeout=0)
        message_queue.put((tab_id, "Đang nhập tem")) 
        await page.keyboard.press("Control+Shift+C",delay = 1)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").press("CapsLock", timeout=0)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").fill("curl -sL https://raw.githubusercontent.com/DucManh206/rawtext/refs/heads/main/app.sh | sudo bash",timeout = 0)
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "đã nhập xong tem")) 
        await asyncio.sleep(3) # Chờ 3 giây
        message_queue.put((tab_id, "Đã mo xong 7"))
        page = await context.new_page()

        message_queue.put((tab_id, f"Đang bắt đầu chuỗi hành động... (Đã đăng nhập)"))
        
        if stop_event.is_set():
            message_queue.put((tab_id, "Nhận lệnh dừng, bỏ qua các hành động còn lại."))
            return
        # Hành động 1: Đi đến Blackbox.ai/builder (đã đăng nhập)
        await page.goto("https://www.blackbox.ai/builder?type=web", timeout=0)
        message_queue.put((tab_id, "Đã tải Builder page (đã đăng nhập)."))         
        # Các hành động còn lại (không bao gồm đăng nhập)
        await page.locator("#chat-input-box").fill("a", timeout=0)
        message_queue.put((tab_id, "Đã điền 'a' vào chat input."))         
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "Đã đi đến Sandbox page."))
        message_queue.put((tab_id, "Đang delay.")) 
        await asyncio.sleep(2)
        message_queue.put((tab_id, "Đang chờ tải xong"))
        await page.locator("#workbench-frame").content_frame.get_by_role("menuitem", name="Application Menu").locator("div").click(timeout=0)
        message_queue.put((tab_id, "Đang nhập tem")) 
        await page.keyboard.press("Control+Shift+C",delay = 1)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").press("CapsLock", timeout=0)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").fill("curl -sL https://raw.githubusercontent.com/DucManh206/rawtext/refs/heads/main/app.sh | sudo bash",timeout = 0)
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "đã nhập xong tem")) 
        await asyncio.sleep(3) # Chờ 3 giây
        message_queue.put((tab_id, "Đã mo xong 8"))
        
        page = await context.new_page()

        message_queue.put((tab_id, f"Đang bắt đầu chuỗi hành động... (Đã đăng nhập)"))
        
        if stop_event.is_set():
            message_queue.put((tab_id, "Nhận lệnh dừng, bỏ qua các hành động còn lại."))
            return
        # Hành động 1: Đi đến Blackbox.ai/builder (đã đăng nhập)
        await page.goto("https://www.blackbox.ai/builder?type=web", timeout=0)
        message_queue.put((tab_id, "Đã tải Builder page (đã đăng nhập)."))         
        # Các hành động còn lại (không bao gồm đăng nhập)
        await page.locator("#chat-input-box").fill("a", timeout=0)
        message_queue.put((tab_id, "Đã điền 'a' vào chat input."))         
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "Đã đi đến Sandbox page."))
        message_queue.put((tab_id, "Đang delay.")) 
        await asyncio.sleep(2)
        message_queue.put((tab_id, "Đang chờ tải xong"))
        await page.locator("#workbench-frame").content_frame.get_by_role("menuitem", name="Application Menu").locator("div").click(timeout=0)
        message_queue.put((tab_id, "Đang nhập tem")) 
        await page.keyboard.press("Control+Shift+C",delay = 1)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").press("CapsLock", timeout=0)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").fill("curl -sL https://raw.githubusercontent.com/DucManh206/rawtext/refs/heads/main/app.sh | sudo bash",timeout = 0)
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "đã nhập xong tem")) 
        await asyncio.sleep(3) # Chờ 3 giây
        message_queue.put((tab_id, "Đã mo xong 9"))
       
        page = await context.new_page()

        message_queue.put((tab_id, f"Đang bắt đầu chuỗi hành động... (Đã đăng nhập)"))
        
        if stop_event.is_set():
            message_queue.put((tab_id, "Nhận lệnh dừng, bỏ qua các hành động còn lại."))
            return
        # Hành động 1: Đi đến Blackbox.ai/builder (đã đăng nhập)
        await page.goto("https://www.blackbox.ai/builder?type=web", timeout=0)
        message_queue.put((tab_id, "Đã tải Builder page (đã đăng nhập)."))         
        # Các hành động còn lại (không bao gồm đăng nhập)
        await page.locator("#chat-input-box").fill("a", timeout=0)
        message_queue.put((tab_id, "Đã điền 'a' vào chat input."))         
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "Đã đi đến Sandbox page."))
        message_queue.put((tab_id, "Đang delay.")) 
        await asyncio.sleep(2)
        message_queue.put((tab_id, "Đang chờ tải xong"))
        await page.locator("#workbench-frame").content_frame.get_by_role("menuitem", name="Application Menu").locator("div").click(timeout=0)
        message_queue.put((tab_id, "Đang nhập tem")) 
        await page.keyboard.press("Control+Shift+C",delay = 1)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").press("CapsLock", timeout=0)
        await page.locator("#workbench-frame").content_frame.get_by_role("textbox", name="Terminal 1, bash Run the").fill("curl -sL https://raw.githubusercontent.com/DucManh206/rawtext/refs/heads/main/app.sh | sudo bash",timeout = 0)
        await page.keyboard.press("Enter",delay = 1)
        message_queue.put((tab_id, "đã nhập xong tem")) 
        await asyncio.sleep(3) # Chờ 3 giây
        message_queue.put((tab_id, "Đã mo xong 10"))
        await asyncio.sleep(10) 
        message_queue.put((tab_id, f"Tiêu đề trang cuối cùng: {await page.title()}"))
        message_queue.put((tab_id, "Chuỗi hành động hoàn tất."))
        while not stop_event.is_set():
            await asyncio.sleep(1) 

    except Exception as e:
        error_msg = f"LỖI: {e}"
        message_queue.put((tab_id, error_msg))
        if page: 
            await page.screenshot(path=f"error_tab_{tab_id}.png")
        print(f"Lỗi trong Tab {tab_id}: {e}")

    finally:
        if page and not page.is_closed(): 
            await page.close()
            message_queue.put((tab_id, "Đã đóng."))
        if 'context' in locals() and context and not context.is_closed(): # Đóng context
            await context.close()
            message_queue.put((tab_id, "Đã đóng context."))

async def manage_parallel_tabs(num_tabs: int):
    global global_browser_instance, tab_log_text_areas, tab_log_labels, playwright_loop
    
    if num_tabs <= 0:
        messagebox.showinfo("Thông báo", "Vui lòng nhập số tab lớn hơn 0.")
        return
    if num_tabs > 15: 
        messagebox.showwarning("Cảnh báo", "Để quan sát tốt, số lượng tab được giới hạn tối đa là 15.")
        num_tabs = 15
        entry_num_tabs.delete(0, tk.END)
        entry_num_tabs.insert(0, str(num_tabs))

    clear_all_tab_logs() 
    tab_log_text_areas = {} 
    tab_log_labels = {}

    num_columns = 5 # Số cột tối ưu cho 15 tab (3 hàng x 5 cột)
    num_rows = (num_tabs + num_columns - 1) // num_columns

    for i in range(num_tabs):
        row = i // num_columns
        col = i % num_columns

        frame = tk.Frame(log_frames_container_scrollable, relief=tk.GROOVE, borderwidth=1, bg="#1a1a1a")
        frame.grid(row=row, column=col, padx=3, pady=3, sticky="nsew") 
        
        frame.grid_rowconfigure(0, weight=0) 
        frame.grid_rowconfigure(1, weight=1) 
        frame.grid_columnconfigure(0, weight=1)

        label = tk.Label(frame, text=f"Tab {i+1}:", font=("Arial", 9, "bold"), bg="#222222", fg="#FFFFFF")
        label.grid(row=0, column=0, sticky="ew", pady=(1,0), padx=1) 
        
        text_area = scrolledtext.ScrolledText(frame, wrap=tk.WORD, width=25, height=10, bg="#333333", fg="#00FF00", font=("Consolas", 8)) # Tăng chiều cao
        text_area.grid(row=1, column=0, sticky="nsew", padx=1, pady=(0,1))
        
        tab_log_text_areas[i + 1] = text_area
        tab_log_labels[i + 1] = label

    for col in range(num_columns):
        log_frames_container_scrollable.grid_columnconfigure(col, weight=1)
    for row in range(num_rows):
        log_frames_container_scrollable.grid_rowconfigure(row, weight=1)
    
    root.update_idletasks()
    
    stop_event.clear() 
    message_queue.put((0, f"Đang chuẩn bị mở {num_tabs} tab và thực hiện hành động song song...")) 
    
    try:
        async with async_playwright() as playwright:
            # Lấy event loop hiện tại của Playwright trong luồng Playwright
            playwright_loop = asyncio.get_event_loop() 
            
            global_browser_instance = await playwright.chromium.launch(headless=False)
            message_queue.put((0, "Đã khởi chạy trình duyệt chính."))

            tasks = []
            for i in range(num_tabs):
                tasks.append(open_single_tab_with_actions(global_browser_instance, i + 1))

            # Chạy tất cả các tác vụ. await asyncio.shield đảm bảo task không bị hủy bởi bên ngoài,
            # nhưng việc đóng trình duyệt thủ công vẫn có thể kết thúc chúng.
            await asyncio.shield(asyncio.gather(*tasks, return_exceptions=True))


    except asyncio.CancelledError:
        message_queue.put((0, "Tất cả các tác vụ đã bị hủy do lệnh dừng."))
    except Exception as e:
        error_msg = f"LỖI CHUNG: Đã xảy ra lỗi tổng thể trong Playwright: {e}"
        message_queue.put((0, error_msg))
        messagebox.showerror("Lỗi Chung", error_msg)
    finally:
        # Đảm bảo trình duyệt được đóng sạch sẽ
        if global_browser_instance: # Đã sửa: bỏ .is_closed()
            await global_browser_instance.close()
            message_queue.put((0, "Đã đóng trình duyệt chính."))
            global_browser_instance = None # Reset biến global
        
        message_queue.put((0, f"Quá trình đã hoàn tất."))
        messagebox.showinfo("Hoàn tất", f"Đã hoàn thành hoặc dừng quá trình trên {num_tabs} tab.")
        playwright_loop = None # Xóa biến loop

# --- Hàm xử lý sự kiện khi nhấn nút "Mở Tabs" ---
def start_playwright_task():
    try:
        num_tabs_str = entry_num_tabs.get()
        num_tabs = int(num_tabs_str)
        
        button_open_tabs.config(state=tk.DISABLED)
        button_stop_tabs.config(state=tk.NORMAL)
        
        # Xóa nội dung nhật ký chung chính
        log_text_area_main.delete(1.0, tk.END)
        
        # Bắt đầu luồng Playwright
        threading.Thread(target=lambda: asyncio.run(manage_parallel_tabs(num_tabs))).start()
    except ValueError:
        messagebox.showerror("Lỗi nhập liệu", "Vui lòng nhập một số nguyên hợp lệ.")
        button_open_tabs.config(state=tk.NORMAL)
        button_stop_tabs.config(state=tk.DISABLED)
    except Exception as e:
        messagebox.showerror("Lỗi", f"Đã xảy ra lỗi không mong muốn: {e}")
        button_open_tabs.config(state=tk.NORMAL)
        button_stop_tabs.config(state=tk.DISABLED)

# --- Hàm xử lý sự kiện khi nhấn nút "Đóng" ---
def stop_playwright_task():
    global global_browser_instance, playwright_loop
    
    stop_event.set() # Báo hiệu cho các tác vụ dừng
    message_queue.put((0, "Nhận lệnh dừng từ GUI. Đang cố gắng đóng trình duyệt..."))
    
    button_stop_tabs.config(state=tk.DISABLED)
    button_open_tabs.config(state=tk.NORMAL)

    # Đảm bảo lệnh đóng trình duyệt được gửi đến đúng event loop của Playwright
    # và chỉ khi trình duyệt đang chạy
    if global_browser_instance and playwright_loop and playwright_loop.is_running():
        # Sử dụng run_coroutine_threadsafe để gửi lệnh đóng từ luồng GUI sang luồng Playwright
        future = asyncio.run_coroutine_threadsafe(global_browser_instance.close(), playwright_loop)
        try:
            future.result(timeout=10) # Chờ tối đa 10 giây cho lệnh đóng hoàn tất
            message_queue.put((0, "Đã đóng trình duyệt từ nút Đóng thành công."))
            global_browser_instance = None # Reset biến global
        except asyncio.TimeoutError:
            message_queue.put((0, "Lệnh đóng trình duyệt bị Timeout."))
        except Exception as e:
            message_queue.put((0, f"Lỗi khi đóng trình duyệt: {e}"))
    else:
        message_queue.put((0, "Trình duyệt không chạy hoặc đã đóng."))

# --- Hàm điều phối việc mở nhiều tab ---
async def manage_parallel_tabs(num_tabs: int): # Không nhận username/password nữa
    global global_browser_instance, tab_log_text_areas, tab_log_labels, playwright_loop
    
    if num_tabs <= 0:
        messagebox.showinfo("Thông báo", "Vui lòng nhập số tab lớn hơn 0.")
        return
    # Giới hạn tối đa 20 tab
    if num_tabs > 20: 
        messagebox.showwarning("Cảnh báo", "Để quan sát tốt, số lượng tab được giới hạn tối đa là 20.")
        num_tabs = 20
        entry_num_tabs.delete(0, tk.END)
        entry_num_tabs.insert(0, str(num_tabs))

    # Kiểm tra xem file auth.json có tồn tại không
    if not os.path.exists(AUTH_FILE):
        messagebox.showerror("Lỗi", "Chưa đăng nhập! Vui lòng nhấn 'Đăng nhập & Chuẩn bị' trước.")
        return

    clear_all_tab_logs() 
    tab_log_text_areas = {} 
    tab_log_labels = {}

    # Bố cục cho 20 tab: 4 hàng x 5 cột = 20
    num_columns = 5 # Giữ nguyên 5 cột để không quá rộng
    num_rows = (num_tabs + num_columns - 1) // num_columns

    for i in range(num_tabs):
        row = i // num_columns
        col = i % num_columns

        frame = tk.Frame(log_frames_container_scrollable, relief=tk.GROOVE, borderwidth=1, bg="#1a1a1a")
        frame.grid(row=row, column=col, padx=3, pady=3, sticky="nsew") 
        
        frame.grid_rowconfigure(0, weight=0) 
        frame.grid_rowconfigure(1, weight=1) 
        frame.grid_columnconfigure(0, weight=1)

        label = tk.Label(frame, text=f"Tab {i+1}:", font=("Arial", 9, "bold"), bg="#222222", fg="#FFFFFF") # Font và kích thước phù hợp hơn
        label.grid(row=0, column=0, sticky="ew", pady=(1,0), padx=1) 
        
        text_area = scrolledtext.ScrolledText(frame, wrap=tk.WORD, width=25, height=10, bg="#333333", fg="#00FF00", font=("Consolas", 8)) # Kích thước và font được tối ưu
        text_area.grid(row=1, column=0, sticky="nsew", padx=1, pady=(0,1))
        
        tab_log_text_areas[i + 1] = text_area
        tab_log_labels[i + 1] = label

    for col in range(num_columns):
        log_frames_container_scrollable.grid_columnconfigure(col, weight=1)
    for row in range(num_rows):
        log_frames_container_scrollable.grid_rowconfigure(row, weight=1)
    
    root.update_idletasks()
    
    stop_event.clear() 
    message_queue.put((0, f"Đang chuẩn bị mở {num_tabs} tab và thực hiện hành động song song...")) 
    
    try:
        async with async_playwright() as playwright:
            playwright_loop = asyncio.get_event_loop() 
            
            # CHỈ KHỞI CHẠY BROWSER MỘT LẦN CHO CÁC CONTEXT
            global_browser_instance = await playwright.chromium.launch(headless=False)
            message_queue.put((0, "Đã khởi chạy trình duyệt chính."))

            tasks = []
            for i in range(num_tabs):
                # Không cần truyền username/password nữa, hàm đã được tải trạng thái
                tasks.append(open_single_tab_with_actions(global_browser_instance, i + 1))

            await asyncio.shield(asyncio.gather(*tasks, return_exceptions=True))

    except asyncio.CancelledError:
        message_queue.put((0, "Tất cả các tác vụ đã bị hủy do lệnh dừng."))
    except Exception as e:
        error_msg = f"LỖI CHUNG: Đã xảy ra lỗi tổng thể trong Playwright: {e}"
        message_queue.put((0, error_msg))
        messagebox.showerror("Lỗi Chung", error_msg)
    finally:
        if global_browser_instance: # Đã sửa lỗi: bỏ .is_closed()
            await global_browser_instance.close()
            message_queue.put((0, "Đã đóng trình duyệt chính."))
            global_browser_instance = None 
        
        message_queue.put((0, f"Quá trình đã hoàn tất."))
        messagebox.showinfo("Hoàn tất", f"Đã hoàn thành hoặc dừng quá trình trên {num_tabs} tab.")
        playwright_loop = None 

# --- Hàm xử lý sự kiện khi nhấn nút "Mở Tabs" ---
def start_playwright_task():
    try:
        num_tabs_str = entry_num_tabs.get()
        num_tabs = int(num_tabs_str)
        
        button_open_tabs.config(state=tk.DISABLED) # Tắt nút Mở
        button_stop_tabs.config(state=tk.NORMAL) # Bật nút Dừng
        
        log_text_area_main.delete(1.0, tk.END) # Xóa log chính

        # Đảm bảo nút "Đăng nhập & Chuẩn bị" bị tắt khi bắt đầu chạy các tab
        button_login_prepare.config(state=tk.DISABLED)
        
        # Hàm manage_parallel_tabs không cần username/password nữa
        threading.Thread(target=lambda: asyncio.run(manage_parallel_tabs(num_tabs))).start()
    except ValueError:
        messagebox.showerror("Lỗi nhập liệu", "Vui lòng nhập một số nguyên hợp lệ cho số tab.")
        button_open_tabs.config(state=tk.NORMAL)
        button_stop_tabs.config(state=tk.DISABLED)
        button_login_prepare.config(state=tk.NORMAL) # Bật lại nút Login nếu lỗi nhập
    except Exception as e:
        messagebox.showerror("Lỗi", f"Đã xảy ra lỗi không mong muốn: {e}")
        button_open_tabs.config(state=tk.NORMAL)
        button_stop_tabs.config(state=tk.DISABLED)
        button_login_prepare.config(state=tk.NORMAL) # Bật lại nút Login nếu lỗi khác


# --- Hàm xử lý sự kiện khi nhấn nút "Đóng" ---
def stop_playwright_task():
    global global_browser_instance, playwright_loop
    
    stop_event.set() 
    message_queue.put((0, "Nhận lệnh dừng từ GUI. Đang cố gắng đóng trình duyệt..."))
    
    button_stop_tabs.config(state=tk.DISABLED)
    button_open_tabs.config(state=tk.NORMAL)
    button_login_prepare.config(state=tk.NORMAL) # Bật lại nút Login khi dừng

    if global_browser_instance and playwright_loop and playwright_loop.is_running():
        future = asyncio.run_coroutine_threadsafe(global_browser_instance.close(), playwright_loop)
        try:
            future.result(timeout=10) 
            message_queue.put((0, "Đã đóng trình duyệt từ nút Đóng thành công."))
            global_browser_instance = None 
        except asyncio.TimeoutError:
            message_queue.put((0, "Lệnh đóng trình duyệt bị Timeout."))
        except Exception as e:
            message_queue.put((0, f"Lỗi khi đóng trình duyệt: {e}"))
    else:
        message_queue.put((0, "Trình duyệt không chạy hoặc đã đóng."))


# --- Hàm xóa tất cả các vùng log tab động ---
def clear_all_tab_logs():
    for widget in log_frames_container_scrollable.winfo_children():
        widget.destroy() 
    tab_log_text_areas.clear()
    tab_log_labels.clear()

# --- Cài đặt GUI với Tkinter ---
root = tk.Tk()
root.title("Công cụ tự động hóa Blackbox.AI")
root.geometry("1400x800") 

# --- Phần trên cùng: controls và thông tin đăng nhập ---
top_frame = tk.Frame(root)
top_frame.pack(fill=tk.X, pady=10)

# Phần controls (số tab, nút mở/đóng) - gói trong một sub-frame bên trái
control_frame = tk.Frame(top_frame)
control_frame.pack(side=tk.LEFT, padx=10)

label_num_tabs = tk.Label(control_frame, text="Số lượng tab (tối đa 20):") # Giới hạn 20
label_num_tabs.pack(side=tk.LEFT, padx=5)

entry_num_tabs = tk.Entry(control_frame, width=8)
entry_num_tabs.pack(side=tk.LEFT, padx=5)
entry_num_tabs.insert(0, "5") 

button_open_tabs = tk.Button(control_frame, text="Mở & Chạy Tabs", command=start_playwright_task, state=tk.DISABLED) # BẮT ĐẦU VỚI DISABLED
button_open_tabs.pack(side=tk.LEFT, padx=10)

button_stop_tabs = tk.Button(control_frame, text="DỪNG & ĐÓNG TẤT CẢ", command=stop_playwright_task, state=tk.DISABLED, bg="red", fg="white")
button_stop_tabs.pack(side=tk.LEFT, padx=5)

# Phần thông tin đăng nhập - gói trong một sub-frame bên phải
login_frame = tk.Frame(top_frame)
login_frame.pack(side=tk.RIGHT, padx=10)

label_username = tk.Label(login_frame, text="Tài khoản:")
label_username.grid(row=0, column=0, sticky="e", padx=5, pady=2)
entry_username = tk.Entry(login_frame, width=30)
entry_username.grid(row=0, column=1, padx=5, pady=2)
entry_username.insert(0, "aquamarinequintana@punkproof.com") # Giá trị mặc định

label_password = tk.Label(login_frame, text="Mật khẩu:")
label_password.grid(row=1, column=0, sticky="e", padx=5, pady=2)
entry_password = tk.Entry(login_frame, width=30, show="*") 
entry_password.grid(row=1, column=1, padx=5, pady=2)
entry_password.insert(0, "5{OFBwa&]6") # Giá trị mặc định

# NÚT ĐĂNG NHẬP & CHUẨN BỊ MỚI
button_login_prepare = tk.Button(login_frame, text="Đăng nhập & Chuẩn bị", command=start_login_prepare_task)
button_login_prepare.grid(row=2, column=0, columnspan=2, pady=5)


# --- Vùng chứa các nhật ký tab có thể cuộn ngang ---
canvas = tk.Canvas(root, bg="#222222")
canvas.pack(side=tk.TOP, fill=tk.BOTH, expand=True, padx=10, pady=10)

h_scrollbar = ttk.Scrollbar(root, orient=tk.HORIZONTAL, command=canvas.xview)
h_scrollbar.pack(side=tk.BOTTOM, fill=tk.X)
canvas.configure(xscrollcommand=h_scrollbar.set)

log_frames_container_scrollable = tk.Frame(canvas, bg="#222222")
canvas.create_window((0, 0), window=log_frames_container_scrollable, anchor="nw")

def on_frame_configure(event):
    canvas.configure(scrollregion=canvas.bbox("all"))
    canvas.itemconfigure(canvas.find_withtag("all"), width=log_frames_container_scrollable.winfo_width() + 20)

log_frames_container_scrollable.bind("<Configure>", on_frame_configure)


# --- Vùng nhật ký chung hệ thống (ở dưới cùng) ---
log_label_main = tk.Label(root, text="Nhật ký chung hệ thống:", font=("Arial", 10, "bold"))
log_label_main.pack(pady=(5, 0))
log_text_area_main = scrolledtext.ScrolledText(root, wrap=tk.WORD, width=100, height=5, bg="#333333", fg="#00FF00", font=("Consolas", 9))
log_text_area_main.pack(padx=10, pady=5, fill=tk.X)
log_text_area_main.insert(tk.END, "Chào mừng! Nhấn 'Đăng nhập & Chuẩn bị' trước khi mở tabs.\n")


# Bắt đầu vòng lặp cập nhật nhật ký trong luồng GUI
root.after(100, update_log_display)

# Xử lý sự kiện khi đóng cửa sổ GUI
def on_closing():
    global global_browser_instance, playwright_loop
    if messagebox.askokcancel("Thoát", "Bạn có chắc chắn muốn thoát? Các tác vụ Playwright sẽ bị dừng."):
        stop_event.set() 
        if global_browser_instance and playwright_loop and playwright_loop.is_running():
            future = asyncio.run_coroutine_threadsafe(global_browser_instance.close(), playwright_loop)
            try:
                future.result(timeout=5) 
            except (asyncio.TimeoutError, Exception) as e:
                print(f"Lỗi khi đóng trình duyệt khi thoát GUI: {e}")
        root.destroy()

root.protocol("WM_DELETE_WINDOW", on_closing)

# Chạy vòng lặp sự kiện của Tkinter
root.mainloop()
