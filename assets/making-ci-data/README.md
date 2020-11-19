# Obtaining data 

## 1 - Introduction

This document describes how test data to use for CI testing was obtained for this pipeline. 

More context:
- Given that this pipeline uses 1000G data (which comes in the form of a large `tar.gz` file that has to be downloaded) and `leg` files (which although smaller also come in the form a `tar.gz` file that has to be downloaded), CI testing using those files will not be possible.

- The aim here is therefore to generate smaller test datasets to be able to use exclusively for CI testing.

First, the pipeline was run as follows:
```
$ nextflow run main.nf --num_participants 40 --simulate_vcf true --simulate_plink true
```

# 2 - Obtaining a subset of the 1000G dataset

This was done as follows:
```
$ cd results/1000G-data
$ mkdir ALL_1000G_phase1integrated_v3_impute
$ cp *chr21* ALL_1000G_phase1integrated_v3_impute/
$ tar cvzf ALL_1000G_phase1integrated_v3_impute.tgz ALL_1000G_phase1integrated_v3_impute/
```

Push to S3:
```
aws s3 cp ALL_1000G_phase1integrated_v3_impute.tgz s3://testdata-magda/simulate-ci-testing/ --acl public-read
```

NB: this file was not commited to the repository. It therefore just present on S3.

# 3 - Obtaining a subset of the 1000G dataset

This was done as follows:
```
$ cd ../leg-data
$ tar cvzf all_leg_chr21.tar.gz chr21-15954660.leg
```

Push to S3:
```
aws s3 cp all_leg_chr21.tar.gz s3://testdata-magda/simulate-ci-testing/ --acl public-read
```

NB: this file was not commited to the repository. It therefore just present on S3.

# 4 - Making CI tests

Proceed to the usual procedure for making CI tests.


