library(recipes)
  library(readr)       
    library(dplyr)       
      library(caret)       
        library(ggplot2)
          library(parsnip)
            library(purrr)
              library(discrim)
                library(tidyr)
                  library(lda)
                    library(VIM)
                      library(MASS)

train = read_csv("train.csv")

# ---------------------------------------------------------------------------------------------------------------------- #
# Data Manipulation:
colnames(train) = gsub("-", "_", colnames(train)) # Replacing hyphens because R can't handle those
train_clean = train[, !grepl("Season", names(train))]
train_clean$sii = factor(train_clean$sii) # Making sure `sii` is a factor with 4 levels (plus extra level for NAs later)


train_clean$sii = factor(train_clean$sii, levels = c(levels(train_clean$sii), "Missing")) # Replacing NAs with new level
train_clean$sii[is.na(train_clean$sii)] = "Missing"

categorical_vars = train_clean[, sapply(train_clean, function(x) is.factor(x) | is.character(x))]
# Select categorical variables including 'sii'
# Identify columns that contain 'PCIAT' in their names but excluding 'PCIAT_PCIAT_Total' (quant. variable)
pciat_columns = grep("PCIAT", names(train_clean), value = TRUE)
pciat_columns = pciat_columns[pciat_columns != "PCIAT_PCIAT_Total"]
categorical_vars = cbind(categorical_vars, train_clean[, pciat_columns])

categorical_vars = categorical_vars %>%
  mutate(across(everything(), ~ replace(., is.na(.), "Missing")))

quantitative_vars = train_clean[, sapply(train_clean, is.numeric)]

quantitative_vars_imputed = quantitative_vars %>%
  mutate(across(where(is.numeric), ~ ifelse(is.na(.), median(., na.rm = TRUE), .)))

train_data = bind_cols(categorical_vars, quantitative_vars_imputed)

quantitative_vars_imputed = quantitative_vars %>% mutate(sii = train_data$sii)

# ---------------------------------------------------------------------------------------------------------------------- #
# Linear Discriminant Analysis

lda_data_train = train_data
lda_data_train$sii = as.factor(lda_data_train$sii)  # Ensure `sii` is a factor for LDA

lda_data_train = subset(lda_data_train, select = -id)

# Perform Linear Discriminant Analysis
lda_model_train = lda(sii ~ ., data = lda_data_train)

# View the LDA model output
summary(lda_model_train)

# Predicting using the LDA model
lda_predictions = predict(lda_model_train, lda_data_train)

# Add predictions to the original data
lda_data_train$predicted_sii = lda_predictions$class

# Confusion matrix to evaluate classification accuracy
confusion_matrix = table(lda_data_train$sii, lda_data_train$predicted_sii)

print("Confusion Matrix:")
print(confusion_matrix)

# Calculate accuracy
accuracy = sum(diag(confusion_matrix)) / sum(confusion_matrix)
print(paste("Accuracy:", round(accuracy * 100, 2), "%"))

# ---------------------------------------------------------------------------------------------------------------------- #
# LDA Visualization

# Check if the number of linear discriminants is sufficient
lda_discriminants = lda_predictions$x
lda_discriminants = as.data.frame(lda_discriminants)
#lda_discriminants = lda_discriminants %>% filter(LD1 < 38)

if (ncol(lda_discriminants) >= 2) {
  # Extract the first two linear discriminants
  lda_data_train$LD1 = lda_discriminants[, 1]  # First Linear Discriminant
  lda_data_train$LD2 = lda_discriminants[, 2]  # Second Linear Discriminant
  lda_data_train_new = lda_data_train %>% filter(LD1 < -8)
  # Plot the LDA results
  ldaplot = ggplot(lda_data_train_new, aes(x = LD2, y = LD1, color = sii)) +
    geom_point(alpha = 0.7) +
    labs(title = "LDA: Linear Discriminants 2 vs 1",
         x = "Linear Discriminant 2",
         y = "Linear Discriminant 1") +
    theme_minimal() +
    scale_color_manual(values = c("red", "blue", "green", "purple", "orange"))  # Adjust colors as needed
} else {
  print("Insufficient linear discriminants for visualization.")
}

print(ldaplot)
# ---------------------------------------------------------------------------------------------------------------------- #
