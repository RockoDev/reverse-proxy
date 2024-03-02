#!/bin/bash

domain=$1

if [[ $domain == "" ]]
then
  echo "Which domain do you want to generate?"
  read input_domain
  domain=$input_domain
fi

if [[ $domain != "" ]]
then
  parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
  domain_path="$parent_path/etc/nginx/tls/$domain"
  mkdir -p "$domain_path"
  mkcert -key-file "$domain_path/key.pem" -cert-file "$domain_path/cert.pem" "$domain"
else
  echo 'Missing domain'
fi
