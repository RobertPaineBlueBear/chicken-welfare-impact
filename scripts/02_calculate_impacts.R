###
###
###

chicken_per_food <- readRDS("/Users/robpaine/chicken-welfare-impact/data/processed/chicken_per_food.rds")

#SETPRODUCTIVITYINFO
Edible_Weight_Per_Chicken_KG <- 1.0764193
Edible_Weight_Per_Chicken_G <- Edible_Weight_Per_Chicken_KG * 1000
Chicken_Per_Gram <- 1 / Edible_Weight_Per_Chicken_G

calculate_chicken_impact <- function(chicken_grams, Chicken_Per_Gram) {
  lives_per_serving <- chicken_grams * Chicken_Per_Gram
  return(lives_per_serving)
}

chicken_per_food$lives_per_serving <- sapply(
  chicken_per_food$ingredient_weight_g,
  function(x) calculate_chicken_impact(x, Chicken_Per_Gram)
)

welfare_prevalence <- data.frame(
  Lameness_GS1 = 32.54,
  Lameness_GS2 = 215.9, 
  Lameness_GS3 = 82.23,
  Lameness_GS4  = 35,
  Lameness_GS4_Culled = 1.801333333,
  Lameness_GS5 = 7.8,
  Lameness_GS5_Culled = 3.441333333,
  Ascites_non_fatal = 22.4,
  Ascites_fatal = 5.889455556,
  Sudden_Death = 0.000330556,
  Heat_Stress_Wk3 = 4.2,
  Heat_Stress_Wk4 = 6.3,
  Heat_Stress_Wk5 = 10.85,
  Heat_Stress_Wk6 = 17.5,
  Breeder_Hunger = 46.58,
  Breeder_Acute_Peritonitis_fatal = 0.242566667,
  Breeder_Chronic_Peritonitis = 6.188,
  Foraging_Exploration_Deprivation = 76.69,
  Perching_Deprivation = 63,
  Dustbathing_Deprivation = 70
)

### Add new column for impacts per serving
for (i in colnames(welfare_prevalence)) {
  new_col_name <- paste0(i, "_per_serving")
  chicken_per_food[[new_col_name]] <- chicken_per_food$lives_per_serving * welfare_prevalence[[i]][1]
}

### SaveRDS
saveRDS(chicken_per_food, "/Users/robpaine/chicken-welfare-impact/data/processed/chicken_per_food_w_impacts.rds")
saveRDS(welfare_prevalence, "/Users/robpaine/chicken-welfare-impact/data/processed/welfare_prevalence.rds")

cat("✓ Calculated impacts for", nrow(chicken_per_food), "foods\n")



