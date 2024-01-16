# HOBO sensor #
This is a function to read the data from the HOBO model MX2301A.

At the moment it works with the `.csv` files. The HOBO file type might follow later.

If you wanna have such a function for your HOBO sensor (different model type), please send me some example files of your sensor and I might be able to include it in the function.

- A (detailed) explanation of the different possible input arguments will follow later

## Function arguments ##

The function has the following arguments.

```R
function(Folder, From=NULL, To=NULL, Device = NULL, all = FALSE,cut = TRUE, ibts=FALSE)
```

- `Folder`: A path to the directory with the `.csv` files. This also can be a top directory as the funciton is recursive.
- `From`: The function will read in all files so the time selection will happen afterwards. With the `From` argument you can define what time range you wanna have in the output. If nothing is defined, the data will be returned from the beginning.
- `To`: The same as 'From' but just for the end of the time period.
- `Device`: Define what devices should be read in. If left empty, all HOBO devices will be read in.
- `all`: You can either read in the most recent file or all the previous files from the same device. By default only the most recent file, that if no changes to the sensor were done, should contain all the data.
- `cut`: Removes the colums 'Connected' and 'End' as in my opinion they do not contain any relevant data.
- `ibts`: Makes an `ibts` - interval based time series - object out of it. For this an additional package is needed. More information about the package can be found on https://github.com/ChHaeni/ibts