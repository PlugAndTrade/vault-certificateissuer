defmodule VaultCertificateIssuer.AFUnix do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, opts)
  end

  def init(opts) do
    path = Keyword.get(opts, :path, "./socket.sock")
    timeout = Keyword.get(opts, :timeout, 1000)
    send(self(), :open)
    {:ok, %{
      path: path,
      timeout: timeout,
      connected: false,
      connecting: false,
      socket: nil,
      last_message: nil
    }}
  end

  @default_opts [:binary]

  def handle_info(:open, %{path: path, timeout: timeout} = state) do
    with {:ok, socket} <- :afunix.connect(to_charlist(path), @default_opts) do
      Process.send_after(self(), :write, 0)
      {:noreply, %{state | socket: socket, connected: true, connecting: false}}
    else
      {:error, err} when err in [:econnrefused, :enoent] -> Process.send_after(self(), :open, timeout)
        {:noreply, %{state | connected: false, connecting: true}}
      {:error, err} -> {:stop, {:error, err}}
    end
  end

  def handle_info({:tcp_closed, _socket}, state) do
    Process.send_after(self(), :open, 0)
    {:noreply, %{state | connected: false, connecting: false, socket: nil}}
  end

  def handle_info(:write, %{last_message: nil} = state), do: {:noreply, state}
  def handle_info(:write, %{connected: false} = state), do: {:noreply, state}
  def handle_info(:write, %{socket: socket, connected: true, last_message: data} = state) do
    :afunix.send(socket, serialize(data))
    {:noreply, state}
  end
  def handle_info({:write, data}, %{connected: false} = state) do
    {:noreply, %{state | last_message: data}}
  end
  def handle_info({:write, data}, %{socket: socket, connected: true} = state) do
    :afunix.send(socket, serialize(data))
    {:noreply, %{state | last_message: data}}
  end

  defp serialize(%Vault.Pki.CertificateSet{private_key: key, certificate: certificate, chain: chain}) do
    private_jwk =
      X509.parse_pem(key)
      |> List.first()
      |> X509.JWK.to_jwk()
    public_jwk =
      "#{certificate}\n#{chain}"
      |> X509.Certificate.from_pem()
      |> X509.JWK.to_jwk()

    Map.merge(private_jwk, public_jwk)
    |> Poison.encode!()
    |> Kernel.<>("\n")
    |> to_charlist()
  end
end
