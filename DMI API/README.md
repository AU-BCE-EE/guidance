# Access DMI via API #

This document provides instructions on how to use API access to DMI (Danish Meteorological Institute) using R. Examples are given for the [meteorological observations *(Observationsdata)*](#meteo) and the [climate data *(Klimadata)*](#climate).

## User Creation ##

Before you start downloading data from the API, you need to:
  1. Register as a user in DMI's [Developer Portal](https://dmiapi.govcloud.dk/#!/)
  2. Register an application in the Developer Portal and get your "API Key"
  3. Save the API key somewhere safe, because you need it every time you make a request for the API. Otherwise, you will not be authorized by the API. For more information, see the [User Creation page](https://confluence.govcloud.dk/display/FDAPI/User+Creation).
  4. You need to make different API keys for different applications, i.e., You can not use the same API key for observational/station data and climate data (grid data). Just make an additional one and make sure that you remember which is for what. 

To summarize, to consume data from the DMI via API, you need to register as an user, register an application, and save the API key securely.

## R packages ##

The following `R` libraries are required to make the requests:

  - `httr`: Needed to make requests
  - `jsonlite`: Needed to read files
  - `data.table`: Best package for data manipulation :). This is not really necessary, but I highly recommend it :).

  ```R
  install.packages(c('httr','jsonlite','data.table'))

  library(httr)
  library(jsonlite)
  library(data.table)
  ```

# Meteorological observational data {#meteo}

