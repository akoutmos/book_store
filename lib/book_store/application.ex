defmodule BookStore.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      BookStore.Repo,
      # Start the Telemetry supervisor
      BookStoreWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: BookStore.PubSub},
      # Start the Endpoint (http/https)
      BookStoreWeb.Endpoint
      # Start a worker by calling: BookStore.Worker.start_link(arg)
      # {BookStore.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BookStore.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BookStoreWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
