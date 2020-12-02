#!/usr/bin/env nextflow
/*
========================================================================================
                         lifebit-ai/simulate
========================================================================================
 lifebit-ai/simulate pipeline
 #### Homepage / Documentation
 https://github.com/lifebit-ai/simulate
----------------------------------------------------------------------------------------
*/



/*---------------------------------------
  Define and show help message if needed
-----------------------------------------*/

def helpMessage() {

    log.info"""
    
    Usage:

    The typical command for running the pipeline is as follows:
    nextflow run main.nf --num_participants 40

    Essential parameters:
    --num_participants              number of participants to simulate
    
    Optional parameters:
    --effective_population_size      population size (for hapgen2) (default: 11418)
    --mutation_rate                  mutation rate (for hapgen2) (default: 1)
    --simulate_vcf                   simulate VCF files (default: false)
    --simulate_plink                 simulate PLINK files (default: false)           
    --simulate_gwas_sum_stats        simulate GWAS summary statistics (default: false)
    --gwas_cases                     the number of cases to simulate for the GWAS summary statistics (the total with controls should match --effective_population_size, see docs/usage.md for important details on how to interpret the GCTA output)
    --gwas_controls                  the number of controls to simulate for the GWAS summary statistics (the total with cases should match --effective_population_size, see docs/usage.md for important details on how to interpret the GCTA output)
    --gwas_pheno_trait_type          type of trait of interest (pheno_col) to use when simulating GWAS summary statistics with GTCA (available: `binary`, `quantitative` ; default: `binary`)
    --gwas_heritability              heritibility for simulating GWAS summary statistics (default: 0.1)
    --gwas_disease_prevalance        disease prevalence for simulating GWAS summary statistics (default: 0.1)
    --gwas_simulation_replicates     number of simulation replicates for simulating GWAS summary statistics (default: 1)
    --simulate_cb_output             whether or not you wish to simulate the cohort browser (CB) output data - this can subsequently be used by lifebit-ai/gel-gwas (default: false)
    --simulate_cb_output_config      the YAML config file used to simulate cohort browser data with (must be provided if --simulate_cb_output is set to true )
    --simulate_cb_output_output_tag  the outprefix you wish to give to the simulated cohort browser data (default: `simulated`)
    """.stripIndent()
}

// Show help message

if (params.help) {
    helpMessage()
    exit 0
}



/*---------------------------------------------------
  Define and show header with all params information 
-----------------------------------------------------*/

// Header log info

def summary = [:]

if (workflow.revision) summary['Pipeline Release'] = workflow.revision

summary['Max Resources']                  = "$params.max_memory memory, $params.max_cpus cpus, $params.max_time time per job"
summary['Output dir']                     = params.outdir
summary['Launch dir']                     = workflow.launchDir
summary['Working dir']                    = workflow.workDir
summary['Script dir']                     = workflow.projectDir
summary['User']                           = workflow.userName

summary['reference_1000G']                = params.reference_1000G
summary['legend_for_hapgen2']             = params.legend_for_hapgen2
summary['num_participants']               = params.num_participants
summary['effective_population_size']      = params.effective_population_size
summary['mutation_rate']                  = params.mutation_rate
summary['simulate_vcf']                   = params.simulate_vcf
summary['simulate_plink']                 = params.simulate_plink
summary['simulate_gwas_sum_stats']        = params.simulate_gwas_sum_stats
summary['gwas_cases']                     = params.gwas_cases
summary['gwas_controls']                  = params.gwas_controls
summary['gwas_pheno_trait_type']          = params.gwas_pheno_trait_type
summary['gwas_disease_prevalance']        = params.gwas_disease_prevalance
summary['gwas_simulation_replicates']     = params.gwas_simulation_replicates
summary['simulate_cb_output']             = params.simulate_cb_output
summary['simulate_cb_output_config']      = params.simulate_cb_output_config   
summary['simulate_cb_output_output_tag']  = params.simulate_cb_output_output_tag 

log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"



/*----------------------------------------------
  Setting up parameters and extra optional flags
------------------------------------------------*/

if (!params.num_participants) {
  exit 1, "You have not provided a number of participants to simulate. \
  \nPlease provide a number using the --num_participants parameter."
}

// Initialise variable to store optional parameters
extra_hapgen2_flags = ""
extra_gcta_flags = ""

