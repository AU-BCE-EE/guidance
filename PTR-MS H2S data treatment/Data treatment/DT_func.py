# -*- coding: utf-8 -*-
"""
Created on Fri Jan 19 11:00:48 2024

@author: Mortensen
"""

import numpy as np
import pandas as pd

#specify excel file and destination
filename = 'experiment_3.2.inlet long'#CHANGE ME

excel_file_path = '..//Raw_data/'+filename+'.xlsx'
csv_destination_path = '..//Processed_data/'+filename+'.csv'



#defining columns of interest 
sheetname1 = 'Time   Cycle'
columnname1 = 'Relative Time'
sheetname2 = 'Raw signal intensities'
columnname21 = 'm/z 37.00 ch4' #CHANGE ME
columnname22 = 'm/z 21.00 ch1'#CHANGE ME
sheetname3 = 'Concentration'
columnname3 = 'm/z 35.00 ch3' #CHANGE ME


#Loading the columns of interest
df1 = pd.read_excel(excel_file_path,sheet_name=sheetname1)
df2 = pd.read_excel(excel_file_path,sheet_name=sheetname2)
df3 = pd.read_excel(excel_file_path,sheet_name=sheetname3)

#defining the raw data
t_s = df1[columnname1] #time in s
mz37 = df2[columnname21] # m/z 37 signal (water cluster)
mz21 = df2[columnname22] # m/z 21 signal (H3O+)
mz35 = df3[columnname3]  #m/z 35 signal (H2S)

#modifying and correction the raw data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


from Calibration_func import a,b    #import calibration parameters from calibration script


time =  t_s / 3600 #time in h
humid = mz37 / mz21
correction = a * np.log10(humid) + b # correction factor, correcting for the amount of water

H2S = mz35 * correction * 10**-6 * 1.01325 / (0.00008314*298) * 34.08088 # concentration of H2S in g/m^3

results = pd.DataFrame ({'Concentration in g/m^3':H2S , 'Time in h':time})

results.to_csv(csv_destination_path, header = True, index=False)



    






