library(readr)       
library(dplyr)       
library(e1071)       
library(caret)       
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
categorical_vars = cbind(categorical_vars, train_clean[, pciat_columns])
# One-Versus-All SVM

categorical_vars = train_clean %>%
  select(where(is.factor) | where(is.character))  # Select categorical variables including 'sii'

categorical_vars = categorical_vars %>%
  mutate(across(everything(), ~ replace(., is.na(.), "Missing")))

# Handling missing values in quantitative variables (impute with median)
quantitative_vars = train_clean %>%
  select(where(is.numeric))  # Select quantitative variables including 'sii'

quantitative_vars_imputed = quantitative_vars %>%
  mutate(across(where(is.numeric), ~ ifelse(is.na(.), median(., na.rm = TRUE), .)))

# Step 2: Train the SVM Model using the entire train_clean data (or just quantitative or categorical data)
# Here we'll use the full dataset (with imputed values for quantitative variables)
train_data = bind_cols(categorical_vars, quantitative_vars_imputed)

# Train SVM using the One-vs-All strategy (default for multi-class classification)
svm_model_ova = svm(sii ~ ., data = train_data, kernel = "linear", type = "C-classification")

# Step 3: Predict the class for the same data
predictions = predict(svm_model_ova, train_data)

# Step 4: Evaluate the model performance with a confusion matrix
confusion_matrix = table(predictions, train_data$sii)
print(confusion_matrix)

# You can use `caret` package to calculate metrics such as accuracy, precision, recall, etc.

confusionMatrix(confusion_matrix)



# Perform PCA to reduce to two dimensions
pca = prcomp(train_data %>% select(where(is.numeric)), scale. = TRUE)

# Extract the first two principal components
train_pca = data.frame(pca$x[, 1:2])  # First two principal components
train_pca$sii = train_data$sii  # Add the target variable
train_pca = train_pca[train_pca$PC1 < 40,] # Removing outlier

# Train the SVM model on the two principal components
svm_model = svm(sii ~ PC1 + PC2, data = train_pca, kernel = "linear", type = "C-classification")


# Create a grid for the two principal components (PC1 and PC2)
x_range = seq(min(train_pca$PC1) - 1, max(train_pca$PC1) + 1, length.out = 500)
y_range = seq(min(train_pca$PC2) - 1, max(train_pca$PC2) + 1, length.out = 500)
grid = expand.grid(PC1 = x_range, PC2 = y_range)

# Predict the class for each point in the grid
grid$pred = predict(svm_model, grid)

# Plot the decision boundaries
ggplot() +
  geom_tile(data = grid, aes(x = PC1, y = PC2, fill = pred), alpha = 0.3) +  # Decision boundary
  geom_point(data = train_pca, aes(x = PC1, y = PC2, color = sii), size = 3) +  # Data points
  labs(title = "SVM Decision Boundaries",
       x = "Principal Component 1",
       y = "Principal Component 2") +
  scale_fill_manual(values = c("red", "blue", "green", "purple", "orange")) +  # Customize colors
  scale_color_manual(values = c("red", "blue", "green", "purple", "orange")) +
  theme_minimal() +
  theme(legend.position = "none")
