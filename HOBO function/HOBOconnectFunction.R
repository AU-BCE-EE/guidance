
#########################################################
#########################################################
#####                                               #####
#####    Function to read in HOBO logger MX2301A    #####
#####                                               #####
#########################################################
#########################################################

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
library(lubridate)

readHOBO <- function(Folder, From=NULL, To=NULL, Device = NULL, all = FALSE,cut = TRUE, ibts=FALSE){
	files <- list.files(Folder,recursive=TRUE,full.names=TRUE,pattern='.csv')
	## explanation of variables
	# Folder: Path to the folder with the files. Top folder is enough
	# From/To: Time range to select the data.Generally in the from 'YYYY.mm.dd HH:MM:SS' but the time can also be left out.
	# select either all files or only the latest of each device
	if(all){files_select <- files} else {
		# browser()
		# create a data table with the list of files
		dt_files <- data.table(file_path = files)
		# extract serial number and date from file names
		dt_files[, c('serial', 'date','time') := tstrsplit(basename(file_path), " ")[1:3]]
		# convert date to POSIXct format
		dt_files[, date_time := as.POSIXct(paste(date,time,sep=' '), format = "%Y-%m-%d %H_%M_%S")]
		# select latest file for each serial number
		files_select <- dt_files[order(-date_time), .SD[1], by = serial]$file_path
		}
	# select only the files of the chosen device (or all if empty)
	if(is.numeric(Device)){stop('Please provide the device name as character')}
	# select loggers
	if(is.null(Device)){Device_name <- unique(sub('.*([0-9]{2}) [0-9]{4}-[0-9]{2}-[0-9]{2}.*', '\\1', files_select))} else {Device_name <- Device}
	selected_files <- files_select[grepl(paste(paste0('217774',Device_name), collapse = "|"), files_select)]
	# read in the data
	HOBO_ls <- lapply(files_select, function(x){
		out <- fread(x)
		setnames(out, old= names(out), new = c('Device','Date','Temp','RH','DewPt','Connected','End'))
		dev_name <- sub('.*([0-9]{2}) [0-9]{4}-[0-9]{2}-[0-9]{2}.*', '\\1', x)
		out[,Device := as.character(Device)]
		out[,Device := dev_name]
		out[,Date := as.POSIXct(Date, '%m/%d/%Y %H:%M:%S',tz='CET')] # convert times
		if(cut){select_cols <- setdiff(names(out), c("Connected", "End"))
		out <- out[, ..select_cols]}
		out <- unique(out)
		setkey(out,Date)
		## select time range
		if(is.null(From)){From <- out[1,Date]} else {From <- convert_date(From)} # define start time
		if(is.null(To)){To <- tail(out[,Date],n=1)} else {To <- convert_date(To)} # define end time
		if(is.na(From) | is.na(To)){stop('Please enter a valid start and end time')} # error/warning message
		if(From > tail(out[,Date],n=1)){warning(paste0('Warning: Your given "From" time is after the available data of the logger #', out[1,Device]))} # error message
		if(From > To){warning(paste0('Warning: Your "From" time is after the "To" time of the logger #', out[1,Device]))} # error message
		out <- out[Date >= From & Date <= To,] # apply exact time range on the data.table
		if(ibts){
		  library(ibts)
		  # Create et column using shift and replace last value with NA
	  	  out[, et := shift(Date, type = 'lead')]
		  # remove rows that have NA in st or et
		  out <- out[complete.cases(out[, c("et", "Date")]), ]
		  # Convert the data.table to ibts class
		  HOBO_ibts <- as.ibts(out,st='Date')
		  # Return the ibts object
		  return(HOBO_ibts)
		} else {return(out)}
		})
	if(!ibts){
		dt <- rbindlist(HOBO_ls)
		return(dt)} else {return(HOBO_ls)}
}



convert_date <- function(x) {
  formats <- c("Y", "%d.%m.%Y", "%d.%m.%y", "%d.%m.%Y %H:%M", "%d.%m.%y %H:%M", 
               "%d.%m.%Y %H:%M:%S", "%d.%m.%y %H:%M:%S", "Ymd", "ymd", "YmdHM", 
               "ymdHM", "YmdHMS", "ymdHMS")
  date_time <- parse_date_time(x, orders = formats, tz = "CET")
  return(date_time)
}

