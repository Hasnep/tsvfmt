import gleam/list
import gleam/string
import string_utils

pub fn shrink_tsv(tsv: String) -> String {
  let lines = {
    use line <- list.map(string_utils.split_lines(tsv))
    line
    |> string_utils.split_by_tab()
    |> list.map(string.trim)
    |> string.join("\t")
  }
  lines |> string.join("\n") |> string.append("\n")
}
