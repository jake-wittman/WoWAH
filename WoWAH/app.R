#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)
library(dbplyr)
library(RSQLite)
library(scales)
library(lubridate)
library(data.table)
library(dtplyr)

conflicted::conflict_prefer("wday", "lubridate")
conflicted::conflict_prefer("filter", "dplyr")

wowdb <- dbConnect(RSQLite::SQLite(), "data/WoWAH_database.sqlite")
wow_tbls <-dbListTables(wowdb)
item_db <- tbl(wowdb, "item_name")
ah_tbls <- map(wow_tbls[str_detect(wow_tbls, pattern = "Malfurion")], 
               function(.x) {
                   tbl(wowdb, .x) %>% 
                       left_join(., item_db, by = "id", copy = TRUE) %>% 
                       filter(name == "Widowbloom") %>% 
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


# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("World of Warcraft Auction House Data - Malfurion NA"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            selectizeInput("items",
                           "Items to view",
                        choices = unique(ah_tbls$name),
                        selected = 'Widowbloom')
        ),

        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("low_price_ts")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    low_price_df <- reactive({
        ah_tbls %>% 
            filter(name %in% input$items) %>%
            group_by(timestamp, name) %>% 
            filter(cost_g == min(cost_g, na.rm = TRUE))
    })

    output$low_price_ts <- renderPlot({
        ggplot(low_price_df(), aes(x = timestamp, y = cost_g)) +
            geom_point() +
            geom_smooth()
        
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
