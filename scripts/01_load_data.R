### Robert Paine
###
### 



#LIBRARIES
library(readxl)

#IMPORT
fndds <- read_excel('/Users/robpaine/chicken-welfare-impact/data/raw/2021-2023 FNDDS At A Glance - FNDDS Ingredients.xlsx')

#CLEANUP
colnames(fndds) <- fndds[1, ]
fndds <- fndds[-1, ]
fndds <- clean_names(fndds)

#FILTERTOCHICKEN
fndds_chicken <- fndds[grepl("chicken", fndds$ingredient_description, ignore.case = TRUE), ]

#AGGREGATECHICKENINGREDIENTS
chicken_per_food <- aggregate(
  ingredient_weight_g ~ food_code + main_food_description,
  data = fndds_chicken,
  FUN = function(x) sum(as.numeric(x))  # Convert to numeric and sum
)

#SAVE
saveRDS(chicken_per_food, "/Users/robpaine/chicken-welfare-impact/data/processed/chicken_per_food.rds")

cat("✓ Processed", nrow(chicken_per_food), "chicken foods\n")