# Obtaining data 

## 1 - Introduction

This document describes how data was obtained for testing this pipeline.

## 2 - Obtaining data for hapgen2

To obtain legend data, the following downloads were performed:

```
$ cd testdata
$ mkdir legend_for_hapgen2 && cd legend_for_hapgen2
# Download a VCF from previous imputation job.
# gunzip it
```

To obtain 1000Genomes data
```
$ cd ../ && mkdir 1000G-data && cd 1000G-data
$ wget http://mathgen.stats.ox.ac.uk/impute/ALL_1000G_phase1integrated_v3_impute.tgz
# Manually unzip/untar the file
```


