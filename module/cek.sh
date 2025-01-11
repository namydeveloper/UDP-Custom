#!/bin/bash
red='\e[1;31m'
green='\e[0;32m'
NC='\e[0m'
MYIP=$(wget -qO- icanhazip.com)
echo "Checking VPS"
clear
echo " "

# Set log file
if [ -e "/var/log/auth.log" ]; then
    LOG="/var/log/auth.log"
elif [ -e "/var/log/secure" ]; then
    LOG="/var/log/secure"
else
    echo "No auth log file found!"
    exit 1
fi

block_ip() {
    local ip=$1
    echo "Blocking IP $ip"
    iptables -A INPUT -s "$ip" -j DROP
}

check_dropbear() {
    data=( $(ps aux | grep -i dropbear | awk '{print $2}') )
    echo "-----=[ Dropbear User Login ]=-----"
    echo "ID  |  Username  |  IP Address"
    echo "-------------------------------------"
    cat $LOG | grep -i dropbear | grep -i "Password auth succeeded" > /tmp/login-db.txt
    for PID in "${data[@]}"; do
        cat /tmp/login-db.txt | grep "dropbear

\[$PID\]

" > /tmp/login-db-pid.txt
        NUM=$(cat /tmp/login-db-pid.txt | wc -l)
        USER=$(cat /tmp/login-db-pid.txt | awk '{print $10}')
        IP=$(cat /tmp/login-db-pid.txt | awk '{print $12}')
        if [ $NUM -eq 1 ]; then
            echo "$PID - $USER - $IP"
            active_users["$USER"]=$((active_users["$USER"]+1))
            user_ip["$USER"]=$IP
        fi
    done
}

check_ssh() {
    data=( $(ps aux | grep "

\[priv\]

" | sort -k 72 | awk '{print $2}') )
    echo " "
    echo "-----=[ OpenSSH User Login ]=-----"
    echo "ID  |  Username  |  IP Address"
    echo "-------------------------------------"
    cat $LOG | grep -i sshd | grep -i "Accepted password for" > /tmp/login-db.txt
    for PID in "${data[@]}"; do
        cat /tmp/login-db.txt | grep "sshd

\[$PID\]

" > /tmp/login-db-pid.txt
        NUM=$(cat /tmp/login-db-pid.txt | wc -l)
        USER=$(cat /tmp/login-db-pid.txt | awk '{print $9}')
        IP=$(cat /tmp/login-db-pid.txt | awk '{print $11}')
        if [ $NUM -eq 1 ]; then
            echo "$PID - $USER - $IP"
            active_users["$USER"]=$((active_users["$USER"]+1))
            user_ip["$USER"]=$IP
        fi
    done
}

check_openvpn_tcp() {
    if [ -f "/etc/openvpn/server/openvpn-tcp.log" ]; then
        echo " "
        echo "-----=[ OpenVPN TCP User Login ]=-----"
        echo "Username  |  IP Address  |  Connected Since"
        echo "-------------------------------------"
        cat /etc/openvpn/server/openvpn-tcp.log | grep -w "^CLIENT_LIST" | cut -d ',' -f 2,3,8 | sed -e 's/,/      /g' > /tmp/vpn-login-tcp.txt
        cat /tmp/vpn-login-tcp.txt
    fi
}

check_openvpn_udp() {
    if [ -f "/etc/openvpn/server/openvpn-udp.log" ]; then
        echo " "
        echo "-----=[ OpenVPN UDP User Login ]=-----"
        echo "Username  |  IP Address  |  Connected Since"
        echo "-------------------------------------"
        cat /etc/openvpn/server/openvpn-udp.log | grep -w "^CLIENT_LIST" | cut -d ',' -f 2,3,8 | sed -e 's/,/      /g' > /tmp/vpn-login-udp.txt
        cat /tmp/vpn-login-udp.txt
    fi
}

main() {
    declare -A active_users
    declare -A user_ip

    check_dropbear
    check_ssh
    check_openvpn_tcp
    check_openvpn_udp

    for user in "${!active_users[@]}"; do
        if [ ${active_users[$user]} -gt 1 ]; then
            echo "User $user has multiple sessions. Blocking IP ${user_ip[$user]}"
            block_ip "${user_ip[$user]}"
        fi
    done

    echo "-------------------------------------"
    echo ""
}

main
