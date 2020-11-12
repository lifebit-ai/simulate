# Obtaining data 

## 1 - Introduction

This document describes how the legend data required as input for hapgen2 was obtained for this pipeline.

## 2 - Obtaining data for hapgen2

To obtain legend data, the following downloads were performed:

```
$ cd assets
$ mkdir legend_for_hapgen2 && cd legend_for_hapgen2
# Download a VCF from previous imputation job (left untracked)
# gunzip it
```

## 3 - Removing any non-biallelic SNPs

In order for the future `.gen` to PLINK/VCF format conversions to work smoothly, we will only keep bi-allelic SNPs. Therefore, before making `*leg` files, one must process the downloaded VCF using `bcftools` to remove any non-biallelic SNPs.

```
# Obtain a container to run the command
$ docker pull lifebitai/bcftools
$ docker run --rm -it -v "$PWD":"$PWD" -w "$PWD" lifebitai/bcftools:latest

# Remove any SNP that is not bi-allelic (as described in 2 links below)
bcftools view -m2 -M2 -v snps 72.ftdna-illumina.36.vcf > only_biallelic_snps.vcf

$ wc -l only_biallelic_snps.vcf 
# 2139 only_biallelic_snps.vcf
$ wc -l 72.ftdna-illumina.36.vcf # which is the download file from a previous imputation job
# 2159 72.ftdna-illumina.36.vcf
# Quit Docker container.
```

Links:
- http://samtools.github.io/bcftools/bcftools.html#view 
- https://www.biostars.org/p/141156/

## 2 - Run a script to obtain, for each chromosome, a *leg file that will be used as input for hapgen2

```
$ pwd
$ assets/legend_for_hapgen2
$ bash make-leg-files.sh -f only_biallelic_snps.vcf
```

## 3 - Create a single tar.gz file to upload to S3

```
$ tar -zcf all_leg.tgz *.leg
```

Then can change the comment to open up
The file can now be uploaded to S3.

