#!/bin/bash" ;;

# Fungsi untuk memvalidasi API Key
validate_api_key() {
    local api_key=$1
    local response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $api_key" \
        "https://api.digitalocean.com/v2/account")

    if [ "$response" == "200" ]; then
        return 0
    else
        return 1
    fi
}


# ===== Multi API Manager =====
API_FILE="api_keys.db"
touch "$API_FILE"

add_api() {
    clear
    read -p "Nama API: " api_name
    read -sp "Token API: " api_token
    echo ""
    if validate_api_key "$api_token"; then
        echo "${api_name}|${api_token}" >> "$API_FILE"
        echo "API berhasil ditambahkan."
    else
        echo "API tidak valid."
    fi
    read -p "Tekan Enter..."
}

show_api_list() {
    clear
    echo "===== DAFTAR API ====="
    nl -w2 -s'. ' "$API_FILE"
    echo ""
}

select_api() {
    show_api_list
    read -p "Pilih nomor API: " nomor
    selected=$(sed -n "${nomor}p" "$API_FILE")
    api_name=$(echo "$selected" | cut -d'|' -f1)
    api_key=$(echo "$selected" | cut -d'|' -f2)

    if [ -z "$api_key" ]; then
        echo "Pilihan tidak valid."
        return 1
    fi

    echo "Menggunakan API : $api_name"
    sleep 2
    return 0
}

delete_api() {
    show_api_list
    read -p "Nomor API yang ingin dihapus: " nomor
    sed -i "${nomor}d" "$API_FILE"
    echo "API berhasil dihapus."
    sleep 2
}

api_menu() {
    while true; do
        clear
        echo "===== DIGITALOCEAN API MANAGER ====="
        echo "1. Pilih API"
        echo "2. Tambah API"
        echo "3. Hapus API"
        echo "0. Lanjut"
        read -p "Pilih: " pilih

        case $pilih in
            1) select_api ;;
            2) add_api ;;
            3) delete_api ;;
            0) break ;;
        esac
    done
}
# ===== End Multi API Manager =====

# Fungsi size map untuk menampilkan ukuran droplet berdasarkan slug
size_map() {
    local size_slug=$1
    case $size_slug in
        # Basic sizes
        "s-1vcpu-1gb") echo "1vCPU 1GB" ;;
        "s-1vcpu-2gb") echo "1vCPU 2GB" ;;
        "s-2vcpu-2gb") echo "2vCPU 2GB" ;;
        "s-2vcpu-4gb") echo "2vCPU 4GB" ;;
        "s-4vcpu-8gb") echo "4vCPU 8GB" ;;
        "s-8vcpu-16gb") echo "8vCPU 16GB" ;;
        "s-16vcpu-32gb") echo "16vCPU 32GB" ;;
        "s-32vcpu-64gb") echo "32vCPU 64GB" ;;
        
        # Premium Intel sizes
        "s-1vcpu-1gb-intel") echo "1vCPU 1GB" ;;
        "s-1vcpu-2gb-intel") echo "1vCPU 2GB" ;;
        "s-2vcpu-4gb-intel") echo "2vCPU 4GB" ;;
        "s-4vcpu-8gb-intel") echo "4vCPU 8GB" ;;
        "s-8vcpu-16gb-intel") echo "8vCPU 16GB" ;;
        "s-16vcpu-32gb-intel") echo "16vCPU 32GB" ;;
        "s-32vcpu-64gb-intel") echo "32vCPU 64GB" ;;
        
        # Premium AMD sizes
        "s-1vcpu-1gb-amd") echo "1vCPU 1GB" ;;
        "s-1vcpu-2gb-amd") echo "1vCPU 2GB" ;;
        "s-2vcpu-2gb-amd") echo "2vCPU 2GB" ;;
        "s-2vcpu-4gb-amd") echo "2vCPU 4GB" ;;
        "s-4vcpu-8gb-amd") echo "4vCPU 8GB" ;;
        "s-8vcpu-16gb-amd") echo "8vCPU 16GB" ;;
        "s-16vcpu-32gb-amd") echo "16vCPU 32GB" ;;
        "s-32vcpu-64gb-amd") echo "32vCPU 64GB" ;;
        *) echo "Unknown Size" ;;
    esac
}

