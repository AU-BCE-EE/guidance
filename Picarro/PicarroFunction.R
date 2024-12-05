
##################################################
##################################################
#####                                        #####
#####    Function to read in Picarro data    #####
#####                                        #####
##################################################
##################################################

library(data.table)
library(lubridate)

readCRDS <- function(Folder, From = NULL, To = NULL, tz = 'ETC/GMT-1', rm = TRUE, ibts = FALSE, mult = FALSE, renamed = FALSE, h5 = FALSE, subfolders = TRUE, name = TRUE, fill = FALSE) {
# browser()
  if (!h5) {
		files_all <- list.files(Folder, recursive = subfolders, full.names = TRUE, pattern = '\\.dat$') # read in only Picarro files
		if (!renamed) { # this is used if the rename argument is true. Could be optimised by detection of a date in the file.
			if (length(files_all) == 0) {stop('There are not Picarro files (.dat) in your chosen directory.')
			}
			# the oldest backpack Picarro has the same name as another backpack Picarro but different column names. Try to do that by reading in the entire string
			Picarro <- unique(sub('^([[:alnum:]]+)[-].*', '\\1', basename(files_all))) # check if the files are from the same Picarro. basename() ignores the Path to the files
			if ('Nomads4066' %in% Picarro) {
				out1 <-	grep('Nomads4066', basename(files_all), value = TRUE)
				out2 <- paste('Nomads4066', unique(sub(".*[\\._]([^-_]+)[-_.].*", "\\1", out1)), sep = '.*')
				Picarro <- c(Picarro[Picarro != 'Nomads4066'], out2)
			}
			if (length(Picarro) == 1 | (length(Picarro) > 1 & mult)) {
				run_function <- TRUE
			} else if (length(Picarro) > 1) {
				answer <- readline('Are you sure that you want to read in data from different Picarros? (Y/N). ')
				if (toupper(answer) %in% c('Y', 'YES')) {
					run_function <- TRUE
				} else {
					message('Please read then in only files from one Picarro model.')
					run_function <- FALSE
					}
				} else {
				run_function <- FALSE
					}
			if (run_function) {
				out <- lapply(Picarro, function(CRDS_name) {
					tryCatch({
						# browser()
						files <- grep(CRDS_name, files_all, value = TRUE)
						time_strings <- sub('^[[:alnum:]]+[-](\\d{8})[-](\\d{6}).*', '\\1\\2', basename(files)) # read out timestamp
						time_files <- strptime(time_strings, '%Y%m%d%H%M%S', tz = tz) # convert times
						files <- files[order(time_files)] # make the correct time order in case of strange folder structure
						time_files <- time_files[order(time_files)] # make the correct time order in case of strange folder structure
						# read in the last file to specify the end time
						last_file <- suppressWarnings(fread(tail(files, n = 1)))
						if ('EPOCH_TIME' %in% colnames(last_file)) { 
							To_end <- last_file[.N, as.POSIXct(EPOCH_TIME, origin = '1970-01-01', tz = tz)]
						} else {
							To_end <- last_file[.N, as.POSIXct(timestamp / 1E3, origin = '0001-01-01', tz = tz)]
						}
						if (is.null(From)) {
							From <- time_files[1]
						} else {
							From <- convert_date(From, tz = tz) # define start time
						}
						if (is.null(To)){
							To <- To_end
						} else {
							To <- convert_date(To, tz = tz) # define end time
						}
						if (is.na(From) | is.na(To)) {
							stop('Please enter a valid start and end time e.g. in the format "13.12.2024 13:12:00".') # error message
						}
						if (From > To | To_end < From) {
							stop(paste0("Please change either your 'From' and/or 'To' time. The avilable data spans from (", time_files[1], ") to (", To_end, ").")) # error message
						}
						# if(From > To_end){stop("Error: Your 'From' time is after the 'To' time.")} # error message
						ls_files <- suppressWarnings(lapply(files[which(time_files >= floor_date(From, 'day') & time_files <= To)], fread)) # read in the files
						dt <- rbindlist(ls_files, fill = fill)
						if (nrow(dt) == 0) {
							stop(paste0("The data.table is empty. A reason might be that the time given in the name strings of the Picarro files e.g. '", sub(".*/","", tail(files[which(time_files >= (From - 86400))], n = 1)), "' is not in the same time zone than the time zone you chosed (", tz, "). Easiest way is to extend your 'From' or 'To' in the correct direction."))
						}
						if ('EPOCH_TIME' %in% colnames(dt)) { 
							dt[, st := as.POSIXct(EPOCH_TIME, origin = '1970-01-01', tz = tz)] # make a time format how I like it
						} else {
							dt[, st := as.POSIXct(timestamp / 1E3, origin = '0001-01-01', tz = tz)]
						}
						# make a column with the Picarro type. Can be switch off by the argument 'name'
						if (name) {					
							dt[, PICARRO := c(JF = 'GHG_Picarro', NO = 'Backpack_Picarro', AH = 'Ammonia_Picarro', AE = 'Ammonia_Picarro', CF = 'Isotope_Picarro')[toupper(substr(CRDS_name, 1, 2))]] # name of the Picarro
						}
						if (rm) {
							suppressWarnings(dt <- dt[, .(st, .SD[, !c('st', 'DATE', 'TIME', 'FRAC_DAYS_SINCE_JAN1', 'FRAC_HRS_SINCE_JAN1', 'EPOCH_TIME', 'JULIAN_DAYS', 'timestamp')])]) # excluding unnecessary date colums and reordering them
							} else {
								dt <- dt[, .(st, .SD[, !c('st')])] # reordering columns
							}
						dt <- dt[st >= From & st <= To] # apply exact time range on the data.table
						if (ibts) {
						  	library(ibts)
							  # Create et column using shift and replace last value with NA
						  	dt[, et := shift(st, type = 'lead')]
							  # remove rows that have NA in st or et
							  dt <- dt[complete.cases(dt[, c("et", "st")]), ]
							  # Convert the data.table to ibts class
							  Picarro_ibts <- as.ibts(dt, st ='st')
							  # Return the ibts object
							  return(Picarro_ibts)
						} else {
							return(dt)
						}
					}, error = function(e) {
						return(e$message)
					}) # closing parentheses for TryCatch
				}) # closing parentheses for lapply 'out'
			out <- setNames(out, paste(Picarro, c(J = 'GHG_Picarro', N = 'Backpack_Picarro', A = 'Ammonia_Picarro', C = 'Isotope_Picarro')[toupper(substr(Picarro, 1, 1))], sep = '/'))
			if (length(out) == 1) {
				out <- out[[1]]
			} 
			return(out)
		} # closing brace for if(run_function)
		} else {
				dt_list <- lapply(files_all, function(x) {
					dt <- fread(x)
					if ('EPOCH_TIME' %in% colnames(dt)) { 
						dt[, st := as.POSIXct(EPOCH_TIME, origin = '1970-01-01', tz = tz)] # make a time format how I like it
						} else {
							dt[, st := as.POSIXct(timestamp / 1E3, origin = '0001-01-01', tz = tz)]
						}
					if (rm) {
						suppressWarnings(dt <- dt[, .(st, .SD[, !c('st', 'DATE', 'TIME', 'FRAC_DAYS_SINCE_JAN1', 'FRAC_HRS_SINCE_JAN1', 'EPOCH_TIME', 'JULIAN_DAYS', 'timestamp')])]) # excluding unnecessary date colums and reordering them
						} else {
							dt <- dt[, .(st, .SD[, !c('st')])] # reordering columns
						}
				}) # closing parenthese for lapply 'dt_list'
				dt_cols <- unique(lapply(dt_list, colnames))
				out <- list()
				for (i in 1:length(dt_cols)) {
					list_sub <-	lapply(dt_list, function(dt) {
				  	if (identical(colnames(dt), dt_cols[[i]])) {
				    return(dt)
				  	}
					})
					out[[i]] <- rbindlist(list_sub, fill = fill)
				}
				if (length(out) == 1) {
					out <- out[[1]]
				}
				return(out)
		}
	} else { # closing if for '!h5'
		# browser()
		library(rhdf5)
		files_all <- list.files(Folder, recursive = subfolders, full.names = TRUE, pattern = '\\.h5$') # read in only h5 files
		if (length(files_all) == 0) {
			stop('There are no Picarro files (.h5) in your chosen directory.')
		}
		Picarro <- unique(sub('^([[:alnum:]]+)[-].*', '\\1', basename(files_all))) # I just read the Picarro name
		files <- grep(Picarro, files_all, value = TRUE)
		time_strings <- sub('^[[:alnum:]]+[-](\\d{8})[-](\\d{6}).*', '\\1\\2', basename(files)) # read out timestamp
		time_files <- strptime(time_strings, '%Y%m%d%H%M%S', tz = tz) # convert times
		files <- files[order(time_files)] # make the correct time order in case of strange folder structure
		time_files <- time_files[order(time_files)] # make the correct time order in case of strange folder structure
		# read in the last file to specify the end time
		open_h5_last <- H5Fopen(tail(files, n = 1))
		last_file <- data.table(h5read(open_h5_last, h5ls(open_h5_last)$name, bit64conversion = 'double'))
		# H5Fclose(open_h5_last)
		To_end <- last_file[.N, as.POSIXct(time, origin = '1970-01-01', tz = tz)]
		if (is.null(From)) {
			From <- time_files[1]
		} else {
			From <- convert_date(From, tz = tz) # define start time
		}
		if (is.null(To)) {
			To <- To_end
		} else {
			To <- convert_date(To, tz = tz) # define end time
		}
		if (is.na(From) | is.na(To)) {
			stop('Please enter a valid start and end time e.g. in the format "13.12.2024 13:12:00".') # error message
		}
		if (From > To | To_end < From) {
			stop(paste0("Please change either your 'From' and/or 'To' time. The avilable data spans from (", time_files[1], ") to (", To_end, ").")) # error message
		}
		# if(From > To_end){stop("Error: Your 'From' time is after the 'To' time.")} # error message
		ls_files <- lapply(files[which(time_files >= floor_date(From, 'day') & time_files <= To)], function(y) {
			h5open <- H5Fopen(y)
			h5read <- data.table(h5read(h5open, h5ls(h5open)$name, bit64conversion = 'double'))
			# H5Fclose(h5open)
			return(h5read)
		})
		dt <- rbindlist(ls_files, fill = fill)
		if (nrow(dt) == 0) {
			stop(paste0("The data.table is empty. A reason might be that the time given in the name strings of the Picarro files e.g. '", sub(".*/", "", tail(files[which(time_files >= (From - 86400))], n = 1)), "' is not in the same time zone than the time zone you chosed (", tz, "). Easiest way is to extend your 'From' or 'To' in the correct direction."))
		}
		dt[, st := as.POSIXct(time, origin = '1970-01-01', tz = tz)] # make a time format how I like it
		# make a column with the Picarro type. Can be switch off by the argument 'name'
		if (name) {					
			dt[, PICARRO := c(JF = 'GHG_Picarro', NO = 'Backpack_Picarro', AH = 'Ammonia_Picarro', AE = 'Ammonia_Picarro', CF = 'Isotope_Picarro')[toupper(substr(Picarro, 1, 2))]] # name of the Picarro
		}
		if (rm) {
			suppressWarnings(dt <- dt[, .(st, .SD[, !c('st', 'DATE', 'TIME', 'FRAC_DAYS_SINCE_JAN1', 'FRAC_HRS_SINCE_JAN1', 'EPOCH_TIME', 'JULIAN_DAYS', 'timestamp', 'time')])]) # excluding unnecessary date colums and reordering them
			} else {
				dt <- dt[, .(st, .SD[, !c('st')])] # reordering columns
			}
		dt <- dt[st >= From & st <= To] # apply exact time range on the data.table
		if (ibts) {
		  	library(ibts)
			  # Create et column using shift and replace last value with NA
		  	dt[, et := shift(st, type = 'lead')]
			  # remove rows that have NA in st or et
			  dt <- dt[complete.cases(dt[, c("et", "st")]), ]
			  # Convert the data.table to ibts class
			  Picarro_ibts <- as.ibts(dt, st = 'st')
			  # Return the ibts object
			  return(Picarro_ibts)
		} else {
			return(dt)
		}
	} # closeing else statement of h5
}


