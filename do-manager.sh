#!/bin/bash

DB_FILE="do_accounts.db"
ACTIVE_FILE=".active_do_account"

touch "$DB_FILE"

validate_api_key() {
    local token="$1"
    local code=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $token" \
        https://api.digitalocean.com/v2/account)

    [ "$code" = "200" ]
}

pause() {
    read -p "Tekan Enter untuk lanjut..."
}

add_account() {
    clear
    echo "=== Tambah Akun DO ==="
    read -p "Nama akun: " name
    read -sp "API Token: " token
    echo

    if validate_api_key "$token"; then
        echo "${name}|${token}" >> "$DB_FILE"
        echo "Akun berhasil ditambahkan."
    else
        echo "Token tidak valid."
    fi
    pause
}

list_accounts() {
    if [ ! -s "$DB_FILE" ]; then
        echo "Belum ada akun."
        return
    fi

    i=1
    while IFS="|" read -r name token; do
        count=$(curl -s \
          -H "Authorization: Bearer $token" \
          https://api.digitalocean.com/v2/droplets 2>/dev/null | \
          jq '.droplets|length' 2>/dev/null)

        [ -z "$count" ] && count="?"

        echo "$i. $name ($count Droplet)"
        i=$((i+1))
    done < "$DB_FILE"
}

select_account() {
    clear
    echo "=== Pilih Akun ==="
    list_accounts
    echo

    read -p "Nomor akun: " num

    line=$(sed -n "${num}p" "$DB_FILE")

    if [ -z "$line" ]; then
        echo "Pilihan tidak valid."
        pause
        return
    fi

    echo "$line" > "$ACTIVE_FILE"
    echo "Akun aktif berhasil diganti."
    pause
}

delete_account() {
    clear
    list_accounts
    echo

    read -p "Nomor akun yang dihapus: " num
    sed -i "${num}d" "$DB_FILE"

    echo "Akun berhasil dihapus."
    pause
}

load_active_account() {
    [ ! -f "$ACTIVE_FILE" ] && return 1

    ACTIVE_NAME=$(cut -d'|' -f1 "$ACTIVE_FILE")
    ACTIVE_TOKEN=$(cut -d'|' -f2 "$ACTIVE_FILE")

    [ -n "$ACTIVE_TOKEN" ]
}

show_droplets() {
    load_active_account || {
        echo "Pilih akun terlebih dahulu."
        pause
        return
    }

    clear
    echo "=== Droplet $ACTIVE_NAME ==="

    curl -s \
      -H "Authorization: Bearer $ACTIVE_TOKEN" \
      https://api.digitalocean.com/v2/droplets | \
      jq -r '.droplets[] |
      "\(.id) | \(.name) | \(.networks.v4[0].ip_address)"'

    pause
}

reboot_droplet() {
    load_active_account || return

    read -p "Droplet ID: " id

    curl -s -X POST \
      -H "Authorization: Bearer $ACTIVE_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"type":"reboot"}' \
      "https://api.digitalocean.com/v2/droplets/$id/actions"

    echo
    echo "Perintah reboot dikirim."
    pause
}

destroy_droplet() {
    load_active_account || return

    read -p "Droplet ID: " id
    read -p "Yakin hapus? (y/n): " c

    [ "$c" != "y" ] && return

    curl -s -X DELETE \
      -H "Authorization: Bearer $ACTIVE_TOKEN" \
      "https://api.digitalocean.com/v2/droplets/$id"

    echo "Perintah destroy dikirim."
    pause
}

main_menu() {
while true; do
    clear

    load_active_account

    echo "==================================="
    echo " DIGITALOCEAN MULTI ACCOUNT MANAGER"
    echo "==================================="
    echo "Akun Aktif : ${ACTIVE_NAME:-Belum Dipilih}"
    echo
    echo "1. Pilih Akun"
    echo "2. Tambah Akun"
    echo "3. Hapus Akun"
    echo "4. List Droplet"
    echo "5. Reboot Droplet"
    echo "6. Destroy Droplet"
    echo "0. Exit"
    echo

    read -p "Pilih: " menu

    case $menu in
        1) select_account ;;
        2) add_account ;;
        3) delete_account ;;
        4) show_droplets ;;
        5) reboot_droplet ;;
        6) destroy_droplet ;;
        0) exit 0 ;;
    esac
done
}

main_menu
