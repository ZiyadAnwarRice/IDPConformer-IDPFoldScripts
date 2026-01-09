#!/bin/bash
#===============================================================================
# IDPFold Pipeline Script
# Generates 200 conformer ensembles for each FASTA file in a directory
#===============================================================================

set -e

# Configuration - MODIFY THESE PATHS
FASTA_DIR="/home/SharedFiles/Wasi/seqs"
OUTPUT_DIR="/home/SharedFiles/Ziyad/IDPFold"
IDPFOLD_DIR="/home/zanwar1/IDPFold"  # Path to IDPFold installation
CHECKPOINT_PATH="/home/zanwar1/IDPFold/pretrained.ckpt"  # Download from Google Drive
NUM_CONFORMERS=200
GPU_ID=0  # Set to -1 for CPU

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Log file
LOG_FILE="$OUTPUT_DIR/idpfold_run_$(date +%Y%m%d_%H%M%S).log"

echo "=======================================" | tee -a "$LOG_FILE"
echo "IDPFold Pipeline" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "FASTA Directory: $FASTA_DIR" | tee -a "$LOG_FILE"
echo "Output Directory: $OUTPUT_DIR" | tee -a "$LOG_FILE"
echo "Number of conformers: $NUM_CONFORMERS" | tee -a "$LOG_FILE"
echo "=======================================" | tee -a "$LOG_FILE"


# Change to IDPFold directory
cd "$IDPFOLD_DIR"

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
    
    START_TIME=$(date +%s)
    
    # Step 1: Extract sequence embeddings using ESM
    echo "  Step 1: Extracting sequence embeddings..." | tee -a "$LOG_FILE"
    python src/read_seqs.py \
        pred_dir="$FASTA_FILE" \
        2>&1 | tee -a "$LOG_FILE"
    
    # Step 2: Run inference to generate conformers
    echo "  Step 2: Generating conformers..." | tee -a "$LOG_FILE"
    python src/eval.py \
        ckpt_path="$CHECKPOINT_PATH" \
        pred_dir="$FASTA_FILE" \
        +num_samples="$NUM_CONFORMERS" \
        +output_dir="$PROTEIN_OUTPUT_DIR" \
        2>&1 | tee -a "$LOG_FILE"
    
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    
    echo "  Completed in ${ELAPSED}s" | tee -a "$LOG_FILE"
    
    # Check output
    PDB_COUNT=$(find "$PROTEIN_OUTPUT_DIR" -name "*.pdb" | wc -l)
    echo "  Generated $PDB_COUNT PDB files" | tee -a "$LOG_FILE"
done

echo "" | tee -a "$LOG_FILE"
echo "=======================================" | tee -a "$LOG_FILE"
echo "Pipeline completed: $(date)" | tee -a "$LOG_FILE"
echo "Processed $COUNTER FASTA files" | tee -a "$LOG_FILE"
echo "Results saved to: $OUTPUT_DIR" | tee -a "$LOG_FILE"
echo "=======================================" | tee -a "$LOG_FILE"
