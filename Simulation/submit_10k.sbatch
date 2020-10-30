#!/bin/bash

#SBATCH --mem=2GB
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=1
#SBATCH --output=logs/%a_%A.out
#SBATCH --error=logs/%a_%A.err
#SBATCH --job-name=Thz
#SBATCH --mail-type=END
#SBATCH --mail-user=mfo254@nyu.edu


module purge
module load matlab/2019a

cd /scratch/$USER/handover/Simulation


echo "$SLURM_ARRAY_TASK_ID"


matlab -nodisplay -r "SimulationLOS_thz_10k, exit"


