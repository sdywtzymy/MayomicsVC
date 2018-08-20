###########################################################################################

##              This WDL script performs realignment using Sentieon                ##

##                                Script Options
#       -t        "Number of Threads"                                     (Optional)
#       -G        "Reference Genome"                                      (Required)
#       -b        "Input Deduped Bam"                                     (Required)
#       -k        "List of Known Sites"                                   (Required)
#       -s        "Name of the sample"                                    (Optional)
#       -S        "Path to the Sentieon Tool"                             (Required)
#       -L        "Sentieon License File"                                 (Required)

###########################################################################################

task realignmentTask {

   File InputAlignedSortedDedupedBam                  # Input Sorted Deduped Bam
   File InputAlignedSortedDedupedBamBai               # Input Sorted Deduped Bam Index

   File Ref                                           # Reference Genome
   File RefFai                                        # Reference Index File
                                  
   String SampleName                                  # Name of the Sample

   String RealignmentKnownSites                                    # List of known sites
#   File KnownSitesBai                                 # Index file for the known sites

   String SentieonLicense                             # Sentieon License Information
   String Sentieon                                    # Path to Sentieon
   String SentieonThreads                             # No of Threads for the Tool

   String DebugMode                                   # Enable or Disable Debug Mode
   
   File RealignmentScript                             # Path to bash script called within WDL script
 

   command {
      /bin/bash ${RealignmentScript} -L ${SentieonLicense} -s ${SampleName} -b ${InputAlignedSortedDedupedBam} -G ${Ref} -k ${RealignmentKnownSites} -S ${Sentieon} -t ${SentieonThreads} ${DebugMode}
   }

   output {
      File AlignedSortedDedupedRealignedBam = "${SampleName}.aligned.sorted.deduped.realigned.bam"
      File AlignedSortedDedupedRealignedBamBai = "${SampleName}.aligned.sorted.deduped.realigned.bam.bai"
   }  
   
} 
