# Simplify loading .RData objects
assign.load <- function(filename) {
  load(filename)
  get(ls()[ls() != 'filename'])
}
