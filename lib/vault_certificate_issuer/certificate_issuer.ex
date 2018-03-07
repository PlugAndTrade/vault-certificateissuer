defmodule VaultCertificateIssuer.CertificateIssuer do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, opts)
  end

  def init(opts) do
    vault_url = Keyword.get(opts, :vault_url, "http://localhost:8200/v1/")
    vault_issue_path = Keyword.get(opts, :vault_issue_path)
    common_name = Keyword.get(opts, :common_name)
    ttl = Keyword.get(opts, :ttl)
    token = Keyword.get(opts, :token)
    dest = Keyword.get(opts, :dest)
    expire_margin = Keyword.get(opts, :expire_margin, 60)
    min_reissue_time = Keyword.get(opts, :min_reissue_time, 60)
    retry_interval = Keyword.get(opts, :retry_interval, 20)
    send(self(), :issue_new)
    {:ok, %{
      vault_url: vault_url,
      vault_issue_path: vault_issue_path,
      common_name: common_name,
      ttl: ttl,
      token: token,
      dest: dest,
      expire_margin: expire_margin,
      min_reissue_time: min_reissue_time,
      retry_interval: retry_interval
    }}
  end

  def issue_new(pid), do: Process.send_after(pid, :issue_new, 0)

  def handle_info(:issue_new, %{
    expire_margin: expire_margin,
    min_reissue_time: min_reissue_time,
    retry_interval: retry_interval,
    dest: dest
  } = state) do
    wait_time = with {:ok, %{key: key, certificate: cert, chain: chain, expires_at: expires_at}} <- get_certificates(state) do
      send_certificates(dest, key, cert, chain)

      valid_duration = Timex.diff(expires_at, Timex.now(), :seconds)
      max(min_reissue_time, (valid_duration - expire_margin))
    else
      {:not_ok, body} -> IO.inspect(body)
        retry_interval
      {:error, error} -> IO.inspect(error)
        retry_interval
    end
    IO.puts("Next run in: #{wait_time}s")
    Process.send_after(self(), :issue_new, wait_time * 1000)
    {:noreply, state}
  end

  defp get_certificates(%{vault_url: url, vault_issue_path: vault_issue_path, common_name: common_name, ttl: ttl, token: token}) do
    with {:ok, %{"data" => %{"private_key" => key, "certificate" => cert} = data}} <- post("#{url}#{vault_issue_path}", %{common_name: common_name, ttl: ttl}, token)
    do
      chain = Map.get(data, "ca_chain", Map.get(data, "issuing_ca"))

      [%{valid_to: valid_to}] = parse_pem_string(cert)
      {:ok, %{key: key, certificate: cert, chain: chain, expires_at: valid_to}}
    else
      e -> e
    end
  end

  defp send_certificates(dest, key, cert, chain) do
    IO.puts("-----BEGIN RSA PRIVATE KEY-----\n[redacted]\n-----END RSA PRIVATE KEY-----\n")
    IO.puts(cert)
    IO.puts(chain)
    Process.send_after(dest, {:write, to_charlist("#{key}\n#{cert}\n#{chain}\n")}, 0)
  end

  defp post(url, json, token) do
    HTTPoison.request(:post, url, Poison.encode!(json), [{"X-Vault-Token", token}])
      |> parse_response()
  end
  defp parse_response({:ok, %HTTPoison.Response{body: json, status_code: 200}}), do: {:ok, Poison.decode!(json)}
  defp parse_response({:ok, %HTTPoison.Response{body: ""}}), do: {:not_ok, %{}}
  defp parse_response({:ok, %HTTPoison.Response{body: json}}), do: {:not_ok, Poison.decode!(json)}
  defp parse_response({_, response}), do: {:error, response}

  defp parse_pem_string(pem_string) do
    pem_string
      |> :public_key.pem_decode()
      |> Enum.map(&parse_pem/1)
  end

  defp parse_pem({:Certificate, pem, _}) do
    {:Certificate, {_, _, _, _, _, {:Validity, _from, {:utcTime, valid_to_s}}, _, _, _, _, _}, _, _} = :public_key.pkix_decode_cert(pem, :plain)
    valid_to = Timex.parse!(to_string(valid_to_s), "{ASN1:UTCtime}")
    %{valid_to: valid_to}
  end
  defp parse_pem(_), do: %{}
end
