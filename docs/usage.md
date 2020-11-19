# Usage documentation

## 1 - Introduction

This document provides a detailed guide on how to run the lifebit-ai/simulate pipeline.

## 2 - Usage

This pipeline requires 2 datasets, both of which are pre-generated (i.e. do not have to be supplied by the user):
- 1000G reference data (used for the re-sampling): hap files and genetic map files
- Legend files containing SNPs you wish to simulate

When combined, `hapgen2` will use your legend files to simulate (or re-sample) 1000G data.
Notably, hapgen2 produced `.gen` and `.sample` files (per chromosome). These are subsequently converted to multisample VCFs and/or PLINK files. See more about this in `output.md`.

## 3 - Regarding builds

This pipeline is based on build 37. In other words, all simulated data is in build 37.

## 4 - Basic example

The typical command for running the pipeline is as follows:

```
nextflow run main.nf --num_participants 40
```

## 5 - Essential parameters

- **--num_participants**: number of participants to simulate

## 5 - Optional parameters

- **--effective_population_size**: population size (for hapgen2) (default: 11418)
  
- **--mutation_rate**: mutation rate (for hapgen2) (default: -1)

- **--simulate_vcf**: simulate VCF files (default: false)

- **--simulate_plink**: simulate PLINK files (default: false)

- **--simulate_gwas_sum_stats**: simulate GWAS summary statistics with GCTA (default: false)

**--gwas_cases**: the number of cases to simulate for the GWAS summary statistics (the total with controls should match --effective_population_size)
   
**--gwas_controls**: the number of controls to simulate for the GWAS summary statistics (the total with cases should match --effective_population_size)

**--gwas_pheno_trait_type**: type of trait of interest (pheno_col) to use when simulating GWAS summary statistics with GTCA (available: `binary`, `quantitative` ; default: `binary`)

**--gwas_heritability**: heritibility for simulating GWAS summary statistics (default: 0.1)

**--gwas_disease_prevelance**: disease prevalence for simulating GWAS summary statistics (default: 0.1)

**--gwas_simulation_replicates**: number of simulation replicates for simulating GWAS summary statistics (default: 1)
    

