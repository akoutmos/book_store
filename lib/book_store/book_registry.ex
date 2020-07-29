defmodule BookStore.BookRegistry do
  def child_spec do
    Registry.child_spec(
      keys: :unique,
      name: __MODULE__,
      partitions: System.schedulers_online()
    )
  end

  def lookup_book(book_id) do
    case Registry.lookup(__MODULE__, book_id) do
      [{book_pid, _}] ->
        {:ok, book_pid}

      [] ->
        {:error, :not_found}
    end
  end
end
