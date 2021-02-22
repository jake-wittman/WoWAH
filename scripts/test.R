library(httr)
library(jsonlite)
library(tidyverse)
library(curlconverter)
library(glue)

source(here::here("keys.R"))

curl_request <- glue("curl -u {client_id}:{client_secret} -d grant_type=client_credentials https://us.battle.net/oauth/token")

request_token <- straighten("curl -u a9b3d235c60e4580825b9bf244a83d5a:Mre8HEYKgcaiPpQ8gBq6AxbI8vSpeopf -d grant_type=client_credentials https://us.battle.net/oauth/token") %>% 
   make_req()

token <- content(request_token[[1]](), as = "parsed")$access_token



# Able to get stuff when I generate a url on the Blizzard webpage
# This gets all US realms I think (or maybe just the ones in EST?)
realm_json <- GET(glue("https://us.api.blizzard.com/data/wow/search/connected-realm?namespace=dynamic-us&locale=en_US&status.type=UP&realms.timezone=America%2FNew_York&orderby=id&_page=1&access_token={token}"))

realm_id <- fromJSON(content(realm_json, as="text"))
realm_names <- realm_id$results$data$realms

lapply(realm_names, function(.x) {
   name <- .x$name$en_U
   id <- .x$id
   c(id, name)
}
)

# Use this to get info on ID for a specific realm
# I suspect that the first id is the one that should be used if multiple realms have been connected
realm_name <- "malfurion"
specific_realm <- GET(glue("https://us.api.blizzard.com/data/wow/search/connected-realm?namespace=dynamic-us&realms.name.en_US={realm_name}&access_token={token}"))
results <- fromJSON(content(specific_realm, as = "text"))
results$results$data$realms[[1]]$id
results$results$data$realms[[1]]$name$en_US




# 60 is id for stormrage.
# Id for Malf is 1132, but doesn't seem to return anything...
# 1175 is the id for Trollbane. I'm guessing because Trollbane is the first listed,
# the ID for trollbane is used as the identifer for all the connected realms
id <- 1175

AH_request <- GET(glue("https://us.api.blizzard.com/data/wow/connected-realm/{id}/auctions?namespace=dynamic-us&locale=en_US&access_token={token}"))
AH_content <- fromJSON(content(AH_request, as = "text"))
# Create df of auction data
AH_df <- as_tibble(AH_content$auctions$item) %>% 
   mutate(id = as.character(id))




