# Obtaining data 

## 1 - Introduction

This document describes how the legend data required as input for hapgen2 was obtained for this pipeline.

## 2 - Obtaining data for hapgen2

To obtain legend data, the following downloads were performed:

```
$ cd testdata
$ mkdir legend_for_hapgen2 && cd legend_for_hapgen2
# Download a VCF from previous imputation job (left untracked)
# gunzip it
```

## 2 - Run a script to obtain, for each chromosome, a *leg file that will be used as input for hapgen2

```
$ pwd
$ assets/legend_for_hapgen2
$ bash make-leg-files.sh -f 72.ftdna-illumina.36.vcf
```




