set -e

# Configuration - MODIFY THESE PATHS
FASTA_DIR="/home/SharedFiles/Wasi/seqs"
OUTPUT_DIR="/home/SharedFiles/Ziyad/IDPConformers"
IDPCONFGEN_DB="./idpconfgen_database.json"  # Path to pre-built torsion angle database
NUM_CONFORMERS=200
NUM_CORES=4  # Adjust based on your system

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Log file
LOG_FILE="$OUTPUT_DIR/idpconfgen_run_$(date +%Y%m%d_%H%M%S).log"

echo "=======================================" | tee -a "$LOG_FILE"
echo "IDPConformerGenerator Pipeline" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "FASTA Directory: $FASTA_DIR" | tee -a "$LOG_FILE"
echo "Output Directory: $OUTPUT_DIR" | tee -a "$LOG_FILE"
echo "Number of conformers: $NUM_CONFORMERS" | tee -a "$LOG_FILE"
echo "=======================================" | tee -a "$LOG_FILE"


# Count FASTA files
FASTA_COUNT=$(find "$FASTA_DIR" -name "*.fasta" -o -name "*.fa" | wc -l)
echo "Found $FASTA_COUNT FASTA files to process" | tee -a "$LOG_FILE"

# Process each FASTA file
COUNTER=0
for FASTA_FILE in "$FASTA_DIR"/*.fasta "$FASTA_DIR"/*.fa; do
    # Skip if no files match
    [[ -e "$FASTA_FILE" ]] || continue
    
    COUNTER=$((COUNTER + 1))
    BASENAME=$(basename "$FASTA_FILE" .fasta)
    BASENAME=$(basename "$BASENAME" .fa)
    BASENAME=$(basename "$BASENAME" .clean)
    
    PROTEIN_OUTPUT_DIR="$OUTPUT_DIR/$BASENAME"
    mkdir -p "$PROTEIN_OUTPUT_DIR"
    
    echo "" | tee -a "$LOG_FILE"
    echo "[$COUNTER/$FASTA_COUNT] Processing: $BASENAME" | tee -a "$LOG_FILE"
    echo "  Input: $FASTA_FILE" | tee -a "$LOG_FILE"
    echo "  Output: $PROTEIN_OUTPUT_DIR" | tee -a "$LOG_FILE"
    
    # Run IDPConformerGenerator build command
    START_TIME=$(date +%s)
    
    idpconfgen build \
        -db "$IDPCONFGEN_DB" \
        -seq "$FASTA_FILE" \
        -nc "$NUM_CONFORMERS" \
        -n "$NUM_CORES" \
        -of "$PROTEIN_OUTPUT_DIR/${BASENAME}_conformers.pdb" \
        --dloop-off \
        --dany \
        2>&1 | tee -a "$LOG_FILE"
    
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    
    echo "  Completed in ${ELAPSED}s" | tee -a "$LOG_FILE"
    
    # Check output
    if [[ -f "$PROTEIN_OUTPUT_DIR/${BASENAME}_conformers.pdb" ]]; then
        # Count models in the PDB file
        MODEL_COUNT=$(grep -c "^MODEL" "$PROTEIN_OUTPUT_DIR/${BASENAME}_conformers.pdb" 2>/dev/null || echo "0")
        echo "  Generated $MODEL_COUNT conformers" | tee -a "$LOG_FILE"
    else
        echo "  WARNING: Output file not found!" | tee -a "$LOG_FILE"
    fi
done

echo "" | tee -a "$LOG_FILE"
echo "=======================================" | tee -a "$LOG_FILE"
echo "Pipeline completed: $(date)" | tee -a "$LOG_FILE"
echo "Processed $COUNTER FASTA files" | tee -a "$LOG_FILE"
echo "Results saved to: $OUTPUT_DIR" | tee -a "$LOG_FILE"
echo "=======================================" | tee -a "$LOG_FILE"
