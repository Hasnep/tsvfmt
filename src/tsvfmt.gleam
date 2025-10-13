import align
import argv
import clip
import clip/arg
import clip/flag
import clip/help
import clip/opt
import gleam/io
import gleam/list
import gleave
import io_utils
import shrink

pub fn main() -> Nil {
  case clip.run(create_command(), argv.load().arguments) {
    Ok(Ok(config)) -> {
      case config.files {
        [] -> process_stdin_stdout(config.mode)
        ["-"] -> process_stdin_stdout(config.mode)
        _ -> process_files(config.mode, config.files)
      }
    }
    Ok(Error(e)) -> {
      io.println_error(e)
      gleave.exit(1)
    }
    Error(e) -> {
      io.println_error(e)
      gleave.exit(1)
    }
  }
}

type Config {
  Config(mode: Mode, files: List(String))
}

type Mode {
  Align
  Shrink
}

fn create_command() -> clip.Command(Result(Config, String)) {
  clip.command({
    use align_flag <- clip.parameter
    use shrink_flag <- clip.parameter
    use mode_result <- clip.parameter
    use files <- clip.parameter

    let mode_result = case align_flag, shrink_flag, mode_result {
      False, False, Error(_) -> Ok(Align)
      // Default mode
      True, False, Error(_) -> Ok(Align)
      False, True, Error(_) -> Ok(Shrink)
      True, True, _ -> Error("Cannot specify both --align and --shrink flags")
      // Mode was specified
      True, False, Ok("align") -> Ok(Align)
      False, True, Ok("shrink") -> Ok(Shrink)
      False, False, Ok("align") -> Ok(Align)
      False, False, Ok("shrink") -> Ok(Shrink)
      _, _, Ok(_) -> Error("Unknown mode specified. Use 'align' or 'shrink'")
    }
    case mode_result {
      Ok(mode) -> Ok(Config(mode, files))
      Error(e) -> Error(e)
    }
  })
  |> clip.flag(
    flag.new("align")
    |> flag.short("a")
    |> flag.help("Set mode to align (default)"),
  )
  |> clip.flag(
    flag.new("shrink") |> flag.short("s") |> flag.help("Set mode to shrink"),
  )
  |> clip.opt(
    opt.new("mode")
    |> opt.short("m")
    |> opt.help("Set mode to align or shrink")
    |> opt.optional()
    |> opt.default(Ok("align")),
  )
  |> clip.arg_many(
    arg.new("files")
    |> arg.help("Files to process (if none provided, reads from stdin)"),
  )
  |> clip.help(help.simple("tsvfmt", "TSV formatter"))
}

fn process_stdin_stdout(mode: Mode) -> Nil {
  let content = io_utils.read_stdin()
  let result = case mode {
    Align -> align.align_tsv(content)
    Shrink -> shrink.shrink_tsv(content)
  }
  io.println(result)
}

fn process_file(mode: Mode, filename: String) -> Nil {
  case io_utils.read_file(filename) {
    Ok(content) -> {
      let result = case mode {
        Align -> align.align_tsv(content)
        Shrink -> shrink.shrink_tsv(content)
      }
      case io_utils.write_file(filename, result) {
        Ok(_) -> Nil
        Error(e) -> {
          io.println_error(e)
          gleave.exit(1)
        }
      }
    }
    Error(e) -> {
      io.println_error(e)
      gleave.exit(1)
    }
  }
}

fn process_files(mode: Mode, files: List(String)) -> Nil {
  list.each(files, fn(file) { process_file(mode, file) })
}
