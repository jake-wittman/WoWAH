library(taskscheduleR)

taskscheduler_create(taskname = "scrapeAH",
                     rscript = here::here("scripts", "scrape_AH.R"),
                     schedule = "HOURLY",
                     startdate = "21/05/2021")

taskscheduler_delete(here::here(""))