// Optional hapgen2 options
if ( params.effective_population_size ) { extra_hapgen2_flags += " -Ne ${params.effective_population_size}" }
if ( params.mutation_rate ) { extra_hapgen2_flags += " -theta ${params.mutation_rate}" }

// Optional gtca options
if ( params.gwas_pheno_trait_type == 'quantitative' ) { extra_gcta_flags += " --simu-qt " }
if ( params.gwas_heritability ) { extra_gcta_flags += " --simu-hsq ${params.gwas_heritability} " }
if ( params.gwas_disease_prevalance ) { extra_gcta_flags += " --simu-k ${params.gwas_disease_prevalance} " }
if ( params.gwas_simulation_replicates ) { extra_gcta_flags += " --simu-rep ${params.gwas_simulation_replicates} " }



/*-------------------------------
  Download legend hapgen2 files  
---------------------------------*/

Channel
    .fromPath("${params.legend_for_hapgen2}")
    .set { legend_for_hapgen2_file_ch }

process download_leg_files {
    label "high_memory"
    publishDir "${params.outdir}/leg-data", mode: "copy"
    
    input:
    file("all_leg.tar.gz") from legend_for_hapgen2_file_ch

    output:
    file("*leg") into downloaded_leg_files_ch

    script:
    """
    tar xvzf all_leg.tar.gz -C .
    """
}

downloaded_leg_files_ch
  .flatMap { it -> it }
  .map { file -> 
       def chr = file.name.toString().tokenize('-').get(0)
       return tuple(chr, file)
   }
  .set { legend_for_hapgen2_ch }



/*-------------------------------------------
  Download 1000G data needed to run hapgen2  
---------------------------------------------*/

Channel
    .fromPath("${params.reference_1000G}")
    .set { reference_1000G_ch }

process download_1000G {
    label "high_memory"
    publishDir "${params.outdir}/1000G-data", mode: "copy"
    
    input:
    file("ALL_1000G_phase1integrated_v3_impute.tgz") from reference_1000G_ch

    output:
    file("*combined_b37.txt") into downloaded_1000G_genetic_map_ch
    file("*impute.hap.gz") into downloaded_1000G_hap_ch

    script:
    """
    tar xvzf ALL_1000G_phase1integrated_v3_impute.tgz --strip-components 1
    """
}

downloaded_1000G_genetic_map_ch
    .flatMap { it -> it }
    .map { file -> 
       def key = file.name.toString().tokenize('_').get(2)
       return tuple(key, file)
    }
    .set { genetic_map_ch }

downloaded_1000G_hap_ch
    .flatMap { it -> it }
    .map { file -> 
       def key = file.name.toString().tokenize('_').get(4)
       return tuple(key, file)
    }
    .set { hap_ch }



/*------------------------------------------------
  Simulating .gen and .sample files using hapgen2  
--------------------------------------------------*/

// Combine all inputs for hapgen2
all_ref_ch = genetic_map_ch.join(hap_ch)
all_hapgen_inputs_ch = all_ref_ch.join(legend_for_hapgen2_ch)

process simulate_gen_and_sample {
    label "high_memory"
    publishDir "${params.outdir}/simulated_hapgen", mode: "copy"
    
    input:
    tuple val(chr), file(map), file(hap), file(leg) from all_hapgen_inputs_ch

    output:
    file("*{simulated_hapgen-updated.gen,simulated_hapgen-updated.sample}") into (simulated_gen_for_vcf_ch, simulated_gen_for_plink_ch)

    shell:
    position = leg.baseName.split("-")[1]
    unzipped_hap = hap.baseName
    '''
    # Gunzip the relevant hap file
    gunzip -f !{hap}
 
    # Run hapgen2
    hapgen2  \
    -m !{map} \
    -l !{leg} \
    -h !{unzipped_hap} \
    -o !{chr}-simulated_hapgen \
    -n !{params.num_participants} 0 \
    -dl !{position} 0 0 0 \
    -no_haps_output !{extra_hapgen2_flags}

    # Rename output files (phenotypes are not relevant at this stage)
    mv !{chr}-simulated_hapgen.controls.gen !{chr}-simulated_hapgen.gen
    mv !{chr}-simulated_hapgen.controls.sample !{chr}-simulated_hapgen.sample

    # Update/correct the output files:
    # (1) Replace fake chromosome names (hapgen2 outputs: "snp_0", "snp_1" instead of a unique chromosome name)
    # (2) Remove the dash from the sample names (but not the header) - required for downstream PLINK steps
    awk '$1="!{chr}"' !{chr}-simulated_hapgen.gen > !{chr}-simulated_hapgen-updated.gen
    sed '1d' !{chr}-simulated_hapgen.sample | sed 's/id1_/id/g' | sed 's/id2_/id/g' | awk 'BEGIN{print "ID_1 ID_2 missing pheno"}{print}' > !{chr}-simulated_hapgen-updated.sample
    '''
}



