# Context

This file contains commands and instructions used to generate data using `lifebit-ai/simulate` that would need be used to run `lifebit-ai/gel-gwas`. To be clear, the aims are as follows:

- Run `lifebit-ai/simulate` to obtain PLINK files and multisample VCF files.
- Use the multisample VCFs to run `lifebit-ai/gel-gwas`.

In order for the inputs to be used by `lifebit-ai/gel-gwas`, they will need some formatting. This document details the formatting steps that were required.

# 1 - Steps for gzipping VCF files, indexing them and producing input .cvs file

1) Run the `lifebit-ai/simulate` to obtain data for 40 participants. 

2) Gzip the VCF files and index them

```
# Launch the appropriate docker image
$ docker run --rm -it -v "$PWD":"$PWD" -w "$PWD" lifebitai/bcftools:latest
$ cd testdata
$ mkdir vcf && cd vcf

# Gzip the VCF files
$ cp ../../results/simulated_vcf/*vcf .
for i in $(ls *vcf)
do
bcftools view -I ${i} -Oz -o ${i}.gz
done

# Index the files
$ for i in $(ls *vcf.gz)
do
bcftools index ${i}
done

# Quit the container and send the files to my S3 bucket
$ aws s3 cp . s3://testdata-magda/gel-gwas-test-vcf/ --include "*vcf.gz" --acl public-read --recursive
```

# 2 - Steps for a .csv file to match the new files

This file was based off `s3://lifebit-featured-datasets/projects/gel/gel-gwas/testdata/vcfs.csv`
Once done, send it to the S3 as show below.

```
aws s3 cp vcfs.csv s3://testdata-magda/gel-gwas-test-vcf/ --acl public-read
```

# 3- Steps for producing the pheno file

1) Download an example pheno file
```
$ cd testdata/pheno
$ mkdir pheno && cd pheno
$ wget https://gist.githubusercontent.com/mcamarad/e98cdd5e69413fb6189ed70405c43ef4/raw/d602bec4b31d5d75f74f1dbb408bd392db57bdb6/cohort_data_phenos.csv
```

2) Manually change the sample IDs to match the ones in my VCF files

For this, manually replace the first row by the IDs present in my VCF files. The simulated data has less samples than the pheno file but the GWAS pipeline will handle this.

```
# Once done, send it to the S3
aws s3 cp cohort_data_phenos_simtest.csv s3://testdata-magda/gel-gwas-test-vcf/ --acl public-read
```

# 4 - About file tracking

This work was done on an AWS EC2 instance. For this purposes:
- `testdata/vcf/vcfs.csv` was not saved to repo but are on the S3.
- `testdata/pheno/cohort_data_phenos_simtest.csv` was not saved to repo but are on the S3.
- The VCFs (which are in `.gz` and index were not saved to repo but are on the S3.


