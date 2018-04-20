defmodule VaultCertificateIssuer do
  use Application
  import Supervisor.Spec
  @moduledoc """
  Documentation for VaultCertificateIssuer.
  """

  def start(_type, _args) do
    socket_path = System.get_env("SOCKET_PATH") || "./certs.sock"
    {socket_timeout, _} = Integer.parse(System.get_env("SOCKET_TIMEOUT") || "1000")

    vault_url = System.get_env("VAULT_URL") || "http://localhost:8200/v1/"
    vault_issue_path = System.get_env("VAULT_ISSUE_PATH")
    vault_token = System.get_env("VAULT_TOKEN")
    common_name = System.get_env("COMMON_NAME")
    {ttl, _} = Integer.parse(System.get_env("TTL") || "60")
    {expire_margin, _} = Integer.parse(System.get_env("EXPIRE_MARGIN") || "60")
    {min_reissue_time, _} = Integer.parse(System.get_env("MIN_REISSUE_TIME") || "60")
    {retry_interval, _} = Integer.parse(System.get_env("RETRY_INTERVAl") || "20")

    children = [
      worker(VaultCertificateIssuer.AFUnix, [[
        path: socket_path,
        timeout: socket_timeout,
        name: :socket
      ]]),
      worker(VaultCertificateIssuer.CertificateIssuer, [[
        vault_url: vault_url,
        token: vault_token,
        vault_issue_path: vault_issue_path,
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
