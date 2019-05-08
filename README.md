# Vault Certificate Issuer

Issues and reissues centrificates from Vault and sends them on a unix domain socket.

## Run

```
VAULT_CA_SHA256='EFs905ao/zCpuPvLoJlv3UhBejuQ+0HSi25nqlZv0ek=' \
VAULT_PKI_PATH=test_int_ca \
VAULT_PKI_ROLE=short_service \
VAULT_TOKEN=myroot \
COMMON_NAME=short_service \
mix run --no-halt
```

Replace `EFs905ao/zCpuPvLoJlv3UhBejuQ+0HSi25nqlZv0ek=` with the sha256 fingerprint of your vault https certificate. See
below for more info. The certificate and its fingerprints are available with the following command.

```
docker run --rm \
  --volumes-from vault-tls \
  -e CERT_PATH=/var/tls \
  -e COMMON_NAME=vault \
  -e SUBJECT='/C=SE/O=Dev' \
  -e VALID_DAYS=365 \
  pntregistry.azurecr.io/certificate-generator:1.0.0
```


### Setup dev vault

```
docker run \
  --name vault-tls \
  -v /var/tls \
  -e CERT_PATH=/var/tls \
  -e COMMON_NAME=vault \
  -e SUBJECT='/C=SE/O=Dev' \
  -e VALID_DAYS=365 \
  pntregistry.azurecr.io/certificate-generator:1.0.0
```

Save the b64 fingerprint from the output, this is required when running ths application.
It can be aquired at any point with:

```
docker run --rm \
  --volumes-from vault-tls \
  -e CERT_PATH=/var/tls \
  -e COMMON_NAME=vault \
  -e SUBJECT='/C=SE/O=Dev' \
  -e VALID_DAYS=365 \
  pntregistry.azurecr.io/certificate-generator:1.0.0
```

```
docker run -it --rm \
  --name=vault \
  --cap-add=IPC_LOCK \
  -e 'VAULT_DEV_ROOT_TOKEN_ID=myroot' \
  -p 8200:8201 \
  --volumes-from vault-tls \
  -e 'VAULT_LOCAL_CONFIG={"listener":[{"tcp":{"address":"0.0.0.0:8201","tls_cert_file":"/var/tls/vault.crt","tls_key_file": "/var/tls/vault.key"}}]}' \
  vault
```

### Bootstrap vault pki module

```
docker run --rm -a stdout -a stderr \
  --name vault-bootstrap \
  --link vault:vault \
  --volumes-from vault-tls \
  -v "$PWD/priv/vault/bootstrap.json":/vault_bootstrap/bootstrap.json \
  plugandtrade/vault-bootstrap:0.2.2 \
  bootstrap \
  --host https://vault:8201 \
  --capath /var/tls/vault.crt \
  --config /vault_bootstrap/bootstrap.json \
  --token myroot
```

## Release

### Build

`docker build --tag vault-certificate-issuer:latest .`

### Run

`docker create [-e ARG=VAL]... [--link container:vault] --name vault-certs-01 vault-certificate-issuer:latest`

`docker start die-scheite-01`

Available arguments:

 * `VAULT_URL` URL to Vault, default: `http://vault:8200`.
 * `VAULT_CA_SHA256` Base64 encoded sha256 fingerprint of vault https certificate, eg `EFs905ao/zCpuPvLoJlv3UhBejuQ+0HSi25nqlZv0ek=`, required.
 * `VAULT_PKI_PATH` Path of the pki module in Vault, eg. `pki`, required.
 * `VAULT_PKI_ROLE` Name of the pki role, eg. `my_certi`, required.
 * `VAULT_TOKEN` Vault token valid for issuing certificates, required.
 * `COMMON_NAME` The CN of the issued certificates, required.
 * `TTL` The TTL of the issued certificates. `0` indicates using the configured value of the role. Default: `0`.
 * `EXPIRE_MARGIN` Reissue certificates `EXPIRE_MARGIN` seconds prior to certificate expiration, default: `60`.
 * `MIN_REISSUE_TIME` Wait at leat `MIN_REISSUE_TIME` seconds between issue requests, default: `60`.
 * `RETRY_INTERVAl` Interval, in seconds, between retries if Vault is inaccessible or failed to issue certificate, default: `20`.
 * `SOCKET_TIMEOUT` Interval, in milliseconds, between connection attempts to the unix domain socket, default `1000`.

The service will wait for a socket at `/tmp/cert/certs.sock`.
