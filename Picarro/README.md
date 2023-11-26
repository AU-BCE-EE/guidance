# readCRDS #
A function to read in data from different type of PICARROS in R.
The `readCRDS` function will provide you a nice `data.table` of your Picarro data (of which you can make again a data.fram with `as.data.frame` if necessary). 
The function is able to read in data from different Picarros at the same time. It will add a column with the name of the Picarro, in case the file name was not altered. A detailed explanation of all arguments is given below.

## packages ##
For the function the packages `data.table` and `lubridate` are necessary and `ibts` is optional. In case you do not have them installed and source the script, it will detect it and asks you if you wanna install them (automatically).

## source function ##
Once the repository is public, the easiest way to source this script is with the aid of the package devtools:
```R
devtools::source_url('https://raw.githubusercontent.com/AU-BCE-EE/guidance/main/Picarro/PicarroFunction.R')
```
At the moment however, the repository is set as private and thus you need to download the `PicarroFunction.R` file and source it on your computer locally:
```R
source('Path to your directory/PicarroFunction.R')
```
If you don't wanna download the script, you can click on the PicarroFunction, then press the `raw` button, copy the url and put your copied url instead of the url above and it should work.

## Arguments ##
The readCRDS function has the following arguments:
```R
> args(readCRDS)
function (Folder, From = NULL, To = NULL, tz = "ETC/GMT-1", rm = TRUE, 
    ibts = FALSE, mult = FALSE, Ali = FALSE, h5 = FALSE, subfolders = TRUE, 
    name = TRUE)
```
- Folder: A file.path to your directory with the Picarro data. This can also be a top directory with multiple subdirectories. It also does not matter if there are other files in the directory like `.xlsx`, `.ppt`, `.jpg` or whatever you can imagine. It will only read in files with the file format `.dat`.
- From: In case you don't wanna read in all data, you can select the start time. The function loads only the file that are witin your defined time period, which is much faster than reading in all data and do the selection afterwards. Different input formats are possible. In general, I recommend you using `'dd.mm.YY HH:MM:SS'` (of course you can also omit the time). In case `From` is not defined, it will just read in the earliest File it finds. The set time is read as the time zone provided in `tz`. More about the conversion can be found in the function `convert_date` (see further below).
- To: The same as for `From` but just the end time.
- tz: The output of the `readCRDS` function with have a column with the name `Date`. The `tz` argument defines in which timezone this column is. The time is calculated from the column `EPOCH_TIME`, which corresponds to the computer time of the Picarro. Be aware, that `Date` might be different than the column `TIME` of the Picarro, as this is set different at every Picarro. To avoid confusion, by default the column `TIME` is not shown. See `rm`. The `tz` argument affects also the time inputs of `From` and `To`. By default, the timezone is set to 'wintertime' resp. 'UTC+1'.
- rm: Defines if the original columns `DATE, TIME, FRAC_DAYS_SINCE_JAN1, FRAC_HRS_SINCE_JAN, JULIAN_DAYS, EPOCH_TIME` should be removed. By default, they are removed.
- ibts: In case you wanna have your data in the `ibts` format. More information about this: https://github.com/ChHaeni/ibts
- mult: The function is able to read in multiple type of Picarro files at the same time e.g., GHG, NH3, CH4, Isotope Picarro. If different Picarros are detected, it will ask you if you really wanna read them in. In such a case, the output will be a list with an entry for each Picarro. If the argument is set to `TRUE`, then there is no prompt.
- Ali: If you had the glourious idea to change to file names of the Picarro files, my function does not really work. In such a case you have to use the argument `Ali` and set it to `TRUE`. This is just a hot fix. It will still be able to read in multiple file types but the detection happens over the column names and not the name string of the file names. If you use multiple Picarros of the same type e.g., two Backpack Picarro, it will rowbind those files together, which is not the case in the original function. Also, with `Ali` it is not possible to select the time range as it will read in anyway all files and I thought you can do thus the selection on your own.
- name: Set it to FALSE if you don't wanna have a column with the Picarro name
- subfolders: Set it to FALSE if you don't wanna look for files in subdirectorys
- h5: If set to TRUE, it is able to read in .h5 (oldest Backpack Picarro). For this to work you need to install some packages: 
```R
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("rhdf5")
```
# Other functions #
In this script there are two other functions of which one is needed for `readCRDS`

### convert_date ###
`convert_date` can be used to make a time object in the `POSIXct` format out of a character string given in almost any format.

### shift_dt ###
`shift_dt` is used to correct the time offset of your device e.g. Picarro with your reference time. If the object has length > 1, a linear regression is applied


# Examples #
```R
PathData <- '~/repos/ProjectXYZ/Data'
dt <- readCRDS(file.path(PathData,'Picarro'),From='17.03.2023 10:12',mult=TRUE)
dt
```

# Feedback #
### things I might include ###
- That you can select a top directory with data from different Picarros and by argument say what type of Picarro data you would like to have. So far, it will just read in all the Picarro files in the directory. 
- That the function is able to differentiate between different Picarros of the same type, e.g., G2509_#3 and G2509_#5. For that, I need more example files.
- Improve the function if you had the 'glourious' idea to change your file name.
- Make it possible to read in .h5 and .dat files at the same time
- The FROM selection is not perfect yet as the time strings are in different timezones.

### Bug reporting ###
If you encounter any bugs, please either open an `issue` here or write me an <a href='mailto:mb@bce.au.dk'>email</a>

<h6> by Marcel