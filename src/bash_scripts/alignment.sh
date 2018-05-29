#!/bin/bash

################################################################################################################################
#
# Align reads using BWA-MEM and sort. Part of the MayomicsVC Workflow.
# 
# Usage:
# alignment.sh -g <readgroup_ID> -s <sample_name> -p <platform> -r <read1.fq> -R <read2.fq> -G <reference_genome> -O <output_directory> -S </path/to/Sentieon> -t <threads> -P <Is_single_end?> -e </path/to/error_log>
#
################################################################################################################################

## Input and Output parameters
while getopts ":h:g:s:p:r:R:G:O:S:t:P:e:" OPT
do
        case ${OPT} in
                h )
                        echo "Usage:"
                        echo "  bash alignment.sh -h       Display this help message."
                        echo "  bash alignment.sh [-g <readgroup_ID> [-s <sample_name>] [-p <platform>] [-r <read1.fq>] [-R <read2.fq>] [-G <reference_genome>] [-O <output_directory>] [-S </path/to/Sentieon>] [-t threads] [-P single-end? (true/false)] [-e </path/to/error_log>] "
                        ;;
                g )
                        g=${OPTARG}
                        echo $g
                        ;;
                s )
                        s=${OPTARG}
                        echo $s
                        ;;
                p )
                        p=${OPTARG}
                        echo $p
                        ;;
                r )
                        r=${OPTARG}
                        echo $r
                        ;;
                R )
                        R=${OPTARG}
                        echo $R
                        ;;
                G )
                        G=${OPTARG}
                        echo $G
                        ;;
                O )
                        O=${OPTARG}
                        echo $O
                        ;;
                S )
                        S=${OPTARG}
                        echo $S
                        ;;
                t )
                        t=${OPTARG}
                        echo $t
                        ;;
                P )
                        P=${OPTARG}
                        echo $P
                        ;;
                e )
                        e=${OPTARG}
                        echo $e
                        ;;
        esac
done



INPUT1=${r}
INPUT2=${R}
GROUP=${g}
SAMPLE=${s}
PLATFORM=${p}
REFGEN=${G}
OUTDIR=${O}
SENTIEON=${S}
THR=${t}
IS_SINGLE_END=${P}
ERRLOG=${e}

#set -x

## Check if input files, directories, and variables are non-zero
if [[ ! -s ${INPUT1} ]]
then 
        echo -e "$0 stopped at line $LINENO. \nREASON=Input read 1 file ${INPUT1} is empty." >> ${ERRLOG}
	exit 1;
fi
if [[ ! -s ${INPUT2} ]]
then
        echo -e "$0 stopped at line $LINENO. \nREASON=Input read 2 file ${INPUT2} is empty." >> ${ERRLOG}
	exit 1;
fi
if [[ ! -s ${REFGEN} ]]
then
        echo -e "$0 stopped at line $LINENO. \nREASON=Reference genome file ${REFGEN} is empty." >> ${ERRLOG}
        exit 1;
fi
if [[ ! -d ${OUTDIR} ]]
then
	echo -e "$0 stopped at line $LINENO. \nREASON=Output directory ${OUTDIR} does not exist." >> ${ERRLOG}
	exit 1;
fi
if [[ ! -d ${SENTIEON} ]]
then
        echo -e "$0 stopped at line $LINENO. \nREASON=BWA directory ${SENTIEON} does not exist." >> ${ERRLOG}
	exit 1;
fi
if (( ${THR} % 2 != 0 ))
then
	THR=$((THR-1))
fi
if [[ ! -f ${ERRLOG} ]]
then
        echo -e "$0 stopped at line $LINENO. \nREASON=Error log file ${ERRLOG} does not exist." >> ${ERRLOG}
        exit 1;
fi

## Parse filenames without full path
#name=$(echo "${INPUT1}" | sed "s/.*\///")
#full=${INPUT1}
#sample1=${full##*/}
#sample=${sample1%%.*}
OUT=${OUTDIR}/${SAMPLE}.sam
SORTBAM=${OUTDIR}/${SAMPLE}.sorted.bam
SORTBAMIDX=${OUTDIR}/${SAMPLE}.sorted.bam.bai

## Record start time
START_TIME=`date "+%m-%d-%Y %H:%M:%S"`
echo "[BWA-MEM] START. ${START_TIME}"

## BWA-MEM command, run for each read against a reference genome.
## Allocates all available threads to the process.
######## ASK ABOUT INTERLEAVED OPTION. NOTE: CAN ADD LANE TO RG OR REMOVE STRING
if [[ ${IS_SINGLE_END} == true ]]
then
	${SENTIEON}/bin/bwa mem -M -R "@RG\tID:$GROUP\tSM:${SAMPLE}\tPL:${PLATFORM}" -K 100000000 -t ${THR} ${REFGEN} ${INPUT1} > ${OUT} &
	wait
else
	${SENTIEON}/bin/bwa mem -M -R "@RG\tID:$GROUP\tSM:${SAMPLE}\tPL:${PLATFORM}" -K 100000000 -t ${THR} ${REFGEN} ${INPUT1} ${INPUT2} > ${OUT} &
	wait
fi
END_TIME=`date "+%m-%d-%Y %H:%M:%S"`
echo "[BWA-MEM] Aligned reads ${SAMPLE} to reference ${REFGEN}. ${END_TIME}"

## Convert SAM to BAM and sort
echo "[SAMTools] Converting SAM to BAM..."
${SENTIEON}/bin/sentieon util sort -t ${THR} --sam2bam -i ${OUT} -o ${SORTBAM} &
wait
BAM_TIME=`date "+%m-%d-%Y %H:%M:%S"`
echo "[SAMTools] Converted output to BAM format and sorted. ${BAM_TIME}"

## Open read permissions to the user group
chmod g+r ${OUT}
chmod g+r ${SORTBAM}
chmod g+r ${SORTBAMIDX}

echo "[BWA-MEM] Finished alignment. Aligned reads found in BAM format at ${SORTBAM}. ${END_TIME}"
