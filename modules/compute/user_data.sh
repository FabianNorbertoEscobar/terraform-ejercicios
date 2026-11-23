#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nginx
cat > /var/www/html/index.html <<'HTML'
<!doctype html>
<html lang="es">
<head><meta charset="utf-8"><title>Terraform Lab</title></head>
<body><h1>Desplegado con Terraform</h1><p>Nginx funciona en AWS EC2.</p></body>
</html>
HTML
systemctl enable --now nginx