# Fungsi untuk menampilkan daftar droplet dengan size map
show_droplet_list() {
    local api_key=$1
    local droplet_info=$(curl -s -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $api_key" \
        "https://api.digitalocean.com/v2/droplets")
        
    echo -e "-------------------DigitalOcean Droplet Manager by RennZONE---------------------"
    echo -e "No.  Hostname     IP Address       OS              Size          Create Date"
    echo -e "--------------------------------------------------------------------------------"

    echo "$droplet_info" | jq -r '
    .droplets[] | 
    {name: .name, public_ip: (.networks.v4[] | select(.type == "public").ip_address), os: .image.distribution, size_slug: .size.slug, created_at: .created_at} |
    "\(.name) \(.public_ip) \(.os) \(.size_slug) \(.created_at)"' | 
    while read -r droplet_name droplet_ip droplet_os droplet_size_slug droplet_created_at; do
        droplet_size=$(size_map "$droplet_size_slug")
        printf "%-4s %-12s %-15s %-15s %-12s %-10s\n" \
            "$((++count))." "$droplet_name" "$droplet_ip" "$droplet_os" "$droplet_size" "${droplet_created_at:0:10}"
    done
}

# Fungsi untuk menampilkan daftar region dan meminta input ulang jika invalid
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
            *) echo "Invalid choice. Please try again." ;;
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
        echo "4. CentOS 9 Stream x64"
        echo "5. Debian 11 x64"
        echo "6. Debian 12 x64"
        echo "7. Fedora 38 x64"
        echo "8. Fedora 40 x64"
        echo "9. AlmaLinux 8"
        echo "10. Rocky Linux 8"
        echo "11. Rocky Linux 9"
        echo "12. Ubuntu Desktop (GNOME)"
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
            *) echo "Invalid choice. Please try again." ;;
        esac
    done
}

# Fungsi untuk menampilkan daftar size dan meminta input ulang jika invalid
choose_size() {
    while true; do
        clear
        echo "Choose Size:"
        echo ""
        echo "Basic Sizes:"
        echo "1. 1 vCPU, 1 GB RAM, 25 GB SSD"
        echo "2. 1 vCPU, 2 GB RAM, 50 GB SSD"
        echo "3. 2 vCPU, 2 GB RAM, 60 GB SSD"
        echo "4. 2 vCPU, 4 GB RAM, 80 GB SSD"
        echo "5. 4 vCPU, 8 GB RAM, 160 GB SSD"
        echo ""
        echo "Premium Intel Sizes:"
        echo "6. 1 vCPU, 1 GB RAM, 35 GB NVME"
        echo "7. 1 vCPU, 2 GB RAM, 90 GB NVME"
        echo "8. 2 vCPU, 4 GB RAM, 120 GB NVME"
        echo ""
        echo "Premium AMD Sizes:"
        echo "9. 1 vCPU, 1 GB RAM, 25 GB NVME"
        echo "10. 1 vCPU, 2 GB RAM, 50 GB NVME"
        echo "11. 2 vCPU, 2 GB RAM, 60 GB NVME"
        echo "12. 2 vCPU, 4 GB RAM, 80 GB NVME"
        echo "13. 4 vCPU, 8 GB RAM, 160 GB NVME"
        echo ""
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
            00) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
    done
}

# Meminta user untuk memasukkan password dan hostname
input_password_hostname() {
    clear
    read -sp "Input Password: " droplet_password
    echo ""
    read -p "Input Hostname: " droplet_hostname
    clear
}

# Fungsi untuk deploy droplet
create_droplet() {
    local api_key=$1
    local droplet_name=$droplet_hostname
    local droplet_region=$region
    local droplet_image=$image
    local droplet_size=$size
    local droplet_password=$droplet_password

    echo "Creating Droplet..."

    # User data script to set root password and configure SSH
    user_data=$(cat <<EOF
#!/bin/bash
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g;s/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
systemctl restart sshd
echo "root:$droplet_password" | chpasswd
EOF
)

    # Menggunakan curl untuk membuat droplet
    response_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://api.digitalocean.com/v2/droplets" \
    -H "Authorization: Bearer $api_key" \
    -H "Content-Type: application/json" \
    -d '{
        "name":"'"$droplet_name"'",
        "region":"'"$droplet_region"'",
        "size":"'"$droplet_size"'",
        "image":"'"$droplet_image"'",
        "user_data":"'"$user_data"'",
        "ssh_keys": [],
        "backups": false,
        "ipv6": true,
        "private_networking": null,
        "volumes": null,
        "tags": []
    }')

    if [ "$response_code" -eq 202 ]; then
        echo "Droplet sedang dalam proses deploy! Tunggu beberapa saat . . ."
        # Tambahkan jeda singkat sebelum menampilkan droplet list yang diperbarui
        sleep 30  # Memberikan jeda agar API memperbarui data
        echo "Memperbarui daftar droplet..."
        clear
        echo "Droplet sukses dibuat!"
        show_droplet_list "$api_key"
    else
        echo "Droplet gagal dibuat! Ingin coba lagi?"
        read -p "(y/n): " try_again
        if [ "$try_again" == "y" ]; then
            create_droplet "$api_key"
        else
            show_droplet_list "$api_key"
        fi
    fi
}

