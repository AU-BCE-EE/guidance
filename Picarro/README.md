A function to read in Picarro data by Marcel

a more extensive readme will follow

# read in Picarro data #
This is a subdirectory with a function to read in Picarro data in R. The `readCRDS` will provide you a nice `data.table` of your Picarro data. In theory, it should work for all type of Picarro data, i.e., Greenhouse gas, Backpack, Isotope and Ammonia Picarro.
I could not test it on all the files we have in our group, but in theory it should be able to detect the type of Picarro you have. It only works, if you did __NOT__ change the file name of the Picarro files.


The easiest way to source this script is with the aid of the package devtools would be like this.
```R
devtools::source_url('https://raw.githubusercontent.com/AU-BCE-EE/guidance/main/Picarro/PicarroFunction.R')
```
however, the repo is still set as private so it does not work. To solve it, you can click on the script, then press the raw button, copy the url and but your copied url instead of the url above and it should work.

# how to #
An explanation of the different arguments will follow. But basically read in the top folder of your Picarro data. Or looka at the code of the function. The function is able to detect files from different Picarro types. If multiple Picarro types are detected, it will ask you if you wanna read them in, and if confirmend, it will give you a list with a data.table entry for each Picarro type.

# what other functions are part of this #
`convert_date`
This function is needed in the `readCRDS` function. But it also can be used to convert a time given as character in almost any format to a POSIXct.

`shift_dt`
Correct the time offset of your Picarro data (or any other data that has a time column) with the help of a variable having the Device time and the Reference time. If the object has length > 1, a linear regression is applied

# things I wanna include #
- That you can select a top folder with data from different Picarros and by argument say what type of Picarro data you would like to have. So far, it will just read in all the Picarro files in the directory. 
- That the function is able to differentiate between different Picarros of the same type, e.g., G2509_#3 and G2509_#5. For that, I need more example files. However, this will most likely not work for the backpack Picarro files, as it seem that they do not have the serial nummer included in the file name (just NOMAD)

# Bug reporting #
If you encounter any bugs, please either open an `issue` here or write me an <a href='mailto:mb@bce.au.dk'>email</a>