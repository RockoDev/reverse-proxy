#!/bin/sh

# This script is used to generate a new Nginx configuration file for a new domain
# Usage example: bash wizard.sh -d example.com -c example-php-1 -s -g -r

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_help()
{
  echo "This script is used to generate a new Nginx configuration file for a new domain."
  echo
  echo "Syntax: bash wizard.sh [OPTIONS]"
  echo
  echo "Options:"
  echo "  -d: (string)                          Domain name."
  echo "  -c: (string)                          Container name."
  echo "  -s|--https: (boolean)                 Enable HTTPS."
  echo "  -g|--generate-certificate: (boolean)  Generate certificate."
  echo "  -r|--restart: (boolean)               Restart Nginx service."
  echo "  -h|--help: (boolean)                  Print this help message."
  echo
}

DOMAIN_NAME=""
CONTAINER_NAME=""
HTTPS_ENABLED=false
RESTART_SERVICE=false
GENERATE_CERTIFICATE=false

for i in "$@"; do
  case $i in
    --) break;;
    '--https') HTTPS_ENABLED=true;;
    '--generate-certificate') GENERATE_CERTIFICATE=true;;
    '--restart') RESTART_SERVICE=true;;
    '-h'|'help'|'--help') print_help; exit 0;;
  esac
done

while getopts ":d:c:sgrh" option; do
  case $option in
    d) DOMAIN_NAME=$OPTARG;;
    c) CONTAINER_NAME=$OPTARG;;
    s) HTTPS_ENABLED=true;;
    g) GENERATE_CERTIFICATE=true;;
    r) RESTART_SERVICE=true;;
    h) print_help; exit 0;;
    *) echo "Invalid option -${OPTARG}"
       exit 1;;
  esac
done

if [[ $DOMAIN_NAME == "" ]]; then
  echo "Which domain do you want to generate?"
  read input_domain
  DOMAIN_NAME=$input_domain
fi

if [[ $DOMAIN_NAME == "" ]]; then
  echo "Error: A domain name is required"
  exit 1
fi

if [[ $CONTAINER_NAME == "" ]]; then
  echo "Which container do you want to assign to ${DOMAIN_NAME}?"
  read input_container
  CONTAINER_NAME=$input_container

  if [ "$HTTPS_ENABLED" != true ]; then
    echo "Do you want to enable HTTPS for ${DOMAIN_NAME}? (y/n)"
    read https
    https=$(echo $https | tr '[:upper:]' '[:lower:]')
    if [ "$https" == "y" ] || [ "$https" == "yes" ] ;then 
      HTTPS_ENABLED=true
    fi
  fi

fi

if [[ $CONTAINER_NAME == "" ]]; then
  echo "Error: A container name is required"
  exit 1
fi

port_80_template=$(cat << EOF
server {
    listen       80;
    listen  [::]:80;
    server_name $DOMAIN_NAME;
    location / {
        set \$container   $CONTAINER_NAME;
        resolver         127.0.0.11;
        proxy_pass       http://\$container;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
)

port_443_template=$(cat << EOF
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN_NAME;
    location / {
        set \$container   $CONTAINER_NAME;
        resolver         127.0.0.11;
        proxy_pass       http://\$container;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    ssl_certificate "/etc/nginx/tls/\${host}/cert.pem";
    ssl_certificate_key "/etc/nginx/tls/\${host}/key.pem";
}
EOF
)

template="${port_80_template}"
if [ "$HTTPS_ENABLED" = true ]; then
  template="${port_80_template}\n\n${port_443_template}"

  if [ "$GENERATE_CERTIFICATE" = true ]; then
    echo "Generating certificate for ${DOMAIN_NAME}"
    parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
    domain_path="$parent_path/etc/nginx/tls/$DOMAIN_NAME"
    mkdir -p "$domain_path"
    mkcert -key-file "$domain_path/key.pem" -cert-file "$domain_path/cert.pem" "$DOMAIN_NAME"
  fi

fi

echo -e "$template" > etc/nginx/conf.d/${DOMAIN_NAME}.conf

if [ "$RESTART_SERVICE" = true ]; then
  echo "Restarting Nginx service"
  docker compose restart nginx
fi

echo -e "${GREEN}[+] Configuration for ${DOMAIN_NAME} has been generated successfully.${NC}\n"
echo -e "    Please make sure to update your DNS records to point to this server."
echo -e "    Or you can use the following command to update your /etc/hosts file:\n"
echo -e "    sudo -- sh -c -e \"echo '127.0.0.1 ${DOMAIN_NAME}' >> /etc/hosts\";\n"
