#!/bin/bash

#
# Sign server and client certificates.
#

set -e;
set -u;

# Install root and intermediate certs.
dpkg -i /usr/local/dreambox/dreambox-ca-certificates.deb;

SSL_DIR_PATH='/usr/local/dh/apache2/apache2-dreambox/etc/ssl.crt';
KEY_FILE="${SSL_DIR_PATH}/dreambox.key";
CRT_FILE="${SSL_DIR_PATH}/dreambox.crt";
SSL_CONF='/root/ca/intermediate/openssl.cnf';

# Copy the ca-chain file into place.
cp /usr/local/dreambox/ca-chain.cert.pem  "${SSL_DIR_PATH}";

# Check for a saved certificate and key.
if [[ -r "/vagrant/certs/dreambox.key" && -r "/vagrant/certs/dreambox.crt" ]]; then
  echo "Using saved cert from /vagrant/certs/";
  cp -f "/vagrant/certs/dreambox".* "${SSL_DIR_PATH}";
else
  # Adds the SAN hosts to the openssl.cnf file.
  if [[ -n "${san_list}" ]]; then
    bash -c "echo -e \"${san_list}\" >> ${SSL_CONF}";
  fi;

  # Create a key.
  openssl genrsa -out "${KEY_FILE}" 2048;
  chmod 400 "${KEY_FILE}";

  # Create a certificate signing request.
  openssl req \
    -config "${SSL_CONF}" \
    -key "${KEY_FILE}" \
    -new \
    -sha256 \
    -subj '/C=US/ST=Washington/L=Seattle/O=Dreambox/OU=Dreambox Web Services/CN=Dreambox VHost/' \
    -out "/root/ca/intermediate/csr/dreambox.csr";

  # Sign the vhost certificate.
  /usr/bin/expect <<EOF
    spawn openssl ca \
      -config "${SSL_CONF}" \
      -extensions server_cert \
      -days 375 \
      -notext \
      -md sha256 \
      -in "/root/ca/intermediate/csr/dreambox.csr" \
      -out "${CRT_FILE}";
    expect "Sign the certificate?"
    send "y\r"
    expect "1 out of 1 certificate requests certified, commit?"
    send "y\r"
    expect eof
EOF

  if [[ $? -lt 1 ]]; then
    # Success!
    echo 'SSL key and certificate created:';
    echo ">> ${KEY_FILE}";
    echo ">> ${CRT_FILE}";

    # Save these for next time.
    [[ ! -d /vagrant/certs ]] && mkdir /vagrant/certs;
    cp -f "${SSL_DIR_PATH}/dreambox".* /vagrant/certs;

    # Open permissions for /root/ca.
    chmod 755 /root/;
  else
    echo 'There was an error signing the certificate...';
  fi;
fi;

exit $?;
