# Access DMI via API #

This document provides instructions on how to use API access to DMI (Danish Meteorological Institute) using R. 

# User Creation
Before you start downloading data from the API, you need to:
  1. Register as a user in DMI's [Developer Portal](https://dmiapi.govcloud.dk/#!/)
  2. Register an application in the Developer Portal and get your "API Key"
  3. Save the API key somewhere safe, because you need it every time you make a request for the API. Otherwise, you will not be authorized by the API. For more information, see the [User Creation page](https://confluence.govcloud.dk/display/FDAPI/User+Creation).

To summarize, to consume data from the DMI via API, you need to register as an user, register an application, and save the API key securely.

# R packages #
The following `R` libraries are required to make the requests:

  - `httr`: Needed to make requests
  - `jsonlite`: Needed to read files
  - `data.table`: Best package for data manipulation :)

  ```R
  install.packages(c('httr','jsonlite','data.table'))
  ```

# Input list #

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
API <- 'api-key=12345-6789-abcd-efgh-987654321'
url <- 'https://dmigw.govcloud.dk/v2/metObs/collections/observation/items?' # url for accessing observational data
url_stat <- 'https://dmigw.govcloud.dk/v2/metObs/collections/station/items?' # url for list of stations and see what parameters are (or rather should be) available at each station, etc
stationId <- paste0('stationId=', '06060')
datetime <- paste0('datetime=', '2023-04-01T00:00:00Z/2023-04-30T04:00:00Z')
parameterId <- paste0('parameterId=', 'wind_dir')
limit <- paste0('limit=', '10000')
bbox <- paste0('bbox=', '9.52,56.44,9.62,56.52')
```

# Request data #

__Make a base request__
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

__Make a request with multiple queries and assign it to a new variable__
```R
v1 <- GET(paste(url,stationId,datetime,limit,API,sep='&'))
```
__Use the `fromJSON` function to make the response readable:__
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


__Extract the relevant data (fourth list within the second list) and convert it to a data.table for better readability (In case you don't wanna use data.table, just don't use the fuction `as.data.table`)__
```R
WS_data <- as.data.table(WS_raw[[2]][[4]])
```
__Display your data__
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

It is not possible to make multiple station or parameter etc requests at the same time (error 400), but you can loop the data to solve this:

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
    v1 <- GET(paste(url,stationId,datetime,limit,parameterId,API,sep='&'))
    WS_raw <- fromJSON(rawToChar(v1$content))
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
    v1 <- GET(paste(url,stationId,datetime,limit,parameterId,API,sep='&'))
    WS_raw <- fromJSON(rawToChar(v1$content))
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
However, instead of using `for loops`, it is recommended to use `lapply` for better performance. For this simple example `lapply` was average about 15% faster but the `for loop` took sometimes 5 times as long and those results were excluded.

#### `lapply` ####

```R
req_parameter <- c('temp_dry', 'temp_dew', 'wind_dir')
par_list <- lapply(req_parameter, function(x){
  parameterId <- paste0('parameterId=', x)
  v1 <- GET(paste(url,stationId,datetime,limit,parameterId,API,sep='&'))
  WS_raw <- fromJSON(rawToChar(v1$content))
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
    v1 <- GET(paste(url,stationId,datetime,limit,parameterId,API,sep='&'))
    WS_raw <- fromJSON(rawToChar(v1$content))
    as.data.table(WS_raw[[2]][[4]])
  })
  rbindlist(par_list)
})
WS_data <- rbindlist(stat_list)
```
It would even be faster if instead of `paste0` the parameters are directly used in the `GET` function, but I am too lazy for that as it does not really fit with how I did it above. Also if multiple queries with multiple requests are used, you could first write a function that will do it but I was also too lazy for that. I might do it on a later time

# Notes #
At the moment, you cannot use DMI's API service to request data from the Foulum weather station, as the station does not provide data to DMI yet. However, witin this year (2023) this will happen and then probably soon after you can access it via DMI's API service (in 10 min resolution).
The API service is a great tool for accessing data for free. In this documentation, Bulk requests are not covered.

<h6>This guide was written by Marcel</h6>
