# Use this script to add tables that were gathered before the database was 
# created

csv_files <- list.files(here::here("data"), pattern = ".csv", full.names = TRUE)
csv_files <- csv_files[2:25]
csv_files

csv_list <- map(csv_files, ~read_csv(.x))

shorter_csv_files <- list.files(here::here("data"), pattern = ".csv", full.names = FALSE)
shorter_csv_files <- shorter_csv_files[2:25]
shorter_csv_files

shorter_csv_files <- str_remove(shorter_csv_files, ".csv")

con <- dbConnect(RSQLite::SQLite(), "data/WoWAH_database.sqlite")
walk2(csv_list, shorter_csv_files, function(.x, .y) {
   dbWriteTable(con, .y, .x)
})



dbWriteTable(con, "item_name", item_df, overwrite = TRUE)