The meteorological observation (metObs) API service contains raw weather observation data, e.g. wind, temperature, and precipitation data, from DMI owned stations located in Denmark and Greenland. You can read more about meteorological observations and how they are attained under [data information](https://confluence.govcloud.dk/pages/viewpage.action?pageId=41716269).

If you want to download large quantities of historical meteorological observation data, DMI recommends that you use thier bulk download service. In this guide I do not yet cover the bulk request.

## Input list ##

There are different [queries](https://confluence.govcloud.dk/pages/viewpage.action?pageId=41717088) you can use to make your request. Here are the most important queries:
 - `API-key` - This is always necessary
 - `url` - This is always necessary. There are different url's for different base requests.
 - `stationId` - This is used if you wanna have data from only a certain station. The station ID can either be found with a basic request with the station url or on the [DMI station list](https://confluence.govcloud.dk/pages/viewpage.action?pageId=41717704)
 - `datetime` - With this you can defien the time range of the data. Different formats are possible. More information in the documentation linked above.
 - `parameterId` - Define which parameter you need. Below is a list (actually a vector) of all possible parameters.
 - `limit` - Define how many rows/entries you need. Default is 1,000. Max is 300,000.
 - `bbox` - This is useful if you wanna select stations in a certian area. The query is southwest corner and northeast corner i.e., `LON1,LAT1,LON2,LAT2`. Otherwiese, just look at the [map](https://www.dmi.dk/friedata/observationer/) with the station network. If you have a stationId defined, there is no need for `bbox`.

List of all available parameterIds:
```R
parameterId_vec <- c("temp_dry", "temp_dew", "temp_mean_past1h", "temp_max_past1h", "temp_min_past1h", "temp_max_past12h", "temp_min_past12h",
  "temp_grass", "temp_grass_max_past1h", "temp_grass_mean_past1h", "temp_grass_min_past1h", "temp_soil", "temp_soil_max_past1h",
  "temp_soil_mean_past1h", "temp_soil_min_past1h", "humidity", "humidity_past1h", "pressure", "pressure_at_sea", "wind_dir", "wind_dir_past1h",
  "wind_speed", "wind_speed_past1h", "wind_gust_always_past1h", "wind_max", "wind_min_past1h", "wind_min", "wind_max_per10min_past1h",
  "precip_past1h", "precip_past10min", "precip_past1min", "precip_past24h", "precip_dur_past10min", "precip_dur_past1h", "snow_depth_man",
  "snow_cover_man", "visibility", "visib_mean_last10min", "cloud_cover", "cloud_height", "weather", "radia_glob", "radia_glob_past1h",
  "sun_last10min_glob", "sun_last1h_glob", "leav_hum_dur_past10min", "leav_hum_dur_past1h")
```

### Some comments to the way I do it ###

For a better overview of your code, I suggest assigning the different queries to variables. Except from the urls, the queries will have the following structure in the request `'query_name=your_input'`. If you narrow down your request with multiple queries, they will be separated by `&`.

```R
API <- 'api-key=12345-6789-abcd-efgh-987654321' # this is just a random API key I made up.
url <- 'https://dmigw.govcloud.dk/v2/metObs/collections/observation/items?' # url for accessing observational data
url_stat <- 'https://dmigw.govcloud.dk/v2/metObs/collections/station/items?' # url for list of stations and see what parameters are (or rather should be) available at each station, etc
stationId <- paste0('stationId=', '06060')
datetime <- paste0('datetime=', '2023-04-01T00:00:00Z/2023-04-30T04:00:00Z')
parameterId <- paste0('parameterId=', 'wind_dir')
limit <- paste0('limit=', '10000')
bbox <- paste0('bbox=', '9.52,56.44,9.62,56.52')
```

## Request data ##

Make a base request
```R
GET(paste(url,API,sep='&'))
```
```HTML
Response [https://dmigw.govcloud.dk/v2/metObs/collections/observation/items?&api-key=12345-6789-abcd-efgh-987654321]
  Date: 2023-09-20 09:29
  Status: 200
  Content-Type: application/json
  Size: 273 kB
```  
You should get a status code `200`, indicating a successful request. If you get another code then there is something wrong. Check this [website](https://www.restapitutorial.com/httpstatuscodes.html) to figure out what your status code means.

Make a request with multiple queries and assign it to a new variable
```R
v1 <- GET(paste(url,stationId,datetime,limit,API,sep='&'))
```
Use the `fromJSON` function to make the response readable:
```R
WS_raw <- fromJSON(rawToChar(v1$content))
```
Your output should look more or less like this. Note, that for the purpose of a better overview, I changed a bit the display of `$features`. 
```HTML
$type
[1] "FeatureCollection"

$features
geometry.coordinates  geometry.type                                    id     type           properties.created   properties.observed  properties.parameterId properties.stationId  properties.value
1      9.1138,56.2935         Point  01a643bc-f804-3287-7484-dd1bb6eaf4ac  Feature  2023-07-07T17:28:15.942898Z  2023-04-30T04:00:00Z         humidity_past1h                06060             81.0
2      9.1138,56.2935         Point  0ad93de0-048b-b120-f267-53dea445793b  Feature  2023-07-07T20:18:35.894407Z  2023-04-30T04:00:00Z       precip_dur_past1h                06060              0.0
3      9.1138,56.2935         Point  0c95a2b7-026f-61a0-31fb-7a701579d949  Feature  2023-07-08T10:02:01.408694Z  2023-04-30T04:00:00Z  temp_grass_mean_past1h                06060              0.8
4      9.1138,56.2935         Point  130a3495-e842-46a6-3af2-14d00e0343bf  Feature  2023-07-08T07:50:47.541576Z  2023-04-30T04:00:00Z                wind_dir                06060            268.0
5      9.1138,56.2935         Point  1a6a8051-18bb-ed8a-fb56-454008ab1551  Feature  2023-07-08T10:02:01.408648Z  2023-04-30T04:00:00Z   temp_grass_max_past1h                06060              1.7
---                                                                                                                                                                                              
9996   9.1138,56.2935         Point  d9b790c1-3443-8175-d29d-8f80ffb1a9bf  Feature  2023-07-08T12:21:12.782107Z  2023-04-26T08:30:00Z              visibility                06060          55000.0
9997   9.1138,56.2935         Point  e2a2f26a-da4a-9605-c5f5-5f1042c1e4e9  Feature  2023-07-08T07:50:30.944071Z  2023-04-26T08:30:00Z              temp_grass                06060              6.2
9998   9.1138,56.2935         Point  e2f16a35-17a4-960e-76e8-863cf40b2164  Feature  2023-07-07T17:28:01.659404Z  2023-04-26T08:30:00Z         pressure_at_sea                06060           1011.2
9999   9.1138,56.2935         Point  e6d1001d-59fb-f7b7-7e83-5fa6e753f0a6  Feature  2023-07-08T07:50:30.944120Z  2023-04-26T08:30:00Z                wind_dir                06060            290.0
10000  9.1138,56.2935         Point  e983f212-ded5-aa92-9c9b-3c2d80a3862f  Feature  2023-07-08T07:50:30.944206Z  2023-04-26T08:30:00Z              wind_speed                06060              8.8

$timeStamp
[1] "2023-09-20T09:33:05Z"

$numberReturned
[1] 10000

$links
                                                                                                                                                                                                  href   rel                  type                title
1 https://dmigw.govcloud.dk/v2/metObs/collections/observation/items?stationId=06060&datetime=2023-04-01T00:00:00Z/2023-04-30T04:00:00Z&limit=10000&api-key=12345-6789-abcd-efgh-987654321               self  application/geo+json        This document
2 https://dmigw.govcloud.dk/v2/metObs/collections/observation/items?stationId=06060&datetime=2023-04-01T00:00:00Z/2023-04-30T04:00:00Z&limit=10000&api-key=12345-6789-abcd-efgh-987654321&offset=10000  next  application/geo+json  Next set of results

```

Extract the relevant data (fourth list within the second list) and convert it to a data.table for better readability (In case you don't wanna use data.table, just don't use the fuction `as.data.table`)
```R
WS_data <- as.data.table(WS_raw[[2]][[4]])
```
Display your data
```R
WS_data
```
```HTML
                           created             observed            parameterId stationId   value
    1: 2023-07-07T17:28:15.942898Z 2023-04-30T04:00:00Z        humidity_past1h     06060    81.0
    2: 2023-07-07T20:18:35.894407Z 2023-04-30T04:00:00Z      precip_dur_past1h     06060     0.0
    3: 2023-07-08T10:02:01.408694Z 2023-04-30T04:00:00Z temp_grass_mean_past1h     06060     0.8
    4: 2023-07-08T07:50:47.541576Z 2023-04-30T04:00:00Z               wind_dir     06060   268.0
    5: 2023-07-08T10:02:01.408648Z 2023-04-30T04:00:00Z  temp_grass_max_past1h     06060     1.7
   ---                                                                                          
 9996: 2023-07-08T12:21:12.782107Z 2023-04-26T08:30:00Z             visibility     06060 55000.0
 9997: 2023-07-08T07:50:30.944071Z 2023-04-26T08:30:00Z             temp_grass     06060     6.2
 9998: 2023-07-07T17:28:01.659404Z 2023-04-26T08:30:00Z        pressure_at_sea     06060  1011.2
 9999: 2023-07-08T07:50:30.944120Z 2023-04-26T08:30:00Z               wind_dir     06060   290.0
10000: 2023-07-08T07:50:30.944206Z 2023-04-26T08:30:00Z             wind_speed     06060     8.8
```

## Multiple data requests ##

It is not possible to make multiple station or parameter etc requests at the same time (error 400), but you can loop the data to solve this. An other option would be using the bulk request on DMI (a guide to that might follow later).

### Example for multiple parameter IDs ###
Define the queries that have multiple entries:
```R
req_parameter <- c('temp_dry', 'temp_dew', 'wind_dir')
```
Create a list:
```R
par_list <- as.list(req_parameter)
```
Loop through the parameter IDs and make the requests:
```R
for(i in seq_along(req_parameter)){
    parameterId <- paste0('parameterId=', req_parameter[i])
    v2 <- GET(paste(url,stationId,datetime,limit,parameterId,API,sep='&'))
    WS_raw <- fromJSON(rawToChar(v2$content))
    par_list[[i]] <- as.data.table(WS_raw[[2]][[4]])
 }
```
Combine the results into a single data.table:
```R
WS_data <- rbindlist(par_list)
```

### Example for multiple stationId and multiple parameterId ###

#### Slow `for` loop(s) ####

Define the queries that have multiple entries:
```R
req_parameter <- c('temp_dry', 'temp_dew', 'wind_dir')
req_stations <- c('06060','06019')
```
Create lists and loop through the station and parameter IDs and make the request:
```R
stat_list <- as.list(req_stations)
for(j in seq_along(req_stations)){
  par_list <- as.list(req_parameter)
  stationId <- paste0('stationId=', req_stations[j])
  for(i in seq_along(req_parameter)){
    parameterId <- paste0('parameterId=', req_parameter[i])
    v3 <- GET(paste(url,stationId,datetime,limit,parameterId,API,sep='&'))
    WS_raw <- fromJSON(rawToChar(v3$content))
    par_list[[i]] <- as.data.table(WS_raw[[2]][[4]])
  }
  stat_list[[j]] <- rbindlist(par_list)  
}
```
Combine the results into a single `data.table`:
```R
WS_data <- rbindlist(stat_list)
```

The same can be done for multiple time periods by adding a third loop, and so on.
However, instead of using `for` loops, it is recommended to use `lapply` for better performance. For this simple example `lapply` was average about 15% faster but the `for` loop took sometimes 5 times as long and those results were excluded.

#### lapply ####

```R
req_parameter <- c('temp_dry', 'temp_dew', 'wind_dir')
par_list <- lapply(req_parameter, function(x){
  parameterId <- paste0('parameterId=', x)
  v4 <- GET(paste(url,stationId,datetime,limit,parameterId,API,sep='&'))
  WS_raw <- fromJSON(rawToChar(v4$content))
  out <- as.data.table(WS_raw[[2]][[4]])
  out
})
WS_data <- rbindlist(par_list)
```

The same can be done for multiple queries:
```R
req_parameter <- c('temp_dry', 'temp_dew', 'wind_dir')
req_stations <- c('06060','06019')

stat_list <- lapply(req_stations, function(x) {
  par_list <- lapply(req_parameter, function(y) {
    stationId <- paste0('stationId=', x)
    parameterId <- paste0('parameterId=', y)
    v5 <- GET(paste(url,stationId,datetime,limit,parameterId,API,sep='&'))
    WS_raw <- fromJSON(rawToChar(v5$content))
    as.data.table(WS_raw[[2]][[4]])
  })
  rbindlist(par_list)
})
WS_data <- rbindlist(stat_list)
```
It would even be faster if instead of `paste0` the parameters are directly used in the `GET` function, but I am too lazy for that as it does not really fit with how I did it above. Also if multiple queries with multiple requests are used, you could first write a function that will do it but I was also too lazy for that. I might do it on a later time.

---------------------------------------------------------------------------------------------------------------------------------------------------------------

# Climate data {#climate}

The climate data (climateData) API service contains quality controlled meteorological observation data from Denmark (DNK) and Greenland (GRL). You can read more about climate data and how they are attained under [data information](https://confluence.govcloud.dk/pages/viewpage.action?pageId=41717434).

If you want to download large quantities of climate data, we recommend that you use DMI’s bulk download service. The service lets you download .zip files, each containing historical data for a month going back to 2011 for Denmark and 1958 for Greenland. You can also download all historical data by selecting the file all.zip.
In this quide, I do not yet cover bulk requests.

With the climate data, you can have interpolated meterological observation data from Denmark in 10 x 10 km resoulution, 20 x 20 km resolution, data for the Danish municipality or the country of Denmark.

## Input list ##

The [queries](https://confluence.govcloud.dk/pages/viewpage.action?pageId=41718244) are mostly the same as for the meteorological data. Just use a different API key. I thus list here only the ones that are different or important for the climate data:
 - `url` - Here are the different `url`s for accessing climate data.
    - Status of stations: `https://dmigw.govcloud.dk/v2/climateData/collections/station/items?`
    - Climate data for stations: `https://dmigw.govcloud.dk/v2/climateData/collections/stationValue/items?`
    - Climate data for municipalities: `https://dmigw.govcloud.dk/v2/climateData/collections/municipalityValue/items?`
    - Climate data for 10 x 10 km grid: `https://dmigw.govcloud.dk/v2/climateData/collections/10kmGridValue/items?`
    - Climate data for 20 x 20 km grid: `https://dmigw.govcloud.dk/v2/climateData/collections/20kmGridValue/items?`
    - Climate data on country level: `https://dmigw.govcloud.dk/v2/climateData/collections/country/items?`
 - `municipalityId` - Narrows the search to a municipality. There is a [list](https://danmarksadresser.dk/adressedata/kodelister/kommunekodeliste) with all municipality IDs.
 - `cellId` - Narrows the search to a specific cellId. There is a [website](https://dmidk.github.io/Climate-Data-Grid-Map/) where you can easily select your grid.
 - `timeResolution` - Narrows the search to a specific time resolution, i.e. `hour`,`day`,`month`,`year`.

The list of all available parameterIds is the same as long as you request station data. If you wanna have grid data, municipality or country values, then there are fewer parameters available as the temporal resolution is lower. See [Website DMI](https://confluence.govcloud.dk/pages/viewpage.action?pageId=41717444).

## Request data - Examples ##

### Temperature Data from Aarhus ###

We wanna have temperature data (hourly resolution) from the Aarhus municipality for the year 2022.

```R
## Define variables
API <- 'api-key=9816-54321-hgfe-dcba-123456789' # this is just a random API key I made up.
url <- 'https://dmigw.govcloud.dk/v2/climateData/collections/municipalityValue/items?' # url for accessing municipality data
municipalityId <- 'municipalityId=0751' # Aarhus, probably the best city in Denmark ;)
datetime <- 'datetime=2022-01-01T00:00:00Z/2022-12-31T23:59:59Z'
parameterId <- 'parameterId=mean_temp'
timeResolution <- 'timeResolution=hour'
limit <- 'limit=300000' # set the limit to max

## Make the request
v6 <- GET(paste(url,municipalityId,datetime,parameterId,timeResolution,limit,API,sep='&'))
## Use the `fromJSON` function to make the response readable
data_raw <- fromJSON(rawToChar(v6$content))
## Extract the relevant data
Aarhus_temp <- as.data.table(data_raw[[2]][[4]])
## Display your data
Aarhus_temp
```
```HTML
                    calculatedAt                          created                      from municipalityId municipalityName parameterId qcStatus timeResolution                        to value
   1: 2023-01-02T15:06:15.003000 2023-05-22T19:51:05.989658+00:00 2022-12-31T23:00:00+00:00           0751           Aarhus   mean_temp   manual           hour 2023-01-01T00:00:00+00:00   5.2
   2: 2023-01-01T17:52:24.510000 2023-05-22T19:50:53.393177+00:00 2022-12-31T22:00:00+00:00           0751           Aarhus   mean_temp   manual           hour 2022-12-31T23:00:00+00:00   5.1
   3: 2023-01-01T17:44:37.966000 2023-05-22T19:50:53.329679+00:00 2022-12-31T21:00:00+00:00           0751           Aarhus   mean_temp   manual           hour 2022-12-31T22:00:00+00:00   5.1
   4: 2023-01-01T17:37:03.144000 2023-05-22T19:50:53.146498+00:00 2022-12-31T20:00:00+00:00           0751           Aarhus   mean_temp   manual           hour 2022-12-31T21:00:00+00:00   5.0
   5: 2023-01-01T17:28:09.290000 2023-05-22T19:50:53.021998+00:00 2022-12-31T19:00:00+00:00           0751           Aarhus   mean_temp   manual           hour 2022-12-31T20:00:00+00:00   5.1
  ---                                                                                                                                                                                          
8756: 2022-01-04T08:53:02.634000 2023-05-22T19:05:41.409508+00:00 2022-01-01T04:00:00+00:00           0751           Aarhus   mean_temp   manual           hour 2022-01-01T05:00:00+00:00   7.0
8757: 2022-01-04T08:46:00.899000 2023-05-22T19:05:41.266899+00:00 2022-01-01T03:00:00+00:00           0751           Aarhus   mean_temp   manual           hour 2022-01-01T04:00:00+00:00   6.8
8758: 2022-01-04T08:37:33.954000 2023-05-22T19:05:41.129370+00:00 2022-01-01T02:00:00+00:00           0751           Aarhus   mean_temp   manual           hour 2022-01-01T03:00:00+00:00   6.7
8759: 2022-01-04T08:31:16.806000 2023-05-22T19:05:40.991742+00:00 2022-01-01T01:00:00+00:00           0751           Aarhus   mean_temp   manual           hour 2022-01-01T02:00:00+00:00   6.9
8760: 2022-01-04T08:25:02.518000 2023-05-22T19:05:40.856406+00:00 2022-01-01T00:00:00+00:00           0751           Aarhus   mean_temp   manual           hour 2022-01-01T01:00:00+00:00   6.7
```
Here are some example on how to manipulate the data further
```R
## convert the character time string to a date
Aarhus_temp[,st := as.POSIXct(gsub('\\+.*$', '', from), format='%Y-%m-%dT%H:%M:%S',tz='UTC')] # start time
Aarhus_temp[,et := as.POSIXct(gsub('\\+.*$', '', to), format='%Y-%m-%dT%H:%M:%S',tz='UTC')] # end time
## you could also use the lubridate package and ymd_hms function e.g.
# library(lubridate)
# Aarhus_temp[,st := ymd_hms(from)]

## order the data according to time
setkey(Aarhus_temp,st)
Temp <- Aarhus_temp[,.(st,et,Temp=value)]

##### Plot data:
library(ggplot2)

Temp[,{
  X <- rbind(.SD)
  X[,Week := week(st)]
  X[,Col := mean(Temp,na.rm=TRUE),by=Week]
  ggplot(X,aes(x=st,y=Temp,group=Week,fill=Col)) +
  geom_boxplot() +
  scale_fill_gradient(low='#030388',high='#F80505') +
  xlab(NULL) +
  ylab('Temperature [°C]') +
  theme_bw()
}]
```

### Wind direction and temperature data from a grid cell ##

We wanna have wind direction and temperature data in daily resolution over the previous 36 months (3 years) from the 10 x 10 km grid No. 622_57 (Aarhus)

```R
## Define variables
API <- 'api-key=9816-54321-hgfe-dcba-123456789' # this is just a random API key I made up.
url <- 'https://dmigw.govcloud.dk/v2/climateData/collections/10kmGridValue/items?' # url for accessing municipality data
cellId <- 'cellId=10km_622_57'
current_time <- format(now(tz='UTC') - years(2),format = "%Y-%m-%dT%H:%M:%SZ") # for having the last two years of data
datetime <- paste0('datetime=',current_time,'/..')
req_parameter <- c('mean_temp', 'mean_wind_dir')
timeResolution <- 'timeResolution=day'
limit <- 'limit=300000' # set the limit to max

## Make the request
par_list <- lapply(req_parameter, function(x){
  parameterId <- paste0('parameterId=', x)
  v7 <- GET(paste(url,cellId,datetime,parameterId,timeResolution,limit,API,sep='&'))
  data_raw <- fromJSON(rawToChar(v7$content))
  out <- as.data.table(data_raw[[2]][[4]])
  out
})
Aarhus_data <- rbindlist(par_list)
## Display your data
Aarhus_data
```
```HTML
                     calculatedAt      cellId                          created                             from   parameterId qcStatus timeResolution                        to value
   1: 2023-10-26T11:28:40.989000 10km_622_57 2023-10-26T12:02:28.291835+00:00 2023-10-26T00:00:00.001000+02:00     mean_temp     none            day 2023-10-27T00:00:00+02:00   7.2
   2: 2023-10-26T07:25:45.125000 10km_622_57 2023-10-26T12:02:21.535253+00:00 2023-10-25T00:00:00.001000+02:00     mean_temp   manual            day 2023-10-26T00:00:00+02:00   8.8
   3: 2023-10-25T07:26:41.680000 10km_622_57 2023-10-26T11:58:13.791206+00:00 2023-10-24T00:00:00.001000+02:00     mean_temp   manual            day 2023-10-25T00:00:00+02:00   8.9
   4: 2023-10-24T07:26:43.777000 10km_622_57 2023-10-25T10:30:50.762343+00:00 2023-10-23T00:00:00.001000+02:00     mean_temp   manual            day 2023-10-24T00:00:00+02:00   9.1
   5: 2023-10-23T07:26:47.910000 10km_622_57 2023-10-25T11:07:22.110020+00:00 2023-10-22T00:00:00.001000+02:00     mean_temp   manual            day 2023-10-23T00:00:00+02:00  10.4
  ---                                                                                                                                                                               
1456: 2021-11-01T07:31:03.146000 10km_622_57 2023-05-20T14:49:53.041709+00:00 2021-10-31T00:00:00.001000+02:00 mean_wind_dir   manual            day 2021-11-01T00:00:00+01:00 177.0
1457: 2021-10-31T07:32:41.737000 10km_622_57 2023-05-20T14:49:17.270974+00:00 2021-10-30T00:00:00.001000+02:00 mean_wind_dir   manual            day 2021-10-31T00:00:00+02:00 154.0
1458: 2021-10-30T07:29:16.440000 10km_622_57 2023-05-20T14:48:42.343544+00:00 2021-10-29T00:00:00.001000+02:00 mean_wind_dir   manual            day 2021-10-30T00:00:00+02:00 166.0
1459: 2021-10-29T07:31:41.468000 10km_622_57 2023-05-20T14:45:33.780031+00:00 2021-10-28T00:00:00.001000+02:00 mean_wind_dir   manual            day 2021-10-29T00:00:00+02:00 197.0
1460: 2021-10-28T07:31:40.649000 10km_622_57 2023-05-20T14:44:55.983806+00:00 2021-10-27T00:00:00.001000+02:00 mean_wind_dir   manual            day 2021-10-28T00:00:00+02:00 227.0
```
Here are some example on how to manipulate the data further
```R
## convert the character time string to a date
Aarhus_data[,st := as.POSIXct(gsub('\\+.*$', '', from), format='%Y-%m-%dT%H:%M:%S',tz='UTC')] # start time
Aarhus_data[,et := as.POSIXct(gsub('\\+.*$', '', to), format='%Y-%m-%dT%H:%M:%S',tz='UTC')] # end time

## order the data according to time
setkey(Aarhus_data,st)
Temp_WD <- Aarhus_data[,.(st,et,value,parameterId)]

## Plot data
library(ggplot2)

Temp_WD[,{
  ggplot(.SD,aes(x=st,y=value,colour=parameterId)) +
  geom_line() +
  facet_grid(parameterId ~ ., scale='free_y') +
  xlab(NULL) +
  theme_bw() +
  theme(strip.background = element_rect(fill="white"), panel.grid = element_blank(),legend.position='none')
}]

## as it is actually interval based data, one could also use the ibts package
library(ibts)

Temp_WD_ibts <- as.ibts(dcast(Temp_WD, st + et ~ parameterId, value.var = list('value')))

par(mfrow=c(2,1))
plot(Temp_WD_ibts[,'mean_temp'],col='indianred')
plot(Temp_WD_ibts[,'mean_wind_dir'],col='blue')

# or in one plot
plot(Temp_WD_ibts,col='red',col2='blue')
```

# Comments #
At the moment, you cannot use DMI's API service to request data from the Foulum weather station, as the station does not provide data to DMI yet. However, witin this year (2023) this should happen and then probably soon after you can access it via DMI's API service (in 10 min resolution).
The API service is a great tool for accessing data for free. In this documentation, Bulk requests are not covered.



<h6>This guide was written by Marcel</h6>
