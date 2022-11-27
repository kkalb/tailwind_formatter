defmodule TailwindFormatter.Sorter do
  @moduledoc false

  alias TailwindFormatter.Defaults

  def sort([]), do: []

  @spec sort(list) :: list
  def sort(class_list) do
    IO.inspect(class_list, label: "class list")
    {base_classes, variants} = class_list |> sort_variant_chains() |> separate()
    base_sorted = sort_base_classes(base_classes)
    variant_sorted = sort_variant_classes(variants)

    a = base_sorted ++ variant_sorted
    IO.inspect(a, label: "ret")
    a
  end

  @spec sort_base_classes(list) :: list
  defp sort_base_classes(base_classes) do
    Enum.map(base_classes, fn class ->
      sort_number = Map.get(Defaults.class_order(), class, -1)
      {sort_number, class}
    end)
    |> Enum.sort(&(elem(&1, 0) <= elem(&2, 0)))
    |> Enum.map(&elem(&1, 1))
    |> List.flatten()
  end

  @doc """
  Seperates class strings with and without a colon.
  Also, class order gets inverted, atm I do not know if this is needed.

  ## Input
    ["text-sm", "potato", "sm:lowercase", "uppercase"]

  ## Output
    {["uppercase", "potato", "text-sm"], ["sm:lowercase"]}
  """
  @spec separate(list) :: {list, list}
  defp separate(class_list) do
    Enum.split_with(class_list, &(not variant?(&1)))
  end

  @spec variant?(binary()) :: boolean()
  defp variant?(class), do: String.contains?(class, ":")

  @spec sort_variant_classes(list) :: list
  defp sort_variant_classes(variants) do
    variants
    |> group_by_first_variant()
    |> sort_variant_groups()
    |> sort_classes_per_variant()
    |> grouped_variants_to_list()
  end

  @spec sort_variant_chains(list) :: list
  def sort_variant_chains(variants) do
    variants
    |> Enum.map(&String.split(&1, ":"))
    |> Enum.map(&sort_inverse_variant_order/1)
    |> Enum.map(&Enum.join(&1, ":"))
  end

  @spec group_by_first_variant(list) :: map
  defp group_by_first_variant(variants) do
    variants
    |> Enum.map(&String.split(&1, ":", parts: 2))
    |> Enum.group_by(&List.first/1, &List.last/1)
  end

  @spec sort_inverse_variant_order(any) :: list
  defp sort_inverse_variant_order(variants) do
    variants
    |> Enum.map(&{Map.get(Defaults.variant_order(), &1, -1), &1})
    |> Enum.sort(&(elem(&1, 0) >= elem(&2, 0)))
    |> Enum.map(&elem(&1, 1))
  end

  @spec sort_variant_groups(map()) :: list
  defp sort_variant_groups(variant_groups) do
    variant_groups
    |> Enum.map(&{Map.get(Defaults.variant_order(), elem(&1, 0), -1), &1})
    |> Enum.sort(&(elem(&1, 0) <= elem(&2, 0)))
    |> Enum.map(&elem(&1, 1))
  end

  @spec sort_classes_per_variant(list) :: list
  defp sort_classes_per_variant(grouped_variants) do
    Enum.map(grouped_variants, &{elem(&1, 0), sort(elem(&1, 1))})
  end

  @doc """
  Seperates class strings with and without a colon.
  Also, class order gets inverted, atm I do not know if this is needed.

  ## Example #1

  ### Input
     [{"disabled", ["text-blue-500"]}]

  ### Output
     ["disabled:text-blue-500"]

  ## Example #2

  ### Input
    [
      {"odd", ["decoration-slate-50"]},
      {"sm",
      ["lowercase", "hover:bg-unknown-500", "hover:bg-gray-500",
        "disabled:text-lg", "disabled:text-2xl"]},
      {"lg", ["sm:dark:group-hover:disabled:text-blue-500"]}
    ]

  ### Output
    ["odd:decoration-slate-50", "sm:lowercase", "sm:hover:bg-unknown-500",
    "sm:hover:bg-gray-500", "sm:disabled:text-lg", "sm:disabled:text-2xl",
    "lg:sm:dark:group-hover:disabled:text-blue-500"]
  """
  @spec grouped_variants_to_list(list) :: list
  defp grouped_variants_to_list(grouped_variants) do
    for {variant, base_classes} <- grouped_variants do
      Enum.map(base_classes, &"#{variant}:#{&1}")
    end
    |> List.flatten()
  end
end
