import gleam/result
import gleam/string
import gleam/yielder
import simplifile
import stdin

pub fn read_file(filename: String) -> Result(String, String) {
  simplifile.read(from: filename)
  |> result.map_error(fn(_) { "Error: Cannot read file: " <> filename })
}

pub fn write_file(filename: String, content: String) -> Result(Nil, String) {
  simplifile.write(content, to: filename)
  |> result.map_error(fn(_) { "Error: Cannot write file: " <> filename })
}

pub fn read_stdin() -> String {
  stdin.read_lines()
  |> yielder.to_list
  |> string.join("\n")
}
