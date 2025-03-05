# Data treatment files

This folder is made for people using the PTR-MS for H2S measurements on AU. 
It makes data treatment easier, by using the raw excel file obtained from the PTR-MS directly, and exporting the time and concentration as a csv file.

# How to use the scripts 
To use the script, start by putting all your raw data (excel files) in the "Raw_data" folder. Also put your calibration file in that folder. 

## Calibration
A calibration file should be made by measuring a known concentration at a variety of water content / air humidity. This can eg. be done in a Tedlar 
bag that is injectred with water. 

Then, go to Calibration_func, and adjust the known concentration to the one you measured at, adjust the start and stop cycles (rows in the excelfile). 
Also adjust the file name to whatever you called your calibration file. 
If you are in eg. Spyder, a graph with your calibration data and the maintained calibration curve will be shown. It is a good idea to check that this
looks reasonable.

## Getting your data
After the calibration, go to "DT_func" and change the filename to your first file. Run the file. Change the file name to the next file. Repeat for all 
your files. The csv files should turn up in the "Processed_data" folder with the same names that they originally had. 

## Smaller detalis
Places labelled #CHANGE ME is places that can be used for troubleshooting, eg.:

Change the variables "columnnameXX" to the names of your masses and channels of interest. The name must match the name of the column in the excel file 
precisely. The channel numbers and m/z values will most likely vary denpending on your experiment but be identical for all files in a given project. 

If you have a ready-made log curve calibration, simply define a and b in the bottomn of "Calibration_func". (where y=a*log(x)+b)

# Creator and contact
This is still not tested by others than me, Anne Nørgaard Mortensen. Email: anm@bce.au.dk
