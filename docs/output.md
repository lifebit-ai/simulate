# Output documentation

This document describes the output produced by the pipeline. 

## 1 - Introduction and dataflow

This pipeline aims to produce a number of different types of simulated outputs. In order to do so, it uses the following setup:

(need to add diagram)

## 2 - Regarding the conversions to PLINK and VCFs

The conversion from `.gen`/`.sample` to PLINK (`.bed`, `.bim` and `.fam`) and VCF (`.vcf`) technically constitutes a lossy transformation. Indeed, as explained in the `PLINK2` documentation (link: https://www.cog-genomics.org/plink/2.0/input):

```
Note that PLINK 2 collapses the raw probabilities stored in .gen/.bgen files down to dosages; you cannot use PLINK 2 to losslessly convert between e.g. BGEN sub-formats. (But if the next program in your pipeline is e.g. BOLT-LMM, which only cares about dosages, it's fine to use PLINK 2 for conversion.)
```

While this would normally lead to issues, the fact that we are simulating data, and more specifically that we are simulating `.gen` and `.sample` files for the sole purpose of converting them to `PLINK`/`VCF` formats, means that no real information is being lost. 


