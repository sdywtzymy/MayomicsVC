#!/bin/bash

################################################################################################################################
#
# Deduplicate BAM using Sentieon Locus Collector and Dedup algorithms. Part of the MayomicsVC Workflow.
# 
# Usage:
# dedup.sh -s <sample_name> -b <aligned.sorted.bam> -O <output_directory> -S </path/to/sentieon> -t <threads> -e </path/to/error_log> -d set_debug_mode (true/false)
#
################################################################################################################################

SCRIPT_NAME=dedup.sh
SGE_JOB_ID=TBD  # placeholder until we parse job ID
SGE_TASK_ID=TBD  # placeholder until we parse task ID


## Logging functions
# Get date and time information
function getDate()
{
    echo "$(date +%Y-%m-%d'T'%H:%M:%S%z)"
}

# This is "private" function called by the other logging functions, don't call it directly,
# use logError, logWarn, etc.
function _logMsg () {
    echo -e "${1}"

    if [[ -n ${ERRLOG-x} ]]; then
        echo -e "${1}" | sed -r 's/\\n//'  >> "${ERRLOG}"
    fi
}

function logError()
{
    local LEVEL="ERROR"
    local CODE="-1"

    if [[ ! -z ${2+x} ]]; then
        CODE="${2}"
    fi

    >&2 _logMsg "[$(getDate)] ["${LEVEL}"] [${SCRIPT_NAME}] [${SGE_JOB_ID-NOJOB}] [${SGE_TASK_ID-NOTASK}] [${CODE}] \t${1}"
}

function logWarn()
{
    local LEVEL="WARN"
    local CODE="0"

    if [[ ! -z ${2+x} ]]; then
        CODE="${2}"
    fi

    _logMsg "[$(getDate)] ["${LEVEL}"] [${SCRIPT_NAME}] [${SGE_JOB_ID-NOJOB}] [${SGE_TASK_ID-NOTASK}] [${CODE}] \t${1}"
}

function logInfo()
{
    local LEVEL="INFO"
    local CODE="0"

    if [[ ! -z ${2+x} ]]; then
        CODE="${2}"
    fi

    _logMsg "[$(getDate)] ["${LEVEL}"] [${SCRIPT_NAME}] [${SGE_JOB_ID-NOJOB}] [${SGE_TASK_ID-NOTASK}] [${CODE}] \t${1}"
}

## Input and Output parameters
while getopts ":h:s:b:O:S:t:e:d:" OPT
do
        case ${OPT} in
                h )  # Flag to display usage 
			echo " "
                        echo "Usage:"
			echo " "
                        echo "  bash dedup.sh -h       Display this help message."
                        echo "  bash dedup.sh [-s sample_name] [-b <aligned.sorted.bam>] [-O <output_directory>] [-S </path/to/sentieon>] [-t threads] [-e </path/to/error_log>] [-d debug_mode [false]]"
			echo " "
			exit 0;
                        ;;
		s )  # Sample name. String variable invoked with -s
			SAMPLE=${OPTARG}
			echo ${SAMPLE}
			;;
                b )  # Full path to the input BAM file. String variable invoked with -b
                        INPUTBAM=${OPTARG}
                        echo ${INPUTBAM}
                        ;;
                O )  # Output directory. String variable invoked with -O
                        OUTDIR=${OPTARG}
                        echo ${OUTDIR}
                        ;;
                S )  # Full path to sentieon directory. String variable invoked with -S
                        SENTIEON=${OPTARG}
                        echo ${SENTIEON}
                        ;;
                t )  # Number of threads available. Integer invoked with -t
                        THR=${OPTARG}
                        echo ${THR}
                        ;;
                e )  # Full path to error log file. String variable invoked with -e
                        ERRLOG=${OPTARG}
                        echo ${ERRLOG}
                        ;;
                d )  # Turn on debug mode. Boolean variable [true/false] which initiates 'set -x' to print all text
                        DEBUG=${OPTARG}
                        echo ${DEBUG}
                        ;;
        esac
done

## Turn on Debug Mode to print all code
if [[ ${DEBUG} == true ]]
then
	logInfo "Debug mode is ON."
        set -x
fi

## Check if input files, directories, and variables are non-zero
if [[ ! -d ${OUTDIR} ]]
then
        logError "$0 stopped at line $LINENO. \nREASON=Output directory ${OUTDIR} does not exist."
        exit 1;
fi
if [[ ! -s ${INPUTBAM} ]]
then 
        logError "$0 stopped at line $LINENO. \nREASON=Input sorted BAM file ${INPUTBAM} is empty."
	exit 1;
fi
if [[ ! -s ${INPUTBAM}.bai ]]
then
        logError "$0 stopped at line $LINENO. \nREASON=Sorted BAM index file ${INPUTBAM}.bai is empty."
        exit 1;
fi
if [[ ! -d ${SENTIEON} ]]
then
        logError "$0 stopped at line $LINENO. \nREASON=Sentieon directory ${SENTIEON} does not exist."
	exit 1;
fi
if (( ${THR} % 2 != 0 ))
then
	logWarn "Threads set to an odd integer. Subtracting 1 to allow for parallel, even threading."
	THR=$((THR-1))
fi

## Defining file names
samplename=${SAMPLE}
SCORETXT=${OUTDIR}/${SAMPLE}.score.txt
OUT=${OUTDIR}/${SAMPLE}.deduped.bam
OUTBAMIDX=${OUTDIR}/${SAMPLE}.deduped.bam.bai
DEDUPMETRICS=${OUTDIR}/${SAMPLE}.dedup_metrics.txt

## Record start time
logInfo "[SENTIEON] Collecting info to deduplicate BAM with Locus Collector."

## Locus Collector command
export SENTIEON_LICENSE=bwlm3.ncsa.illinois.edu:8989
${SENTIEON}/bin/sentieon driver -t ${THR} -i ${INPUTBAM} --algo LocusCollector --fun score_info ${SCORETXT} 
wait
logInfo "[SENTIEON] Locus Collector finished; starting Dedup."

## Dedup command (Note: optional --rmdup flag will remove duplicates; without, duplicates are marked but not removed)
export SENTIEON_LICENSE=bwlm3.ncsa.illinois.edu:8989
${SENTIEON}/bin/sentieon driver -t ${THR} -i ${INPUTBAM} --algo Dedup --score_info ${SCORETXT} --metrics ${DEDUPMETRICS} ${OUT}

logInfo "[SENTIEON] Deduplication Finished."
logInfo "[SENTIEON] Deduplicated BAM found at ${OUT}"

## Check for creation of output BAM and index. Open read permissions to the user group
if [[ ! -s ${OUT} ]]
then
        logError "$0 stopped at line $LINENO. \nREASON=Output deduplicated BAM file ${OUT} is empty."
        exit 1;
fi
if [[ ! -s ${OUTBAMIDX} ]]
then
        logError "$0 stopped at line $LINENO. \nREASON=Output deduplicated BAM index file ${OUTBAMIDX} is empty."
        exit 1;
fi

chmod g+r ${OUT}
chmod g+r ${OUTBAMIDX}
chmod g+r ${DEDUPMETRICS}
