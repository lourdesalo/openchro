#!/bin/bash

# Help message
print_help() {
    echo "Usage: $0 <input.sam> <single|paired>"
    echo ""
    echo "Arguments:"
    echo "  <input.sam>       Input SAM file"
    echo "  <single|paired>   Type of sequencing data:"
    echo "                    'single' for single-end"
    echo "                    'paired' for paired-end"
    echo ""
    echo "Example:"
    echo "  $0 sample.sam single"
}

# Check for help flag
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    print_help
    exit 0
fi

# Check for correct number of arguments
if [[ $# -ne 2 ]]; then
    echo "Error: Invalid number of arguments."
    print_help
    exit 1
fi

IN_1=$1          # Input SAM file
END_TYPE=$2      # "single" or "paired"

# Validate second argument
if [[ "$END_TYPE" != "single" && "$END_TYPE" != "paired" ]]; then
    echo "Error: Second argument must be 'single' or 'paired'."
    print_help
    exit 1
fi

# Extract directory paths and filenames (without extension)
BASE_1=$(basename "$IN_1" .sam)

# Construct the output file paths
SORTED="${BASE_1}_sorted.sam"
NO_DUP="${BASE_1}_sorted_rmdup.sam"

# Sort, filter specific references, and remove unmapped reads while preserving headers
{
    # Extract header
    samtools view -H "$IN_1"
    # Filter the body
    samtools sort -@ 10 "$IN_1" -O sam | \
        samtools view -@ 10 -F 4 - | \
        grep -Ev 'NC_037304.1|NC_000932.1'
} > "$SORTED"


# Remove duplicates, adding -s if single-end
if [ "$END_TYPE" = "single" ]; then
    samtools rmdup -s "$SORTED" "$NO_DUP"
else
    samtools rmdup "$SORTED" "$NO_DUP"
fi

# Clean up
rm "$SORTED"
