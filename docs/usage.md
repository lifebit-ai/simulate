# Usage documentation

## 1 - Introduction

This document provides a detailed guide on how to run the lifebit-ai/simulate pipeline.

## 2 - Usage

This pipeline requires 2 datasets, both of which are pre-generated (i.e. do not have to be supplied by the user):
- 1000G reference data (used for the re-sampling): hap files and genetic map files
- Legend files containing SNPs you wish to simulate

When combined, `hapgen2` will use your legend files to simulate (or re-sample) 1000G data.
Notably, hapgen2 produced `.gen` and `.sample` files (per chromosome). These are subsequently converted to multisample VCFs and/or PLINK files.

## 3 - Basic example

The typical command for running the pipeline is as follows:

```
nextflow run main.nf --num_participants 10
```

## 4 - Essential parameters

- **--num_participants**: number of participants to simulate

## 5 - Optional parameters

- **--simulate_vcf**: whether you wish to simulate VCF files (default: true)

- **--simulate_plink**: whether you wish to simulate PLINK files (default: true)


