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

- **--simulate_gwas_sum_stats**: simulate GWAS summary statistics with GCTA (default: false).

- **--gwas_cases_proportion**: the number of cases to simulate for the GWAS summary statistics, represented as a fraction of --num_participants bigger than 0 and up to 1 (default: 0.5). Notably, if the proportion of cases results in a a float number of cases (i.e. for example if num_participants=40 and gwas_cases_proportion=0.42, then the number of cases would be 0.42*40 = 16.8), the pipeline will round down the number (i.e. in the example given, the number of cases will be set to 16). In addition, it should be noted that the final number of simulated cases may be smaller than the number provided by the user, due to how `GCTA` samples individuals for the simulation (i.e. it selects a subset of individuals in the provided genotype data). See more details at: https://cnsgenomics.com/software/gcta/#GWASSimulation.

- **--gwas_pheno_trait_type**: type of trait of interest (pheno_col) to use when simulating GWAS summary statistics with GTCA (available: `binary`, `quantitative` ; default: `binary`)

- **--gwas_heritability**: heritibility for simulating GWAS summary statistics (default: 0.1)

- **--gwas_disease_prevelance**: disease prevalence for simulating GWAS summary statistics (default: 0.1)

- **--gwas_simulation_replicates**: number of simulation replicates for simulating GWAS summary statistics (default: 1)

- **--simulate_cb_output**: whether or not you wish to simulate the cohort browser (CB) output data - this can subsequently be used by lifebit-ai/gel-gwas (default: false)

- **--simulate_cb_output_config**: the YAML config file used to simulate cohort browser data with (must be provided if --simulate_cb_output is set to true )

- **simulate_cb_output_output_tag**: the outprefix you wish to give to the simulated cohort browser data (default: `simulated`)


