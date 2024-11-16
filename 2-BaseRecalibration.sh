#!/bin/bash

### 2- Base Quality Recalibration Script

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

variation_site01="/home/user07/genomics/project/snpDb/1000G_omni2.5.hg19.vcf"
variation_site02="/home/user07/genomics/project/snpDb/hapmap_3.3.hg19.vcf"
variation_site03="dbsnp"
variation_site04="1000g high confidence"
variation_site05="gnomAD"
variation_site06="ExAc"

for sample_no in 01 02 03
do
	$gatk_path --java-options "-Dsamjdk.compression_level=$compression_level -Xmx${command_mem_gb}g" \
		BaseRecalibrator \
		-I $resultsDir/$sample_name$sample_no.piped.undup.sorted.bam \
		-R $ref_fasta \
		-O $resultsDir/recal_data$sample_no.table \
		--known-sites $variation_site01 \
		--known-sites $variation_site02

	$gatk_path --java-options "-Dsamjdk.compression_level=$compression_level -Xmx${command_mem_gb}g" \
		ApplyBQSR \
		-R $ref_fasta \
		-I $resultsDir/$sample_name$sample_no.piped.undup.sorted.bam \
		--bqsr-recal-file $resultsDir/recal_data$sample_no.table \
		-O $resultsDir/$sample_name$sample_no.piped.undup.sorted.recal.bam

done

