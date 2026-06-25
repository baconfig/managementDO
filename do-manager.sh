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
    load_active
    echo -e "${GREEN}Active account changed.${NC}"
    echo
    account_info
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
        echo "0. Back to Main Menu"
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
            0) return 1 ;;
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
        echo "0. Back to Main Menu"
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
            0) return 1 ;;
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


select_droplet_menu(){
    mapfile -t droplets < <(
        curl -s -H "Authorization: Bearer $ACTIVE_TOKEN" \
        https://api.digitalocean.com/v2/droplets | \
        jq -r '.droplets[] | "\(.id)|\(.name)|\(.networks.v4[0].ip_address // "N/A")"'
    )

    [ ${#droplets[@]} -eq 0 ] && echo "No droplets found." && return 1

    echo "===================================="
    echo "         SELECT DROPLET"
    echo "===================================="

    for i in "${!droplets[@]}"; do
        IFS='|' read -r did dname dip <<< "${droplets[$i]}"
        printf "%2d. %-20s %s\n" "$((i+1))" "$dname" "$dip"
    done

    echo
    echo "0. Back to Main Menu"
    read -p "Choose Number: " num

    if [ "$num" = "0" ]; then
        return 1
    fi

    if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt "${#droplets[@]}" ]; then
        echo "Invalid selection."
        return 1
    fi

    IFS='|' read -r SELECTED_ID SELECTED_NAME SELECTED_IP <<< "${droplets[$((num-1))]}"
}

list_droplets(){
header

[ -z "$ACTIVE_TOKEN" ] && echo "Select account first" && pause && return

running=0
stopped=0
total_ram=0
total_vcpu=0
no=1

echo "========================================================================================================================"
printf "%-3s %-8s %-18s %-15s %-14s %-12s %-20s %-8s %-12s
" \
"No" "STATUS" "HOSTNAME" "PUBLIC IP" "REGION" "SPEC" "OS" "AGE" "ID"
echo "========================================================================================================================"

curl -s -H "Authorization: Bearer $ACTIVE_TOKEN" \
https://api.digitalocean.com/v2/droplets | \
jq -r '.droplets[] |
"\(.status)|\(.id)|\(.name)|\(.networks.v4[]? | select(.type=="public") | .ip_address)|\(.size.vcpus)|\(.size.memory)|\(.region.slug)|\(.image.distribution) \(.image.name)|\(.created_at)"' |
while IFS='|' read -r status id name ip vcpus memory region os created; do

    created_ts=$(date -d "$created" +%s 2>/dev/null)
    now_ts=$(date +%s)
    age_days=$(( (now_ts - created_ts) / 86400 ))

    case "$region" in
        sgp1) region_name="Singapore" ;;
        nyc1) region_name="New York" ;;
        sfo1) region_name="San Francisco" ;;
        ams1) region_name="Amsterdam" ;;
        lon1) region_name="London" ;;
        fra1) region_name="Frankfurt" ;;
        tor1) region_name="Toronto" ;;
        blr1) region_name="Bangalore" ;;
        syd1) region_name="Sydney" ;;
        *) region_name="$region" ;;
    esac

    spec="${vcpus}C/$((memory/1024))GB"

    if [ "$status" = "active" ]; then
        state="ON"
        running=$((running+1))
    else
        state="OFF"
        stopped=$((stopped+1))
    fi

    total_ram=$((total_ram + memory))
    total_vcpu=$((total_vcpu + vcpus))

    printf "%-3s %-8s %-18s %-15s %-14s %-12s %-20s %-8s %-12s
" \
    "$no" "$state" "$name" "${ip:-N/A}" "$region_name" "$spec" "$os" "${age_days}d" "$id"

    no=$((no+1))
done

echo "========================================================================================================================"
echo "Summary: RAM & vCPU totals may vary when using shell pipelines."
echo "========================================================================================================================"

pause
}


input_password_hostname() {
    clear
    read -p "Input Hostname : " droplet_hostname
    read -sp "Input Root Password : " droplet_password
    echo ""
}


deploy_droplet(){
header
[ -z "$ACTIVE_TOKEN" ] && echo "Select account first" && pause && return

input_password_hostname

choose_region
choose_image
choose_size || return

user_data=$(cat <<EOF
#!/bin/bash
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart ssh || systemctl restart sshd
echo "root:${droplet_password}" | chpasswd
EOF
)

response=$(curl -s -X POST \
-H "Authorization: Bearer $ACTIVE_TOKEN" \
-H "Content-Type: application/json" \
-d "{
\"name\":\"${droplet_hostname}\",
\"region\":\"${region}\",
\"size\":\"${size}\",
\"image\":\"${image}\",
\"ipv6\":true,
\"monitoring\":true,
\"user_data\":$(jq -Rs . <<< "$user_data")
}" https://api.digitalocean.com/v2/droplets)

droplet_id=$(echo "$response" | jq -r '.droplet.id')

if [ "$droplet_id" != "null" ] && [ -n "$droplet_id" ]; then

sleep 20

droplet_ip=$(curl -s \
-H "Authorization: Bearer $ACTIVE_TOKEN" \
"https://api.digitalocean.com/v2/droplets/$droplet_id" | \
jq -r '.droplet.networks.v4[] | select(.type=="public") | .ip_address' 2>/dev/null)

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}           VPS READY TO USE                     ${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "${CYAN}Hostname   :${NC} $droplet_hostname"
echo -e "${CYAN}IP Address :${NC} ${droplet_ip:-Pending}"
echo -e "${CYAN}Username   :${NC} root"
echo -e "${CYAN}Password   :${NC} $droplet_password"
echo -e "${CYAN}Droplet ID :${NC} $droplet_id"
echo -e "${GREEN}================================================${NC}"

else
echo "$response" | jq .
fi

pause
}

