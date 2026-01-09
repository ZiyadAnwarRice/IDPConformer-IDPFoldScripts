# IDP Ensemble Generation Pipeline
## Setup and Usage Guide

This guide explains how to set up and run IDPConformerGenerator and IDPFold to generate 200 conformational ensembles for your FASTA files.

---

## 1. IDPConformerGenerator Setup

### Installation

```bash
# Clone the repository
git clone https://github.com/julie-forman-kay-lab/IDPConformerGenerator.git
cd IDPConformerGenerator

# Create conda environment
run ./install_miniconda3.sh
run source ./activate.sh
run ./install_deps.sh
#Note source ./activate.sh must be called everytime the session is opened whenever trying to create conformers

# Verify installation
idpconfgen -h
```

### Build the Database (One-time setup)

IDPConformerGenerator requires a pre-built torsion angle database. This is a one-time setup:

```bash
# 1. Download a PDB list from PISCES (recommended: 90% sequence identity, 1.6Å resolution)
# Go to: https://www.dropbox.com/scl/fi/sfmxgdgw3h3ram79fq41d/idpconfgen_database_2024.tar.xz?rlkey=tm02sea1pcqykoer2cw06nstj&e=1&st=vlwcmedd&dl=0
# Download the culled list
# A copy can also be found in the following path: /home/SharedFiles/Ziyad/idpconfgen_database.json

```

The database file (`idpconfgen_database.json`) can be reused for all your proteins.
ls
### Run IDPConformerGenerator

```bash
# Single protein
idpconfgen build \
    -db /path/to/idpconfgen_database.json \
    -seq /path/to/your/protein.fasta \
    -nc 200 \
    -n 4 \
    -of output_conformers.pdb \
    --dloop-off

# Multiple proteins (using the provided script)
# First, edit run_idpconfgen.sh to set your paths, then:
chmod +x run_idpconfgen.sh
./run_idpconfgen.sh
#Ths file can be found in /home/SharedFiles/Ziyad
```

---

## 2. IDPFold Setup

### Installation

```bash
# Clone the repository
git clone https://github.com/Junjie-Zhu/IDPFold.git
cd IDPFold

# Create conda environment
conda env create -f environment.yml
conda activate idpfold

# Install ESM for sequence embeddings
pip install fair-esm

# Install IDPFold
pip install -e .

# Initialize environment file
python -c "from dotenv import dotenv_values; print('Setup complete')"
```

### Download Checkpoint

Download the pretrained model checkpoint (Pretrained.ckpt and fine_tuned.ckpt):
Can be found in the following /home/SharedFiles/Ziyad/IDPFold/

### Run IDPFold

```bash
cd /path/to/IDPFold

# 1. Extract sequence embeddings
python src/read_seqs.py pred_dir='/path/to/your/protein.fasta'

# 2. Generate conformers
python src/eval.py \
    ckpt_path='/path/to/checkpoint.ckpt' \
    pred_dir='/path/to/your/protein.fasta' \
    output_dir='/path/to/output/' \
    num_samples=200

# Multiple proteins (using the provided script)
# First, edit run_idpfold.sh to set your paths, then:
chmod +x run_idpfold.sh
./run_idpfold.sh
```

---

## 3. Using the Python Pipeline (Recommended)

The `run_ensemble_pipeline.py` script provides a unified interface for both tools:

### Run IDPConformerGenerator only:
```bash
python run_ensemble_pipeline.py \
    --tool idpconfgen \
    --fasta_dir /home/mkabir3/Research/44_EnsemblePipeline/CEG-IDP/out/clean_fastas \
    --output_dir /home/mkabir3/Research/44_EnsemblePipeline/CEG-IDP/out/results \
    --num_conformers 200 \
    --num_cores 4 \
    --idpconfgen_db /path/to/idpconfgen_database.json
```

### Run IDPFold only:
```bash
python run_ensemble_pipeline.py \
    --tool idpfold \
    --fasta_dir /home/mkabir3/Research/44_EnsemblePipeline/CEG-IDP/out/clean_fastas \
    --output_dir /home/mkabir3/Research/44_EnsemblePipeline/CEG-IDP/out/results \
    --num_conformers 200 \
    --idpfold_dir /path/to/IDPFold \
    --idpfold_checkpoint /path/to/checkpoint.ckpt
```

### Run both tools:
```bash
python run_ensemble_pipeline.py \
    --tool both \
    --fasta_dir /home/mkabir3/Research/44_EnsemblePipeline/CEG-IDP/out/clean_fastas \
    --output_dir /home/mkabir3/Research/44_EnsemblePipeline/CEG-IDP/out/results \
    --num_conformers 200 \
    --num_cores 4 \
    --idpconfgen_db /path/to/idpconfgen_database.json \
    --idpfold_dir /path/to/IDPFold \
    --idpfold_checkpoint /path/to/checkpoint.ckpt
```

---

## 4. Output Structure

After running the pipeline, your output directory will look like:

```
results/
├── idpconfgen/
│   ├── PED00001/
│   │   └── PED00001_conformers.pdb    # Multi-model PDB with 200 conformers
│   ├── PED00002/
│   │   └── PED00002_conformers.pdb
│   └── ...
├── idpfold/
│   ├── PED00001/
│   │   ├── sample_001.pdb
│   │   ├── sample_002.pdb
│   │   └── ...                        # 200 individual PDB files
│   ├── PED00002/
│   │   └── ...
│   └── ...
├── pipeline_YYYYMMDD_HHMMSS.log       # Detailed log
└── results_summary.json                # Summary of successes/failures
```

---

## 5. Troubleshooting

### IDPConformerGenerator Issues

1. **"Database file not found"**
   - Make sure you've built the database first (see Section 1)
   - Check the path is correct

2. **"DSSP not found"**
   - Install DSSP: `conda install -c salilab dssp`

3. **Memory errors**
   - Reduce the number of cores: `-n 2`
   - Process proteins sequentially

### IDPFold Issues

1. **"Checkpoint not found"**
   - Download from the Google Drive link in the IDPFold GitHub README
   - Verify the path is correct

2. **CUDA out of memory**
   - Reduce batch size in the config
   - Use CPU: set `GPU_ID=-1` in the script

3. **ESM embedding errors**
   - Ensure `fair-esm` is installed: `pip install fair-esm`
   - Check FASTA format is correct

---

## 6. FASTA File Format

Ensure your FASTA files are properly formatted:

```
>PED00001
MSEQVENCE...
```

- One sequence per file (recommended)
- No special characters in sequence
- Standard amino acid letters only

---

## 7. Hardware Requirements

| Tool | Minimum | Recommended |
|------|---------|-------------|
| IDPConformerGenerator | 8GB RAM, 4 cores | 32GB RAM, 8+ cores |
| IDPFold | 16GB RAM, GPU with 8GB VRAM | 32GB RAM, GPU with 16GB+ VRAM |

---

## 8. Citations

If you use these tools, please cite:

**IDPConformerGenerator:**
```
Teixeira et al. (2022) IDPConformerGenerator: A Flexible Software Suite for 
Sampling the Conformational Space of Disordered Protein States. 
J. Phys. Chem. A, 126(35), 5985-6003.
```

**IDPFold:**
```
Zhu et al. (2024/2025) Accurate Generation of Conformational Ensembles for 
Intrinsically Disordered Proteins with IDPFold. Advanced Science.
```
