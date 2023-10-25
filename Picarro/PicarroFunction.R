
##################################################
##################################################
#####                                        #####
#####    Function to read in Picarro data    #####
#####                                        #####
##################################################
##################################################

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

readCRDS <- function(Folder,From=NULL,To=NULL,tz='ETC/GMT-1',rm=TRUE,ibts=FALSE,mult=FALSE,Ali=FALSE){
# browser()	
	files_all <- list.files(Folder,recursive=TRUE,full.names=TRUE,pattern='\\.dat$') # read in only Picarro files
	if(!Ali){
		if(length(files_all) == 0){stop('There are not Picarro files (.dat) in your chosen directory')}
		Picarro <- unique(sub('^([[:alnum:]]+)[-].*', '\\1', basename(files_all))) # check if the files are from the same Picarro
		if(length(Picarro) == 1 | (length(Picarro) > 1 & mult)){
			run_function <- TRUE
		} else if (length(Picarro) > 1){
			answer <- readline('Are you sure that you want to read in data from different Picarros? (Y/N) ')
			if(toupper(answer) %in% c('Y','YES')){
				run_function <- TRUE
			} else {
				message('Please read then in only one files from one Picarro model')
				run_function <- FALSE
			}
		} else {
			run_function <- FALSE
		}
		if(run_function){
		out <- lapply(Picarro, function(CRDS_name){
				tryCatch({
					# browser()
					files <- grep(CRDS_name,files_all,value=TRUE)
					time_strings <- sub('^[[:alnum:]]+[-](\\d{8})[-](\\d{6}).*', '\\1\\2', basename(files)) # read out timestamp
					time_files <- strptime(time_strings, '%Y%m%d%H%M%S',tz=tz) # convert times
					files <- files[order(time_files)] # make the correct time order in case of strange folder structure
					time_files <- time_files[order(time_files)] # make the correct time order in case of strange folder structure
					# read in the last file to specify the end time
					last_file <- suppressWarnings(fread(tail(files,n=1)))
					To_end <- last_file[.N,as.POSIXct(EPOCH_TIME, origin='1970-01-01',tz=tz)]
					if(is.null(From)){From <- time_files[1]} else {From <- convert_date(From,tz=tz)} # define start time
					if(is.null(To)){To <- To_end} else {To <- convert_date(To,tz=tz)} # define end time
					if(is.na(From) | is.na(To)){stop('Please enter a valid start and end time e.g. in the format "13.12.1312 13:12:00"')} # error message
					# if(From > To_end){stop(paste0("Your given 'From' time (",From,") is after the available data (",To_end,")"))} # error message
					# if(To < time_files[1]){stop(paste0("Your given 'To' time (",To,") is before the available data (",time_files[1],")"))} # error message
					if(From > To | To_end < From){stop(paste0("Please change either your 'From' and/or 'To' time. The avilable data spans from (",time_files[1],") to (",To_end,")"))} # error message
					# if(From > To_end){stop("Error: Your 'From' time is after the 'To' time.")} # error message
					ls_files <- suppressWarnings(lapply(files[which(time_files >= From & time_files <= To)], fread)) # read in the files
					dt <- rbindlist(ls_files)
					if(nrow(dt) == 0){stop(paste0("The data.table is empty. A reason might be that the time given in the name strings of the Picarro files e.g. '",sub(".*/","",tail(files[which(time_files >= (From - 86400))],n=1)),"' is not in the same time zone than the time zone you chosed (",tz,"). Easiest way is to extend your 'From' or 'To' in the correct direction"))}
					dt[, Date := as.POSIXct(EPOCH_TIME, origin='1970-01-01',tz=tz)] # make a time format how I like it
					dt[, PICARRO := c(JF='GHG_Picarro',NO='Backpack_Picarro',AH='Ammonia_Picarro',AE='Ammonia_Picarro',CF='Isotope_Picarro')[toupper(substr(CRDS_name,1,2))]] # name of the Picarro
					if(rm){suppressWarnings(dt <- dt[,.(Date,.SD[,!c('Date','DATE','TIME','FRAC_DAYS_SINCE_JAN1','FRAC_HRS_SINCE_JAN1','EPOCH_TIME','JULIAN_DAYS')])]) # excluding unnecessary date colums and reordering them
						} else {dt <- dt[,.(Date,.SD[,!c('Date')])]} # reordering columns
					dt <- dt[Date >= From & Date <= To] # apply exact time range on the data.table
					if(ibts){
					  	library(ibts)
						  # Create et column using shift and replace last value with NA
					  	dt[, et := shift(Date, type = 'lead')]
						  # remove rows that have NA in st or et
						  dt <- dt[complete.cases(dt[, c("et", "Date")]), ]
						  # Convert the data.table to ibts class
						  Picarro_ibts <- as.ibts(dt,st='Date')
						  # Return the ibts object
						  return(Picarro_ibts)
						} else {return(dt)}
				}, error = function(e){
			return(e$message)
			})
		})
		out <- setNames(out, paste(Picarro, c(J='GHG_Picarro',N='Backpack_Picarro',A='Ammonia_Picarro',C='Isotope_Picarro')[toupper(substr(Picarro,1,1))],sep='/'))
		if(length(out) == 1){out <- out[[1]]} 
		return(out)
	}
	} else {
			dt_list <- lapply(files_all, function(x) {
				dt <- fread(x)
				dt[, Date := as.POSIXct(EPOCH_TIME, origin='1970-01-01',tz=tz)] # make a time format how I like it
				if(rm){suppressWarnings(dt <- dt[,.(Date,.SD[,!c('Date','DATE','TIME','FRAC_DAYS_SINCE_JAN1','FRAC_HRS_SINCE_JAN1','EPOCH_TIME','JULIAN_DAYS')])]) # excluding unnecessary date colums and reordering them
					} else {dt <- dt[,.(Date,.SD[,!c('Date')])]} # reordering columns
					})
			dt_cols <- unique(lapply(dt_list,colnames))
			out <- list()
			for(i in 1:length(dt_cols)){
				list_sub <-	lapply(dt_list, function(dt) {
			  if (identical(colnames(dt), dt_cols[[i]])) {
			    return(dt)
			  }
			})
				out[[i]] <- rbindlist(list_sub)
			}
			if(length(out) == 1){out <- out[[1]]}
			return(out)
	}
}


