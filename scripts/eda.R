library(tidyverse)
library(mgcv)

ah_dat <- read_csv(here::here("data/AH_data.csv"),
                   col_types = c("dddfddcdT")) %>% 
   # Get rid of weird NA id values
   filter(!is.na(id)) #%>% 
   # I'm not sure what the unit_price column is so I'm just going to work with buyout
   filter(!is.na(buyout))
item_db <- read_csv(here::here("data/item_db.csv"))

dat <- left_join(ah_dat, item_db, by = c("item_id" = "data.id")) %>% 
   rename(item_class = data.item_class.name.en_US,
          item_type = data.item_subclass.name.en_US,
          item_name = data.name.en_US,
          vendor_sell = data.sell_price,
          vendor_price = data.purchase_price) %>% 
   mutate(buyout_g = buyout / 10000) %>% 
   select(item_name, buyout, buyout_g, unit_price, everything())


dat %>% 
   filter(str_detect(item_name, "Elethium Ore")) %>% 
   ggplot(aes(x = date_time, y = unit_price / 1000, group = item_name)) +
   geom_point() +
   geom_smooth() +
   facet_wrap(~item_name, scales = "free")

dat %>% 
   filter(str_detect(item_name, "Marrowroot")) %>% 
   group_by(item_name) %>% View()
   summarise(mean = mean(buyout, na.rm = TRUE),
             min = min(buyout, na.rm = TRUE),
             max = max(buyout, na.rm = TRUE))

dat %>% 
   filter(str_detect(item_name, "Widowbloom")) %>% 
   group_by(item_name, date_time) %>% 
   summarise(mean = mean(buyout, na.rm = TRUE),
             min = min(buyout, na.rm = TRUE),
             ) %>% 
   ggplot(aes(x = date_time, y = min, group = item_name)) +
   geom_point() +
   geom_smooth() +
   facet_wrap(~item_name, scales = "free")
