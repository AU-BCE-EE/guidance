# readHOBO #
This is a function to read the data from the HOBO model MX2301A.

At the moment it works with the `.csv` files.




## Function arguments ##

The function has the following arguments.

```R
function(Folder, From=NULL, To=NULL, Device = NULL, latest = FALSE,cut = TRUE)
```

- `Folder`: A path to the directory with the `.csv` files. This also can be a top directory as the funciton is recursive.
- `From`: The function works with the time stamps of the `.csv` files. With the `From` argument you can define what time range you wanna have and it will thus read in only the files within your chosen time range. See `To`. If nothing is defined, the data will be read in and returned from the beginning.
- `To`: The same as 'From' but just for the end of the time period. If nothing is defined, it will read in and output the data until the end. It is also possible to only define one of `To` and `From`.
- `Device`: Define what devices should be read in. If left empty, all HOBO devices will be read in. The Device name are the last two digits of the serial number. Input is as a character.
- `latest`: If TRUE, it will only read in the latest file of the selected Device. If no changes are done to the device, it should contain all the data. Doublcates are removed automatically. The argument `latest` has higher priority than `From` and `To`. It is possible to use those argument in combination to select a time range within the last available file.
- `cut`: Removes the colums 'Connected' and 'End' and whatever exists that are not measurement values as in my opinion they do not contain any relevant data.

## Notes ##
- If you wanna have such a function for your HOBO sensor (different model type), please send me some example files of your sensor and I might be able to include it in the function.
- In the far future I might implement that the function can also read .hobo or .xlsx

#### by Marcel