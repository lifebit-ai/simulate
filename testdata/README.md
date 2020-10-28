# Obtaining test data 

## 1 - Introduction

This document describes how testdata was obtained.

## 2 - Obtaining test data for hapgen2

To obtain input data, the following downloads were performed:

```
$ cd testdata
$ mkdir hapgen2-data && cd hapgen2-data
$ wget http://mathgen.stats.ox.ac.uk/genetics_software/hapgen/download/example/hapgen2.example.tgz
# Untar

$ cd ../ && mkdir 1000G-data && cd 
$ wget http://mathgen.stats.ox.ac.uk/impute/ALL_1000G_phase1integrated_v3_impute.tgz
# Unzip the *hap.gz files
```

