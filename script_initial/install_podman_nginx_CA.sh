#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# Función para mostrar mensajes con color
print_step() {
    echo -e "${YELLOW}==> ${1}${NC}"
}

print_success() {
    echo -e "${GREEN}==> ${1}${NC}"
}

print_error() {
    echo -e "${RED}==> ${1}${NC}"
}

# Actualizar el sistema
print_step "Actualizando el sistema..."
sudo apt-get update -y && sudo apt-get upgrade -y
if [ $? -eq 0 ]; then
    print_success "Sistema actualizado correctamente."
else
    print_error "Error al actualizar el sistema."
    exit 1
fi

# Instalar Podman
print_step "Instalando Podman..."
sudo apt-get install -y podman
if [ $? -eq 0 ]; then
    print_success "Podman instalado correctamente."
else
    print_error "Error al instalar Podman."
    exit 1
fi

# Instalar Nginx
print_step "Instalando Nginx..."
sudo apt-get install -y nginx
if [ $? -eq 0 ]; then
    print_success "Nginx instalado correctamente."
else
    print_error "Error al instalar Nginx."
    exit 1
fi

# Iniciar y habilitar Nginx
print_step "Iniciando y habilitando Nginx..."
sudo systemctl start nginx && sudo systemctl enable nginx
if [ $? -eq 0 ]; then
    print_success "Nginx iniciado y habilitado correctamente."
else
    print_error "Error al iniciar y habilitar Nginx."
    exit 1
fi

# Crear directorios y archivos necesarios para la CA
print_step "Configurando la Entidad Certificadora (CA)..."
mkdir -p ~/my_ca/certs ~/my_ca/newcerts ~/my_ca/private
touch ~/my_ca/index.txt
echo 1000 > ~/my_ca/serial

# Crear archivo de configuración para la CA
cat > ~/my_ca/my_ca.cnf <<EOL
[ ca ]
default_ca = my_ca

[ my_ca ]
dir = /home/esotelo/my_ca
certificate = \$dir/certs/ca.cert.pem
database = \$dir/index.txt
new_certs_dir = \$dir/newcerts
private_key = \$dir/private/ca.key.pem
serial = \$dir/serial
default_md = sha256
policy = policy_any
email_in_dn = no
name_opt = ca_default
cert_opt = ca_default
copy_extensions = copy
default_days = 365
preserve = no

[ policy_any ]
countryName = colombia
stateOrProvinceName = bogota
organizationName = es-lab
organizationalUnitName = sistemas
commonName = es-lab-company
emailAddress = es-lab@admin.com

[ req ]
default_bits = 4096
default_md = sha256
distinguished_name = req_distinguished_name
x509_extensions = v3_ca

[ req_distinguished_name ]
countryName = Country Name (2 letter code)
countryName_default = US
stateOrProvinceName = State or Province Name (full name)
stateOrProvinceName_default = California
localityName = Locality Name (eg, city)
localityName_default = San Francisco
organizationName = Organization Name (eg, company)
organizationName_default = My Company
commonName = Common Name (e.g. server FQDN or YOUR name)
commonName_max = 64

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
EOL

print_success "Directorio y archivo de configuración para la CA creados."

# Generar la clave privada de la CA
print_step "Generando la clave privada para la CA..."
openssl genpkey -algorithm RSA -out ~/my_ca/private/ca.key.pem -aes256
if [ $? -eq 0 ]; then
    print_success "Clave privada de la CA generada correctamente."
else
    print_error "Error al generar la clave privada de la CA."
    exit 1
fi

# Generar el certificado de la CA
print_step "Generando el certificado de la CA..."
openssl req -config ~/my_ca/my_ca.cnf -key ~/my_ca/private/ca.key.pem -new -x509 -days 3650 -sha256 -extensions v3_ca -out ~/my_ca/certs/ca.cert.pem
if [ $? -eq 0 ]; then
    print_success "Certificado de la CA generado correctamente."
else
    print_error "Error al generar el certificado de la CA."
    exit 1
fi

print_success "Entidad Certificadora (CA) configurada correctamente."

# Finalización
print_success "Instalación y configuración completadas con éxito."

