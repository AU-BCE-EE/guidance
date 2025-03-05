# -*- coding: utf-8 -*-
"""
Created on Fri Nov 17 10:19:13 2023

@author: bruger
"""

##data treatment of experiment 1.3 repetitions

#Import packages
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit

#Things that should be changed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#start time
startcyclecali=80 #Row of data where the calibration starts
endcyclecali=500 #Row of data where the calibration ends

#actual concentration in ppm
C_actual=40

#specify excel file (put the excel file in Raw_data)
filename = 'Calibration_23.01.24'

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


excel_file_path = '..//Raw_data/'+filename+'.xlsx'

#initial guesses for the calibration curve constants
params=[0.008,-0.006]


#defining columns of interest 
sheetname1 = 'Time   Cycle'
columnname1 = 'Relative Time'
sheetname2 = 'Raw signal intensities'
columnname21 = 'm/z 37.00 ch4'#CHANGE ME
columnname22 = 'm/z 21.00 ch1' #CHANGE ME
sheetname3 = 'Concentration'
columnname3 = 'm/z 35.00 ch3' #CHANGE ME


#Loading the columns of interest
df1 = pd.read_excel(excel_file_path,sheet_name=sheetname1)
df2 = pd.read_excel(excel_file_path,sheet_name=sheetname2)
df3 = pd.read_excel(excel_file_path,sheet_name=sheetname3)

#defining the raw data
mz37 = df2[columnname21] # m/z 37 signal (water cluster)
mz21 = df2[columnname22] # m/z 21 signal (H3O+)
mz35 = df3[columnname3]  #m/z 35 signal (H2S)

#modifying and correction the raw data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

humid = mz37 / mz21

correction = C_actual / (mz35)
x=humid[startcyclecali:endcyclecali].values 
y=correction[startcyclecali:endcyclecali].values    
    
        
def logcurve(h,a,b):#a and b is calibration parameters, h is humidity and c is correction factor
    n=h.size
    c=np.zeros(n)
    for i in range(n):
        c[i]=a*np.log(h[i])+b
    return c

#Making the regression
copt,ccov=curve_fit(logcurve,x,y,p0=params)

a=float(copt[0])
b=float(copt[1])



#plotting
yfit=logcurve(x,copt[0],copt[1])
plt.plot(x,y,'o')
plt.plot(x,yfit,label=('y= %1.5f'%copt[0]+'*ln(x) %1.5f'%copt[1]))
plt.xlabel('m/z 37 / m/z 21')
plt.ylabel('correction factor []')
plt.title('Calibration Curve') #CHANGE ME
plt.legend(loc='lower right')
plt.show
#plt.savefig('Calibration curve.png) #remove first hashtag to save picture