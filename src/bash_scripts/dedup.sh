#!/bin/bash

################################################################################################################################
#
# Deduplicate BAM using Sentieon Locus Collector and Dedup algorithms. Part of the MayomicsVC Workflow.
# 
# Usage:
# dedup.sh -s <sample_name> -b <aligned.sorted.bam> -O <output_directory> -S </path/to/sentieon> -t <threads> -e </path/to/error_log>
#
################################################################################################################################

## Input and Output parameters
while getopts ":h:s:b:O:S:t:e:" OPT
do
        case ${OPT} in
                h )
                        echo "Usage:"
                        echo "  bash dedup.sh -h       Display this help message."
                        echo "  bash dedup.sh [-s sample_name] [-b <aligned.sorted.bam>] [-O <output_directory>] [-S </path/to/sentieon>] [-t threads] [-e </path/to/error_log>] "
                        ;;
		s )
			s=${OPTARG}
			echo $s
			;;
                b )
                        b=${OPTARG}
                        echo $b
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
                e )
                        e=${OPTARG}
                        echo $e
                        ;;
        esac
done



INPUTBAM=${b}
SAMPLE=${s}
OUTDIR=${O}
SENTIEON=${S}
THR=${t}
ERRLOG=${e}

#set -x

## Check if input files, directories, and variables are non-zero
if [[ ! -s ${INPUTBAM} ]]
then 
        echo -e "$0 stopped at line $LINENO. \nREASON=Input sorted BAM file ${INPUTBAM} is empty." >> ${ERRLOG}
	exit 1;
fi
if [[ ! -d ${OUTDIR} ]]
then
	echo -e "$0 stopped at line $LINENO. \nREASON=Output directory ${OUTDIR} does not exist." >> ${ERRLOG}
	exit 1;
fi
if [[ ! -d ${SENTIEON} ]]
then
        echo -e "$0 stopped at line $LINENO. \nREASON=Sentieon directory ${SENTIEON} does not exist." >> ${ERRLOG}
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

samplename=${SAMPLE}
SCORETXT=${OUTDIR}/${SAMPLE}.score.txt
OUT=${OUTDIR}/${SAMPLE}.deduped.bam
OUTBAMIDX=${OUTDIR}/${SAMPLE}.deduped.bam.bai
DEDUPMETRICS=${OUTDIR}/${SAMPLE}.dedup_metrics.txt

## Record start time
START_TIME=`date "+%m-%d-%Y %H:%M:%S"`
echo "[SENTIEON] Collecting info to deduplicate BAM with Locus Collector. ${START_TIME}"

## Locus Collector command
${SENTIEON}/bin/sentieon driver -t ${THR} -i ${INPUTBAM} --algo LocusCollector --fun score_info ${SCORETXT} 
wait
echo "[SENTIEON] Locus Collector finished; starting Dedup."

## Dedup command (Note: optional --rmdup flag will remove duplicates; without, duplicates are marked but not removed)
${SENTIEON}/bin/sentieon driver -t ${THR} -i ${INPUTBAM} --algo Dedup --score_info ${SCORETXT} --metrics ${DEDUPMETRICS} ${OUT}

## Record end of the program execution
END_TIME=`date "+%m-%d-%Y %H:%M:%S"`
echo "[SENTIEON] Deduplication Finished. ${END_TIME}"
echo "[SENTIEON] Deduplicated BAM found at ${OUT}"

## Open read permissions to the user group
chmod g+r ${OUT}
chmod g+r ${OUTBAMIDX}
chmod g+r ${DEDUPMETRICS}