# Fungsi untuk destroy droplet
destroy_droplet() {
    local api_key=$1
    read -p "Masukkan IP droplet yang ingin dihapus: " droplet_ip

    # Mendapatkan ID droplet berdasarkan IP
    droplet_id=$(curl -s -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $api_key" \
        "https://api.digitalocean.com/v2/droplets" | \
        jq -r --arg ip "$droplet_ip" '.droplets[] | select(.networks.v4[]?.ip_address == $ip) | .id')

    if [ -z "$droplet_id" ]; then
        clear
        echo "ERROR : Droplet dengan IP $droplet_ip tidak ditemukan."
        show_droplet_list "$api_key"
        return
    fi

    # Konfirmasi sebelum penghapusan
    read -p "Apakah Anda yakin ingin menghapus droplet dengan IP $droplet_ip (y/n)? " confirm
    if [ "$confirm" == "y" ]; then
        response_code=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
            -H "Authorization: Bearer $api_key" \
            "https://api.digitalocean.com/v2/droplets/$droplet_id")

        if [ "$response_code" -eq 204 ]; then
            echo "Droplet dengan IP $droplet_ip dalam proses untuk dihapus. Tunggu beberapa saat . . ."
            sleep 30  # Memberikan waktu tambahan bagi API DigitalOcean
            clear  # Membersihkan layar sebelum menampilkan daftar droplet yang diperbarui
            echo "Droplet sukses dihapus!"
            show_droplet_list "$api_key"  # Menampilkan daftar droplet yang diperbarui
        else
            echo "Gagal menghapus droplet. Ingin coba lagi?"
            read -p "(y/n): " try_again
            if [ "$try_again" == "y" ]; then
                destroy_droplet "$api_key"
            else
                clear  # Membersihkan layar sebelum menampilkan daftar droplet yang diperbarui
                show_droplet_list "$api_key"
            fi
        fi
    fi
}

# Fungsi untuk reboot droplet
reboot_droplet() {
    local api_key=$1
    read -p "Masukkan IP droplet yang ingin direboot: " droplet_ip

    # Mendapatkan ID droplet berdasarkan IP
    droplet_id=$(curl -s -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $api_key" \
        "https://api.digitalocean.com/v2/droplets" | \
        jq -r --arg ip "$droplet_ip" '.droplets[] | select(.networks.v4[]?.ip_address == $ip) | .id')

    if [ -z "$droplet_id" ]; then
        clear
        echo "ERROR : Droplet dengan IP $droplet_ip tidak ditemukan."
        show_droplet_list "$api_key"
        return
    fi

    # Konfirmasi sebelum penghapusan
    read -p "Apakah Anda yakin ingin melakukan reboot pada droplet dengan IP $droplet_ip (y/n)? " confirm
    if [ "$confirm" == "y" ]; then
            response_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://api.digitalocean.com/v2/droplets/$droplet_id/actions" \
    -H "Authorization: Bearer $api_key" \
    -H "Content-Type: application/json" \
    -d '{"type":"reboot"}')

        if [ "$response_code" -eq 201 ]; then
            echo "Droplet dengan IP $droplet_ip dalam proses untuk direboot. Tunggu beberapa saat . . ."
            sleep 30  # Memberikan waktu tambahan bagi API DigitalOcean
            clear  # Membersihkan layar sebelum menampilkan daftar droplet yang diperbarui
            echo "Droplet sukses direboot!"
            show_droplet_list "$api_key"  # Menampilkan daftar droplet yang diperbarui
        else
            echo "Gagal melakukan reboot pada droplet. Ingin coba lagi?"
            read -p "(y/n): " try_again
            if [ "$try_again" == "y" ]; then
                reboot_droplet "$api_key"
            else
                clear  # Membersihkan layar sebelum menampilkan daftar droplet yang diperbarui
                show_droplet_list "$api_key"
            fi
        fi
    fi
}

