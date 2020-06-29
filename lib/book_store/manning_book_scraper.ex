defmodule BookStore.ManningBookScraper do
  def get_all_manning_books do
    books_data =
      get_manning_catalog_page()
      |> get_book_links_from_page()
      |> Task.async_stream(
        fn book ->
          get_book_details(book)
        end,
        max_concurrency: 5,
        timeout: 10_000
      )
      |> Enum.reduce([], fn {:ok, book_details}, acc ->
        [book_details | acc]
      end)
      |> inspect(pretty: true, limit: :infinity)

    data_file_location()
    |> File.write(books_data)
  end

  def data_file_location, do: "./books_data.exs"

  defp get_manning_catalog_page do
    %HTTPoison.Response{body: body} = HTTPoison.get!("https://www.manning.com/catalog")

    body
  end

  defp get_book_links_from_page(page_source) do
    page_source
    |> Floki.parse_document!()
    |> Floki.find("a.catalog-link")
    |> Enum.map(fn a_tag ->
      %URI{
        path: Floki.attribute(a_tag, "href"),
        host: "www.manning.com",
        scheme: "https"
      }
      |> URI.to_string()
    end)
  end

  defp get_book_details(book_url) do
    %HTTPoison.Response{body: body} = HTTPoison.get!(book_url)

    parsed_page = Floki.parse_document!(body)

    %{
      title: get_title_from_book_page(parsed_page),
      authors: get_authors_from_book_page(parsed_page),
      description: get_description_from_book_page(parsed_page),
      price: get_price_from_book_page(parsed_page)
    }
  end

  defp get_title_from_book_page(parsed_page) do
    parsed_page
    |> Floki.find(".visible-sm .product-title")
    |> Floki.text(deep: false)
    |> String.trim()
  end

  defp get_authors_from_book_page(parsed_page) do
    parsed_page
    |> Floki.find(".visible-sm .product-authorship")
    |> Floki.text(deep: false)
    |> String.split([",", "and"])
    |> Enum.map(fn author ->
      String.trim(author)
    end)
    |> Enum.reject(fn
      "" -> true
      _ -> false
    end)
  end

  defp get_description_from_book_page(parsed_page) do
    primary_lookup =
      parsed_page
      |> Floki.find(".description-body > p")
      |> Floki.text(deep: false)
      |> String.trim()

    secondary_lookup =
      parsed_page
      |> Floki.find(".description-body")
      |> Floki.text(deep: false)
      |> String.trim()

    if primary_lookup == "", do: secondary_lookup, else: primary_lookup
  end

  defp get_price_from_book_page(parsed_page) do
    book_id =
      parsed_page
      |> Floki.find(".all-buy-bits-type-combo form[action=\"/cart/addToCart\"]")
      |> Floki.attribute("data-product-offering-id")

    parsed_page
    |> Floki.find("#price-#{book_id}")
    |> Floki.text(deep: false)
    |> String.trim()
    |> case do
      "" -> :not_for_sale
      value -> value
    end
  end
end
