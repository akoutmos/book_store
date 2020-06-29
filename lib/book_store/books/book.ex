defmodule BookStore.Books.Book do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__

  @derive {Jason.Encoder, only: ~w(title authors description price quantity)a}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "books" do
    field :title, :string
    field :authors, {:array, :string}
    field :description, :string
    field :price, :string
    field :quantity, :integer

    timestamps()
  end

  @doc false
  def changeset(%Book{} = book, attrs) do
    book
    |> cast(attrs, ~w(title authors description price quantity)a)
    |> validate_required(~w(title authors description quantity)a)
  end
end
