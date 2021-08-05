rmarkdown::render(input = "F:/Documents/WoWAH/scrape_AH.Rmd",
                  output_file = "F:/Documents/WoWAH/delete_me.html")
file.remove("F:/Documents/WoWAH/delete_me.html")
