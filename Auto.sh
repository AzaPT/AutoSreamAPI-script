#!/bin/bash

# =======================================================
#      Công cụ Sao lưu / Vá lỗi EOS SDK Đa Thư Mục
# =======================================================

# Mảng lưu trữ các thư mục đích
declare -a target_dirs
use_gui=false

# Kiểm tra Zenity (Công cụ GUI)
if command -v zenity &> /dev/null; then
    use_gui=true
    echo "Phát hiện GUI (Zenity). Đang chuyển sang chế độ đồ họa..."
else
    echo "Không tìm thấy Zenity. Sử dụng chế độ văn bản."
fi

# =======================================================
# 1. Nhập Thư Mục Trò Chơi
# =======================================================
if [ "$use_gui" = true ]; then
    # Hiển thị hộp thoại thông tin
    zenity --info --title="Công cụ vá lỗi EOS SDK" --text="Chào mừng.\n\nBước 1: Bây giờ bạn sẽ chọn (các) thư mục trò chơi.\nĐể hỗ trợ tất cả trình quản lý tệp, chúng ta sẽ thêm từng thư mục một." --width=400

    # Vòng lặp thêm từng thư mục (Sửa lỗi Dolphin/KDE)
    while true; do
        # Chọn MỘT thư mục
        new_dir=$(zenity --file-selection --directory --title="Chọn Thư Mục Trò Chơi")

        # Xử lý nút Hủy
        if [ -z "$new_dir" ]; then
            if [ ${#target_dirs[@]} -eq 0 ]; then
                echo "Chưa chọn thư mục nào. Đang thoát."
                exit 1
            else
                # Nếu họ hủy nhưng đã thêm một số thư mục, tiếp tục chạy
                break
            fi
        fi

        target_dirs+=("$new_dir")

        # Hỏi xem người dùng có muốn thêm cái khác không
        if ! zenity --question --title="Thêm thư mục khác?" --text="Đã thêm thư mục:\n$new_dir\n\nBạn có muốn chọn MỘT thư mục trò chơi KHÁC không?"; then
            # Người dùng bấm Không, thoát vòng lặp
            break
        fi
    done

else
    # --- CHẾ ĐỘ VĂN BẢN (DỰ PHÒNG) ---
    while true; do
        if [ ${#target_dirs[@]} -eq 0 ]; then
            echo "Nhập một thư mục trò chơi để quét (hoặc gõ 'done' để hoàn tất):"
        else
            echo "Nhập một thư mục khác (hoặc gõ 'done' để tiếp tục):"
        fi

        read -r -e input_dir

        # Dọn dẹp dấu ngoặc kép khi kéo thả
        input_dir="${input_dir%\"}"
        input_dir="${input_dir#\"}"

        if [[ "$input_dir" == "done" ]]; then
            if [ ${#target_dirs[@]} -eq 0 ]; then
                echo "Lỗi: Bạn phải nhập ít nhất một thư mục."
                continue
            fi
            break
        fi

        if [ -d "$input_dir" ]; then
            target_dirs+=("$input_dir")
            echo "Đã thêm: $input_dir"
        else
            echo "Cảnh báo: Thư mục không tồn tại. Thử lại."
        fi
    done
fi

echo "-------------------------------------------------------"

# =======================================================
# 2. Nhập Thư Mục Chứa File Thay Thế
# =======================================================
replacement_dir=""

if [ "$use_gui" = true ]; then
    zenity --info --title="Công cụ vá lỗi EOS SDK" --text="Bước 2: Chọn thư mục chứa các file DLL thay thế MỚI của bạn.\n(Phải chứa EOSSDK-Win64-Shipping.dll, EOSSDK-Win32-Shipping.dll, hoặc ScreamAPI64/32.dll)" --width=400

    while true; do
        replacement_dir=$(zenity --file-selection --directory --title="Chọn Thư Mục Nguồn Thay Thế")

        if [ -z "$replacement_dir" ]; then
            echo "Đã hủy lựa chọn."
            exit 1
        fi

        # Xác thực xem có file EOSSDK hoặc ScreamAPI không
        if [[ -f "$replacement_dir/EOSSDK-Win64-Shipping.dll" ]] || [[ -f "$replacement_dir/EOSSDK-Win32-Shipping.dll" ]] || [[ -f "$replacement_dir/ScreamAPI64.dll" ]] || [[ -f "$replacement_dir/ScreamAPI32.dll" ]]; then
            break
        else
            zenity --error --text="Lỗi: Thư mục đó không chứa file EOSSDK hoặc ScreamAPI yêu cầu.\nVui lòng thử lại."
        fi
    done
else
    # --- CHẾ ĐỘ VĂN BẢN (DỰ PHÒNG) ---
    while true; do
        echo "Nhập thư mục chứa các file DLL thay thế MỚI (Hỗ trợ EOSSDK và ScreamAPI):"
        read -r -e replacement_dir

        # Dọn dẹp dấu ngoặc kép
        replacement_dir="${replacement_dir%\"}"
        replacement_dir="${replacement_dir#\"}"

        if [ -d "$replacement_dir" ]; then
            if [[ -f "$replacement_dir/EOSSDK-Win64-Shipping.dll" ]] || [[ -f "$replacement_dir/EOSSDK-Win32-Shipping.dll" ]] || [[ -f "$replacement_dir/ScreamAPI64.dll" ]] || [[ -f "$replacement_dir/ScreamAPI32.dll" ]]; then
                break
            else
                echo "Lỗi: Thư mục đó không chứa EOSSDK-Win...dll hoặc ScreamAPI...dll."
            fi
        else
            echo "Lỗi: Thư mục không tồn tại."
        fi
    done
fi

echo "======================================================="
echo "Bắt đầu Quá Trình Quét và Vá Lỗi..."
echo "======================================================="

count_patched=0
log_text=""

# 3. Lặp qua tất cả các thư mục đã cung cấp
for dir in "${target_dirs[@]}"; do
    echo "Đang quét: $dir"

    # Tìm các tệp đệ quy
    find "$dir" -type f \( -name "EOSSDK-Win64-Shipping.dll" -o -name "EOSSDK-Win32-Shipping.dll" \) -print0 | while IFS= read -r -d '' game_file; do

        filename=$(basename "$game_file")
        dir_path=$(dirname "$game_file")
        backup_file="${game_file/.dll/_o.dll}"

        # Xác định file thay thế dựa trên tên tệp gốc (Ưu tiên ScreamAPI trước)
        replacement_src=""
        if [[ "$filename" == "EOSSDK-Win64-Shipping.dll" ]]; then
            if [[ -f "$replacement_dir/ScreamAPI64.dll" ]]; then
                replacement_src="$replacement_dir/ScreamAPI64.dll"
                echo "     [INFO] Phát hiện ScreamAPI64.dll, sẽ sử dụng tệp này để đổi tên."
            elif [[ -f "$replacement_dir/EOSSDK-Win64-Shipping.dll" ]]; then
                replacement_src="$replacement_dir/EOSSDK-Win64-Shipping.dll"
            fi
        elif [[ "$filename" == "EOSSDK-Win32-Shipping.dll" ]]; then
            if [[ -f "$replacement_dir/ScreamAPI32.dll" ]]; then
                replacement_src="$replacement_dir/ScreamAPI32.dll"
                echo "     [INFO] Phát hiện ScreamAPI32.dll, sẽ sử dụng tệp này để đổi tên."
            elif [[ -f "$replacement_dir/EOSSDK-Win32-Shipping.dll" ]]; then
                replacement_src="$replacement_dir/EOSSDK-Win32-Shipping.dll"
            fi
        fi

        if [ -z "$replacement_src" ] || [ ! -f "$replacement_src" ]; then
            echo "  [BỎ QUA] Đã tìm thấy $filename, nhưng không có file thay thế phù hợp (kể cả ScreamAPI) trong thư mục nguồn."
            continue
        fi

        # -------------------------------------------------------
        # KIỂM TRA: Đã vá lỗi chưa?
        # Kiểm tra byte-for-byte, nếu giống hệ file sẽ thay thế thì bỏ qua.
        # -------------------------------------------------------
        if [ -f "$backup_file" ] && cmp -s "$game_file" "$replacement_src"; then
            echo "  -> Tìm thấy: $game_file"
            echo "     [BỎ QUA] $filename đã được cập nhật (giống hệt file thay thế)."
            continue
        fi

        echo "  -> Đang xử lý: $game_file"

        # SAO LƯU
        if [ -f "$backup_file" ]; then
            echo "     [INFO] Bản sao lưu đã tồn tại. Bỏ qua đổi tên (Giữ nguyên bản gốc)."
        else
            mv "$game_file" "$backup_file"
            echo "     [OK] Đã đổi tên bản gốc thành _o.dll"
        fi

        # COPY VÀ ĐỔI TÊN
        # Lệnh cp này sẽ copy nội dung của replacement_src (ví dụ: ScreamAPI64.dll) 
        # vào vị trí của game_file (tên là EOSSDK-Win64-Shipping.dll).
        cp "$replacement_src" "$game_file"

        if [ $? -eq 0 ]; then
            echo "     [THÀNH CÔNG] Đã thay thế $filename bằng phiên bản mới."
        else
            echo "     [THẤT BẠI] Lỗi khi sao chép tệp."
        fi

    done
done

echo "======================================================="
echo "Tất cả các hoạt động đã hoàn tất."

if [ "$use_gui" = true ]; then
    zenity --info --text="Quá trình vá lỗi hoàn tất!\n\nKiểm tra terminal để xem chi tiết log." --title="Thành công"
fi
