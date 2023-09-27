a more extensive readme will follow

# read in Picarro data #
This is a subdirectory with a function to read in Picarro data in R. The `readCRDS` will provide you a nice `data.table` of your Picarro data. In theory, it should work for all type of Picarro data, i.e., Greenhouse gas, Backpack, Isotope and Ammonia Picarro.
I could not test it on all the files we have here, but in theory it should be able to detect the type of Picarro you have. It only works, if you did __NOT__ change the file name of the Picarro files.

# how to #
An explanation of the different arguments will follow. But basically read in the top folder of your Picarro data. Or looka at the code of the function

# what other functions are part of this #
`convert_date`
This function is needed in the `readCRDS` function. But it also can be used to convert a time given as character in almost any format to a POSIXct.

`shift_dt`
Correct the time offset of your Picarro data (or any other data that has a time column) with the help of a variable having the Device time and the Reference time. If the object has length > 1, a linear regression is applied

# things I wanna include #
That you can select a top folder with data from different Picarros and by argument say what type of Picarro data you would like to have. If multiple types e.g. GHG and Backpack are selected (or those two file types are in any subdirectory of your selected folder), then it will make a list with a `data.table` for each Picarro type.
