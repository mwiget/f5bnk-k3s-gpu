#!/bin/bash

generate_config() {
    local hostname=$1
    local password=$2
    local ip_address=$3
    local ip_mask=$4
    local output_file=$5
    local net_rshim_mac=$6

    sed -e "s/{{HOSTNAME}}/${hostname}/g" \
        -e "s|{{PASSWORD}}|${password}|g" \
        -e "s/{{IP_ADDRESS}}/${ip_address}/g" \
        -e "s/{{IP_MASK}}/${ip_mask}/g" \
        -e "s/{{NET_RSHIM_MAC}}/${net_rshim_mac}/g" \
        bf.conf.template > "${output_file}"
}


read -p "Enter the number of DPUs (default: 1): " num_dpus
num_dpus=${num_dpus:-1}
read -p "Enter the base hostname (default: dpu): " base_hostname
base_hostname=${base_hostname:-dpu}
echo "Enter the Ubuntu password minimum 12 characters (e.g. 'a123456AbCd!'): "
# Password policy reference: https://docs.nvidia.com/networking/display/bluefielddpuosv490/default+passwords+and+policies#src-3432095135_DefaultPasswordsandPolicies-UbuntuPasswordPolicy
read -s clear_password
ubuntu_password=$(openssl passwd -1 "${clear_password}")
read -p "Enter tmfifo_net IP subnet mask. Useful if you have more than 1 DPU (default: 30): " ip_mask
ip_mask=${ip_mask:-30}


base_ip=${base_ip:-192.168.100}

for ((i=1; i<=num_dpus; i++)); do
    hostname="${base_hostname}${i}"
    ip_address="${base_ip}.$(( i + 1 ))"
    net_rshim_mac=00:1a:ca:ff:ff:1${i}
    output_file="bfb_config_${hostname}.conf"

    echo "Generating configuration for ${hostname} with IP ${ip_address}..."
    generate_config "${hostname}" "${ubuntu_password}" "${ip_address}" "${ip_mask}" "${output_file}" "${net_rshim_mac}"
    cat << EOL
Configuration for ${hostname} is ${output_file}
To use the config run:
bfb-install --rshim rshim$(( i - 1 )) --config ${output_file} --bfb <bf-bundle-path>
EOL
done
