#!/bin/bash

### 1- Preprocessing Script

## Variable Definition

# System Parameters
thread_no=16
command_mem_gb=16
compression_level=5

# Workflow Parameters
gatk_path="/home/data/gatk4/gatk"
ref_fasta="/home/data/Project/Ref/human_g1k_v37.fasta"
bed_path="/home/data/Project/Bed/SureSelect_V7.bed"

resultsDir="/home/user07/genomics/project/results"

sample_name="Case"

fastq01_1="/home/data/Project/Trio/CASE01/CASE01_1.fastq.gz"
fastq01_2="/home/data/Project/Trio/CASE01/CASE01_2.fastq.gz"
fastq02_1="/home/data/Project/Trio/CASE02/CASE02_1.fastq.gz"
fastq02_2="/home/data/Project/Trio/CASE02/CASE02_2.fastq.gz"
fastq03_1="/home/data/Project/Trio/CASE03/CASE03_1.fastq.gz"
fastq03_2="/home/data/Project/Trio/CASE03/CASE03_1.fastq.gz"
platform_unit01="A00553.114.H5TJTDSX3.4.GGTATCAC+CACAAGTA"
platform_unit02="A00553.114.H5TJTDSX3.4.CGCACTCG+GATCTTAA"
platform_unit03="GWES1257.325.HH2WJDSX2.1.ATAGTGAA+ACGGCTGG"

for sample_no in 01 02 03
do
	R1=fastq${sample_no}_1
	R2=fastq${sample_no}_2
	R3=platform_unit${sample_no}

	# Converts Fastq file to uBam along with adding Group information
	$gatk_path --java-options "-Dsamjdk.compression_level=$compression_level -Xmx${command_mem_gb}g" \
		FastqToSam \
		--FASTQ ${!R1} \
		--FASTQ2 ${!R2} \
		--OUTPUT $resultsDir/$sample_name$sample_no.unmapped.bam \
		--READ_GROUP_NAME G$sample_name$sample_no \
		--SAMPLE_NAME $sample_name$sample_no \
		--LIBRARY_NAME Lib$sample_name$sample_no \
		--PLATFORM_UNIT ${!R3} \
		--PLATFORM Illumina

	# Marks Adapter Sequences
	$gatk_path --java-options "-Dsamjdk.compression_level=$compression_level -Xmx${command_mem_gb}g" \
		MarkIlluminaAdapters \
		--INPUT $resultsDir/$sample_name$sample_no.unmapped.bam \
		--OUTPUT $resultsDir/$sample_name$sample_no.unmapped.markilluminaadapters.bam \
		--METRICS $resultsDir/$sample_name$sample_no.unmapped.markilluminaadapters.metrics.txt


	#[SamToFastq] | [BWA-MEM] | [MergeBamAlignment]
	#Piped command

	$gatk_path --java-options "-Dsamjdk.compression_level=$compression_level -Xmx${command_mem_gb}g" \
		SamToFastq \
		--INPUT $resultsDir/$sample_name$sample_no.unmapped.markilluminaadapters.bam \
		--FASTQ /dev/stdout \
		--CLIPPING_ATTRIBUTE XT \
		--CLIPPING_ACTION 2 \
		--INTERLEAVE true \
		--NON_PF true | \

	bwa mem -M -t $thread_no -p $ref_fasta /dev/stdin | \

	$gatk_path --java-options "-Dsamjdk.compression_level=$compression_level -Xmx${command_mem_gb}g" \
		MergeBamAlignment \
		--ALIGNED_BAM /dev/stdin \
		--UNMAPPED_BAM $resultsDir/$sample_name$sample_no.unmapped.bam \
		--OUTPUT $resultsDir/$sample_name$sample_no.piped.bam \
		--REFERENCE_SEQUENCE $ref_fasta \
		--CREATE_INDEX true \
		--ADD_MATE_CIGAR true \
		--CLIP_ADAPTERS false \
		--CLIP_OVERLAPPING_READS true \
		--INCLUDE_SECONDARY_ALIGNMENTS true \
		--MAX_INSERTIONS_OR_DELETIONS -1 \
		--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
		--ATTRIBUTES_TO_RETAIN XS

	$gatk_path --java-options "-Dsamjdk.compression_level=$compression_level -Xmx${command_mem_gb}g" \
		MarkDuplicates \
		--INPUT $resultsDir/$sample_name$sample_no.piped.bam \
		--OUTPUT $resultsDir/$sample_name$sample_no.piped.undup.bam \
		--METRICS_FILE $resultsDir/$sample_name$sample_no.piped.undup.metrics.txt \
		--VALIDATION_STRINGENCY SILENT \
		--OPTICAL_DUPLICATE_PIXEL_DISTANCE 2500 \
		--ASSUME_SORT_ORDER "queryname" \
		--CREATE_MD5_FILE true

	$gatk_path --java-options "-Dsamjdk.compression_level=$compression_level -Xmx${command_mem_gb}g" \
		SortSam \
		--INPUT $resultsDir/$sample_name$sample_no.piped.undup.bam \
		--OUTPUT /dev/stdout \
		--SORT_ORDER "coordinate" \
		--CREATE_INDEX false \
		--CREATE_MD5_FILE false \
		| \

	$gatk_path --java-options "-Dsamjdk.compression_level=$compression_level -Xmx${command_mem_gb}g" \
		SetNmMdAndUqTags \
		--INPUT /dev/stdin \
		--OUTPUT $resultsDir/$sample_name$sample_no.piped.undup.sorted.bam \
		--CREATE_INDEX true \
		--CREATE_MD5_FILE true \
		--REFERENCE_SEQUENCE $ref_fasta

	samtools flagstat $resultsDir/$sample_name$sample_no.piped.undup.sorted.bam \
		> $resultsDir/$sample_name$sample_no.bamflagstat.txt
	samtools idxstats $resultsDir/$sample_name$sample_no.piped.undup.sorted.bam \
		> $resultsDir/$sample_name$sample_no.bamidxstats.txt
done
