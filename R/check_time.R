

check_time <- function(data, duration_threshold_lower, duration_threshold_upper){
  ## Input sanitation
  if(!is.data.frame(data))stop("data needs to be a dataframe!")
  if(!("start" %in% names(data)))stop("data needs to have a column called 'start' for this function work")
  if(!("end" %in% names(data)))stop("data needs to have a column called 'end' for this function work")
  ## pick apart the date and time parts of the start and end columns and identify those survey completed on different days
  df_col_separated <- data %>% separate(start, c("start_date", "start_time"), "T") %>%
    separate(end, c("end_date", "end_time"), "T")
  df_col_separated$days_diff <- difftime(as.POSIXct(df_col_separated$end_date), as.POSIXct(df_col_separated$start_date), units="days")
  same_date <- df_col_separated[((as.numeric(df_col_separated$days_diff))==0),]
  different_date <- df_col_separated[((as.numeric(df_col_separated$days_diff))>0),]
  
  #Making time into numeric so that calculations can be done
  same_date$start_time <- round(as.difftime(same_date$start_time, units = "mins"),2)
  same_date$end_time <- round(as.difftime(same_date$end_time, units = "mins"),2)
  same_date$duration_min <- as.numeric(same_date$end_time-same_date$start_time)
  same_date$time_short_flag <- ifelse(same_date$duration_min<=duration_threshold_lower,1,0)
  same_date$time_long_flag <- ifelse(same_date$duration_min>=duration_threshold_upper,1,0)
  
  ## Add Issue column
  same_date <- mutate(same_date, issue_type = ifelse((time_short_flag >= 1), "form duration too short", 
                                                     ifelse((time_long_flag >= 1), "form duration too long", "form duration is ok")))
  
  
  ## seperate the filtering into those surveys that are too long and those that are too short
  #too_short <- same_date %>% dplyr::filter(time_short_flag == 1)
  #too_short$issue_type <- "form duration too short"
  #too_long <- same_date %>% dplyr::filter(time_long_flag == 1)
  #too_long$issue_type <- "form duration too long"

  
  ## bind and reformat the two culprits !!!
  #time_problems <- rbind(too_short, too_long)
  
  time_problems <- dplyr::filter(same_date, issue_type != "form duration is ok")
  time_problems <- mutate(time_problems, status_name= ifelse(status == "yes", "refugee", "host community"))
  
  if(nrow(same_date)>=1){
    
    colnames(time_problems)[grep("uuid", colnames(time_problems))] <- "uuid"
    time_problems$enumerator <- time_problems$enumerator
    time_problems$sub_county_div <- time_problems$sub_county_div
    time_problems$status_name <- time_problems$status_name
    time_problems$variable <- "Completion Duration (min)"
    time_problems$has_issue <- "TRUE"
    time_problems$issue_type <- time_problems$issue_type
    
    
  } else {
    
    time_problems$enumerator <- as.character()
    time_problems$sub_county_div <- as.character()
    time_problems$status_name <- as.character()
    time_problems$variable <- as.character()
    time_problems$has_issue <- as.character()
    time_problems$issue_type <- as.character()
    
    }

  
  time_grab <- time_problems %>% dplyr::select(uuid, enumerator, district_name, refugee_settlement, status_name, duration_min, variable,	has_issue,	issue_type)
  names(time_grab) <- c("uuid", "enumerator", "area", "settlemet", "status",	"value",	"variable",	"has_issue",	"issue_type")
  return(time_grab)
}