# Fungsi untuk rebuild droplet
rebuild_droplet() {
    local api_key=$1
    local droplet_id
    local droplet_ip
    read -p "Masukkan IP droplet yang ingin di-rebuild: " droplet_ip

    # Mendapatkan ID droplet berdasarkan IP
    droplet_id=$(curl -s -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $api_key" \
        "https://api.digitalocean.com/v2/droplets" | \
        jq -r --arg ip "$droplet_ip" '.droplets[] | select(.networks.v4[]?.ip_address == $ip) | .id')

    if [ -z "$droplet_id" ]; then
        clear
        echo "ERROR : Droplet dengan IP $droplet_ip tidak ditemukan."
        show_droplet_list "$api_key"
        return
    fi

    # Konfirmasi rebuild
    read -p "Apakah Anda yakin ingin melakukan rebuild pada Droplet $droplet_ip ? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo "Rebuild dibatalkan."
        return
    fi

    # Meminta user untuk memilih image
    choose_image() {
        while true; do
            clear
            echo "Choose Image:"
            echo "1. Ubuntu 20.04"
            echo "2. Ubuntu 22.04"
            echo "3. Ubuntu 24.04"
            echo "4. AlmaLinux 8"
            echo "5. AlmaLinux 9"
            echo "6. CentOS Stream 9"
            echo "7. Debian 11"
            echo "8. Debian 12"
            echo "9. Fedora 39"
            echo "10. Fedora 40"
            echo "11. Rocky Linux 8"
            echo "12. Rocky Linux 9"
            read -p "Input image number: " image_choice

            case $image_choice in
                1) image="ubuntu-20-04-x64"; break ;;
                2) image="ubuntu-22-04-x64"; break ;;
                3) image="ubuntu-24-04-x64"; break ;;
                4) image="almalinux-8-x64"; break ;;
                5) image="almalinux-9-x64"; break ;;
                6) image="centos-stream-9-x64"; break ;;
                7) image="debian-11-x64"; break ;;
                8) image="debian-12-x64"; break ;;
                9) image="fedora-39-x64"; break ;;
                10) image="fedora-40-x64"; break ;;
                11) image="rockylinux-8-x64"; break ;;
                12) image="rockylinux-9-x64"; break ;;
                *) echo "Invalid choice. Please try again." ;;
            esac
        done
    }

    # Memilih image untuk rebuild
    choose_image

    # Melakukan rebuild Droplet
    response_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://api.digitalocean.com/v2/droplets/$droplet_id/actions" \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d '{"type":"rebuild", "image":"'"$image"'"}')

    # Menampilkan hasil rebuild
    if [ "$response_code" -eq 201 ]; then
        echo "Droplet dengan IP $droplet_ip dalam proses untuk di-rebuild. Tunggu beberapa saat . . ."
        sleep 30  # Memberikan waktu tambahan bagi API DigitalOcean
        clear  # Membersihkan layar sebelum menampilkan daftar droplet yang diperbarui
        echo "Droplet sukses di-rebuild! Cek email Anda untuk mendapatkan aksesnya."
        show_droplet_list "$api_key"  # Menampilkan daftar droplet yang diperbarui        
    else
        echo "Rebuild gagal! Cek kembali ID Droplet atau image."
    fi
}

# Fungsi untuk menampilkan menu utama
main_menu() {
    while true; do
        echo ""
        echo -e "--------------------------------------------------------------------------------"
        echo ""
        echo "Pilih opsi berikut:"
        echo "1. Deploy"
        echo "2. Destroy"
        echo "3. Reboot"
        echo "4. Rebuild"
        echo "0. Exit"
        read -p "Masukkan pilihan: " choice
        case $choice in
            1)
                choose_region
                choose_image
                choose_size
                input_password_hostname
                create_droplet "$api_key"
                ;;
            2)
                destroy_droplet "$api_key"
                ;;
            3)
                reboot_droplet "$api_key"
                ;;
            4)  
                rebuild_droplet "$api_key"
                ;;
            0)
                echo "Anda memilih untuk keluar. Terima kasih!"
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid. Silakan coba lagi."
                ;;
        esac
    done
}
# Meminta API Key dan validasi
while true; do
    clear
    read -sp "Masukkan DigitalOcean API Key Anda: " api_key
    echo ""

    if validate_api_key "$api_key"; then
        clear
        echo "API Key valid! Menampilkan daftar droplet..."
        show_droplet_list "$api_key"
        break
    else
        echo "API Key tidak valid. Silakan coba lagi."
    fi
done

# Memanggil menu utama
main_menu
