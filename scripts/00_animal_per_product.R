library(janitor)
library(tidyverse)

df <- data.frame(
  animal = character(),
  prod_lbs = numeric(),
  prod_head = numeric()
)

chicken <- read_csv("/Users/robpaine/chicken-welfare-impact/data/raw/Chicken_NASS_Data.csv")
chicken <- clean_names(chicken)

chicken_row <- data.frame(
  animal = "meat_chicken",
  prod_lbs = chicken$chickens_broilers_production_measured_in_lb_b_value_b[1],
  prod_head = chicken$chickens_broilers_production_measured_in_head_b_value_b[1]
)

df <- rbind(df, chicken_row)
df$yield_per_animal_lbs <- df$prod_lbs/df$prod_head
df$yield_per_animal_kg <- df$yield_per_animal_lbs * 0.4535924

df$years_producing_product[1] <- 1

###https://www.nationalchickencouncil.org/about-the-industry/statistics/u-s-broiler-performance/ 

df$market_age[1] <- 47.4
df$dressing_pct[1] <- .75
df$carcass_to_edible_pct[1] <- .74

###https://livestock.extension.wisc.edu/articles/bird-breakdown-exploring-yields-and-cuts-of-poultry/
###https://www.ams.usda.gov/sites/default/files/media/QAD%20635%20-%20Standard%20Yield.pdf

df$carcass_weight_kg <- df$yield_per_animal_kg * df$dressing_pct
df$edible_kg <- df$carcass_weight_kg * df$carcass_to_edible_pct

df$life_per_kg <- 1/df$edible_kg

df <- df[ ,c(1, 12)]

saveRDS(df, "/Users/robpaine/chicken-welfare-impact/data/processed/animal_per_kg.rds")