/*-----------------------------------------------------
  Simulating VCF files (based on simulated .gen files) 
-------------------------------------------------------*/

if (params.simulate_vcf){
  process simulate_vcf {
    publishDir "${params.outdir}/simulated_vcf/not_compressed_and_indexed", mode: "copy"

    input:
    tuple file(gen), file(sample) from simulated_gen_for_vcf_ch

    output:
    file("*") into not_compressed_and_indexed_simulated_vcf_results
    file("*vcf") into not_compressed_and_indexed_simulated_vcf_ch

    shell:
    out_vcf_name=gen.baseName
    '''
    plink2 \
    --gen !{gen} ref-unknown \
    --sample !{sample} \
    --recode vcf \
    --out !{out_vcf_name} \
    '''
    }

    process compress_and_index_vcf {
      publishDir "${params.outdir}/simulated_vcf/compressed_and_indexed", mode: "copy"

      input:
      file(vcf) from not_compressed_and_indexed_simulated_vcf_ch

      output:
      file("*") into compressed_and_indexed_simulated_vcf_ch

      shell:
      '''
      # Compress the VCF file
      bcftools view -I !{vcf} -Oz -o !{vcf}.gz

      # Index the compressed VCFc file
      bcftools index !{vcf}.gz
      '''
    }
}



/*-----------------------------------------------------
  Simulating PLINK files (based on simulated .gen files) 
-------------------------------------------------------*/

if (params.simulate_plink){
    process simulate_plink {
        publishDir "${params.outdir}/simulated_plink", mode: "copy"

        input:
        tuple file(gen), file(sample) from simulated_gen_for_plink_ch

        output:
        file("*.{bed,bim,fam}") into simulated_plink_ch

        shell:
        out_plink_name=gen.baseName
        '''
        plink2 \
        --gen !{gen} ref-unknown \
        --sample !{sample} \
        --make-bed \
        --out !{out_plink_name} \
        '''
    }
}



/*------------------------------------------------
  Simulating GWAS summary statistics (using GCTA) 
--------------------------------------------------*/

// Check that PLINK files are being simulated prior to GCTA simulation
if (!params.simulate_plink && params.simulate_gwas_sum_stats) {
  exit 1, "In order to simulate GWAS summary statistics with GCTA, you must first simulate PLINK files (which are then used as input for GCTA. \
  \nPlease set both --simulate_plink and --simulate_gwas_sum_stats to true."
}

// Check that the number of cases and controls to simulate match the total number of simulated participants.
if (params.gwas_cases && params.gwas_controls) {

  def cases_num = params.gwas_cases
  def controls_num = params.gwas_controls
  def total = cases_num + controls_num
  
  if (params.num_participants != total) {
    exit 1, "The number of cases and controls to simulate in the GWAS summary statistics must match the total number of simulated participants. \
    \nPlease ensure that the sum of --gwas_cases and --gwas_controls match --num_participants."
    }
}

if ( params.simulate_plink && params.simulate_gwas_sum_stats && params.gwas_cases && params.gwas_controls){
  process simulate_gwas_sum_stats {
    publishDir "${params.outdir}/simulated_gwas_sum_stats", mode: "copy"

    input:
    tuple file(bed), file(bim), file(fam) from simulated_plink_ch

    output:
    file("*") into simulated_gwas_sum_stats_ch

    shell:
    bfile_name=bed.baseName
    chr=bfile_name.split("-")[0]
    '''
    # Create list of causal SNPs required by GCTA
    cut -f2 !{bim} | head -n 10 > !{chr}-causal.snplist

    # Run GCTA
    gcta64 \
    --bfile !{bfile_name} \
    --simu-cc !{params.gwas_cases} !{params.gwas_controls} \
    --simu-causal-loci !{chr}-causal.snplist \
    --out !{chr}-gwas-statistics \
    !{extra_gcta_flags}
    '''
  }
}



/*---------------------------
  Simulating CB output data   
-----------------------------*/

