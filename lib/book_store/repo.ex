defmodule BookStore.Repo do
  use Ecto.Repo,
    otp_app: :book_store,
    adapter: Ecto.Adapters.Postgres
end
