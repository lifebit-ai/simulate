# Simulation pipeline

[![GitHub Actions CI Status](https://github.com/lifebit-ai/simulate/workflows/nf-core%20CI/badge.svg)](https://github.com/lifebit-ai/simulate/actions)
[![GitHub Actions Linting Status](https://github.com/lifebit-ai/simulate/workflows/nf-core%20linting/badge.svg)](https://github.com/lifebit-ai/simulate/actions)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A519.10.0-brightgreen.svg)](https://www.nextflow.io/)

## 1 - Introduction

This pipeline performs simulations of various genomics datasets. It is is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner.

## 2 - Quick Start

```
nextflow run main.nf \
--simulate_vcf true \
--simulate_plink true
```

## 3 - Documentation

The lifebit-ai/simulate pipeline comes with documentation about the pipeline which you can find in the [`docs/` directory](docs).