// Check that the right combination of files was provided to perform the simulation
if (params.simulate_cb_output && !params.simulate_cb_output_config && !params.simulate_cb_query_file && !params.simulate_cb_pheno_metadata) {
  exit 1, "In order to simulate cohort browser (CB) output data, you must first simulate supply a YAML configuration file or corresponding query and metadata files. \
  \nPlease use both --simulate_cb_output and --simulate_cb_output_config or \
  \nPlease use all --simulate_cb_output, --simulate_cb_query_file and --simulate_cb_pheno_metadata ."
}

if (params.simulate_cb_output && !params.simulate_cb_output_config && params.simulate_cb_query_file && !params.simulate_cb_pheno_metadata) {
  exit 1, "In order to simulate cohort browser (CB) output data, you must first simulate supply a YAML configuration file or corresponding query and metadata files. \
  \nPlease use both --simulate_cb_output and --simulate_cb_output_config or \
  \nPlease use all --simulate_cb_output, --simulate_cb_query_file and --simulate_cb_pheno_metadata ."
}

if (params.simulate_cb_output && !params.simulate_cb_output_config && !params.simulate_cb_query_file && params.simulate_cb_pheno_metadata) {
  exit 1, "In order to simulate cohort browser (CB) output data, you must first simulate supply a YAML configuration file or corresponding query and metadata files. \
  \nPlease use both --simulate_cb_output and --simulate_cb_output_config or \
  \nPlease use all --simulate_cb_output, --simulate_cb_query_file and --simulate_cb_pheno_metadata ."
}

if (params.simulate_cb_output && params.simulate_cb_output_config && params.simulate_cb_query_file && params.simulate_cb_pheno_metadata) {
  exit 1, "In order to simulate cohort browser (CB) output data, you must first simulate supply a YAML configuration file or corresponding query and metadata files. \
  \nPlease use both --simulate_cb_output and --simulate_cb_output_config or \
  \nPlease use all --simulate_cb_output, --simulate_cb_query_file and --simulate_cb_pheno_metadata ."
}

// Start processes

if (params.simulate_cb_output && params.simulate_cb_query_file && params.simulate_cb_pheno_metadata){
  Channel
    .fromPath("${params.simulate_cb_query_file}")
    .set { cohort_browser_query_file_ch }
  Channel
    .fromPath("${params.simulate_cb_pheno_metadata}")
    .set { cohort_browser_pheno_metadata_file_ch }

  process simulate_pheno_config_file{
    publishDir "${params.outdir}/simulated_cohort_browser_data", mode: 'copy'

    input: 
    file(metadata) from cohort_browser_pheno_metadata_file_ch
    file(query) from cohort_browser_query_file_ch

    output:
    file("${params.simulate_cb_output_output_tag}.yaml") into cohort_browser_yaml_config_ch

    script:
    """
    generate_sim_config.R --pheno_metadata "$metadata" \
                          --query "$query" \
                          --n_samples "${params.num_participants}" \
                          --pheno_col_name "${params.simulate_cb_pheno_col_name}" \
                          --pheno_col_type "${params.simulate_cb_pheno_col_type}" \
                          --pheno_col_fraction_of_cases ${params.simulate_cb_pheno_col_fraction_of_cases} \
                          --pheno_col_case_group ${params.simulate_cb_pheno_col_case_group} \
                          --outprefix "${params.simulate_cb_output_output_tag}"
    """
  }

}

if (params.simulate_cb_output && params.simulate_cb_output_config) {
  Channel
      .fromPath("${params.simulate_cb_output_config}")
      .set { cohort_browser_yaml_config_ch }
}

if (params.simulate_cb_output && (params.simulate_cb_output_config || (params.simulate_cb_query_file && params.simulate_cb_pheno_metadata))) {
  

  process simulate_cb_output{
    publishDir "${params.outdir}/simulated_cohort_browser_data", mode: 'copy'

    input:
    file(config) from cohort_browser_yaml_config_ch

    output:
    file("${params.simulate_cb_output_output_tag}_pheno_data.csv") into simulated_cb_pheno_data_ch
    file("${params.simulate_cb_output_output_tag}_pheno_metadata.csv") into simulated_cb_pheno_metadata_ch

    script:
    """
    simulate_cb_output.R --config_file "${config}" \
                         --outprefix "${params.simulate_cb_output_output_tag}"
    """
  }

}
