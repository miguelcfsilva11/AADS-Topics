#!/bin/bash

# Define directories for input and alternative files
OUTPUT_DIR="data/output"
ALT_DIR="data/output_alt"

# Path to the benchmark executable
BENCHMARK_EXEC="./benchmark"

# Check if benchmark executable exists
if [[ ! -f "$BENCHMARK_EXEC" ]]; then
  echo "Error: Benchmark executable not found at $BENCHMARK_EXEC"
  exit 1
fi

# Iterate over all files in the output directory
for file in "$OUTPUT_DIR"/*; do
  # Get the base file name (without directory path)
  base_file=$(basename "$file")

  # Construct the corresponding file path in the alternative directory
  alt_file="$ALT_DIR/$base_file"

  # Check if the alternative file exists
  if [[ ! -f "$alt_file" ]]; then
    echo "Warning: Corresponding file not found in $ALT_DIR for $base_file. Skipping."
    continue
  fi

  # Run the benchmark
  echo "Running benchmark for $file and $alt_file"
  $BENCHMARK_EXEC "$file" "$alt_file"

done

echo "All benchmarks completed."
