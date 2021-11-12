#' @title Read and combine tables from database of auction house items
#' @description Hourly auction house data are stored as an individual table in
#' a database.This function pulls these tables into one data frame.
#' @export
#' @return A data frame of auction house data
#' @param database.path Relative path to the database
#' @param date.start Earliest date from which to get data. Default value is NA, 
#' which results in oldest available data.
#' @param date.end Latest date from which to get data. Default value is NA,
#' which results in most recently available data.
#' @param num.hours Specify the number of 
#' @examples 
#' library(dbplyr)
#' library(RSQLite)
#' library(lubridate)
#' library(tidyverse)
getTimeSeries <- function(database.path, date.start = NA, date.end = NA){
   wowdb <- dbConnect(RSQLite::SQLite(), database.path)
   wow_tbls <-dbListTables(wowdb)
   item_db <- tbl(wowdb, "item_name")
   ah_tbls <- map(wow_tbls[str_detect(wow_tbls, pattern = "Malfurion")], 
                  function(.x) {
                     tbl(wowdb, .x) %>% 
                        left_join(., item_db, by = "id", copy = TRUE) %>% 
                        collect() %>% 
                        mutate(across(starts_with("collection"), ~as.numeric(.x)))
                  }) %>% 
      bind_rows(.) 
   ah_tbls <- ah_tbls %>% 
      # Engineer some features
      mutate(
         timestamp = make_datetime(
            year = collection_year,
            month = collection_month,
            day = collection_day,
            hour = collection_hour,
            min = 5L,
            tz = "US/Pacific"
         ),
         day_of_week = wday(timestamp, label = TRUE, abbr = TRUE),
         weekend = case_when(day_of_week %in% c("Sat", "Sun") ~ 1,
                             TRUE ~ 0)
      ) 
   
}