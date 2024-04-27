# Configuración

1. Crear copia del archivo .env.example con el nombre .env
```sh
cp .env.example .env
```

2. Especificar el valor de la variable **APP_NETWORK** en el archivo **.env**.

Esto define el nombre de la red que se usará en docker. En otros proyectos se deberá usar el mismo valor para que se conecten a la misma red y se puedan comunicar.
```
APP_NETWORK=development
```

# Montar
```sh
docker compose up -d
```

# Wizard:
Preguntará los parámetros de sitio:
```sh
bash wizard.sh
```
Creará el sitio example.com apuntando al contenedor example-php-1 escuchando el puerto 80 y 443, generará el certificado y reiniciará nginx:
```sh
bash wizard.sh -d example.com -c example-php-1 -s -g -r
```
Argumantos:
- **-d:** Nombre de dominio.
- **-c:** Nombre del contenedor.
- **-s:** Escuchar puerto 443.
- **-g:** Generar certificados. (Solo si **-s** también está habilitado).
- **-r:** Reiniciar servicio NGINX al finalizar.
- **-h|--help:** Mostrar ayuda.

# Agregar dominio

1. Crear el archivo **etc/nginx/conf.d/local.example.com.conf** reemplazando **local.example.com** por el dominio (local) que se usará.
2. En ese archivo agregar lo siguiente:
```
server {
    listen       80;
    listen  [::]:80;
    server_name local.example.com;
    location / {
        set $container   example_container_name;
        resolver         127.0.0.11;
        proxy_pass       http://$container;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```
3. Reemplazar **local.example.com** por el dominio (local) que se usará.
4. Reemplazar **example_container_name** por el nombre del contenedor que responderá las solicitudes.
5. Reiniciar este contenedor:
```sh
docker compose restart
```
6. Agregar al archivo /private/etc/hosts (en la máquina local) el dominio que se usará:
```
127.0.0.1 local.example.com
```

# HTTPS

1. En el archivo **etc/nginx/conf.d/local.example.com.conf** (donde **local.example.com** es el dominio deseado) agregar lo siguiente:
```
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name local.example.com;
    location / {
        set $container   example_container_name;
        resolver         127.0.0.11;
        proxy_pass       http://$container;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    ssl_certificate "/etc/nginx/tls/${host}/cert.pem";
    ssl_certificate_key "/etc/nginx/tls/${host}/key.pem";
}
```
2. Reemplazar **local.example.com** por el dominio (local) que se usará.
3. Reemplazar **example_container_name** por el nombre del contenedor que responderá las solicitudes.
4. Generar un certificado TLS para el dominio y guardar los archivos **cert.pem** y **key.pem** en la ruta "etc/nginx/tls/*DOMINIO*/"
5. Reiniciar este contenedor:
```sh
docker compose restart
```

# Generar certificados

Una opción para generar los certificados es [mkcert](https://github.com/FiloSottile/mkcert), pero se puede usar cualquier otra herramienta o servicio.
```sh
mkdir -p etc/nginx/tls/local.example.com
cd etc/nginx/tls/local.example.com
mkcert -key-file key.pem -cert-file cert.pem local.example.com
```
