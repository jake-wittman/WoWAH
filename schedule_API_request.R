library(taskscheduleR)

taskscheduler_create(
   taskname = "scrape_WoW_AH",
   rscript = "F:/Documents/WoWAH/render_code.R",
   schedule = "HOURLY",
   starttime = "02:05"
)

# If I need to delete the task for some reason
taskscheduler_delete(taskname = "scrape_WoW_AH")
