#Retrieves data for the desktop stuff we care about, drops it in the aggregate-datasets directory.
#Should be run on stat1002, /not/ on the datavis machine.
source("common.R")

main <- function(date = NULL, table = "Search_12057910"){
  
  #Get data and format
  data <- query_func(fields = "
                    SELECT timestamp,
                    CASE event_action WHEN 'click-result' THEN 'clickthroughs'
                    WHEN 'session-start' THEN 'search sessions'
                    WHEN 'impression-results' THEN 'Result pages opened'
                    WHEN 'submit-form' THEN 'Form submissions' END AS action,
                    event_clickIndex AS click_index,
                    event_numberOfResults AS result_count,
                    event_resultSetType as result_type,
                    event_timeOffsetSinceStart AS time_offset,
                    event_timeToDisplayResults AS load_time
                    ",
                     date = date,
                     table = table,
                     conditionals = "event_action IN ('click-result','session-start','impression-results', 'submit-form')")
  data$timestamp <- as.Date(olivr::from_mediawiki(data$timestamp))
  
  #Generate aggregates and save
  results <- data[,j = list(events = .N), by = c("timestamp","action")]
  conditional_write(results, file.path(base_path, "desktop_event_counts.tsv"))
  
  #Generate load time data and save that
  load_times <- data[data$action == "Result pages opened",{
    output <- numeric(3)
    quantiles <- quantile(load_time,probs=seq(0,1,0.01))
    output[1] <- round(median(load_time))
    output[2] <- quantiles[95]
    output[3] <- quantiles[99]
    
    output <- data.frame(t(output))
    names(output) <- c("Median","95th percentile","99th Percentile")
    output
  }, by = "timestamp"]
  conditional_write(load_times, file.path(base_path, "desktop_load_times.tsv"))
  return(invisible())
}

main()
q(save = "no")