#!/usr/bin/env Rscript

###########################
# Import libraries
###########################
suppressPackageStartupMessages({
library(data.table)
library(tidyverse)
library(optparse)
library(yaml)
library(jsonlite)
library(snakecase)
    })

###########################
# CLI & Arguments parsing #
###########################

option_list = list(
  make_option(c("--pheno_metadata"), action="store", default='None', type='character',
              help="String containing path/URL to input pheno metadata use as template for building config file."),
  make_option(c("--query"), action="store", default='None', type='character',
              help="String containing path/URL to input pheno query data use as template for building config file."),
  make_option(c("--n_samples"), action="store", default='None', type='integer',
              help="Integer containing number of samples to be generated."),
  make_option(c("--pheno_col_name"), action="store", default='None', type='character',
              help="String containing path/URL to input pheno query data use as template for building config file."),
  make_option(c("--pheno_col_type"), action="store", default='None', type='character',
              help="String containing data type of variable pheno_col"),
  make_option(c("--pheno_col_fraction_of_cases"), action="store", default=0, type='double',
              help="Float containing fraction of cases"),
  make_option(c("--pheno_col_case_group"), action="store", default='None', type='character',
              help="String containing case group"),
  make_option(c("--outprefix"), action="store", default='sim_1', type='character',
              help="String containing output simulated prefixes.")
)

args = parse_args(OptionParser(option_list=option_list))

# Args to variables
pheno_metadata              = args$pheno_metadata
query_file                  = args$query
n_samples                   = args$n_samples
pheno_col_name              = args$pheno_col_name
pheno_col_type              = args$pheno_col_type
pheno_col_fraction_of_cases = args$pheno_col_fraction_of_cases
pheno_col_case_group        = args$pheno_col_case_group
outprefix                   = args$outprefix


##################################
# Import metadata for phenotypes #
##################################

# Use phenotype metadata (data dictionary) to determine the type of each phenotype -> This will be given by CB
pheno_dictionary = fread(pheno_metadata) %>%
        as.tibble # Change by metadata input var
colnames(pheno_dictionary) = colnames(pheno_dictionary) %>%
                             to_snake_case(sep_in = ":|\\(|\\)|(?<!\\d)\\.")
print('Here1')
# Import query json
if (query_file != 'None'){
    pheno_id = colnames(pheno_dictionary)[colnames(pheno_dictionary) %in% c('id','field_id')]
    query_df = fromJSON(query_file, flatten=T)$search
    query_df = left_join(query_df, pheno_dictionary, by = c('column.id' = pheno_id),  suffix=c("_query", "_dict"))
    query_df = query_df[ , colSums(is.na(query_df)) < dim(query_df)[1]]
    query_df[is.na(query_df)] = 0
}

# Temporal fix for working with testing version of phenodata and real pheno seamlessly
# valueType in testing points to the type of visualization, in real data points to the real datatype
# Causes bugs when working with testing and GEL
print('here2')
#Real
if (sum(c('value_type', 'type') %in% colnames(query_df)) > 1){
    type_col = colnames(query_df)[str_detect(colnames(query_df), '^value.*type$')]
}
#Testing
if (sum(c('value_type', 'field_id_type') %in% colnames(query_df)) > 1){
    type_col = colnames(query_df)[str_detect(colnames(query_df), '^field.*type$')]
}
name_col = colnames(query_df)[str_detect(colnames(query_df), '^name|^field.*name$')]
column_to_keep = c('column.id', name_col, type_col, "array", 'instances','low','high','values')
query_df = query_df %>% select(all_of(column_to_keep))
print('here3')
config_list = list(params=list(n_samples=n_samples,
                               seed=as.integer(777), 
                               col_params=list(pheno_col=list(name=pheno_col_name,
                                                              type=pheno_col_type,
                                                              fraction_of_cases=pheno_col_fraction_of_cases,
                                                              case_group = pheno_col_case_group))))

for (i in 1:dim(query_df)[1]){
    if (str_detect(query_df[[type_col]][i], 'Continuous')){
        config_list$params$col_params[[query_df$field_name[i]]] = list(type=strsplit(query_df[[type_col]][i], " ")[[1]][1],
                                                                    n_arrays=query_df$array[i],
                                                                    n_instances=query_df$instances[i],
                                                                    mean = (as.double(query_df$low[i]) + as.double(query_df$high[i]))/2,
                                                                    sd = (as.double(query_df$high[i]) - as.double(query_df$low[i]))/2,
                                                                    distribution='normal')
    }
    if (str_detect(query_df[[type_col]][i], 'Integer')){
        config_list$params$col_params[[query_df$field_name[i]]] = list(type=strsplit(query_df[[type_col]][i], " ")[[1]][1],
                                                                    n_arrays=query_df$array[i],
                                                                    n_instances=query_df$instances[i],
                                                                    mean = as.integer((as.integer(query_df$low[i]) + as.integer(query_df$high[i]))/2),
                                                                    sd = (as.double(query_df$high[i]) - as.double(query_df$low[i]))/2,
                                                                    distribution='normal')
    }
    if (str_detect(query_df[[type_col]][i], 'Date')){
        config_list$params$col_params[[query_df$field_name[i]]] = list(type=strsplit(query_df[[type_col]][i], " ")[[1]][1],
                                                                    n_arrays=query_df$array[i],
                                                                    n_instances=query_df$instances[i],
                                                                    starting_date = query_df$low[i],
                                                                    end_date = query_df$high[i])
    
    }
    if (str_detect(query_df[[type_col]][i], 'Categorical')){
        config_list$params$col_params[[query_df$field_name[i]]] = list(type=strsplit(query_df[[type_col]][i], " ")[[1]][1],
                                                                    n_arrays=query_df$array[i],
                                                                    n_instances=query_df$instances[i],
                                                                    values= query_df$values[[i]]) 
    }
}
print(config_list)
write_yaml(config_list, paste0(outprefix,'.yml'))