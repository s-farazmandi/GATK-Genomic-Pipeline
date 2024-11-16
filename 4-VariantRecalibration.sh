#!/bin/bash

### 4- Variant Recalibration Script
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

mergedvcf="$resultsDir/$sample_name.merged.vcf"

$gatk_path VariantRecalibrator \
	-R $ref_fasta \
	-V $mergedvcf \
	--resource:omni,known=false,training=true,truth=true,prior=12.0 $variation_site01 \
	--resource:hapmap,known=false,training=true,truth=true,prior=15.0 $variation_site02 \
	--resource:dbsnp,known=true,training=false,truth=false,prior=2.0 $variation_site03 \
	--resource:1000G,known=false,training=true,truth=false,prior=10.0 $variation_site04 \
	-an QD -an MQ -an MQRankSum -an ReadPosRankSum -an FS -an SOR \
	-mode SNP \
	-O $resultsDir/$sample_name.recal \
	--tranches-file $resultsDir/$sample_name.tranches \
	--rscript-file $resultsDir/$sample_name.plots.R

$gatk_path ApplyVQSR \
	-R $ref_fasta \
	-V $mergedvcf \
	-O $resultsDir/$sample_name.VQSR.vcf.gz \
	--truth-sensitivity-filter-level 99 \
	--tranches-file $resultsDir/$sample_name.tranches \
	--recal-file $resultsDir/$sample_name.recal \
	-mode SNP


