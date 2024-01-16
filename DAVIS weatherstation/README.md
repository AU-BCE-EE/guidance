# readWS #
This is a function that can read in exported data from DAVIS weatherstations. So far, the model Vantage VUE and Vantage Vue Pro 2+ or whatever its name is, work.

A detailed explanation of the arguments will follow...

## Function arguments ##

```R
function(Folder, From = NULL, To = NULL,ibts=FALSE)
```

- `Folder`: A file path to the file directory. This can also be a top directory.
- `From / To`: Define the time range of your data. Note, that still all data will be loaded and just the output will be reduced.
- `ibts`: Makes and `ibts` object of your data. This requires the `ibts` package. More information about the package can be found under https://github.com/ChHaeni/ibts


