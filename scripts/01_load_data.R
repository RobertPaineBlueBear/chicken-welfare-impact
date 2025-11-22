### Robert Paine


### LIBRARIES

library(readxl)
library(haven)
library(tidyverse)
library(dplyr)
library(readxl)
library(openxlsx)
library(janitor)

### IMPORT

fndds <- read_excel('/Users/robpaine/chicken-welfare-impact/data/raw/2021-2023 FNDDS At A Glance - FNDDS Ingredients.xlsx')
nhanes <- read_xpt('/Users/robpaine/chicken-welfare-impact/data/raw/DR1IFF_I.xpt')

colnames(fndds) <- fndds[1, ]
fndds <- fndds[-1, ]
fndds <- clean_names(fndds)

fndds$ingredient_weight_g <- as.numeric(fndds$ingredient_weight_g)
fndds$food_code <- as.numeric(fndds$food_code)
nhanes$SEQN <- as.numeric(nhanes$SEQN)

animal_products <- list(
  chicken = c("chicken", "poultry"),
  beef = c("beef", "veal", "cattle"),
  pork = c("pork", "bacon", "ham", "sausage.*pork"),
  turkey = c("turkey"),
  eggs = c("egg", "yolk", "albumin"),
  milk = c("milk", "cream", "cheese", "yogurt", "butter", "ice cream", "dairy")
)

classify_ingredient <- function(ingredient_desc) {
  ingredient_desc <- tolower(ingredient_desc)
  
  for (product_name in names(animal_products)) {
    patterns <- animal_products[[product_name]]
    if (any(sapply(patterns, function(p) grepl(p, ingredient_desc, ignore.case = TRUE)))) {
      return(product_name)
    }
  }
  return(NA)
}

fndds$animal_product <- sapply(fndds$ingredient_description, classify_ingredient)

fndds_animals <- fndds[!is.na(fndds$animal_product), ]

animal_per_food_long <- fndds_animals %>%
  group_by(food_code, main_food_description, animal_product) %>%
  summarise(
    animal_grams = sum(ingredient_weight_g, na.rm = TRUE),
    .groups = "drop"
  )

animal_per_food <- animal_per_food_long %>%
  pivot_wider(
    id_cols = c(food_code, main_food_description),
    names_from = animal_product,
    values_from = animal_grams,
    values_fill = 0
  ) %>%
  rename_with(~paste0(., "_g"), .cols = any_of(names(animal_products)))

animal_per_food <- animal_per_food %>%
  mutate(
    total_animal_g = rowSums(select(., ends_with("_g")), na.rm = TRUE)
  )

weighted_median <- function(x, w) {
  valid <- !is.na(x) & !is.na(w)
  x <- x[valid]
  w <- w[valid]
  
  if (length(x) == 0) return(NA)
  
  ord <- order(x)
  x <- x[ord]
  w <- w[ord]
  
  cumsum_w <- cumsum(w)
  total_w <- sum(w)
  
  median_idx <- which(cumsum_w >= total_w / 2)[1]
  
  return(x[median_idx])
}

nhanes_servings <- nhanes %>%
  group_by(DR1IFDCD) %>%
  summarise(
    n_servings = n(),
    median_serving_g = weighted_median(DR1IGRMS, WTDRD1),
    mean_serving_g = weighted.mean(DR1IGRMS, WTDRD1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  rename(food_code = DR1IFDCD)

foods_complete <- animal_per_food %>%
  inner_join(nhanes_servings, by = "food_code") %>%
  filter(n_servings >= 5)  # Only keep foods with at least 5 servings in NHANES

# Calculate median animal product consumed per serving
# (scale from 100g base to actual median serving)
animal_cols <- names(foods_complete)[grepl("_g$", names(foods_complete)) & 
                                       !grepl("total|serving", names(foods_complete))]

for (col in animal_cols) {
  new_col <- paste0("median_", col, "_per_serving")
  foods_complete[[new_col]] <- (foods_complete[[col]] / 100) * foods_complete$median_serving_g
}

foods_complete <- foods_complete %>%
  mutate(
    median_total_animal_g_per_serving = (total_animal_g / 100) * median_serving_g
  )

foods_complete <- foods_complete %>%
  select(
    food_code,
    main_food_description,
    n_servings,
    median_serving_g,
    mean_serving_g,
    everything()
  )

foods_complete <- foods_complete[foods_complete$median_chicken_g_per_serving > 0, ]
write.csv(foods_complete, "chickenfoods.csv", row.names = FALSE)

foods_complete <- foods_complete[foods_complete$main_food_description %in% c(
                                   "Chicken breast, grilled without sauce, skin not eaten",
                                   "Chicken drumstick, baked, broiled, or roasted, skin not eaten, from raw",
                                   "Chicken thigh, baked, broiled, or roasted, skin not eaten, from raw",
                                   "Chicken wing, baked, broiled, or roasted, from raw",
                                   "Chicken patty, breaded",
                                   "Chicken nuggets, from fast food",
                                   "Chicken tenders or strips, NFS",
                                   "Chicken, prepackaged or deli, luncheon meat",
                                   "Chicken curry",
                                   "Orange chicken",
                                   "Pot pie, chicken",
                                   "Soup, chicken",
                                   "Gravy, poultry",
                                   "Fajita, chicken",
                                   "Rice, fried, with chicken",
                                   "Pasta with cream sauce and poultry, restaurant",
                                   "Soup, chicken noodle"), ]

saveRDS(foods_complete, "data/processed/foods_complete.rds")

#### WFP

wfp <- read_csv('/Users/robpaine/chicken-welfare-impact/data/raw/WFP Estimates of Time in Pain - Broilers (Farm) - Time in Pain per Harm.csv')

wfp$pain_hours <- ifelse(wfp$`Time Unit` == "seconds", 
                         wfp$`Mean time in pain (spent by 'average' population member, takes harm prevalence into account)` / 60,
                         wfp$`Mean time in pain (spent by 'average' population member, takes harm prevalence into account)`)

wfp <- wfp[wfp[ , 2] == "Conventional", ]

wfp <- wfp %>%
  dplyr::group_by(Challenge) %>%
  dplyr::summarize(
    total_hours = sum(pain_hours)
  )

wfp <- wfp %>%
  add_row(
    Challenge = "Lameness",
    total_hours = sum(wfp$total_hours[grepl("Gait Score", wfp$Challenge)])
  )

wfp <- wfp %>%
  add_row(
    Challenge = "Ascites",
    total_hours = sum(wfp$total_hours[grepl("Ascites", wfp$Challenge)])
  )

wfp <- wfp %>%
  add_row(
    Challenge = "Peritonitis",
    total_hours = sum(wfp$total_hours[grepl("Peritonitis", wfp$Challenge)])
  )

wfp <- wfp[!grepl("Gait Score", wfp$Challenge), ]
wfp <- wfp[!wfp$Challenge %in% c("Ascites (fatal)", "Ascites (non-fatal)", "Chronic Peritonitis", "Acute Peritonitis"), ]

saveRDS(wfp, '/Users/robpaine/chicken-welfare-impact/data/processed/welfare-footprint-chicken-harms.rds')






