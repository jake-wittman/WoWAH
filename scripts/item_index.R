library(httr)
library(jsonlite)
library(tidyverse)
library(curlconverter)
library(glue)

source(here::here("keys.R"))
# Finished(ish): Function for creating/updating item DB with item info
# TODO: Repeatedly get data from AH, probably move functions to their own script

# Initital AH scrape and build database
# Future scrapes check against database and build further as necessary
# Add timestamp for each scrape
# Remove duplicate rows from AH scrape

curl_request <- glue("curl -u {client_id}:{client_secret} -d grant_type=client_credentials https://us.battle.net/oauth/token")

request_token <- straighten("curl -u a9b3d235c60e4580825b9bf244a83d5a:Mre8HEYKgcaiPpQ8gBq6AxbI8vSpeopf -d grant_type=client_credentials https://us.battle.net/oauth/token") %>% 
   make_req()

token <- content(request_token[[1]](), as = "parsed")$access_token

# Malf realm ID
id <- 1175

AH_request <- GET(glue("https://us.api.blizzard.com/data/wow/connected-realm/{id}/auctions?namespace=dynamic-us&locale=en_US&access_token={token}"))
AH_content <- fromJSON(content(AH_request, as = "text"))
# Create df of auction data

AH_df <- as_tibble(AH_content$auctions) %>% 
   mutate(item_id = as.character(item$id))

# Get Item classes index an

# Items to get IDs for
id_num_vector <- unique(AH_df$item_id)[1:50]
# Turn into an OR string using the API syntax
id_char <- paste(id_num_vector, collapse = "||")
item_json <- GET(glue("https://us.api.blizzard.com/data/wow/search/item?namespace=static-us&locale=en_US&orderby=id&&_pageSize=1000&id={id_char}&_&access_token={token}"))

item_list <- fromJSON(content(item_json, as="text"), flatten = TRUE)
# Flattened json to get data frame then removed the unnecessary foreign language columns
# data.id column is the item id
item_df <- item_list$results %>% 
   select(-contains(c("GB", "ES", "DE", "RU", "KR", "BR", "FR", "TW", "IT", "CN", ignore.case = FALSE)))


# Function for determining what items I don't yet have in the data base

#' @param item.db.path File path to item database. Default is NULL. If no path
#'   is given, assumes the file does not exist. Path should be relative to
#'   project working directory
#' @param item.id Character vector of item id in auction house

item.db.path <- here::here("item_db.csv")


# Functions ---------------------------------------------------------------
item.id <- unique(AH_df$item_id)


# Helper function to chunk id vector
createChunks <- function(x, elements.per.chunk){
   # plain R version
   split(x, rep(seq_along(x), each = elements.per.chunk)[seq_along(x)])

}

updateItemDB <- function(item.db.path = NULL, item.id) {
   if (is.null(item.db.path) == FALSE) {
      # Code here to determine what item id, if any, need to be added
      db <- read_csv(here::here(item.db.path),
                     col_types = c("cdddldldcccccccc"))
      
      if (any(item.id %!in% db$data.id) == FALSE) {
         # If there are no items missing from the database, this function is done
         db
         stop("Database is complete.")
         
      } else{
         # Get the item id numbers that are not present in database already and
         # then chunk them by 50. I think 50 is the largest # I can query at once
         item_id_index <- which(item.id %!in% db$data.id)
         item_id_absent <- item.id[item_id_index]
         id_chunks <- createChunks(item_id_absent, 50)
         
      }
      

   }
   
   else {
      # Code here for building new database. Just works with the whole
      # vector of item id
      id_chunks <- createChunks(item.id, 50)
   }
   
   # Get new items, if any exist
   
   # Map over the id chunks
   new_db <- map_dfr(id_chunks, function(.x) {
      # Turn into an OR string using the API syntax
      id_char <- paste(.x, collapse = "||")
      item_json <- GET(glue("https://us.api.blizzard.com/data/wow/search/item?namespace=static-us&locale=en_US&orderby=id&&_pageSize=1000&id={id_char}&_&access_token={token}"))
      
      item_list <- fromJSON(content(item_json, as="text"), flatten = TRUE)
      
      if (length(item_list$results) == 0) {
         return(db)
         stop("Missing item id did not match any item in Blizzard query.")
      } else {
         # Flattened json to get data frame then removed the unnecessary foreign language columns
         # data.id column is the item id
         item_df <- item_list$results %>% 
            select(-contains(c("GB", "ES", "DE", "RU", "KR", "BR", "FR", "TW", "IT", "CN", ignore.case = FALSE)))
      }
      # Flattened json to get data frame then removed the unnecessary foreign language columns
      # data.id column is the item id
      item_df <- item_list$results %>% 
         select(-contains(c("GB", "ES", "DE", "RU", "KR", "BR", "FR", "TW", "IT", "CN", ignore.case = FALSE)))
   })
   
   # Prevent empty query from duplicating database
   if (identical(new_db, db) == TRUE) {
      stop("Missing item id did not match any item in Blizzard query. Database not updated. Database is likely complete.")
   }
   
   # If the database exists, update it
   if (is.null(item.db.path) == FALSE) {
      new_db <- bind_rows(db, new_db)
   }
   
   write_csv(new_db, here::here("item_db.csv"))
   
   message("Database is updated.")
   return(new_db)
   
}

updateItemDB(item.db.path = "item_db.csv", item.id = unique(AH_df$item_id))
