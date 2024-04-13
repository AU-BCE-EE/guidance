
###########################################################
###########################################################
#####                                                 #####
#####    Function to read in data from the Axetris    #####
#####                                                 #####
###########################################################
###########################################################



library(data.table)
library(lubridate)

readLGD <- function(data,From=NULL,To=NULL,tz='Etc/GMT-1',fill=TRUE,type='Measurement',cut=TRUE){
	# browser()
	files_all <- list.files(data,recursive=TRUE,full.names=TRUE,pattern=paste0('\\',type,'.log$')) # read in only .log files
	if(length(files_all) == 0){stop('There are not Axetris files (.dat) in your chosen directory')}
	time_strings <- sub('.*_(\\d+)_[^_]*$', '\\1', basename(files_all)) # read out timestamp
	time_files <- strptime(time_strings, '%Y%m%d%H%M%S',tz=tz) # convert times. The Axetris seems to run in winter time
	files_all <- files_all[order(time_files)] # make the correct time order in case of strange folder structure
	time_files <- time_files[order(time_files)] # make the correct time order in case of strange folder structure
	# read in the last file to specify the end time
	last_file <- suppressWarnings(fread(tail(files_all,n=1)))
	To_end <- last_file[.N,as.POSIXct(Timestamp, format='%m/%d/%Y %H:%M:%OS',tz=tz)]
	if(is.null(From)){From <- time_files[1]} else {From <- convert_date(From,tz=tz)} # define start time
	if(is.null(To)){To <- To_end} else {To <- convert_date(To,tz=tz)} # define end time
	if(is.na(From) | is.na(To)){stop('Please enter a valid start and end time e.g. in the format "13.12.1312 13:12:00"')} # error message
	if(From > To | To_end < From){stop(paste0("Please change either your 'From' and/or 'To' time. The avilable data spans from (",time_files[1],") to (",To_end,")"))} # error message
	ls_files <- suppressWarnings(lapply(files_all[which(time_files >= floor_date(From, 'day') & time_files <= To)], fread)) # read in the files
	dt <- rbindlist(ls_files,fill=fill)
	if(nrow(dt) == 0){stop(paste0("The data.table is empty. A reason might be that the time given in the name strings of the Picarro files e.g. '",sub(".*/","",tail(files[which(time_files >= (From - 86400))],n=1)),"' is not in the same time zone than the time zone you chosed (",tz,"). Easiest way is to extend your 'From' or 'To' in the correct direction"))}
	dt[, st := as.POSIXct(Timestamp, format='%m/%d/%Y %H:%M:%OS',tz=tz)]
	setnames(dt,old=c('Data','V6'),new=c('CH4','CO2'))
	if(cut){out <- dt[,.(st,CH4,CO2)]} else {out <- dt}
	out
}




convert_date <- function(x,tz=NULL) {
  formats <- c("Y", "%d.%m.%Y", "%d.%m.%Y %H:%M", "%d.%m.%Y %H:%M:%S", "Ymd", "YmdHM", "YmdHMS")
  date_time <- parse_date_time(x, orders = formats, tz = tz)
  return(date_time)
}
