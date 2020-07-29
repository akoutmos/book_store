defmodule BookStore.Books.BookProcess do
  use GenServer, restart: :transient

  require Logger

  alias BookStore.Repo
  alias BookStore.Books.Book
  alias Ecto.Changeset

  def start_link(%Book{} = book) do
    GenServer.start_link(__MODULE__, book,
      name: {:via, Registry, {BookStore.BookRegistry, book.id}}
    )
  end

  @impl true
  def init(%Book{} = state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:read, _from, %Book{} = state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:update, attrs}, _from, %Book{} = state) do
    state
    |> update_book(attrs)
    |> case do
      {:ok, %Book{} = updated_book} ->
        {:reply, updated_book, updated_book, {:continue, :persist_book_changes}}

      error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call(:order_copy, _from, %Book{quantity: 0} = state) do
    {:reply, :no_copies_available, state}
  end

  @impl true
  def handle_call(:order_copy, _from, %Book{quantity: quantity} = state) do
    state
    |> update_book(%{quantity: quantity - 1})
    |> case do
      {%Book{} = updated_book, changeset} ->
        {:reply, :ok, updated_book, {:continue, {:persist_book_changes, changeset}}}

      error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_continue({:persist_book_changes, changeset}, state) do
    Repo.update(changeset)

    {:noreply, state}
  end

  defp update_book(book, attrs) do
    book
    |> Book.changeset(attrs)
    |> case do
      %Changeset{valid?: true} = changeset ->
        updated_book = Changeset.apply_changes(changeset)
        {updated_book, changeset}

      error_changeset ->
        {:error, error_changeset}
    end
  end
end
