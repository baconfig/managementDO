#!/bin/bash
# =====================================================
# DigitalOcean Multi Account Manager v3
# GitHub Ready
# Requirements: curl jq
# =====================================================

DB_FILE="do_accounts.db"
ACTIVE_FILE=".active_account"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

touch "$DB_FILE"

pause(){ read -p "Press Enter to continue..."; }

header(){
clear
load_active
echo -e "${CYAN}====================================================${NC}"
echo -e "${GREEN} DigitalOcean Multi Account Manager v3 ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "Active Account : ${YELLOW}${ACTIVE_NAME:-None}${NC}"
echo
}

validate_api_key() {
    local token="$1"
    local code=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $token" \
    https://api.digitalocean.com/v2/account)
    [ "$code" = "200" ]
}

load_active(){
    [ -f "$ACTIVE_FILE" ] || return
    ACTIVE_NAME=$(cut -d'|' -f1 "$ACTIVE_FILE")
    ACTIVE_TOKEN=$(cut -d'|' -f2- "$ACTIVE_FILE")
}

add_account(){
    header
    read -p "Account Name : " name
    read -sp "API Token : " token
    echo

    if validate_api_key "$token"; then
        echo "$name|$token" >> "$DB_FILE"
        echo -e "${GREEN}Account Added Successfully${NC}"
    else
        echo -e "${RED}Invalid API Token${NC}"
    fi
    pause
}

select_account(){
    header
    nl -w2 -s'. ' "$DB_FILE"
    echo
    read -p "Select Account Number : " num

    line=$(sed -n "${num}p" "$DB_FILE")

    if [ -z "$line" ]; then
        echo "Invalid selection."
        pause
        return
    fi

    echo "$line" > "$ACTIVE_FILE"
    echo -e "${GREEN}Active account changed.${NC}"
    pause
}

delete_account(){
    header
    nl -w2 -s'. ' "$DB_FILE"
    echo
    read -p "Delete Account Number : " num
    sed -i "${num}d" "$DB_FILE"
    echo -e "${YELLOW}Account deleted.${NC}"
    pause
}

choose_region() {
    while true; do
        clear
        echo "Choose Region:"
        echo "1. Singapore"
        echo "2. New York"
        echo "3. San Francisco"
        echo "4. Amsterdam"
        echo "5. London"
        echo "6. Frankfurt"
        echo "7. Toronto"
        echo "8. Bangalore"
        echo "9. Sydney"
        read -p "Input region number: " region_choice

        case $region_choice in
            1) region="sgp1"; break ;;
            2) region="nyc1"; break ;;
            3) region="sfo1"; break ;;
            4) region="ams1"; break ;;
            5) region="lon1"; break ;;
            6) region="fra1"; break ;;
            7) region="tor1"; break ;;
            8) region="blr1"; break ;;
            9) region="syd1"; break ;;
        esac
    done
}

choose_image() {
    while true; do
        clear
        echo "Choose Image:"
        echo "1. Ubuntu 20.04 LTS"
        echo "2. Ubuntu 22.04 LTS"
        echo "3. Ubuntu 24.04 LTS"
        echo "4. CentOS 9 Stream"
        echo "5. Debian 11"
        echo "6. Debian 12"
        echo "7. Fedora 38"
        echo "8. Fedora 40"
        echo "9. AlmaLinux 8"
        echo "10. Rocky Linux 8"
        echo "11. Rocky Linux 9"
        echo "12. Ubuntu Desktop"
        echo "13. OpenVPN"
        echo "14. WordPress"
        read -p "Input image number: " image_choice

        case $image_choice in
            1) image="ubuntu-20-04-x64"; break ;;
            2) image="ubuntu-22-04-x64"; break ;;
            3) image="ubuntu-24-04-x64"; break ;;
            4) image="centos-9-x64"; break ;;
            5) image="debian-11-x64"; break ;;
            6) image="debian-12-x64"; break ;;
            7) image="fedora-38-x64"; break ;;
            8) image="fedora-40-x64"; break ;;
            9) image="almalinux-8"; break ;;
            10) image="rocky-8-x64"; break ;;
            11) image="rocky-9-x64"; break ;;
            12) image="ubuntu-desktop-gnome"; break ;;
            13) image="openvpn"; break ;;
            14) image="wordpress"; break ;;
        esac
    done
}

