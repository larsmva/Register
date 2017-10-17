#!/bin/bash
# Job name:
#SBATCH --job-name=kent
#
# Project:
#SBATCH --account=nn9279k
# Wall clock limit:
#SBATCH --time='30:00:00'
#
# Max memory usage per task:
#SBATCH --mem-per-cpu=20000M
#
# Number of tasks (cores):
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

#SBATCH --partition=long
##SBATCH --output=output.$SCRATCH 
source /cluster/bin/jobsetup
module load freesurfer/6.0.0
module load fsl

cleanup "mkdir $HOME/$2"
cleanup "cp -r $SCRATCH/REGISTERED $HOME/$2"
cleanup "cp -r $SCRATCH/LTA $HOME/$2"
cleanup "cp -r $SCRATCH/CONFORM $HOME/$2"
#cleanup "cp -r $SCRATCH/$2 $HOME/$2"

#export PATH=$FREESURFER_HOME/bin:$PATH
echo $SCRATCH
echo `date`

#INPUT $1=mgz-folder $2=subjid

cp -r $1 $SCRATCH

mkdir -p $SCRATCH/REGISTERED
mkdir -p $SCRATCH/LTA
mkdir -p $SCRATCH/CONFORM


list=$( find $SCRATCH -type f | grep "MGZ/T1_3D" | sort)

${FREESURFER_HOME}/bin/mri_robust_template --mov ${list} --average 1 --template $SCRATCH/REGISTERED/template.mgz --satit --inittp 1 --fixtp --noit --maxit 10 --subsample 200 
for i in ${list}; do 
	fname=$(basename $i) 
	${FREESURFER_HOME}/bin/mri_robust_register --mov $i --dst $SCRATCH/REGISTERED/template.mgz --satit --maxit 10 --mapmov $SCRATCH/REGISTERED/$fname --lta $SCRATCH/LTA/"${fname%.*}".lta
done

list=$( find $SCRATCH/REGISTERED -type f | grep -e "T1_3D" )

for i in ${list}; do 
	${FREESURFER_HOME}/bin/mri_convert --conform -odt float $i $SCRATCH/CONFORM/$(basename $i)
done





















