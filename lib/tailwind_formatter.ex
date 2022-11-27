defmodule TailwindFormatter do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias TailwindFormatter.Defaults
  alias TailwindFormatter.Sorter

  if Version.match?(System.version(), ">= 1.13.0") do
    @behaviour Mix.Tasks.Format
  end

  def features(_opts) do
    [sigils: [:H], extensions: [".heex"]]
  end

  def format(contents, _opts) do
    Regex.replace(Defaults.class_regex(), contents, fn original_str ->
      inline_elixir_functions =
        Regex.scan(Defaults.func_regex(), original_str) |> List.flatten() |> Enum.join(" ")

      classes_only = Regex.replace(Defaults.func_regex(), original_str, "")
      [class_attr, class_val] = String.split(classes_only, ~r/[=:]/, parts: 2)
      needs_curlies = String.match?(class_val, ~r/{/)

      trimmed_classes =
        class_val
        |> String.trim()
        |> String.trim("{")
        |> String.trim("}")
        |> String.trim("\"")
        |> String.trim()

      invalid_regex = Regex.match?(Defaults.invalid_input_regex(), trimmed_classes)

      input_map = %{
        original_str: original_str,
        trimmed_classes: trimmed_classes,
        inline_elixir_functions: inline_elixir_functions,
        needs_curlies: needs_curlies,
        class_attr: class_attr,
        invalid_regex: invalid_regex
      }

      build_sorted_css_string(input_map)
    end)
  end

  defp build_sorted_css_string(%{trimmed_classes: "", original_str: str}), do: str
  defp build_sorted_css_string(%{invalid_regex: true, original_str: str}), do: str

  defp build_sorted_css_string(%{
         original_str: original_str,
         trimmed_classes: trimmed_classes,
         inline_elixir_functions: inline_elixir_functions,
         needs_curlies: needs_curlies,
         class_attr: class_attr
       }) do
    sorted_list = trimmed_classes |> String.split() |> Sorter.sort()

    sorted_list = Enum.join([inline_elixir_functions | sorted_list], " ") |> String.trim()
    wrapped_classes = wrap_classes(sorted_list, needs_curlies)

    build_resulting_classes(original_str, class_attr, wrapped_classes)
  end

  defp build_resulting_classes(original_str, class_attr, wrapped_classes) do
    if String.contains?(original_str, "class:") do
      "#{class_attr}: #{wrapped_classes}"
    else
      "#{class_attr}=#{wrapped_classes}"
    end
  end

  @spec wrap_classes(binary, boolean()) :: binary
  defp wrap_classes(class_list, true), do: "{\"" <> class_list <> "\"}"
  defp wrap_classes(class_list, false), do: "\"" <> class_list <> "\""
end