##########################################################
### Function to shift Picarro time to the correct time ###
##########################################################


shift_dt <- function(x, d_t, tz = 'Etc/GMT-1', cRef = 'RefTime', cDev = 'DeviceTime', ST = 'st', tzDev = 'UTC', tzRef = 'CET'){
	# browser()
	x <- as.data.table(x)
	if (!('RefTime' %in% colnames(x) & 'DeviceTime' %in% colnames(x))) {
		stop('The data table/frame x with the time differences needs to have a column with the name "RefTime" and "DeviceTime".
			Otherwise you can use also the "cRef" and "cDev" argument to use other column names.')
	}
	x[, RefTime := convert_date(.SD[[cRef]], tz = as.character(tzRef))]	 
	x[, DeviceTime := convert_date(.SD[[cDev]], tz = as.character(tzDev))] 
	offset <- as.numeric(x$RefTime - x$DeviceTime, units = "secs")
	times <- with_tz(x[, RefTime], tz = tz)
	# st_out <- st_in <- d_t[,.SD[[ST]]]
	st_out <- st_in <- d_t[[ST]]
	if(length(offset) == 1){
		st_out <- st_in + offset
	} else {
		b <- offset[-length(offset)]
		a <- (offset[-1] - b) / as.numeric(times[-1] - times[-length(times)], units = "secs")
		ind <- findInterval(st_in, times, all.inside = TRUE)
			for(i in unique(ind)){
				st_sub <- st_in[ind == i]
				st_out[ind == i] <- st_sub + b[i] + a[i] * as.numeric(st_sub - times[i], units = "secs")
			}
	}
	# d_t[[ST]] <- st_out
	dt_out <- copy(d_t)
	set(dt_out, j = ST, value = st_out)
	return(dt_out)
}


convert_date <- function(x, tz = NULL) {
  formats <- c("Y", "%d.%m.%Y", "%d.%m.%Y %H:%M", "%d.%m.%Y %H:%M:%S", "Ymd", "YmdHM", "YmdHMS")
  date_time <- parse_date_time(x, orders = formats, tz = tz)
  return(date_time)
}


#########################
### Written by Marcel ###
#########################



