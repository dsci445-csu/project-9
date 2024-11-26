library(readr)       
library(dplyr)       
library(e1071)       
library(caret)       
library(ggplot2)

# Loading data
train = read_csv("train.csv")

# Data Manipulation
train_clean = train %>% select(-ends_with("Season"))
train_clean$sii = factor(train_clean$sii)

# Replacing any remaining NAs in the target variable 'sii' with the level 'Missing'
train_clean$sii = factor(train_clean$sii, levels = c(levels(train_clean$sii), "Missing")) # Replacing NAs with new level
train_clean$sii[is.na(train_clean$sii)] = "Missing"

# Prepare categorical and quantitative variables
categorical_vars = train_clean %>% select(where(is.factor) | where(is.character))  
pciat_columns = grep("PCIAT", names(train_clean), value = TRUE)
pciat_columns = pciat_columns[pciat_columns != "PCIAT_PCIAT_Total"]
categorical_vars = cbind(categorical_vars, train_clean[, pciat_columns])
categorical_vars = categorical_vars %>% mutate(across(everything(), ~ replace(., is.na(.), "Missing")))

quantitative_vars = train_clean %>% select(where(is.numeric))
quantitative_vars_imputed = quantitative_vars %>% mutate(across(where(is.numeric), ~ ifelse(is.na(.), median(., na.rm = TRUE), .)))

train_data = bind_cols(categorical_vars, quantitative_vars_imputed)

# Convert factors to numeric for SVM
train_data_num = train_data %>%
  mutate(across(where(is.factor), as.numeric)) %>%
  select(-sii) # Excluding the target variable

# Create a train and test split
set.seed(123)
train_index = createDataPartition(train_clean$sii, p = 0.8, list = FALSE)
train_set = train_data[train_index, ]
test_set = train_data[-train_index, ]

# Check if there are any missing values in the target variable for the training data
if (any(is.na(train_clean$sii[train_index]))) {
  stop("There are missing values in the target variable (sii) in the training data.")
}

# Perform One-Versus-All SVM Classification for each class in 'sii'
models = list()
for (level in levels(train_clean$sii)) {
  # Create a binary target for each class in 'sii'
  binary_target = ifelse(train_clean$sii[train_index] == level, 1, 0)
  
  # Ensure no missing values in the binary_target
  if (any(is.na(binary_target))) {
    stop("There are missing values in the binary target for class: ", level)
  }
  
  # Train the SVM model (linear kernel is commonly used for simplicity)
  model = svm(x = train_set, y = factor(binary_target), type = 'C-classification', kernel = 'linear')
  models[[level]] = model
}

# Continue with PCA and plotting steps as previously outlined...


# Continue with PCA and plotting steps as previously outlined...


# For graphing, we need to reduce the data to two dimensions (e.g., using PCA)
train_pca = prcomp(train_set, center = TRUE, scale. = TRUE)
train_pca_data = as.data.frame(train_pca$x[, 1:2])  # First two principal components

# Predict decision boundaries
grid = expand.grid(X1 = seq(min(train_pca_data$PC1), max(train_pca_data$PC1), length.out = 100),
                   X2 = seq(min(train_pca_data$PC2), max(train_pca_data$PC2), length.out = 100))

# Combine with PCA for predictions
grid_pca = predict(train_pca, newdata = grid)

# Plot decision boundaries for each class
ggplot() +
  geom_point(data = train_pca_data, aes(x = PC1, y = PC2, color = factor(train_clean$sii[train_index]))) +
  geom_tile(data = grid_pca, aes(x = PC1, y = PC2, fill = factor(grid_pca$predicted_class)), alpha = 0.3) +
  labs(title = "SVM Decision Boundaries (One-vs-All)", x = "PC1", y = "PC2") +
  scale_color_manual(values = c("red", "blue", "green", "purple")) + 
  theme_minimal()
