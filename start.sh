#!/usr/bin/env bash

if [ -z "$DOMAINS" ] ; then
  echo "No domains set, please fill -e 'DOMAINS=example.com www.example.com'"
  exit 1
fi

if [ -z "$EMAIL" ] ; then
  echo "No email set, please fill -e 'EMAIL=your@email.tld'"
  exit 1
fi

if [ -z "$WEBROOT_PATH" ] ; then
  echo "No webroot path set, please fill -e 'WEBROOT_PATH=/tmp/letsencrypt'"
  exit 1
fi

DOMAINS_ARRAY=(${DOMAINS})
EMAIL_ADDRESS=${EMAIL}

exp_limit="${EXP_LIMIT:-30}"
check_freq="${CHECK_FREQ:-30}"

SCALE_ENABLED="${SCALE_ENABLED:-disabled}"
DEFAULT_CONTAINER_SCALE="${DEFAULT_CONTAINER_SCALE:-1}"


container_id=$HOSTNAME
container_name=$(docker inspect --format="{{.Name}}" ${container_id} | grep -oP '[0-9A-Za-z]+_[a-zA-Z0-9_.-]+_[0-9]+')
network_name=$(docker inspect --format="{{.HostConfig.NetworkMode}}" ${container_id})
image_name=$(echo ${container_name} | sed -r 's/_[0-9]+$//')
scale_num=$(echo ${container_name} | grep -oP '[0-9+]$')

echo "[NOTICE] Starting letsencrypt container $container_name($container_id)..."

if [[ "$SCALE_ENABLED" == 'disabled' ]]; then
    echo "[NOTICE] Scaling is disabled for letsencrypt"
    if [[ "$DEFAULT_CONTAINER_SCALE" != $scale_num ]]; then
        echo "[NOTICE] Stopping container with scale number $scale_num and container id $container_id"
        docker stop ${container_id}
    fi
else
    echo "[WARNING] Scaling is not disabled for letsencrypt. Starting container with scale number $scale_num..."
fi

dry_run="--dry-run"
ENV_TYPE="${ENV_TYPE:0}"
if [ "$ENV_TYPE" == "production" ]; then
    echo "[NOTICE] Container started in production mode"
    dry_run=""
else
    echo "[NOTICE] Container started in developer mode"
fi

env

le_hook() {
    local network_containers_name=$(docker network inspect --format '{{range $index, $lement := .Containers}}{{.Name}} {{end}}' ${network_name})
    
    echo "[NOTICE] Start checking containers from network $network_name"
    for network_container_name in ${network_containers_name[@]}; do
        echo "[NOTICE] Checking container $network_container_name"
        if [[ ! "$network_container_name" =~ ^.*${image_name}_[0-9]+$ ]]; then
            echo "[NOTICE] It's not letsencrypt container $network_container_name"
            if [[ "$network_container_name" =~ ^.+_${scale_num}$ ]] || [[ "$SCALE_ENABLED" == 'disabled' ]]; then
                echo "[NOTICE] Restarting container ${network_container_name}"
                docker restart ${network_container_name}
            fi
        fi
    done
}

le_fixpermissions() {
    echo "[INFO] Fixing permissions"
    chown -R ${CHOWN:-root:root} /etc/letsencrypt
    find /etc/letsencrypt -type d -exec chmod 755 {} \;
    find /etc/letsencrypt -type f -exec chmod ${CHMOD:-644} {} \;
    echo "[INFO] Fixed permissions"
}

le_renew() {
    local domains=$1
    echo "[NOTICE] Getting new certificates"
    certbot certonly --webroot --agree-tos --renew-by-default ${dry_run} --email ${EMAIL_ADDRESS} -w ${WEBROOT_PATH} -d ${domains}
    echo "[NOTICE] Getted new certificates"
    le_fixpermissions
    le_hook
}

le_check() {
    local domains=$1
    local first_domain="$( cut -d ',' -f 1 <<< "$domains" )"
    
    local cert_file="/etc/letsencrypt/live/$first_domain/fullchain.pem"
    
    echo "[NOTICE] Start processing domains $first_domain($domains)"
    
    if [ -f $cert_file ]; then
        
        local exp=$(date -d "`openssl x509 -in $cert_file -text -noout|grep "Not After"|cut -c 25-`" +%s)
        local cert_domains=$(openssl x509 -in $cert_file -text -noout | grep -oP '(?<=DNS:)[^,]*' | tr '\n' ' ')
        local datenow=$(date -d "now" +%s)
        local days_exp=$[ ( $exp - $datenow ) / 86400 ]
        
        local cert_domains_string=${cert_domains// /,}
        
        echo "Checking expiration date for $first_domain($cert_domains_string)..."
        
        if [ "$days_exp" -gt "$exp_limit" ] ; then
            echo "The certificate is up to date, no need for renewal ($days_exp days left)."
        else
            echo "The certificate for $first_domain($cert_domains_string) is about to expire soon. Starting webroot renewal script for domains $first_domain($domains)..."
            le_renew $domains
            echo "Renewal process finished for domain $first_domain($domains)"
        fi
        
        echo "Compairing domains for $first_domain($cert_domains_string) and $first_domain($domains)..."
        
        local domains_array=${domains//,/ }
        local new_domains=($(
            for domain in ${domains_array[@]}; do
                [[ " ${cert_domains[@]} " =~ " ${domain} " ]] || echo $domain
            done
        ))
        
        new_domains_string=$(echo $new_domains | tr ' ' ',')
        if [ -z "$new_domains" ] ; then
            echo "The certificate have no changes, no need for renewal"
        else
            echo "The list of domains for $first_domain($cert_domains_string) certificate has been changed to $first_domain($domains). List of new domains($new_domains_string). Starting webroot renewal script..."
            le_renew $domains
            echo "Renewal process finished for domains $first_domain($domains)"
        fi
        
    else
        echo "Certificate for domain $first_domain not found. Starting webroot renewal script..."
        le_renew $domains
        echo "Renewal process finished for domains $first_domain($domains)"
    fi
    
    echo "[NOTICE] Finished process domains $first_domain($domains)"
}

le_check_domains() {
    for domains in ${DOMAINS_ARRAY[@]}; do
        le_check $domains
    done
}

le_check_cycle() {
    local arg_once=$1
    while true; do
        le_check_domains
        if [ "$arg_once" == "once" ]; then
            echo "[NOTICE] Container started in script mode. Stopping script..."
            break
        fi
        sleep ${check_freq}d
    done
}

le_check_cycle $1
