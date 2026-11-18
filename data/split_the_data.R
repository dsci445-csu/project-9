# This r script will be used to split unclean_cars.csv into two different
# csv files: one for testing, and one for training the model.

# DSCI 445 Project
# Data Split Script

# Reproducibility
set.seed(445)

# Load raw data
cars <- read.csv("data/raw/unclean_cars.csv")

# Basic dataset information
cat("Rows:", nrow(cars), "\n")
cat("Columns:", ncol(cars), "\n")

# Create an 80/20 train-test split using an integer-sized training set
train_size <- floor(0.80 * nrow(cars))
train_index <- sample(seq_len(nrow(cars)), size = train_size)

train <- cars[train_index, ]
test <- cars[-train_index, ]

# Save datasets
write.csv(
  train,
  "data/processed/train.csv",
  row.names = FALSE
)

write.csv(
  test,
  "data/processed/test.csv",
  row.names = FALSE
)

# Verify split
cat("Training observations:", nrow(train), "\n")
cat("Testing observations:", nrow(test), "\n")
