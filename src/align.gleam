import gleam/list
import gleam/string
import string_utils

pub fn align_tsv(tsv: String) -> String {
  let lines = string_utils.split_lines(tsv)
  let widths = string_utils.get_column_widths(tsv)

  lines
  |> list.map(fn(line) { align_line(line, widths) })
  |> string.join("\n")
  |> string.append("\n")
}

fn align_line(line: String, widths: List(Int)) -> String {
  let n_columns = list.length(widths)
  let aligned_columns = case line {
    "" -> {
      // For empty lines, create a line with spaces for each column
      case widths {
        [] -> []
        _ -> list.map(widths, string.repeat(" ", _))
      }
    }
    _ -> {
      string_utils.split_by_tab(line)
      |> fn(columns) {
        list.append(columns, list.repeat("", n_columns - list.length(columns)))
      }
      |> list.map2(widths, string_utils.pad_right)
    }
  }
  string.join(aligned_columns, "\t") |> string.trim_end()
}
