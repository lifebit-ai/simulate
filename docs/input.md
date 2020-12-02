# Input documentation

This document describes the input needed by the pipeline. Currently we consider three scenarios for inputs

## 1 - Phenotypic data as query.json and metadata.csv

Because the pipeline needs a `query.json` file similar to [query.json](../testdata/query.json), it will only produce columns for those variables for which the `column` data has been filled in the `search` list. Example below.

In order to fill the `search` field with real data from columns, filters must be applied at the Cohort Browser GUI/API.

```json
{
    "columns":[ {
        "id":40,
                "instance":0,
                "array":{
                    "type":"exact",
                    "value":0

                }
    }],
    "type":"csv",
    "filename":"example_data",
    "parentId":"123456789",
    "kind":"dataset",
    "search":[
        {
            "column":{
                "id":10,
                "instance":0,
                "array":{
                    "type":"any",
                    "value":0

                }

            },
            "values":[
                "F",
                "M"
            ]
        }
    ]
}

```



The `generate_sim_config.R` script will read this file and the `metadata.csv` in order to create the following yaml file that will be used to simulate data:

```yaml
params:
  n_samples: 100.0
  seed: 777.0
  col_params:
    pheno_col:
      name: 'Participant phenotypic sex'
      type: 'Categorical'
      fraction_of_cases: 0.5
    Participant phenotypic sex:
      type: Categorical
      n_arrays: 1
      n_instances: 1
      values:
      - F
      - M
```
In order to do this, it will make use of a `.csv` file with the following header:

**NOTE**: In real data some columns will have different names, the script address this by adding an if clause to manage the differences.
```csv
FieldID Category Path,Level 2,FieldID,Array,Instances,Field Name,valueType,Sorting,FieldID Type,FieldID Type Units,Coding,Description Text,Description Participants No,Link,Description Stability,Description Category ID,Description ItemType,Description Strata,Description Sexed,order_phenotype,instance0_name,instance1_name,instance2_name,instance3_name,instance4_name,instance5_name,instance6_name,instance7_name,instance8_name,instance9_name,instance10_name,instance11_name,instance12_name,instance13_name,instance14_name,instance15_name,instance16_name,instance17_name,bucket_300,bucket_500,bucket_1000,bucket_2500,bucket_5000,bucket_10000,Original_name
```

The following parameters are responsible from controlling number of samples and pheno_col behaviour for subsequent scripts.
- **n_samples** : Number of total samples
- **pheno_col_name** : Name of the pheno_col
- **pheno_col_type** : Dtype for the pheno_col
- **pheno_col_fraction_of_cases** : Fraction of case samples if pheno_col is binary

## 2 - Phenotipic data as configuration files

Requires a `.yaml` file similar to the output of the previous process. Example below:

```yaml
params:
  n_samples: 100.0
  seed: 777.0
  col_params:
    pheno_col:
      name: Participant phenotypic sex
      type: Categorical
      fraction_of_cases: 0.5
    Participant phenotypic sex:
      type: Categorical
      n_arrays: 1
      n_instances: 1
      values:
      - F
      - M
```

This file contains all the necessary information for the simulation to run and generate data and metadata for it.

## 3 - Phenotipic data as raw files

Requires a form of phenotipic data/metadata (as `.tsv` or as `.json`) with at least the following fields:

- Column ID
- Column name
- Column Dtype: From Integer, Continuous, Categorical, Date.
- Instances
- Arrays
- Values - Can be either 1 or more columns in case of `.tsv`:
    - List of values (Categorical): i.e 'Nose', 'NOS', 'SWAB - Pharyngue'.
    - Range of values 
        - Dates: from 2000 - to 2020; 
        - Continuous and Integers: Min and Max values as 1, 10
- pheno_col Flag:
    - True
    - False/NA
