library(targets)


# Set options
options(tidyverse.quiet = TRUE)

# Targets options
# Packages = packages to load before building targets
tar_option_set(
   packages = c("tidyverse")
)

list(
   tar_target(db, 'data/WoWAH_database.sqlite', format = 'file'),
   tar_target(ah_ts, getTimeSeries(db))
)