import align
import gleeunit
import shrink

pub fn main() -> Nil {
  gleeunit.main()
}

// Align

pub fn align_single_line_test() {
  assert align.align_tsv("a\tb\n") == "a\tb\n"
}

pub fn align_without_final_newline_test() {
  assert align.align_tsv("a\tb") == "a\tb\n"
}

pub fn align_single_cell_test() {
  assert align.align_tsv("hello\n") == "hello\n"
}

pub fn align_single_column_test() {
  assert align.align_tsv("hello\nworld!\n") == "hello\nworld!\n"
}

pub fn align_empty_test() {
  assert align.align_tsv("") == "\n"
}

pub fn align_single_newline_test() {
  assert align.align_tsv("\n") == "\n"
}

pub fn align_empty_lines_test() {
  assert align.align_tsv("a\tb\n\nc\td\n") == "a\tb\n\nc\td\n"
}

pub fn align_tsv_full_example_test() {
  assert align.align_tsv(
      "header1\theader2\theader3\nvalue1\tvalue2\tvalue3\nlongervalue\tshort\tveryverylongvalue",
    )
    == "header1    \theader2\theader3\nvalue1     \tvalue2 \tvalue3\nlongervalue\tshort  \tveryverylongvalue\n"
}

pub fn align_tsv_single_column_no_padding_test() {
  assert align.align_tsv("a\nb\nc") == "a\nb\nc\n"
}

pub fn align_irregular_column_counts_test() {
  assert align.align_tsv("a\tb\nc\td\te\n") == "a\tb\nc\td\te\n"
}

pub fn align_tsv_preserve_last_column_no_padding_test() {
  assert align.align_tsv("a\tbbbb") == "a\tbbbb\n"
}

pub fn align_with_chinese_characters_test() {
  assert align.align_tsv("hello\thello!\n你好\t你好！")
    == "hello\thello!\n你好 \t你好！\n"
}

// Shrink

pub fn shrink_single_line_test() {
  assert shrink.shrink_tsv("  a  \t  b  \n") == "a\tb\n"
}

pub fn shrink_without_final_newline_test() {
  assert shrink.shrink_tsv("  a  \t  b  ") == "a\tb\n"
}

pub fn shrink_multiline_test() {
  assert shrink.shrink_tsv(
      "  header1   \t     header2   \t  header3  \n  value1 \t   value2 \tvalue3\n longervalue\t  short \t  veryverylongvalue",
    )
    == "header1\theader2\theader3\nvalue1\tvalue2\tvalue3\nlongervalue\tshort\tveryverylongvalue\n"
}

pub fn shrink_no_trim_test() {
  assert shrink.shrink_tsv("a\tb\n") == "a\tb\n"
}

pub fn shrink_empty_test() {
  assert shrink.shrink_tsv("") == "\n"
}

pub fn shrink_single_column_test() {
  assert shrink.shrink_tsv("  hello  ") == "hello\n"
}

pub fn shrink_whitespace_only_test() {
  assert shrink.shrink_tsv("   \t   \t   \n    \t   \t \n") == "\t\t\n\t\t\n"
}
