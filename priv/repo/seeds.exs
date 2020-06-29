alias BookStore.Books.Book
alias BookStore.Repo

{book_data, _} =
  BookStore.ManningBookScraper.data_file_location()
  |> Code.eval_file()

book_data
|> Enum.map(fn
  %{price: :not_for_sale} = book ->
    book
    |> Map.put(:price, "N/A")
    |> Map.put(:quantity, 0)

  book ->
    book
    |> Map.put(:quantity, 5_000)
end)
|> Enum.each(fn book ->
  %Book{}
  |> Book.changeset(book)
  |> Repo.insert()
end)
