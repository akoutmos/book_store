defmodule BookStore.Books do
  import Ecto.Query, warn: false

  alias BookStore.Books.Book
  alias BookStore.{BookDynamicSupervisor, BookRegistry, Repo}

  # All the OTP/actor model based calls
  def actor_all do
    BookDynamicSupervisor.all_book_pids()
    |> Enum.reduce([], fn pid, acc ->
      case actor_read(pid) do
        %Book{} = book -> [book | acc]
        _ -> acc
      end
    end)
  end

  def actor_read(book_pid) when is_pid(book_pid) do
    book_pid
    |> GenServer.call(:read)
    |> case do
      %Book{} = book -> book
      _ -> {:error, :not_found}
    end
  end

  def actor_read(book_id) do
    book_id
    |> BookRegistry.lookup_book()
    |> case do
      {:ok, pid} -> GenServer.call(pid, :read)
      error -> error
    end
  end

  def actor_order(book_id) do
    book_id
    |> BookRegistry.lookup_book()
    |> case do
      {:ok, pid} -> GenServer.call(pid, :order_copy)
      error -> error
    end
  end

  # Database only calls
  def all do
    Repo.all(Book)
  end

  def read(id) do
    case Repo.get(Book, id) do
      %Book{} = book ->
        book

      _ ->
        {:error, :not_found}
    end
  end

  def order(book_id) do
    {_, result} =
      Repo.transaction(fn ->
        case Repo.get(Book, book_id) do
          %Book{quantity: 0} ->
            :no_copies_available

          %Book{quantity: quantity} = book ->
            update_book(book, %{quantity: quantity - 1})
            :ok

          thing ->
            IO.inspect(thing)
            {:error, :not_found}
        end
      end)

    result
  end

  def update_book(%Book{} = book, attrs) do
    book
    |> Book.changeset(attrs)
    |> Repo.update()
  end

  def create(attrs \\ %{}) do
    %Book{}
    |> Book.changeset(attrs)
    |> Repo.insert()
  end
end
