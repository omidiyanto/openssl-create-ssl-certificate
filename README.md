1. Create the certificate
   ```bash
   bash create-selfsigned-ssl.sh
   ```

2. Check the certificate
   ```bash
   openssl x509 -in <CERTIFICATE.crt> -text -noout | grep -A1 "Subject Alternative Name"
   ```
