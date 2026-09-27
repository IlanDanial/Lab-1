#!/bin/bash -l
#SBATCH --job-name=gpu_lab1
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16gb
#SBATCH --gpus=1
#SBATCH --time=00:10:00
#SBATCH --account=eel4930
#SBATCH --qos=eel4930

# 1. Load modules on HiPerGator
module purge
module load gcc cuda

echo "Job ID:     $SLURM_JOB_ID"
echo "Host:       $(hostname)"
echo "Date:       $(date)"

# Environment for the report
echo -e "\n=== Environment ==="
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv
nvcc --version | tail -2
gcc --version | head -1

# 2. Build lab1
echo -e "\n=== Build ==="
make clean
make

# 3. Tests

echo -e "\n=== Correctness test matrix ==="
for N in 1 255 256 257 1000 10000000; do
    echo "--- N=$N ---"
    ./lab1 "$N"
done
