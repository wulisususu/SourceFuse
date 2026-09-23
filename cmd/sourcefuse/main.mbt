///|
fn usage() -> String {
  "Usage: sourcefuse <record.json>"
}

///|
/// Native reference adapter for the stable sourcefuse.record.v1 wire format.
///
/// The executable intentionally contains no reconciliation policy logic. It
/// only reads one JSON file, delegates to @wire, and writes the report JSON.
fn main {
  let argv = @env.args()

  if argv.length() == 2 && (argv[1] == "--help" || argv[1] == "-h") {
    println(usage())
    return
  }

  if argv.length() != 2 {
    eprintln(usage())
    @sys.exit(2)
    return
  }

  let path = argv[1]
  try {
    let text = @fs.read_file_to_string(path)
    match @wire.reconcile_record_json(text, pretty=true) {
      Ok(report_json) => println(report_json)
      Err(error) => {
        eprintln("sourcefuse: \{error.path}: \{error.message}")
        @sys.exit(1)
      }
    }
  } catch {
    _ => {
      eprintln("sourcefuse: cannot read input file: \{path}")
      @sys.exit(2)
    }
  }
}
