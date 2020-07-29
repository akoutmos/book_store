defmodule BookStore.BookDynamicSupervisor do
  use DynamicSupervisor

  alias BookStore.Books.{Book, BookProcess}

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_book_to_supervisor(%Book{} = book) do
    child_spec = %{
      id: BookProcess,
      start: {BookProcess, :start_link, [book]},
      restart: :transient
    }

    {:ok, _pid} = DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def all_book_pids do
    __MODULE__
    |> DynamicSupervisor.which_children()
    |> Enum.reduce([], fn {_, book_pid, _, _}, acc ->
      [book_pid | acc]
    end)
  end
end