choose_size() {
while true; do
clear
echo "Choose Size:"
echo "1. 1vCPU 1GB"
echo "2. 1vCPU 2GB"
echo "3. 2vCPU 2GB"
echo "4. 2vCPU 4GB"
echo "5. 4vCPU 8GB"
echo "6. 1vCPU 1GB Intel"
echo "7. 1vCPU 2GB Intel"
echo "8. 2vCPU 4GB Intel"
echo "9. 1vCPU 1GB AMD"
echo "10. 1vCPU 2GB AMD"
echo "11. 2vCPU 2GB AMD"
echo "12. 2vCPU 4GB AMD"
echo "13. 4vCPU 8GB AMD"
echo "00. Exit"
read -p "Input size number: " size_choice
case $size_choice in
1) size="s-1vcpu-1gb"; break ;;
2) size="s-1vcpu-2gb"; break ;;
3) size="s-2vcpu-2gb"; break ;;
4) size="s-2vcpu-4gb"; break ;;
5) size="s-4vcpu-8gb"; break ;;
6) size="s-1vcpu-1gb-intel"; break ;;
7) size="s-1vcpu-2gb-intel"; break ;;
8) size="s-2vcpu-4gb-intel"; break ;;
9) size="s-1vcpu-1gb-amd"; break ;;
10) size="s-1vcpu-2gb-amd"; break ;;
11) size="s-2vcpu-2gb-amd"; break ;;
12) size="s-2vcpu-4gb-amd"; break ;;
13) size="s-4vcpu-8gb-amd"; break ;;
00) return 1 ;;
esac
done
}

list_droplets(){
header
curl -s -H "Authorization: Bearer $ACTIVE_TOKEN" \
https://api.digitalocean.com/v2/droplets | \
jq -r '.droplets[] | "ID: \(.id) | Name: \(.name) | IP: \(.networks.v4[0].ip_address // "N/A") | Size: \(.size.slug)"'
pause
}

deploy_droplet(){
header
[ -z "$ACTIVE_TOKEN" ] && echo "Select account first" && pause && return

read -p "Hostname : " name
choose_region
choose_image
choose_size || return

response=$(curl -s -X POST \
-H "Authorization: Bearer $ACTIVE_TOKEN" \
-H "Content-Type: application/json" \
-d "{
\"name\":\"$name\",
\"region\":\"$region\",
\"size\":\"$size\",
\"image\":\"$image\",
\"ipv6\":true,
\"monitoring\":true
}" https://api.digitalocean.com/v2/droplets)

echo "$response" | jq .
pause
}

reboot_droplet(){
header
read -p "Droplet ID : " id
curl -s -X POST -H "Authorization: Bearer $ACTIVE_TOKEN" \
-H "Content-Type: application/json" \
-d '{"type":"reboot"}' \
"https://api.digitalocean.com/v2/droplets/$id/actions" | jq .
pause
}

rebuild_droplet(){
header
read -p "Droplet ID : " id
choose_image
curl -s -X POST -H "Authorization: Bearer $ACTIVE_TOKEN" \
-H "Content-Type: application/json" \
-d "{\"type\":\"rebuild\",\"image\":\"$image\"}" \
"https://api.digitalocean.com/v2/droplets/$id/actions" | jq .
pause
}

resize_droplet(){
header
read -p "Droplet ID : " id
choose_size || return
curl -s -X POST -H "Authorization: Bearer $ACTIVE_TOKEN" \
-H "Content-Type: application/json" \
-d "{\"type\":\"resize\",\"size\":\"$size\"}" \
"https://api.digitalocean.com/v2/droplets/$id/actions" | jq .
pause
}

destroy_droplet(){
header
read -p "Droplet ID : " id
read -p "Confirm delete (y/n): " c
[ "$c" != "y" ] && return
curl -s -X DELETE -H "Authorization: Bearer $ACTIVE_TOKEN" \
"https://api.digitalocean.com/v2/droplets/$id"
echo "Destroy request sent."
pause
}

menu(){
while true; do
header
echo "1. Select Account"
echo "2. Add Account"
echo "3. Delete Account"
echo "4. List Droplets"
echo "5. Deploy Droplet"
echo "6. Reboot Droplet"
echo "7. Rebuild Droplet"
echo "8. Resize Droplet"
echo "9. Destroy Droplet"
echo "0. Exit"
echo
read -p "Choose : " c
case $c in
1) select_account ;;
2) add_account ;;
3) delete_account ;;
4) list_droplets ;;
5) deploy_droplet ;;
6) reboot_droplet ;;
7) rebuild_droplet ;;
8) resize_droplet ;;
9) destroy_droplet ;;
0) exit 0 ;;
esac
done
}

menu
