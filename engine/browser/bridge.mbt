///|
/// Run the same bounded JSON contract used by the terminal application.
#export_name("coordinate")
pub fn coordinate(source : String) -> String {
  @exchange.process(source)
}
