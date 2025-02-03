#!/bin/bash

# Prompt for key and certificate details
echo "Enter the country (C) [default: ID]: "
read COUNTRY
COUNTRY=${COUNTRY:-ID}

echo "Enter the state (ST) [default: Jakarta]: "
read STATE
STATE=${STATE:-Jakarta}

echo "Enter the locality (L) [default: Jakarta]: "
read LOCALITY
LOCALITY=${LOCALITY:-Jakarta}

echo "Enter the organization (O) [default: MyOrg]: "
read ORGANIZATION
ORGANIZATION=${ORGANIZATION:-MyOrg}

echo "Enter the organizational unit (OU) [default: MyOrgUnit]: "
read ORGANIZATIONAL_UNIT
ORGANIZATIONAL_UNIT=${ORGANIZATIONAL_UNIT:-MyOrgUnit}

echo "Enter the common name (CN) [default: mydomain]: "
read COMMON_NAME
COMMON_NAME=${COMMON_NAME:-mydomain}

echo "Enter the days the certificate will be valid [default: 365]: "
read DAYS
DAYS=${DAYS:-365}

# Ask for the private key file name
echo "Enter the private key filename or path [default: cert.key]: "
read PRIVATE_KEY
PRIVATE_KEY=${PRIVATE_KEY:-cert.key}

# Ask for the certificate filename
echo "Enter the certificate filename or path [default: cert.crt]: "
read CERTIFICATE
CERTIFICATE=${CERTIFICATE:-cert.crt}

# Ask for DNS names for Subject Alternative Name (SAN)
echo "Enter DNS names for Subject Alternative Name (SAN), separated by commas (e.g., example.com,www.example.com): "
read SAN_DNS

# Ask for IP addresses for Subject Alternative Name (SAN)
echo "Enter IP addresses for Subject Alternative Name (SAN), separated by commas (e.g., 192.168.1.1,10.0.0.1): "
read SAN_IP

# Generate the private key
echo "Creating private key..."
openssl genrsa -out $PRIVATE_KEY 2048

# Create the configuration file dynamically with SAN
cat > openssl.cnf <<EOF
[ req ]
distinguished_name = req_distinguished_name
req_extensions = v3_req

[ req_distinguished_name ]
C = $COUNTRY
ST = $STATE
L = $LOCALITY
O = $ORGANIZATION
OU = $ORGANIZATIONAL_UNIT
CN = $COMMON_NAME

[ v3_req ]
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
EOF

# Add DNS SAN entries
SAN_LIST=""
if [[ ! -z "$SAN_DNS" ]]; then
  IFS=',' read -r -a DNS_ARRAY <<< "$SAN_DNS"
  for dns in "${DNS_ARRAY[@]}"; do
    SAN_LIST="$SAN_LIST,DNS:$dns"
  done
fi

# Add IP SAN entries (make sure they are in the same `subjectAltName` line)
if [[ ! -z "$SAN_IP" ]]; then
  IFS=',' read -r -a IP_ARRAY <<< "$SAN_IP"
  for ip in "${IP_ARRAY[@]}"; do
    SAN_LIST="$SAN_LIST,IP:$ip"
  done
fi

# Remove the leading comma and add to the configuration file
if [[ ! -z "$SAN_LIST" ]]; then
  SAN_LIST="${SAN_LIST:1}"
  echo "subjectAltName = $SAN_LIST" >> openssl.cnf
fi

# Generate the certificate
echo "Creating certificate..."
openssl req -x509 -nodes -days $DAYS \
  -key $PRIVATE_KEY \
  -out $CERTIFICATE \
  -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$COMMON_NAME" \
  -extensions v3_req \
  -reqexts v3_req \
  -config openssl.cnf

# Clean up the temporary configuration file
rm -f openssl.cnf

echo "Certificate and private key have been created:"
echo "Private Key: $PRIVATE_KEY"
echo "Certificate: $CERTIFICATE"
