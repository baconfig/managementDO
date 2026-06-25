#!/bin/bash

# DigitalOcean Multi Account Manager v2
# GitHub Ready

DB_FILE="do_accounts.db"
ACTIVE_FILE=".active_account"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

touch "$DB_FILE"

pause(){ read -p "Press Enter..."; }

header(){
clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${GREEN} DigitalOcean Multi Account Manager v2${NC}"
echo -e "${CYAN}====================================================${NC}"
echo "Active Account : ${ACTIVE_NAME:-None}"
echo
}

validate_api_key() {
token="$1"
code=$(curl -s -o /dev/null -w "%{http_code}" \
-H "Authorization: Bearer $token" \
https://api.digitalocean.com/v2/account)
[ "$code" = "200" ]
}

load_active(){
[ -f "$ACTIVE_FILE" ] || return
ACTIVE_NAME=$(cut -d'|' -f1 "$ACTIVE_FILE")
ACTIVE_TOKEN=$(cut -d'|' -f2 "$ACTIVE_FILE")
}

add_account(){
header
read -p "Account Name : " name
read -sp "API Token : " token
echo
if validate_api_key "$token"; then
echo "$name|$token" >> "$DB_FILE"
echo -e "${GREEN}Account Added${NC}"
else
echo -e "${RED}Invalid Token${NC}"
fi
pause
}

select_account(){
header
nl -w2 -s'. ' "$DB_FILE"
echo
read -p "Select Number : " num
line=$(sed -n "${num}p" "$DB_FILE")
[ -z "$line" ] && pause && return
echo "$line" > "$ACTIVE_FILE"
load_active
}

list_droplets(){
load_active
header
curl -s -H "Authorization: Bearer $ACTIVE_TOKEN" \
https://api.digitalocean.com/v2/droplets | \
jq -r '.droplets[] |
"ID: \(.id) | Name: \(.name) | IP: \(.networks.v4[0].ip_address // "N/A") | Size: \(.size_slug)"'
pause
}

deploy_droplet(){
load_active
header

read -p "Hostname : " name
read -p "Region (sgp1/nyc1/fra1): " region
read -p "Image (ubuntu-24-04-x64): " image
read -p "Size (s-1vcpu-1gb): " size

curl -s -X POST \
-H "Authorization: Bearer $ACTIVE_TOKEN" \
-H "Content-Type: application/json" \
-d "{
\"name\":\"$name\",
\"region\":\"$region\",
\"size\":\"$size\",
\"image\":\"$image\"
}" \
https://api.digitalocean.com/v2/droplets

echo
echo -e "${GREEN}Deploy Request Sent${NC}"
pause
}

reboot_droplet(){
load_active
header

read -p "Droplet ID : " id

curl -s -X POST \
-H "Authorization: Bearer $ACTIVE_TOKEN" \
-H "Content-Type: application/json" \
-d '{"type":"reboot"}' \
https://api.digitalocean.com/v2/droplets/$id/actions

echo
echo -e "${GREEN}Reboot Sent${NC}"
pause
}

rebuild_droplet(){
load_active
header

read -p "Droplet ID : " id
read -p "Image (ubuntu-24-04-x64): " image

curl -s -X POST \
-H "Authorization: Bearer $ACTIVE_TOKEN" \
-H "Content-Type: application/json" \
-d "{\"type\":\"rebuild\",\"image\":\"$image\"}" \
https://api.digitalocean.com/v2/droplets/$id/actions

echo
echo -e "${GREEN}Rebuild Sent${NC}"
pause
}

resize_droplet(){
load_active
header

read -p "Droplet ID : " id
read -p "New Size (s-2vcpu-2gb): " size

curl -s -X POST \
-H "Authorization: Bearer $ACTIVE_TOKEN" \
-H "Content-Type: application/json" \
-d "{\"type\":\"resize\",\"size\":\"$size\"}" \
https://api.digitalocean.com/v2/droplets/$id/actions

echo
echo -e "${GREEN}Resize Sent${NC}"
pause
}

destroy_droplet(){
load_active
header
read -p "Droplet ID : " id
read -p "Confirm Delete (y/n): " c
[ "$c" != "y" ] && return

curl -s -X DELETE \
-H "Authorization: Bearer $ACTIVE_TOKEN" \
https://api.digitalocean.com/v2/droplets/$id

echo -e "${YELLOW}Destroy Request Sent${NC}"
pause
}

menu(){
while true; do
load_active
header

echo "1. Select Account"
echo "2. Add Account"
echo "3. List Droplets"
echo "4. Deploy Droplet"
echo "5. Reboot Droplet"
echo "6. Rebuild Droplet"
echo "7. Resize Droplet"
echo "8. Destroy Droplet"
echo "0. Exit"
echo

read -p "Choose : " c

case $c in
1) select_account ;;
2) add_account ;;
3) list_droplets ;;
4) deploy_droplet ;;
5) reboot_droplet ;;
6) rebuild_droplet ;;
7) resize_droplet ;;
8) destroy_droplet ;;
0) exit 0 ;;
esac
done
}

menu