reboot_droplet(){
header
[ -z "$ACTIVE_TOKEN" ] && echo "Select account first" && pause && return
echo "===================================="
echo "      PILIH VPS YANG MAU DIREBOOT"
echo "===================================="
select_droplet_menu || { pause; return; }

curl -s -X POST -H "Authorization: Bearer $ACTIVE_TOKEN" \
-H "Content-Type: application/json" \
-d '{"type":"reboot"}' \
"https://api.digitalocean.com/v2/droplets/$SELECTED_ID/actions" | jq .
pause
}

rebuild_droplet(){
header
[ -z "$ACTIVE_TOKEN" ] && echo "Select account first" && pause && return
echo "===================================="
echo "      PILIH VPS YANG MAU DIREBUILD"
echo "===================================="
select_droplet_menu || { pause; return; }
choose_image

curl -s -X POST -H "Authorization: Bearer $ACTIVE_TOKEN" \
-H "Content-Type: application/json" \
-d "{\"type\":\"rebuild\",\"image\":\"$image\"}" \
"https://api.digitalocean.com/v2/droplets/$SELECTED_ID/actions" | jq .
pause
}

resize_droplet(){
header
[ -z "$ACTIVE_TOKEN" ] && echo "Select account first" && pause && return
echo "===================================="
echo "      PILIH VPS YANG MAU DIRESIZE"
echo "===================================="
select_droplet_menu || { pause; return; }
choose_size || return

curl -s -X POST -H "Authorization: Bearer $ACTIVE_TOKEN" \
-H "Content-Type: application/json" \
-d "{\"type\":\"resize\",\"size\":\"$size\"}" \
"https://api.digitalocean.com/v2/droplets/$SELECTED_ID/actions" | jq .
pause
}

destroy_droplet(){
header
[ -z "$ACTIVE_TOKEN" ] && echo "Select account first" && pause && return
echo "===================================="
echo "      PILIH VPS YANG MAU DIHAPUS"
echo "===================================="
select_droplet_menu || { pause; return; }

read -p "Delete $SELECTED_NAME ? (y/n): " c
[ "$c" != "y" ] && return

curl -s -X DELETE -H "Authorization: Bearer $ACTIVE_TOKEN" \
"https://api.digitalocean.com/v2/droplets/$SELECTED_ID"

echo "Destroy request sent."
pause
}



account_info(){
header
[ -z "$ACTIVE_TOKEN" ] && echo "Select account first" && pause && return

info=$(curl -s -H "Authorization: Bearer $ACTIVE_TOKEN" \
https://api.digitalocean.com/v2/account)

name=$(echo "$info" | jq -r '.account.name // "-"')
email=$(echo "$info" | jq -r '.account.email // "-"')
uuid=$(echo "$info" | jq -r '.account.uuid // "-"')
status=$(echo "$info" | jq -r '.account.status // "-"')
droplet_limit=$(echo "$info" | jq -r '.account.droplet_limit // "-"')
email_verified=$(echo "$info" | jq -r '.account.email_verified // "-"')

echo "===================================================="
echo "                 ACCOUNT INFORMATION"
echo "===================================================="
printf "%-18s : %s\n" "Account Name" "$name"
printf "%-18s : %s\n" "Email" "$email"
printf "%-18s : %s\n" "UUID" "$uuid"
printf "%-18s : %s\n" "Status" "$status"
printf "%-18s : %s\n" "Droplet Limit" "$droplet_limit"
printf "%-18s : %s\n" "Email Verified" "$email_verified"
echo "===================================================="

pause
}


manage_droplet_menu(){
while true; do
header
echo "========== MANAGE DROPLET =========="
echo "1. Account Information"
echo "2. List Droplets"
echo "3. Deploy Droplet"
echo "4. Reboot Droplet"
echo "5. Rebuild Droplet"
echo "6. Resize Droplet"
echo "7. Destroy Droplet"
echo "0. Back"
echo
read -p "Choose : " c
case $c in
1) account_info ;;
2) list_droplets ;;
3) deploy_droplet ;;
4) reboot_droplet ;;
5) rebuild_droplet ;;
6) resize_droplet ;;
7) destroy_droplet ;;
0) return ;;
esac
done
}


menu(){
while true; do
header
echo "1. Select Account"
echo "2. Add Account"
echo "3. Delete Account"
echo "4. Manage Droplet"
echo "0. Exit"
echo
read -p "Choose : " c
case $c in
1) select_account ;;
2) add_account ;;
3) delete_account ;;
4) manage_droplet_menu ;;
0) exit 0 ;;
esac
done
}

menu
