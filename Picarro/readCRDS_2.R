
##################################################
##################################################
#####                                        #####
#####    Function to read in Picarro data    #####
#####                                        #####
##################################################
##################################################

library(data.table)
library(lubridate)

readCRDS2 <- function(Folder, From = NULL, To = NULL, tz = 'ETC/GMT-1', rm = TRUE, ibts = FALSE, mult = FALSE,
	renamed = FALSE, h5 = FALSE, subfolders = TRUE, name = TRUE, fill = FALSE, meta = FALSE) {
# browser()
  if (!h5) {
  # browser()	
		files_all <- list.files(Folder, recursive = subfolders, full.names = TRUE, pattern = '\\.dat$') # read in all .dat files
		if (length(files_all) == 0 && grepl('\\.dat$', Folder)) {
			files_all <- Folder
			} 
		if (!renamed) {
			# check what kind of files are present
			if (!mult | (mult && is.null(From) && is.null(To))) {
				out_check_files <- check_files(files_all = files_all, mult = mult, h5 = h5)
				if (out_check_files$run_function) {
					out <- read_CRDS_data(out_check_files = out_check_files, files_all = files_all, Picarro = out_check_files$Picarro, From = From, To = To, tz = tz, name = name, h5 = h5, fill = fill, rm = rm, ibts = ibts)
					return(out)
					if (ibts) {
						out_ibts <- as.ibts(out)
						return(out_ibts)
					}
				}
			} else {
				## select first the files within the provided time range
				files <- data.table(path=files_all)
				files[, time_strings := sub('^[[:alnum:]]+[-](\\d{8})[-](\\d{6}).*', '\\1\\2', basename(path))] # read out timestamp
				files[, datetime := as.POSIXct(time_strings, '%Y%m%d%H%M%S', tz = tz)] # convert times
				setkey(files, datetime) # set correct row order
				From_To <- def_From_To(files = files, From = From, To = To, tz = tz, h5 = h5) # see function below
				# then proceed with only those files
				out_check_files <- check_files(files_all = files[datetime >= floor_date(From_To$From, 'day') & datetime <= From_To$To, path], mult = mult, h5 = h5)
				if (out_check_files$run_function) {
					out <- read_CRDS_data(out_check_files = out_check_files, files_all = files[datetime >= floor_date(From_To$From, 'day') & datetime <= From_To$To, path], Picarro = out_check_files$Picarro, From = From, To = To, tz = tz, name = name, h5 = h5, fill = fill, rm = rm, ibts = ibts)
					return(out)
						if (ibts) {
							out_ibts <- as.ibts(out)
							return(out_ibts)
						}
				}
			}
		}
		if (renamed) {
# browser()
			if (!meta | (meta & is.null(From) & is.null(To))) { # if meta is false
				dt_list_renamed <- lapply(files_all, function(x) {
					dt <- fread(x)
					dt <- make_st(dt, tz) # see function below
					dt <- remove_columns(dt, rm) # see function below
					if (!is.null(From)) {
						dt <- dt[st >= convert_date(From), ]
					}
					if (!is.null(To)) {
						dt <- dt[st <= convert_date(To), ]
					}
					if (name) {
						dt[, PICARRO := name_Picarro(dt)]
					}
					dt
				}) # closing parenthese for lapply 'dt_list_renamed'
				dt_list_renamed_sub <- dt_list_renamed[sapply(dt_list_renamed, function(x) nrow(x) > 0)] # remove the empty entries due to definition of From and To			
				dt_cols <- unique(lapply(dt_list_renamed_sub, colnames))
				out <- list()
				for (i in 1:length(dt_cols)) {
					list_sub <-	lapply(dt_list_renamed_sub, function(dt) {
				  	if (identical(colnames(dt), dt_cols[[i]])) {
				    	return(dt)
				  	}
					})					
					out[[i]] <- rbindlist(list_sub, fill = fill)[order(st)]
				}
				if (length(out) == 1) {
					out <- out[[1]]
				}
				return(out)
					if (ibts) {
						out_ibts <- as.ibts(out)
						return(out_ibts)
					}
			} # closing of !meta

			if (meta & (!is.null(From) | !is.null(To))) { # routine to read out date based on meta data
				library(fs)
				renamed_list <- lapply(files_all, function(x) {
					info <- data.table(file_info(x))
					datetime <- info[, do.call(pmin, c(.SD, na.rm = TRUE)), .SDcols = is.POSIXct]
					info_dt <- data.table(datetime, name=basename(x), path = x)
					info_dt
				}) # closing lapply renamed_list
				files <- rbindlist(renamed_list)
				setkey(files, datetime)
				From_To <- def_From_To(files, From, To, tz, h5) # see function below
				From_To$From <- From_To$From - 86400 # go one day back as the creation is usually the end time. As there are hourly and daily files, I am just on the safe side with 1 day.
# browser()
				dt_list_renamed_meta <- lapply(files[datetime >= floor_date(From_To$From, 'day') & datetime <= From_To$To, path], function(x) {				
					dt <- fread(x)
					is_empty(dt = dt, files = files, h5 = h5, tz = tz, From = From_To$From, To = From_To$To) # see function below
					dt <- make_st(dt, tz) # see function below
					dt <- remove_columns(dt, rm) # see function below	
					dt <- dt[st >= From_To$From & st <= From_To$To] # apply exact time range on the data.table
					if (name) {
						dt[, PICARRO := name_Picarro(dt)]
					}
					return(dt)
				}) # closing parenthese for lapply 'dt_list_renamed' meta = TRUE
				if (length(dt_list_renamed_meta) > 0) {
					dt_cols <- unique(lapply(dt_list_renamed_meta, colnames))
					out <- list()
					for (i in 1:length(dt_cols)) {
						list_sub <-	lapply(dt_list_renamed_meta, function(dt) {
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
					if (ibts) {
						out_ibts <- as.ibts(out)
						return(out_ibts)
					}
				} else {
					cat('no data found within your period or the meta data is not reliable. Try using "meta = FALSE".')
				}
			}



		} # closing curly brace for renamed = TRUE
	} else { # closing if for '!h5'






		# load library to read in h5 files
		library(rhdf5)
		files_all <- list.files(Folder, recursive = subfolders, full.names = TRUE, pattern = '\\.h5$') # read in only h5 files
		if (!renamed) { # this is used if the rename argument is true.
			


		
			Picarro <- unique(sub('^([[:alnum:]]+)[-].*', '\\1', basename(files_all))) # I just read the Picarro name
			files <- data.table(path = grep(Picarro, files_all, value = TRUE))
			files[, time_strings := sub('^[[:alnum:]]+[-](\\d{8})[-](\\d{6}).*', '\\1\\2', basename(path))] # read out timestamp
			files[, datetime := as.POSIXct(time_strings, '%Y%m%d%H%M%S', tz = tz)] # convert times
			setkey(files, datetime)
			From_To <- def_From_To(files = files, From = From, To = To, tz = tz, h5 = h5) # see function below
			ls_files <- lapply(files[datetime >= floor_date(From_To$From, 'day') & datetime <= From_To$To, path], function(y) {
				h5open <- H5Fopen(y)
				h5read <- data.table(h5read(h5open, h5ls(h5open)$name, bit64conversion = 'double'))
				H5Fclose(h5open)
				return(h5read)
			})
			dt <- rbindlist(ls_files, fill = fill)
			is_empty(dt = dt, files = files, h5 = h5, tz = tz, From = From_To$From, To = From_To$To) # see function below
			dt <- make_st(dt, tz) # see function below
			# make a column with the Picarro type. Can be switch off by the argument 'name'
			if (name) {					
				dt[, PICARRO := c(JF = 'GHG_Picarro', NO = 'Backpack_Picarro', AH = 'Ammonia_Picarro', AE = 'Ammonia_Picarro', CF = 'Isotope_Picarro')[toupper(substr(Picarro, 1, 2))]] # name of the Picarro
			}
			dt <- remove_columns(dt, rm) # see function below
			dt <- dt[st >= From_To$From & st <= From_To$To] # apply exact time range on the data.table
			return(dt)
					if (ibts) {
						dt_ibts <- as.ibts(dt)
						return(dt_ibts)
					}
		}
	} # closeing else statement of h5
}

####################
### subfunctions ###
####################

name_Picarro <- function(dt) {
# make a data.table with key columns
	dt_Picarro <- rbind(
		data.table(include = c("InletValve", "NH3", "NH3_raw"), exclude = c('Battery', 'CH4', 'N2O'), Picarro = 'Ammonia_Picarro'),
		data.table(include = c("HP_12CH4", "HP_13CH4", "12CO2"), exclude = c('N2O', 'Battery', 'GPS'), Picarro = 'Isotope_Picarro'),
		data.table(include = c("N2O", "CH4", "NH3"), exclude = c('12CO2', 'Battery', 'GPS'), Picarro = 'GHG_Picarro'),
		data.table(include = c("Battery", "CH4", "CO2"), exclude = c("NH3", "N2O", "Empty"), Picarro = 'Backpack_Picarro')
	)

	ls_named <- lapply(dt_Picarro[, unique(Picarro)], function(i) {
		# browser()
		cols <- names(dt)
		has_include <- any(sapply(dt_Picarro[Picarro == i, include], function(x) {
			any(grepl(x, cols, fixed = TRUE))
			}
		))
		has_exclude <- any(sapply(dt_Picarro[Picarro == i, exclude], function(x) {
			any(grepl(x, cols, fixed = TRUE))
			}
		))
	  if (has_include && !has_exclude) {
	  	i
	  }
	})
	Picarro_name <- ls_named[sapply(ls_named, function(x) length(x) > 0)][[1]]
	Picarro_name
}


read_CRDS_data <- function(out_check_files, files_all, Picarro, From, To, tz, name, h5, fill, rm, ibts) {
	out <- lapply(out_check_files$Picarro, function(CRDS_name) {
		tryCatch({
# browser()
			files <- data.table(path = grep(CRDS_name, files_all, value = TRUE))
			files[, time_strings := sub('^[[:alnum:]]+[-](\\d{8})[-](\\d{6}).*', '\\1\\2', basename(path))] # read out timestamp
			files[, datetime := as.POSIXct(time_strings, '%Y%m%d%H%M%S', tz = tz)] # convert times
			setkey(files, datetime) # set correct row order
			From_To <- def_From_To(files = files, From = From, To = To, tz = tz, h5 = h5) # see function below
			ls_files <- suppressWarnings(lapply(files[datetime >= floor_date(From_To$From, 'day') & datetime <= From_To$To, path], fread)) # read in the files
			dt <- rbindlist(ls_files, fill = fill)
			is_empty(dt = dt, files = files, h5 = h5, tz = tz, From = From_To$From, To = From_To$To) # see function below
			dt <- make_st(dt = dt, tz = tz) # see function below
			# make a column with the Picarro type. Can be switch off by the argument 'name'
			if (name) {					
				dt[, PICARRO := c(JF = 'GHG_Picarro', NO = 'Backpack_Picarro', AH = 'Ammonia_Picarro', AE = 'Ammonia_Picarro', CF = 'Isotope_Picarro')[toupper(substr(CRDS_name, 1, 2))]] # name of the Picarro
			}
			dt <- remove_columns(dt = dt, rm = rm) # see function below
			dt <- dt[st >= From_To$From & st <= From_To$To] # apply exact time range on the data.table
			make_ibts(dt = dt, ibts = ibts) # see function below
		}, error = function(e) { # closing curly brace TryCatch
				return(e$message)
			 } # closing error message
		) # closing parenthesis for TryCatch
	}) # closing parentheses for lapply 'out'
	out <- setNames(out, paste(Picarro, c(J = 'GHG_Picarro', N = 'Backpack_Picarro', A = 'Ammonia_Picarro', C = 'Isotope_Picarro')[toupper(substr(Picarro, 1, 1))], sep = '/'))
	if (length(out) == 1) {
		out <- out[[1]]
	}
	return(out)
}




##### check available files:
check_files <- function(files_all, mult, h5) {
	if (length(files_all) == 0) {
		if (!h5) {
			stop('There are no .dat Picarro files in your chosen directory. Chose a different directory. In case you try to read in .h5 files, set "h5 = TRUE".')
		} else {
			stop('There are no .h5 Picarro files in your chosen directory. Chose a different directory. In case you try to read in .dat files, set "h5 = FALSE" (default).')
		}
	}
	# the oldest backpack Picarro has the same name as another backpack Picarro but different column names. This is checked by reading in the entire string
	Picarro <- unique(sub('^([[:alnum:]]+)[-].*', '\\1', basename(files_all))) # check if the files are from the same Picarro.
	if ('Nomads4066' %in% Picarro) {
		out1 <-	grep('Nomads4066', basename(files_all), value = TRUE)
		out2 <- paste('Nomads4066', unique(sub(".*[\\._]([^-_]+)[-_.].*", "\\1", out1)), sep = '.*')
		Picarro <- c(Picarro[Picarro != 'Nomads4066'], out2)
	}
	if (length(Picarro) == 1 | (length(Picarro) > 1 & mult)) {
		run_function <- TRUE
	} else if (length(Picarro) > 1) {
		prompt_text <- paste0("Files from the following Picarro models were detected: ", paste(Picarro, collapse = ', '), ".\nDo you wanna read in data from different Picarros? (Y/N).\nIn case you renamed your files, use renamed = TRUE.")
		cat(prompt_text, '\n')
		answer <- readline(prompt = "")
		if (toupper(answer) %in% c('Y', 'YES')) {
			run_function <- TRUE
		} else {
			message('No data were loaded.')
			run_function <- FALSE
		} 
	}	else {
		run_function <- FALSE
	}
	list(run_function = run_function, Picarro = Picarro)
}


##### error massage in case dt is empty:
is_empty <- function(dt, files, h5, tz, From, To) {
	if (nrow(dt) == 0) {
		To_end <- end_time(files, h5, tz = tz)
		if (From > To | To_end < From) {
	    stop(paste0("Please change either your 'From' and/or 'To' time. The avilable data spans from '", files[1, datetime], "' to '", To_end, "'."))
	  } else {
			stop(paste0("The data.table is empty. A reason might be that the time given in the name strings of the Picarro files e.g. '", sub(".*/","", files[datetime >= (From - 86400), path][.N]), "' is not in the same time zone than the time zone you chosed (", tz, "). Easiest way is to extend your 'From' or 'To' in the correct direction."))
		}
	}
}


##### open last file to read out time stamp:
end_time <- function(files, h5, tz) {
	if (!h5) {
		last_file <- suppressWarnings(fread(files[.N, path]))
	} else {
		library(rhdf5)
		open_h5_last <- H5Fopen(files[.N, path])
		last_file <- data.table(h5read(open_h5_last, h5ls(open_h5_last)$name, bit64conversion = 'double'))
		H5Fclose(open_h5_last)
	}
	# last time of the last file
	To_end <- make_st(last_file[.N, ], tz = tz)[, st]
	To_end
}


##### time range definition:
def_From_To <- function(files, From, To, tz, h5) {
	# Define start time
	if (is.null(From)) {
		From <- files[1, datetime]
	} else {
		From <- convert_date(From, tz = tz)
	}
	# Define end time
	if (is.null(To)) {
		To <- end_time(files, h5, tz = tz)
  } else {
    To <- convert_date(To, tz = tz)
  }
  ## error messages
  if (is.na(From) | is.na(To)) {
  	suppressWarnings(stop("Please enter a valid start and end time e.g. in the format '13.12.2024 13:12:00'."))
	}
  list(From = From, To = To)
}


##### make st column in the correct time
make_st <- function(dt, tz) {
	if ('EPOCH_TIME' %in% colnames(dt)) { 
		dt[, st := as.POSIXct(EPOCH_TIME, origin = '1970-01-01', tz = tz)] 
	} else if ('time' %in% colnames(dt)) {
		dt[, st := as.POSIXct(time, origin = '1970-01-01', tz = tz)]
	}	else {
		dt[, st := as.POSIXct(timestamp / 1E3, origin = '0001-01-01', tz = tz)]
	}
}


##### remove columns:
remove_columns <- function(dt, rm) {
  cols_to_exclude <- c('DATE', 'TIME', 'FRAC_DAYS_SINCE_JAN1', 'FRAC_HRS_SINCE_JAN1', 'EPOCH_TIME', 'JULIAN_DAYS', 'timestamp')
  if (rm) {
    dt[, c('st', setdiff(names(dt), c('st', cols_to_exclude))), with = FALSE]
  } else {
    setcolorder(dt, 'st')
  }
}


##### Make ibts:
make_ibts <- function(dt, ibts) {
	if (ibts) {
	 	library(ibts)
		# Create et column using shift and replace last value with NA
		dt[, et := shift(st, type = 'lead')]
		# remove rows that have NA in st or et
		dt_complete <- dt[complete.cases(dt[, c("et", "st")]), ]
		# Convert the data.table to ibts class
		Picarro_ibts <- as.ibts(dt_complete, st = 'st')
		# Return the ibts object
		return(Picarro_ibts)
	} else {
		return(dt)
	}
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


### Things that could be implemented:
# - Automatic detection of device based on column names in case file names were changed
# - implement meta data routine for h5 files in case those were renamed
# - implement ibts argument/routine for all cases
# - split the functions in different functions as it is most of the time the same. Less code and a better overview 
# - the renamed argument could be improved by detection of a date in the string.