
#########################################################
#########################################################
#####                                               #####
#####    Function to read in HOBO logger MX2301A    #####
#####                                               #####
#########################################################
#########################################################


library(data.table)
library(lubridate)

readHOBO <- function(Folder, From=NULL, To=NULL, Device = NULL, latest = FALSE,cut = TRUE){
	# browser()
	all_files <- list.files(Folder,recursive=TRUE,full.names=TRUE,pattern='.csv')
		
	## select only the relevant devices
	# make a table with all the files
	dt_files <- data.table(file_path = all_files,file_name=basename(all_files),serial = gsub('\\s.*', '', basename(all_files)))
	# extract serial number and date from file names
	dt_files[, ':=' (date_time = as.POSIXct(gsub('.*?(\\d{4}-\\d{2}-\\d{2} \\d{2}_\\d{2}_\\d{2}).*', '\\1', file_name), format = "%Y-%m-%d %H_%M_%S")
									,Dev = substr(serial, nchar(serial) - 1, nchar(serial)))]
	# select only the chosen devices
	if(is.numeric(Device)){stop('Please provide the device name as two digit character, e.g. "04".')}
	if(is.null(Device)){dt_devices <- dt_files[order(date_time)]} else {dt_devices <- dt_files[Dev %in% Device][order(date_time)]}

# browser()

	HOBO_ls <- lapply(dt_devices[,unique(Dev)], function(k) {
		tryCatch({
			# browser()
			dt_sub <- dt_devices[Dev == k]

			if(latest){dt_sub2 <- tail(dt_sub,n=1)} else {dt_sub2 <- dt_sub}
			# select rough time range
			if(is.null(From)){y_from <- fread(dt_sub[1,file_path],sep=',',fill=TRUE)
				setnames(y_from, old=names(y_from)[2], new = 'Date')
				y_from[,Date := as.POSIXct(Date, '%m/%d/%Y %H:%M:%S',tz='CET')] # convert times
				FROM <- y_from[!is.na(Date),Date][1]} else {FROM <- convert_date(From)} # define start time
			if(is.null(To)){TO <- tail(dt_sub2[,date_time],n=1)} else {TO <- convert_date(To)} # define end time
			if(is.na(FROM) | is.na(TO)){stop('Please enter a valid start and end time')} # error/warning message
			if(!is.null(From) & !is.null(To)){if(From > To){stop('Your chosen "From" time is after the chosen "To" time.')}} # error message
			if(FROM > tail(dt_sub2[,date_time],n=1)){stop('Your chosen "From" time is after the available data.')} # error message
			if(FROM > TO){stop('Your chosen "To" time is before the available data.')} # error message
			
			# browser()
			# also select one file earlier and one file later
			i_From <- which(dt_sub2[,date_time >= FROM])[1] - 1
			i_To <- ifelse(is.na(which(dt_sub2[,date_time >= TO])[1]),tail(which(dt_sub2[,date_time < TO]),n=1),tail(which(dt_sub2[,date_time >= TO]),n=1))
			files_select <- dt_sub2[i_From : i_To,file_path]

			device_ls <- lapply(files_select, function(x){
				out <- fread(x,sep=',',fill=TRUE)
				setnames(out, new = c('Device','Date','Temp','RH','DewPt', gsub(" ", "_", names(out)[6:length(names(out))])))
				out[,Device := as.character(Device)]
				out[,Device := k]
				out[,st := as.POSIXct(Date, '%m/%d/%Y %H:%M:%S',tz='CET')] # convert times
				if(cut){out1 <- out[, .(Device,st,Temp,RH,DewPt)]} else{out1 <- out}
				return(out1)
			})
# browser()
			device_out <- rbindlist(device_ls,fill=TRUE)
			device_out2 <- device_out[st >= FROM & st <= TO,] # apply exact time range on the data.table
			# remove dublicates
			device_out3 <- unique(device_out2)
			return(device_out3)
		}, error = function(e){
			cat('Warning/Error: Device #',k, e$message, '\n')
			return(NULL)
			})
	})

	# remove empty list entires form possible errors
	HOBO_clean <- HOBO_ls[!sapply(HOBO_ls, is.null)]
	dt <- rbindlist(HOBO_clean,fill=TRUE)
	dt[order(Device,st)]
	return(dt)
}




convert_date <- function(x,tz=NULL) {
  formats <- c("Y", "%d.%m.%Y", "%d.%m.%Y %H:%M", "%d.%m.%Y %H:%M:%S", "Ymd", "YmdHM", "YmdHMS")
  date_time <- parse_date_time(x, orders = formats, tz = tz)
  return(date_time)
}

# by Marcel