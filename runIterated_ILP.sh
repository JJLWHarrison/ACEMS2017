#!/bin/sh
# This shell script runs runIterated_ILP.m in the portable batch system.
# It would be better to call a function with a few arguments next time.
#PBS -l select=1:ncpus=16:mem=96gb
#PBS -l walltime=400:00:00
#PBS -k oe

cd $PBS_O_WORKDIR

source /etc/profile.d/modules.sh

module load matlab/R2016b
module load gurobi/7.5.1

matlab -nodisplay -r "runIterated_ILP; exit;"
exit 0


