# readCRDS #
A function to read in data from different type of PICARROS in R. 
The `readCRDS` function will provide you a nice `data table` of your Picarro data (of which you can make again a `data frame` with `as.data.frame` if necessary). 

## Packages ##
For the function the packages `data.table` and `lubridate` are necessary and `ibts` is optional. In case you do not have them installed and source the script, it will detect it and should ask you via promit, if you wanna install them.

## Source the function ##
The easiest way to source this script/function is with the aid of the package devtools:
```R
devtools::source_url('https://raw.githubusercontent.com/AU-BCE-EE/guidance/main/Picarro/PicarroFunction.R')
```
Otherwise, download the `PicarroFunction.R` file and source it on your computer locally:
```R
source('Path to your directory/PicarroFunction.R')
```

## Arguments ##
The readCRDS function has the following arguments:
```R
> args(readCRDS)
function (Folder, From = NULL, To = NULL, tz = "ETC/GMT-1", rm = TRUE, 
    ibts = FALSE, mult = FALSE, Ali = FALSE, h5 = FALSE, subfolders = TRUE, 
    name = TRUE)
```
- `Folder`: A path to your directory with the Picarro files inside. This can also be a top directory with multiple subdirectories. It also does not matter if there are other file types in the directory like `.xlsx`, `.ppt`, `.jpg` or whatever you can imagine. It will only read in files with the file format `.dat` or `.h5`.
- `From`: In case you don't wanna read in all data, you can select the start time. The `readCRDS` function first reads in all file names and extracts the time stamp out of it and then loads only the files that are witin your defined time period, which is much faster than reading in all data and do the selection afterwards. Different input formats are possible. In general, I recommend you using `'dd.mm.YY HH:MM:SS'` (of course you can also omit the time). In case `From` is not defined, it will just read in the earliest file it finds. The set time in this argument is read as the time zone provided in `tz`. More about the conversion can be found in the function `convert_date` (see further below). As the original file names of the Picarros have a time stamp based on the 'Date' column, it can be in some cases, that you will be missing some hours of data. In this case, just extend your time period a bit and do then the exact date selection afterwards manually.
- `To`: The same as for `From` but just the end time.
- `tz`: The output of the `readCRDS` function with have a column with the name `st` (for start time). The `tz` argument what timezone this column has. The time is calculated from the column `EPOCH_TIME` (or `time` for .h5 files), which corresponds to the computer time of the Picarro. Be aware, that the time in the `st` column might be different from the column `TIME` of the Picarro, as this column is set different at every Picarro. To avoid confusion, by default the column `TIME` is not shown (see `rm` argument). The `tz` argument affects also the time inputs of `From` and `To`. By default, the timezone is set to Central European wintertime resp. 'UTC+1' or in R written as ETC/GMT-1.
- `rm`: Defines if the original columns `DATE, TIME, FRAC_DAYS_SINCE_JAN1, FRAC_HRS_SINCE_JAN, JULIAN_DAYS, EPOCH_TIME` should be removed. By default, they are removed.
- `ibts`: In case you wanna have your data in the `ibts` (interval based time series) format, then set it to TRUE. More information about this on: https://github.com/ChHaeni/ibts
- `mult`: The function is able to read in multiple type of Picarro files at the same time e.g., GHG, NH3, CH4, Isotope Picarro. If different Picarros are detected, it will ask you if you really wanna read them in. In such a case, the output will be a list with an entry for each Picarro. If the argument is set to `TRUE`, then there is no prompt.
- `Ali`: If you had the glourious idea to change to file names of the Picarro files, the function does not work as intended as no time stamp can be found and thus an error will be generated. In such a case, you have to use the argument `Ali` and set it to `TRUE`. It still will be able to read in multiple file types but the detection happens over the column names and not the name string of the file names. If you use multiple Picarros of the same type e.g., two GHG Picarro, it will rowbind those files together, which is not the case in the original function. Also, with `Ali=TURE` it is not possible to select the time range as it will read in anyway all files and I thought you can do thus the selection on your own afterwards.
- `h5`: If set to TRUE, the function reads in `.h5` files e.g., from the oldest Backpack Picarro. For this to work you need to install some packages: 
```R
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("rhdf5")
```
All other arguments should work as usual.
- `name`: Set it to FALSE if you don't wanna have a column with the Picarro name. In case your Picarro type is not detected, please provide me with an example file and the Picarro name, so I can add it to the function (see contact below).
- `subfolders`: Set it to FALSE if you don't wanna look for files in subdirectorys.

# Other functions #
In this script there are two other functions of which one is needed for `readCRDS`

### convert_date ###
`convert_date` can be used to make a time object in the `POSIXct` format out of a character string given in almost any format.

### shift_dt ###
`shift_dt` is used to correct the time offset of your device e.g. Picarro, with your reference time. If the object has length > 1, a linear regression is applied.


# Examples #
```R
PathData <- '~/repos/ProjectXYZ/Data'
dt <- readCRDS(file.path(PathData,'Picarro'),From='17.03.2023 10:12',mult=TRUE)
dt
```

# Feedback #
### things I might include ###
- That you can select a top directory with data from different Picarros and by argument say what type of Picarro data you would like to have. So far, it will just read in all the Picarro files in the directory. 
- Improve the function if you had the 'glourious' idea to change your file name.
- Make it possible to read in .h5 and .dat files at the same time
- The FROM selection is not perfect yet as the time strings are in different timezones.

### Bug reporting ###
If you encounter any bugs, please either open an `issue` here or write me an <a href='mailto:mb@bce.au.dk'>email</a>

<h6> by Marcel