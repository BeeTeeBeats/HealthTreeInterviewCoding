install.packages('tidyverse', dependencies=TRUE, type="source")

library(tidyverse)

# --------------------------
# SET VARIABLES
# --------------------------

# If a CSV file is passed in from the command line, use that.
# Otherwise, default to the file sent to me.
args = commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  data_filepath <- "bquxjob_6307f8ce_1905abc1f18.csv"
} else {
  data_filepath <- args[1]
}

# These two columns are obviously necessary, but you can uncomment "codeText" if you decide.
necessary_columns <- c(
  # "codeText",
  "value",
  "unit"
)

# All conversion ratios are set relative to g/dL.
# All units should be converted to lowercase before checking.
mass_conversions <- list(
  "g"     = 1,
  "gm"    = 1,
  "gram"  = 1,
  "grams" = 1,
  "mg"         = 0.001,
  "milligram"  = 0.001,
  "milligrams" = 0.001)
vol_conversions <- list(
  "dl"         = 1,
  "deciliter"  = 1,
  "deciliters" = 1,
  "l"      = 10,
  "liter"  = 10,
  "liters" = 10)

allowed_mass_units <- names(mass_conversions)
allowed_vol_units <- names(vol_conversions)


# --------------------------
# FUNCTIONS
# --------------------------

# Returns TRUE/FALSE based on if the units make sense and are usable
is_valid_unit <- function(units) {
  valid_units <- c()
  
  for (unit in units) {
    if (is.na(unit) | str_count(unit, "/") != 1) {
      valid_units <- c(valid_units, FALSE)
    } else {
      lowercase_units <- str_to_lower(unit)
      units_frac <- str_split_1(lowercase_units, "/")
      mass <- units_frac[1]
      vol <- units_frac[2]
      valid_units <- c(valid_units,
                      mass %in% allowed_mass_units & vol %in% allowed_vol_units)
    }
  }
  
  return (valid_units)
}

# Figures out what to multiply the given value by to convert to g/dL
get_conversion_factor <- function(units) {
  conversion_factors <- c()
  
  for (unit in units) {
    if (!is_valid_unit(unit)) {
      conversion_factors <- c(conversion_factors, NA)
    } else {
      lowercase_units <- str_to_lower(unit)
      units_frac <- str_split_1(lowercase_units, "/")
      mass <- units_frac[1]
      vol <- units_frac[2]
      conversion_factor <- mass_conversions[[mass]] / vol_conversions[[vol]]
      conversion_factors <- c(conversion_factors, conversion_factor)
    }
  }
  
  return (conversion_factors)
}


# ------------------------------
# SCRIPT START
# ------------------------------

# Read in the data, add error_flag column
m_protein_data <- read_csv(data_filepath) |>
  mutate(error_flag = FALSE)

# Flags rows with empty cells in necessary spots
full_data_rows <- m_protein_data |>
  select(all_of(necessary_columns)) |>
  complete.cases()
m_protein_data$error_flag <- m_protein_data$error_flag | (!full_data_rows)

# Flags rows with values less than 0 because negative concentrations make no sense
m_protein_data$error_flag <- m_protein_data$error_flag | (m_protein_data$value < 0)

# Flags rows with invalid units
m_protein_data$error_flag <- m_protein_data$error_flag | (!is_valid_unit(m_protein_data$unit))

# Map values to g/dL
m_protein_data <- m_protein_data |>
  mutate(value_g_dL = value * get_conversion_factor(unit), .before = error_flag)

# Flag absurdly high data. Seeing as plasma typically has between 6-8 g/dL of all
# proteins combined, and a result greater than 3 is effectively a diagnosis of
# multiple myeloma, I will arbitrarily set the cutoff at 25 g/dL (3-4x the normal
# total), as any more protein would appear absurd.
m_protein_data$error_flag <- m_protein_data$error_flag | (m_protein_data$value_g_dL > 25)

# Create a separate tibble for only the data that has no error flags
filtered_m_protein_data <- filter(m_protein_data, !error_flag) |>
  select(-error_flag)

# Write the resulting tibbles back to files
stripped_filename = str_split_1(data_filepath, "\\.")[1]

flagged_file_name = paste0(stripped_filename, "_flagged.csv")
write_csv(m_protein_data, flagged_file_name)

filtered_file_name = paste0(stripped_filename, "_filtered.csv")
write_csv(filtered_m_protein_data, filtered_file_name)
