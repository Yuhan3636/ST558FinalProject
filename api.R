# api.R
#* @apiTitle Diabetes Risk API

library(plumber)
library(tidyverse)
library(caret)
library(conflicted)

conflict_prefer("filter", "dplyr")
conflict_prefer("lag",    "dplyr")

# 1. Load and prep data
diab <- read_csv("diabetes_012_health_indicators_BRFSS2015.csv", show_col_types = FALSE) %>%
  filter(Diabetes_012 != 2) %>%    # drop pre-diabetes
  mutate(
    Diabetes = factor(Diabetes_012, levels = c(0,1), labels = c("No","Yes"))
  )

# 2. Refit the best logistic model on all data
best_glm <- train(
  Diabetes ~ PhysActivity + HighBP + BMI + HighChol,
  data      = diab,
  method    = "glm",
  family    = "binomial",
  metric    = "logLoss",
  trControl = trainControl(method = "none")
)

# 3. Compute defaults
defaults <- list(
  PhysActivity = diab$PhysActivity %>% table() %>% which.max() %>% names(),
  HighBP       = diab$HighBP       %>% table() %>% which.max() %>% names(),
  HighChol     = diab$HighChol     %>% table() %>% which.max() %>% names(),
  BMI          = mean(diab$BMI, na.rm = TRUE)
)

#* API info: author name & GitHub Pages URL
#* @get /info
function(){
  list(
    name = "Yuhan Hu",
    site = "https://github.com/Yuhan3636/ST558FinalProject.git"
  )
}

#* Predict probability of diagnosed diabetes (Yes)
#* @param PhysActivity Default: `r defaults$PhysActivity`
#* @param HighBP       Default: `r defaults$HighBP`
#* @param HighChol     Default: `r defaults$HighChol`
#* @param BMI          Default: `r round(defaults$BMI,2)`
#* @post /pred
function(PhysActivity = defaults$PhysActivity,
         HighBP       = defaults$HighBP,
         HighChol     = defaults$HighChol,
         BMI          = defaults$BMI){
  
  # 1) Ensure incoming predictor values are character strings
  PhysActivity <- as.character(PhysActivity)
  HighBP       <- as.character(HighBP)
  HighChol     <- as.character(HighChol)
  
  # 2) Build a tibble with exactly the factor levels used in training
  newdata <- tibble(
    PhysActivity = factor(PhysActivity, levels = levels(diab$PhysActivity)),
    HighBP       = factor(HighBP,       levels = levels(diab$HighBP)),
    HighChol     = factor(HighChol,     levels = levels(diab$HighChol)),
    BMI          = as.numeric(BMI)
  )
  
  # 3) Predict and return probability
  prob_yes <- predict(best_glm, newdata = newdata, type = "prob")$Yes
  list(probability_of_diabetes = prob_yes)
}
