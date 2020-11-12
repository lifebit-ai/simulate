# Context

This file contains commands and instructions used to generate data using `lifebit-ai/simulate` that would need be used to run `lifebit-ai/gel-gwas`. To be clear, the aims are as follows:

- Run `lifebit-ai/simulate` to obtain PLINK files and multisample VCF files.

# Specific steps

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

3) Make a .csv file to match the new files
```
# Once done, send it to the S3
aws s3 cp vcfs.csv s3://testdata-magda/gel-gwas-test-vcf/ --acl public-read
```


# Steps that should be added into the pipeline:

- Ability to merge PLINK files (if need be - should be an option perhaps): useful for `lifebit-ai/gel-gwas`
- In `hapgen2` process, rename the samples (using bash/sed etc) to match the kind of IDs one would expect in `lifebit-ai/gel-gwas`
- In step producing the VCF:
  - gzip them
  - index them (will need to add bcftools to container) 
  - Produce a `vfc.csv` file maybe 


