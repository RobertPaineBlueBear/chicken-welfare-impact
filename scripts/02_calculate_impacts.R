###
###
###

chicken_per_food <- readRDS("/Users/robpaine/chicken-welfare-impact/data/processed/foods_complete.rds")
welfare_prevalence <- readRDS("/Users/robpaine/chicken-welfare-impact/data/processed/welfare-footprint-chicken-harms.rds")
animal_per_kg <- readRDS("/Users/robpaine/chicken-welfare-impact/data/processed/animal_per_kg.rds")

welfare_prevalence <- as.data.frame(t(welfare_prevalence))
colnames(welfare_prevalence) <- welfare_prevalence[1, ]
welfare_prevalence <- welfare_prevalence[-1, ]
welfare_prevalence[1, ] <- as.numeric(welfare_prevalence[1, ])

#SETPRODUCTIVITYINFO
Edible_Weight_Per_Chicken_KG <- animal_per_kg[1, 2]
Edible_Weight_Per_Chicken_G <- Edible_Weight_Per_Chicken_KG * 1000
Chicken_Per_Gram <- 1 / Edible_Weight_Per_Chicken_G

calculate_chicken_impact <- function(chicken_grams, Chicken_Per_Gram) {
  lives_per_serving <- chicken_grams * Chicken_Per_Gram
  return(lives_per_serving)
}

chicken_per_food$lives_per_serving <- sapply(
  chicken_per_food$median_chicken_g_per_serving,
  function(x) calculate_chicken_impact(x, Chicken_Per_Gram)
)
chicken_per_food$lives_per_serving <- as.numeric(chicken_per_food$lives_per_serving)
class(chicken_per_food$lives_per_serving)
class(welfare_prevalence[1, ])

### Add new column for impacts per serving
for (i in colnames(welfare_prevalence)) {
  new_col_name <- paste0(i, "_per_serving")
  chicken_per_food[[new_col_name]] <- chicken_per_food$lives_per_serving * as.numeric(welfare_prevalence[[i]][1])
}

### SaveRDS
saveRDS(chicken_per_food, "/Users/robpaine/chicken-welfare-impact/data/processed/chicken_per_food_w_impacts.rds")
saveRDS(welfare_prevalence, "/Users/robpaine/chicken-welfare-impact/data/processed/welfare_prevalence.rds")

cat("✓ Calculated impacts for", nrow(chicken_per_food), "foods\n")



