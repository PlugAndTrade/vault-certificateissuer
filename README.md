# Vault Certificate Issuer

Issues and reissues centrificates from Vault and sends them on a unix domain socket.

## Run

`mix run --no-halt`

## Release

### Build

`docker build --tag vault-certificate-issuer:latest .`

### Run

`docker create [-e ARG=VAL]... [--link container:vault] --name vault-certs-01 vault-certificate-issuer:latest`

`docker start die-scheite-01`

Available arguments:

 * `VAULT_URL` URL to Vault, default: `http://vault:8200/v1/`.
 * `VAULT_ISSUE_PATH` Path to the issue endpoint in Vault, eg. `pki/issue/my_role`, required.
 * `VAULT_TOKEN` Vault token valid for issuing certificates, required.
 * `COMMON_NAME` The CN of the issued certificates, required.
 * `TTL` The TTL of the issued certificates, default: `60`.
 * `EXPIRE_MARGIN` Reissue certificates `EXPIRE_MARGIN` seconds prior to certificate expiration, default: `60`.
 * `MIN_REISSUE_TIME` Wait at leat `MIN_REISSUE_TIME` seconds between issue requests, default: `60`.
 * `RETRY_INTERVAl` Interval, in seconds, between retries if Vault is inaccessible or failed to issue certificate, default: `20`.
 * `SOCKET_TIMEOUT` Interval, in milliseconds, between connection attempts to the unix domain socket, default `1000`.

The service will wait for a socket at `/tmp/cert/certs.sock`.
