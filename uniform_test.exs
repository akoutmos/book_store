:rand.seed(:exrop, {1, 2, 3})
:inets.start()
:ssl.start()

total_requests = 2_000
concurrency = 20

book_ids =
  BookStore.Books.Book
  |> BookStore.Repo.all()
  |> Enum.map(fn %BookStore.Books.Book{id: id} -> id end)

request_book_ids =
  1..ceil(total_requests / length(book_ids))
  |> Enum.reduce([], fn _, acc ->
    acc ++ book_ids
  end)
  |> Enum.shuffle()
  |> Enum.take(total_requests)
  |> Enum.zip(1..total_requests)

request_book_ids
|> Task.async_stream(
  fn {book_id, count} ->
    case rem(count, 3) do
      0 ->
        url = 'http://localhost:4000/api/books'
        method = :get
        :httpc.request(method, {url, []}, [], [])

      1 ->
        url = String.to_charlist("http://localhost:4000/api/books/#{book_id}")
        method = :get
        :httpc.request(method, {url, []}, [], [])

      2 ->
        url = String.to_charlist("http://localhost:4000/api/books/#{book_id}/order")
        method = :post
        :httpc.request(method, {url, [], 'application/json', '{}'}, [], [])
    end
  end,
  max_concurrency: concurrency
)
|> Stream.run()
