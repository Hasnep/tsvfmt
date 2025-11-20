import gleam/int
import gleam/list
import gleam/result
import gleam/string
import string_width

pub fn pad_right(input: String, width: Int) -> String {
  string_width.align(input, width, align: string_width.Left, with: " ")
}

pub fn split_lines(input: String) -> List(String) {
  let lines = string.split(input, "\n")
  // Check whether the string has a final newline or not
  case list.reverse(lines) {
    // If the string had a final newline, remove the empty line
    ["", ..other_lines_reversed] -> list.reverse(other_lines_reversed)
    _ -> lines
  }
}

pub fn split_by_tab(input: String) -> List(String) {
  input |> string.split("\t") |> list.map(string.trim)
}

pub fn get_column_widths(tsv: String) -> List(Int) {
  let lines = split_lines(tsv)
  let all_line_widths = {
    use line <- list.map(lines)
    use column <- list.map(split_by_tab(line))
    string_width.dimensions(column).columns
  }
  let n_columns =
    all_line_widths
    |> list.map(list.length)
    |> list.max(int.compare)
    |> result.unwrap(0)
  list.fold(
    all_line_widths,
    list.repeat(0, n_columns),
    fn(running_widths, new_widths) {
      let new_widths =
        list.append(
          new_widths,
          list.repeat(0, n_columns - list.length(new_widths)),
        )
      list.map2(running_widths, new_widths, int.max)
    },
  )
}
