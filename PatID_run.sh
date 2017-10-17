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
cleanup "cp -r $SCRATCH/MGZ $HOME/$2"
cleanup "cp -r $SCRATCH/REGISTERED $HOME/$2"
cleanup "cp -r $SCRATCH/LTA $HOME/$2"
#cleanup "cp -r $SCRATCH/CONFORM $HOME/$2"
#cleanup "cp -r $SCRATCH/$2 $HOME/$2"

#export PATH=$FREESURFER_HOME/bin:$PATH
echo $SCRATCH
echo `date`

#INPUT $1=filename.tar.gz $2=subjid

tar -xzvf $1 -C $SCRATCH/

mkdir -p $SCRATCH/MGZ
mkdir -p $SCRATCH/REGISTERED
mkdir -p $SCRATCH/LTA
mkdir -p $SCRATCH/CONFORM

folder=$(find $SCRATCH -type d -links 2 | grep "DICOM")

for f in ${folder} ; do
    ffile=$(find ${f} -type f | head -1) # Finds first Dicom File
    ttime=$(${FREESURFER_HOME}/bin/mri_probedicom --i ${ffile} --t 8 31 | cut -d '.' -f 1)
    date=$(${FREESURFER_HOME}/bin/mri_probedicom --i ${ffile} --t 8 21)
    scan=$(${FREESURFER_HOME}/bin/mri_probedicom --i ${ffile} --t 8 103E | cut -d ' ' -f 1 )
    mri_convert -iid 0 -1 0 -ijd 0 0 -1 -ikd 1 0 0 ${ffile} $SCRATCH/MGZ/${scan}-${date}-${ttime}.mgz
done

find $SCRATCH/MGZ -type f  -size -10M -delete # Delete corrupted files, i.e. files that uses less than 10 MB memory 


list=$( find $SCRATCH -type f | grep "MGZ/T1_3D" | sort)

for i  in ${list}; do 
       ${FREESURFER_HOME}/bin/mri_convert --conform -odt float $i $SCRATCH/CONFORM/$(basename $i)
done  

#list=$( find $SCRATCH/CONFORM -type f | sort )
#baseline=$(find $SCRATCH/CONFORM -type f | sort | head -1 ) 
${FREESURFER_HOME}/bin/mri_robust_template --mov ${list} --average 1 --template $SCRATCH/REGISTERED/template.mgz --satit --inittp 1 --fixtp --noit --maxit 10 --subsample 200 
for i in ${list}; do 
	fname=$(basename $i) 
	${FREESURFER_HOME}/bin/mri_robust_register --mov $i --dst $SCRATCH/REGISTERED/template.mgz --satit --maxit 10 --mapmov $SCRATCH/REGISTERED/$fname --lta $SCRATCH/LTA/"${fname%.*}".lta
done


#if [ -z "$T2" ]; then
#recon-all -sd $SCRATCH -subjid $2 -i $T1 -all
#else 
#recon-all -sd $SCRATCH -subjid $2 -i $T1 -T2 $T2 -all
#fi



















