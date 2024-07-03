# Interview CSV Filter

This R script takes in a CSV file with M-protein test results, adds a column converting all concentrations to g/dL, and then marks which data is usable and which is unusable. It outputs two separate CSV files:
1. [filename]_flagged.csv also adds a column called *error_flag* which contains TRUE or FALSE values. A TRUE value in *error_flag* means the data is unusable.
2. [filename]_filtered.csv has all unusable data completely removed from the file.

  It is simple to run:
```
Rscript sort_valid_ehr_results.R
```
  It has the filepath for the CSV file sent to me hard-coded, but if you would like to use a different CSV file, just pass it in as the first argument from the command line like this:
```
Rscript sort_valid_ehr_results.R [your_file].csv
```

# How it Works
  
  There are a few steps outlined in comments in the code:
1. Read the CSV file into a data frame.
2. Add a column for the error flag.
3. Flag rows that have an empty value in necessary rows (which you can specify/change in the script).
4. Flag rows which have a negative concentration.
5. Add another row to store all concentrations in g/dL, then map the values.
6. Flag any test result higher than the "absurd" cutoff.
7. Create the two output CSV files.
