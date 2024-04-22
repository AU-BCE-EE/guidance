
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
	if(is.null(Device)){dt_devices <- dt_files} else {dt_devices <- dt_files[Dev %in% Device]}

# browser()

	HOBO_ls <- lapply(dt_devices[,unique(Dev)], function(k) {
		# browser()
		tryCatch({
			dt_sub <- dt_devices[Dev == k]

			if(latest){dt_sub2 <- tail(dt_sub,n=1)} else {dt_sub2 <- dt_sub}
			# select rough time range
			if(is.null(From)){From <- dt_sub2[1,date_time]} else {From <- convert_date(From)} # define start time
			if(is.null(To)){To <- tail(dt_sub2[,date_time],n=1)} else {To <- convert_date(To)} # define end time
			if(is.na(From) | is.na(To)){stop('Please enter a valid start and end time')} # error/warning message
			if(From > tail(dt_sub2[,date_time],n=1)){stop('Warning: Your given "From" time is after the available data of the logger')} # error message
			if(From > To){stop('Warning: Your "From" time is after the "To" time of the logger #')} # error message
			
			# browser()
			# select also the file before the From time
			i_From <- which(dt_sub2[,date_time >= From])[1] - 1
			i_To <- tail(which(dt_sub2[,date_time >= To]),n=1)+1
			files_select_all <- dt_sub2[i_From : i_To,file_path]
			files_select <- files_select_all[!is.na(files_select_all)]

			device_ls <- lapply(files_select, function(x){
				# browser()
				out <- fread(x,sep=',',fill=TRUE)
				setnames(out, new = c('Device','Date','Temp','RH','DewPt', gsub(" ", "_", names(out)[6:length(names(out))])))
				# setnames(out, old=names(out)[1:5], new = c('Device','Date','Temp','RH','DewPt','Connected','End'))
				dev_name <- sub('.*([0-9]{2}) [0-9]{4}-[0-9]{2}-[0-9]{2}.*', '\\1', x)
				out[,Device := as.character(Device)]
				out[,Device := k]
				out[,Date := as.POSIXct(Date, '%m/%d/%Y %H:%M:%S',tz='CET')] # convert times
				if(cut){out1 <- out[, .(Device,Date,Temp,RH,DewPt)]} else{out1 <- out}
				return(out1)
			})
# browser()
			device_out <- rbindlist(device_ls,fill=TRUE)
			device_out2 <- device_out[Date >= From & Date <= To,] # apply exact time range on the data.table
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
	dt[order(Device,Date)]
	return(dt)
}




convert_date <- function(x,tz=NULL) {
  formats <- c("Y", "%d.%m.%Y", "%d.%m.%Y %H:%M", "%d.%m.%Y %H:%M:%S", "Ymd", "YmdHM", "YmdHMS")
  date_time <- parse_date_time(x, orders = formats, tz = tz)
  return(date_time)
}

