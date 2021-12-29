# Configuración

Agregar la variable **APP_NETWORK** al archivo **.env**.

Esto define el nombre de la red que se usará en docker. En otros proyectos se deberá usar el mismo valor para que se conecten a la misma red y se puedan comunicar.
```
APP_NETWORK=development
```

# Montar
```sh
$ docker-compose up -d
```

# Agregar dominio

1. En el archivo **etc/nginx/conf.d/default.conf** agregar lo siguiente:
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
    }
}
```
2. Reemplazar **local.example.com** por el dominio (local) que se usará.
3. Reemplazar **example_container_name** por el nombre del contenedor que responderá las solicitudes.
4. Agregar al archivo /private/etc/hosts (en la máquina local) el dominio que se usará:
```
127.0.0.1 local.example.com
```

# HTTPS

1. En el archivo **etc/nginx/conf.d/default.conf** agregar lo siguiente:
```
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name local.example.com;
    location / {
        set $container   newsletter_php_1;
        resolver         127.0.0.11;
        proxy_pass       http://$container;
        proxy_set_header Host $host;
        #proxy_set_header X-Forwarded-For  $proxy_add_x_forwarded_for;
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
$ docker-compose restart
```