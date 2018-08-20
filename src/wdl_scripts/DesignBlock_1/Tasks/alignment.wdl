###########################################################################################

##              This WDL script performs alignment using BWA Mem                         ##

##                              Script Options
#       -t        "Number of Threads"                         (Optional)
#       -P        "Single Ended Reads specification"          (Required)
#       -l        "Left Fastq File"                           (Required)
#       -r        "Right Fastq File"                          (Optional)
#       -G        "Reference Genome"                          (Required)
#       -s        "Name of the sample"                        (Optional)
#       -S        "Path to the Sentieon Tool"                 (Required)
#       -L        "Sentieon License File"                     (Required)
#       -g        "Group"                                     (Required)
#       -p        "Platform"                                  (Required)

###########################################################################################

task alignmentTask {

   File InputRead1                 # Input Read File           
   String InputRead2               # Input Read File           
   String SampleName               # Name of the Sample
   String Group                    # starting read group string
   String Platform                 # sequencing platform for read group
   Boolean PairedEnd               # Variable to check if single ended or not

   File Ref                        # Reference Genome
   File RefAmb                     # reference file index
   File RefAnn                     # reference file index
   File RefBwt                     # reference file index
   File RefPac                     # reference file index
   File RefSa                      # reference file index

   String SentieonLicense          # Sentieon License server
   String Sentieon                 # Path to Sentieon
   String SentieonThreads          # Specifies the number of thread required per run

   File AlignmentScript            # Bash script which is called inside the WDL script
   String ChunkSizeInBases         # The -K option for BWA MEM


   String DebugMode                # Flag to enable Debug Mode

   command {

      /bin/bash ${AlignmentScript} -L ${SentieonLicense} -P ${PairedEnd} -g ${Group} -l ${InputRead1} -r ${InputRead2} -s ${SampleName} -p ${Platform} -G ${Ref} -K ${ChunkSizeInBases} -S ${Sentieon} -t ${SentieonThreads} ${DebugMode}

   }

   output {

      File AlignedSortedBam = "${SampleName}.aligned.sorted.bam"
      File AlignedSortedBamBai = "${SampleName}.aligned.sorted.bam.bai"

   }

} 

