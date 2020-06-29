defmodule BookStore.Repo.Migrations.Books do
  use Ecto.Migration

  def change do
    create table(:books, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :authors, {:array, :string}
      add :description, :text
      add :price, :string
      add :quantity, :integer

      timestamps()
    end
  end
end
