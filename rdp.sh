#!/bin/bash
clear

# Màu sắc
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[1;34m'
NC='\033[0m'

LOG_FILE="iprdp.log"

# Nếu file log tồn tại => chỉ chạy lại ssh + xrdp
if [ -f "$LOG_FILE" ]; then
    echo -e "${GREEN}Phát hiện đã cài đặt trước đó.${NC}"
    echo -e "${YELLOW}Đang khởi động lại dịch vụ XRDP và SSH tunnel...${NC}"

    service xrdp start  

    echo -e "${BLUE}Đang tạo SSH tunnel qua Pinggy.io...${NC}"  
    ssh -p 443 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -R0:localhost:3389 tcp@a.pinggy.io | tee -a "$LOG_FILE"  

    exit 0
fi

# Lần chạy đầu tiên
echo -e "${BLUE}
################################################################################



CÀI ĐẶT LẦN ĐẦU: XRDP + LXDE + TUNNEL SSH



################################################################################
${NC}"

# Xác nhận
echo -e "${GREEN}Bạn có chắc muốn tiếp tục cài đặt không? (y/n): ${NC}"
read confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "${RED}Đã huỷ cài đặt.${NC}"
    exit 0
fi

# Cài đặt
echo -e "${YELLOW}Đang cập nhật và cài đặt các gói cần thiết...${NC}"
apt update && apt upgrade -y
export SUDO_FORCE_REMOVE=yes
apt remove sudo -y
apt install -y lxde xrdp

# Cấu hình XRDP
echo "lxsession -s LXDE -e LXDE" >> /etc/xrdp/startwm.sh

# Chọn cổng RDP
clear
read -p "$(echo -e ${YELLOW}Nhập port RDP muốn sử dụng (mặc định 3389): ${NC})" selectedPort
selectedPort=${selectedPort:-3389}

sed -i "s/port=3389/port=$selectedPort/g" /etc/xrdp/xrdp.ini
service xrdp restart

# Ghi chú lệnh SSH và chạy nó
clear
echo -e "${GREEN}
╔════════════════════════════════════════════╗
║      XRDP đã cài và khởi động thành công   ║
╠════════════════════════════════════════════╣
║        Giao diện: LXDE                     ║
║        Port RDP:  $selectedPort            ║
╚════════════════════════════════════════════╝
${NC}"

echo -e "${BLUE}Đang tạo SSH tunnel qua Pinggy.io...${NC}"

ssh_cmd="ssh -p 443 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -R0:localhost:$selectedPort tcp@a.pinggy.io"

# Lưu lệnh và chạy
echo "$ssh_cmd" > "$LOG_FILE"
$ssh_cmd | tee -a "$LOG_FILE"
