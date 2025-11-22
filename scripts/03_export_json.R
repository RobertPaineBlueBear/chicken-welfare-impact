###
###
###



library(jsonlite)


chicken_per_food <- readRDS("/Users/robpaine/chicken-welfare-impact/data/processed/chicken_per_food_w_impacts.rds")
welfare_prevalence <- readRDS("/Users/robpaine/chicken-welfare-impact/data/processed/welfare_prevalence.rds")

food_impacts_list <- vector("list", nrow(chicken_per_food))

for (i in 1:nrow(chicken_per_food)) {
  
  # Get welfare harms for this food
  welfare_harms <- list()
  
  for (condition in colnames(welfare_prevalence)) {
    animals_affected_col <- paste0(condition, "_per_serving")
    
    # Only include if column exists
    if (animals_affected_col %in% colnames(chicken_per_food)) {
      welfare_harms[[length(welfare_harms) + 1]] <- list(
        condition = gsub("_", " ", condition),  # Make readable
        hours_per_life = welfare_prevalence[[condition]][1],
        hours_per_serving = chicken_per_food[[animals_affected_col]][i]
      )
    }
  }
  
  # Create food entry
  food_impacts_list[[i]] <- list(
    food_code = chicken_per_food$food_code[i],
    food_name = chicken_per_food$main_food_description[i],
    chicken_grams = chicken_per_food$median_chicken_g_per_serving[i],
    lives_per_serving = chicken_per_food$lives_per_serving[i],
    welfare_harms = welfare_harms
  )
}

# Export to JSON
write_json(
  food_impacts_list,
  "/Users/robpaine/chicken-welfare-impact/output/chicken_food_impacts.json",
  pretty = TRUE,
  auto_unbox = TRUE
)

cat("✓ Exported", length(food_impacts_list), "chicken foods to JSON!\n")
cat("File location: output/chicken_food_impacts.json\n")