##########################################################
### Function to shift Picarro time to the correct time ###
##########################################################


shift_dt <- function(x,d_t,tz="Etc/GMT-1",cRef='RefTime',cDev='DeviceTime',st='st',tzI='CET'){
	# browser()
	x <- as.data.table(x)
	if(!('RefTime' %in% colnames(x) & 'DeviceTime' %in% colnames(x))){
		stop('The data table/frame x with the time differences needs to have a column with the name "RefTime" and "DeviceTime".
			Otherwise you can use also the "cRef" and "cDev" argument to use other column names')
		}
	x[,RefTime := convert_date(.SD[[cRef]],tz=tzI)]	 
	x[,DeviceTime := convert_date(.SD[[cDev]],tz=tzI)] 
	versatz <- as.numeric(x$RefTime - x$DeviceTime,units="secs")
	zeiten <- with_tz(x[,RefTime],tz=tz)
	st_out <- st_in <- d_t[,.SD[[st]]]
	if(length(versatz) == 1){
		st_out <- st_in + versatz
	} else {
		b <- versatz[-length(versatz)]
		a <- (versatz[-1] - b)/as.numeric(zeiten[-1] - zeiten[-length(zeiten)],units="secs")
		ind <- findInterval(st_in,zeiten,all.inside=TRUE)
			for(i in unique(ind)){
				st_sub <- st_in[ind == i]
				st_out[ind == i] <- st_sub + b[i] + a[i]*as.numeric(st_sub - zeiten[i],units="secs")
			}
		}
	d_t[[st]] <- st_out	
	return(d_t)
}


convert_date <- function(x,tz=NULL) {
  formats <- c("Y", "%d.%m.%Y", "%d.%m.%Y %H:%M", "%d.%m.%Y %H:%M:%S", "Ymd", "YmdHM", "YmdHMS")
  date_time <- parse_date_time(x, orders = formats, tz = tz)
  return(date_time)
}
