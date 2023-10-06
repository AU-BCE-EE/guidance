
#############################################################
#############################################################
#####                                                   #####
#####    Function to read DAVIS weather station data    #####
#####                                                   #####
#############################################################
#############################################################

# Specify the packages to check
required_packages <- c('data.table', 'lubridate')
# Check if the packages are installed
missing_packages <- required_packages[!(required_packages %in% installed.packages()[, 'Package'])]
# Install missing packages if any
if (length(missing_packages) > 0) {
  message(paste("The following package(s) are needed and not installed:", paste(missing_packages, collapse = ", ")))
  install_packages <- readline("Do you want to install the missing package(s)? (Y/N): ")
  if (toupper(install_packages) %in% c('Y','YES')) {
    install.packages(missing_packages)
    message("Missing package(s) installed.")
  } else if (toupper(install_packages) %in% c('N','NO')){
    message("Missing package(s) not installed.")
  } else {message(paste0("Mate, you typed '",install_packages,"'. This is neither Yes or No, so I assume that you don't want to install them.
  However, I recommend doing it as they are great packages :)"))
}}


library(data.table)

readWS <- function(Folder, From = NULL, To = NULL,ibts=FALSE) {
# browser()
  # List all the text files in the folder
  files <- list.files(Folder, recursive = TRUE, full.names = TRUE, pattern = '.txt')
  # Read all files into a single data.table using fread
  dt <- tryCatch(
    rbindlist(lapply(files, fread)),
    error = function(e) {
      message("Error: It seems that you read in files from different weather station types (as the columns do not match).
       Please read in files from one weather  station only\n\n", e$message)
      return(NULL)
    }
  )
  # Extract column names from the first file and set appropriate column names
  col_clean <- gsub('[^[:alnum:]]', '', paste0(dt[1], dt[2]))
  setnames(dt, new = col_clean)
  dt <- dt[!grepl("[A-Za-z]", TempOut)]
  # Convert Date and Time columns to POSIXct
  dt[, Date := as.POSIXct(paste(Date, Time), format = '%d/%m/%y %H:%M', tz = 'CET')]
  dt[,Time := NULL]
  # remove duplicated rows
  dt <- unique(dt)
  setkey(dt,Date)
  if(is.null(From)){From <- dt[1,Date]} else {From <- convert_date(From)} # define start time
	if(is.null(To)){To <- dt[,tail(Date,n=1)]} else {To <- convert_date(To)} # define end time
	if(is.na(From) | is.na(To)){stop('Please enter a valid start and end time')} # error message
	if(From > dt[,tail(Date,n=1)]){stop('Your given "From" time is after the available data')} # error message
	if(From > To){stop('Error: Your "From" time is after the "To" time.')} # error message
	dt <- dt[Date >= From & Date <= To]
  # Define wind direction conversion
  Wind_dir <- c('N' = 360, 'NNE' = 22.5, 'NE' = 45, 'ENE' = 67.5, 'E' = 90, 'ESE' = 112.5, 'SE' = 135, 'SSE' = 157.5,
                'S' = 180, 'SSW' = 202.5, 'SW' = 225, 'WSW' = 247.5, 'W' = 270, 'WNW' = 292.5, 'NW' = 315, 'NNW' = 337.5, '---' = NA_real_)
  # Convert WindDir column to numeric using the Wind_dir conversion
  dt[, WD := as.numeric(as.character(factor(WindDir, levels = names(Wind_dir), labels = Wind_dir)))]
  # Convert selected columns to numeric
  numeric_cols <- names(dt)[sapply(dt, function(x) all(grepl("^[[:alnum:][:space:].-]+$", x)) & any(grepl("[0-9]", x)))]
  dt[, (numeric_cols) := lapply(.SD, as.numeric), .SDcols = numeric_cols]
  # Calculate time intervals and identify repeated intervals
  mt <- dt[,diff(Date)]
  table_mt <- table(mt)
  repeated_intervals <- table_mt[table_mt > 1]
  if(length(repeated_intervals) > 1){
	  cat("In the data, there are", length(repeated_intervals), "logging interval that are repeated more than once:\n")} else {
	  cat("In the data, there is", length(repeated_intervals), "logging interval that is repeated more than once:\n")}
  cat(paste0("- ", names(repeated_intervals), " min (", repeated_intervals, " times)\n"))
  if(ibts){
  	library(ibts)
	  # Create et column using shift and replace last value with NA
  	dt[, et := shift(Date, type = 'lead')]
	  # remove rows that have NA in st or et
	  dt <- dt[complete.cases(dt[, c("et", "Date")]), ]
	  # Convert the data.table to ibts class
	  WS_ibts <- as.ibts(dt,st='Date')
	  colClasses(WS_ibts)['WD'] <- 'circ'
	  # Return the ibts object
	  return(WS_ibts)
	} else {return(dt)}
}


convert_date <- function(x) {
  formats <- c("Y", "%d.%m.%Y", "%d.%m.%Y %H:%M", "%d.%m.%Y %H:%M:%S", "Ymd", "YmdHM", "YmdHMS")
  date_time <- parse_date_time(x, orders = formats, tz = "CET")
  return(date_time)
}
