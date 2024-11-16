#!/bin/bash

### 3- Variant Calling Script

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

sample01bam=$resultsDir/${sample_name}01.piped.undup.sorted.recal.bam
sample02bam=$resultsDir/${sample_name}02.piped.undup.sorted.recal.bam
sample03bam=$resultsDir/${sample_name}03.piped.undup.sorted.recal.bam

# Uncalibrated BAMs
# sample01bam=$resultsDir/${sample_name}01.piped.undup.sorted.bam
# sample02bam=$resultsDir/${sample_name}02.piped.undup.sorted.bam
# sample03bam=$resultsDir/${sample_name}03.piped.undup.sorted.bam

db_import_path="/home/user07/genomics/project/results/db"

for sample_no in 01 02 03
do
	R=sample${sample_no}bam

	$gatk_path --java-options "-Dsamjdk.compression_level=$compression_level -Xmx${command_mem_gb}g" \
		HaplotypeCaller \
		-R $ref_fasta \
		-I ${!R} \
		-O $resultsDir/$sample_name$sample_no.vcf \
		-L $bed_path \
		-ERC GVCF
done

# The db path should be a non-existant directory
rm -r $db_import_path

$gatk_path --java-options "-Xmx${command_mem_gb}g" \
	GenomicsDBImport \
	-V $resultsDir/${sample_name}01.vcf \
	-V $resultsDir/${sample_name}02.vcf \
	-V $resultsDir/${sample_name}03.vcf \
	--genomicsdb-workspace-path $db_import_path \
	-L $bed_path

$gatk_path --java-options "-Xmx${command_mem_gb}g" \
	GenotypeGVCFs \
	-R $ref_fasta \
	-O $resultsDir/$sample_name.merged.vcf \
	-V gendb://$db_import_path
