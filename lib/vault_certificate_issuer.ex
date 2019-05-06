defmodule VaultCertificateIssuer do
  use Application
  import Supervisor.Spec
  @moduledoc """
  Documentation for VaultCertificateIssuer.
  """

  def start(_type, _args) do
    socket_path = System.get_env("SOCKET_PATH") || "./certs.sock"
    {socket_timeout, _} = Integer.parse(System.get_env("SOCKET_TIMEOUT") || "1000")

    vault_url = System.get_env("VAULT_URL") || "http://localhost:8200"
    vault_ca_fingerprint = System.get_env("VAULT_CA_SHA256")
    vault_pki_path = System.get_env("VAULT_PKI_PATH")
    vault_pki_role = System.get_env("VAULT_PKI_ROLE")
    vault_token = System.get_env("VAULT_TOKEN")
    common_name = System.get_env("COMMON_NAME")
    {ttl, _} = Integer.parse(System.get_env("TTL") || "0")
    {expire_margin, _} = Integer.parse(System.get_env("EXPIRE_MARGIN") || "60")
    {min_reissue_time, _} = Integer.parse(System.get_env("MIN_REISSUE_TIME") || "60")
    {retry_interval, _} = Integer.parse(System.get_env("RETRY_INTERVAl") || "20")

    {:ok, vault} = Vault.Conn.init(
      host: vault_url,
      ca_fingerprint: {:sha256, Base.decode64!(vault_ca_fingerprint)},
      token: vault_token
    )

    children = [
      worker(Vault.Session, [[
        vault: vault
      ]]),
      worker(VaultCertificateIssuer.AFUnix, [[
        path: socket_path,
        timeout: socket_timeout,
        name: :socket
      ]]),
      worker(Vault.Pki.CertificateIssuer, [[
        vault: vault,
        pki_path: vault_pki_path,
        pki_role: vault_pki_role,
        common_name: common_name,
        ttl: ttl,
        expire_margin: expire_margin,
        min_reissue_time: min_reissue_time,
        retry_interval: retry_interval,
        dest: :socket,
        name: :certificate_issuer
      ]])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
