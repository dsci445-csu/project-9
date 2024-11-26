library(e1071)
library(dplyr)
# library(missForest)
library(readr)
library(caret)
# library(tidyverse)
library(tidyr)
library(tidymodels)
library(kernlab)
library(ggplot2)


test = read_csv("test.csv")
train = read_csv("train.csv")
# data_dictionary = read_csv("data_dictionary.csv")
# ---------------------------------------------------------------------------------------------------------------------- #

# Data Manipulation
train_clean = train %>% select(-ends_with("Season")) 
train_clean$sii = factor(train_clean$sii)

colnames(train_clean) = gsub("-", "_", colnames(train_clean))

train_clean$sii = factor(train_clean$sii, levels = c(levels(train_clean$sii), "Missing"))
train_clean$sii[is.na(train_clean$sii)] = "Missing"


categorical_vars = train_clean %>% select(where(is.factor) | where(is.character) | 'sii')
quantitative_vars = train_clean %>% select(where(is.numeric) | 'sii')

# Identify columns that contain 'PCIAT' in their names but excluding 'PCIAT_PCIAT_Total'
pciat_columns = grep("PCIAT", names(train_clean), value = TRUE)
pciat_columns = pciat_columns[pciat_columns != "PCIAT_PCIAT_Total"]
categorical_vars = cbind(categorical_vars, train_clean[, pciat_columns]) # Extract these columns and add them to the categorical variables
# ---------------------------------------------------------------------------------------------------------------------- #
# SVM Workflow:

# Data imputation, otherwise R cannot perform SVM prediction
train_clean_imputed = train_clean %>%
  mutate(across(where(is.factor) | where(is.character), 
                ~ replace(., is.na(.), "Missing"))) %>% 
  mutate(across(where(is.numeric), 
                ~ ifelse(is.na(.), median(., na.rm = TRUE), .)))

svm_linear_spec = svm_poly(degree = 1) %>%
  set_mode("classification") %>%
  set_engine("kernlab", scaled = FALSE)

# Train the SVM model with cost = 10 using the `train_clean` dataset and predicting `sii`
svm_linear_fit = svm_linear_spec %>% 
  set_args(cost = 1) %>%
  fit(sii ~ ., data = train_clean_imputed)

# summary(svm_linear_fit)

# 307 support vectors #


# ---------------------------------------------------------------------------------------------------------------------- #

# PERFORM SVM on quantitative dataset:

# Impute missing values for quantitative variables (replace NA with the median)
train_quantitative_imputed = quantitative_vars %>%
  mutate(across(where(is.numeric), ~ ifelse(is.na(.), median(., na.rm = TRUE), .)))

# Check if there are any remaining NA values in the dataset
sum(is.na(train_quantitative_imputed))

# Split the data into predictors (X) and target variable (y)
X_quant = train_quantitative_imputed %>% select(-sii)
y_quant = train_quantitative_imputed$sii

# Train the SVM model with radial kernel
svm_model_quant = svm(x = X_quant, y = y_quant, kernel = "radial", cost = 1, scale = TRUE)

# Print the model summary
summary(svm_model_quant)

# Predict using the trained SVM model
predictions_quant = predict(svm_model_quant, X)

# Evaluate model performance (e.g., confusion matrix)
confusion_matrix = table(predictions_quant, y)
print(confusion_matrix)


# GRAPHING WITH PCA

# Step 1: Perform PCA to reduce to two principal components for visualization
pca_result = prcomp(X, center = TRUE, scale. = TRUE)
X_pca = as.data.frame(pca_result$x[, 1:2])  # Extract the first two principal components
loadings = pca_result$rotation
X_pca$sii = y  # Add the target variable back to the PCA-transformed dataset


variance_explained = pca_result$sdev^2 / sum(pca_result$sdev^2)
print(variance_explained)

X_pca = X_pca[X_pca$PC1 < 40,] # removing outlier
svm_model_pca = svm(sii ~ ., data = X_pca, kernel = "radial", cost = 1, scale = TRUE)

# Create a grid of points for plotting decision boundaries
grid = expand.grid(
  PC1 = seq(min(X_pca$PC1) - 1, max(X_pca$PC1) + 1, length = 100),
  PC2 = seq(min(X_pca$PC2) - 1, max(X_pca$PC2) + 1, length = 100)
)

# Predict class labels for the grid points
grid$Prediction = predict(svm_model_pca, newdata = grid)

# Step 4: Plot the decision boundaries and data points
svm_plot = ggplot() +
  geom_tile(data = grid, aes(x = PC1, y = PC2, fill = Prediction), alpha = 0.3) +
  geom_point(data = X_pca, aes(x = PC1, y = PC2, color = sii), size = 2) +
  labs(title = "SVM Decision Boundary (PCA-transformed Data)", x = "PC1", y = "PC2") +
  scale_fill_manual(values = c("lightblue", "lightpink", "green", "magenta", "yellow")) +  # Adjust colors as needed
  scale_color_manual(values = c("blue", "red", "forestgreen", "purple", "goldenrod")) +                # Adjust colors as needed
  theme_minimal()

svm_plot
# ---------------------------------------------------------------------------------------------------------------------- #

# Perform SVM using categorical dataset:

train_categorical_vars_imputed = categorical_vars %>%
  mutate(across(where(is.factor) | where(is.character), 
                ~ replace(., is.na(.), "Missing")))

X_catg = train_quantitative_imputed %>% select(-sii)
y_catg = train_quantitative_imputed$sii

# Train the SVM model with radial kernel
svm_model_catg = svm(x = X_catg, y = y_catg, kernel = "radial", cost = 1, scale = TRUE, type = "C-classification")

summary(svm_model_catg)

# Predict using the trained SVM model
predictions_catg = predict(svm_model_catg, X)

# Evaluate model performance (e.g., confusion matrix)
confusion_matrix = table(predictions_catg, y)
print(confusion_matrix)
# ---------------------------------------------------------------------------------------------------------------------- #

