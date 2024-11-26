library(readr)       
library(dplyr)       
library(e1071)       
library(caret)       
library(ggplot2)     

test = read_csv("test.csv")
train = read_csv("train.csv")
# ---------------------------------------------------------------------------------------------------------------------- #

# Data Manipulation:

train_clean = train %>% select(-ends_with("Season")) # Season variables deemed unnecessary
train_clean$sii = factor(train_clean$sii) # Making sure `sii` is a factor with 4 factors (plus extra level for NAs later)

colnames(train_clean) = gsub("-", "_", colnames(train_clean)) # Replacing hyphens because R can't handle those

train_clean$sii = factor(train_clean$sii, levels = c(levels(train_clean$sii), "Missing")) # Replacing NAs with new level
train_clean$sii[is.na(train_clean$sii)] = "Missing"


categorical_vars = train_clean %>%
  select(where(is.factor) | where(is.character))  # Select categorical variables including 'sii'
# Identify columns that contain 'PCIAT' in their names but excluding 'PCIAT_PCIAT_Total'
pciat_columns = grep("PCIAT", names(train_clean), value = TRUE)
pciat_columns = pciat_columns[pciat_columns != "PCIAT_PCIAT_Total"]
categorical_vars = cbind(categorical_vars, train_clean[, pciat_columns])

categorical_vars = categorical_vars %>%
  mutate(across(everything(), ~ replace(., is.na(.), "Missing")))

quantitative_vars = train_clean %>%
  select(where(is.numeric))  # Select quantitative variables including 'sii'

quantitative_vars_imputed = quantitative_vars %>%
  mutate(across(where(is.numeric), ~ ifelse(is.na(.), median(., na.rm = TRUE), .)))
# ---------------------------------------------------------------------------------------------------------------------- #

# One-Versus-All SVM

train_data = bind_cols(categorical_vars, quantitative_vars_imputed)

svm_model_ova = svm(sii ~ ., data = train_data, kernel = "radial", type = "C-classification")

predictions = predict(svm_model_ova, train_data)

# Model performance with a confusion matrix
confusion_matrix = table(predictions, train_data$sii)
print(confusion_matrix)


confusionMatrix(confusion_matrix)
# ---------------------------------------------------------------------------------------------------------------------- #

# Graphing Decision Boundaries:
# Perform PCA to reduce to two dimensions:
pca = prcomp(train_data %>% select(where(is.numeric)), scale. = TRUE)

train_pca = data.frame(pca$x[, 1:2])  # First two principal components
train_pca$sii = train_data$sii  # Add `sii` (response)
train_pca = train_pca[train_pca$PC1 < 16 ,] # Removing outliers in PC1 (x)

# Train the SVM model on the two principal components
svm_model = svm(sii ~ PC1 + PC2, data = train_pca, kernel = "radial", type = "C-classification")


x_range = seq(min(train_pca$PC1) - 1, max(train_pca$PC1) + 1, length.out = 500)
y_range = seq(min(train_pca$PC2) - 1, max(train_pca$PC2) + 1, length.out = 500)
grid = expand.grid(PC1 = x_range, PC2 = y_range)

# Predict the class for each point in the grid
grid$pred = predict(svm_model, grid)

# Plotting decision boundaries
ova_plot = ggplot() +
  geom_tile(data = grid, aes(x = PC1, y = PC2, fill = pred), alpha = 0.3) +  # Decision boundary
  geom_point(data = train_pca, aes(x = PC1, y = PC2, color = sii), size = 2) +  # Data points
  labs(title = "SVM Decision Boundaries",
       x = "Principal Component 1",
       y = "Principal Component 2") +
  scale_fill_manual(values = c("red", "blue", "green", "purple", "orange")) +  # Customize colors
  scale_color_manual(values = c("red", "blue", "green", "purple", "orange")) +
  theme_minimal() +
  theme(legend.position = "none")

ova_plot
# ---------------------------------------------------------------------------------------------------------------------- #

# 5-Fold CV for kernel choice

train_data = train_pca %>%
  select(PC1, PC2, sii) 

train_index = createDataPartition(train_data$sii, p = 0.8, list = FALSE)
train_set = train_data[train_index, ]
test_set = train_data[-train_index, ]

cv_control = trainControl(method = "cv", number = 5)  # 10-fold too computationally heavy

svm_linear = train(sii ~ PC1 + PC2, data = train_set, 
                   method = "svmLinear", 
                   trControl = cv_control,
                   tuneLength = 5)  

svm_poly = train(sii ~ PC1 + PC2, data = train_set, 
                 method = "svmPoly", 
                 trControl = cv_control,
                 tuneLength = 5)  

svm_rbf = train(sii ~ PC1 + PC2, data = train_set, 
                method = "svmRadial", 
                trControl = cv_control,
                tuneLength = 5)  

print(svm_linear)
print(svm_poly)
print(svm_rbf)

resamples_list = resamples(list(linear = svm_linear, poly = svm_poly, rbf = svm_rbf))
summary(resamples_list)



