#!/bin/bash

### 4- Variant Hard Filtering Script

## Variable Definition

# System Parameters
thread_no=$(nproc)
command_mem_gb=16
compression_level=5

# Workflow Parameters
gatk_path="/home/data/gatk4/gatk"
ref_fasta="/home/data/Project/Ref/human_g1k_v37.fasta"
bed_path="/home/data/Project/Bed/SureSelect_V7.bed"

resultsDir="/home/user07/genomics/project/results"

sample_name="CASE"

mergedvcf="/home/Master/Master/TeamA/$sample_name.merged.vcf"

# Subset to SNPs-only callset with SelectVariants
$gatk_path SelectVariants \
	-V $mergedvcf \
	-select-type SNP \
	-O $resultsDir/snps.$sample_name.merged.vcf

# Subset to indels-only callset with SelectVariants
$gatk_path SelectVariants \
        -V $mergedvcf \
        -select-type INDEL \
        -O $resultsDir/indels.$sample_name.merged.vcf

# Subset to Mixed-only callset with SelectVariants
$gatk_path SelectVariants \
        -V $mergedvcf \
        -select-type MIXED \
        -O $resultsDir/mixed.$sample_name.merged.vcf

# Subset to indels-only and mixed-type callset with SelectVariants
$gatk_path SelectVariants \
        -V $mergedvcf \
        -select-type INDEL \
	-select-type MIXED \
        -O $resultsDir/indelsMixed.$sample_name.merged.vcf

# Filter SNPs-only callset
$gatk_path VariantFiltration \
	-V $resultsDir/snps.$sample_name.merged.vcf \
	-filter "QD < 2.0" --filter-name "QD2" \
	-filter "QUAL < 30.0" --filter-name "QUAL30" \
	-filter "SOR > 3.0" --filter-name "SOR3" \
	-filter "FS > 60.0" --filter-name "FS60" \
	-filter "MQ < 40.0" --filter-name "MQ40" \
	-filter "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" \
	-filter "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8" \
	-O $resultsDir/snps.filtered.$sample_name.merged.vcf

# Filter indels-only and mixed-only callset
$gatk_path VariantFiltration \
	-V $resultsDir/indelsMixed.$sample_name.merged.vcf \
	-filter "QD < 2.0" --filter-name "QD2" \
	-filter "QUAL < 30.0" --filter-name "QUAL30" \
	-filter "FS > 200.0" --filter-name "FS200" \
	-filter "ReadPosRankSum < -20.0" --filter-name "ReadPosRankSum-20" \
	-O $resultsDir/indelsMixed.filtered.$sample_name.merged.vcf


