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
    --num_participants               number of participants to simulate
    or
    --sample_ids                     a single column file with sample IDs
                                     a suitable file can be generated using bcftools query --list-samples cohort_multisample.vcf
                                     The number of participants to simulate will be equal to the number of ids in the --sample_ids file
    
    NOTE: The parameters --num_participants and --sample_ids are mutually exclusive.
          Please define only one.

    Optional parameters:
    --effective_population_size      population size (for hapgen2) (default: 11418)
    --mutation_rate                  mutation rate (for hapgen2) (default: 1)
    --simulate_vcf                   simulate VCF files (default: false)
    --simulate_plink                 simulate PLINK files (default: false)           
    --simulate_gwas_sum_stats        simulate GWAS summary statistics (default: false)
    --gwas_cases_proportion          the number of cases to simulate for the GWAS summary statistics, represented as a fraction of --num_participants (bigger than 0 and up to 1) (default: 0.5) (see docs/usage.md for important additional details including on how to interpret the GCTA output)
    --gwas_pheno_trait_type          type of trait of interest (pheno_col) to use when simulating GWAS summary statistics with GTCA (available: `binary`, `quantitative` ; default: `binary`)
    --gwas_heritability              heritibility for simulating GWAS summary statistics (default: 0.1)
    --gwas_disease_prevalance        disease prevalence for simulating GWAS summary statistics (default: 0.1)
    --gwas_simulation_replicates     number of simulation replicates for simulating GWAS summary statistics (default: 1)
    --simulate_cb_output             whether or not you wish to simulate the cohort browser (CB) output data - this can subsequently be used by lifebit-ai/biobank-gwas (default: false)
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

summary['Output dir']                     = params.outdir
summary['Launch dir']                     = workflow.launchDir
summary['Working dir']                    = workflow.workDir
summary['Script dir']                     = workflow.projectDir
summary['User']                           = workflow.userName

summary['reference_1000G']                = params.reference_1000G
summary['legend_for_hapgen2']             = params.legend_for_hapgen2
summary['num_participants']               = params.num_participants
summary['sample_ids']                     = params.sample_ids
summary['effective_population_size']      = params.effective_population_size
summary['mutation_rate']                  = params.mutation_rate
summary['simulate_vcf']                   = params.simulate_vcf
summary['simulate_plink']                 = params.simulate_plink
summary['simulate_gwas_sum_stats']        = params.simulate_gwas_sum_stats
summary['gwas_cases_proportion']          = params.gwas_cases_proportion
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

if (!params.num_participants && !params.sample_ids) {
  exit 1, "You have not provided a number of participants to simulate. \
  \nPlease provide either a number using the --num_participants parameter or provide a --sample_ids file. \
  \nRun the command nextflow run . --help to get a list of required and optional parameters."
}

if (params.num_participants && params.sample_ids) {
  exit 1, "You have provided both --num_participants and --sample_ids parameters. \
  \nPlease provide only one of the two. \
  \nRun the command nextflow run . --help to get a list of required and optional parameters."
}


// Harmonise num_participants channel name regardless of source
if (params.sample_ids) {
  ch_sample_ids =  Channel.value(file(params.sample_ids))
  ch_num_participants = Channel.fromPath(params.sample_ids).splitText().map{ it.trim() }.count()
}

if (params.num_participants) {
  ch_num_participants = Channel.value(params.num_participants)
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
    file leg from legend_for_hapgen2_file_ch

    output:
    file("*leg") into downloaded_leg_files_ch

    script:
    """
    tar xvzf ${leg} -C .
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
    file reference_1000G from reference_1000G_ch

    output:
    file("*combined_b37.txt") into downloaded_1000G_genetic_map_ch
    file("*impute.hap.gz") into downloaded_1000G_hap_ch

    script:
    """
    tar xvzf ${reference_1000G} --strip-components 1
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
    publishDir "${params.outdir}/simulated_hapgen", mode: "copy",
    saveAs: { filename ->
        if (filename.endsWith('-updated.gen')) "$filename"
        else if (filename.endsWith('-updated.sample')) "$filename"
        else if (filename.endsWith('.summary')) "logs/$filename"
    }
    
    input:
    tuple val(chr), file(map), file(hap), file(leg) from all_hapgen_inputs_ch
    val num_participants from ch_num_participants

    output:
    file("*") into simulated_gen_results_ch
    file("*{simulated_hapgen-${num_participants}ind-updated.gen,simulated_hapgen-${num_participants}ind-updated.sample}") into (simulated_gen_for_vcf_ch, simulated_gen_for_plink_ch)

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
    -o !{chr}-simulated_hapgen-!{num_participants}ind \
    -n !{num_participants} 0 \
    -dl !{position} 0 0 0 \
    -no_haps_output !{extra_hapgen2_flags}

    # Rename output files (phenotypes are not relevant at this stage)
    mv !{chr}-simulated_hapgen-!{num_participants}ind.controls.gen !{chr}-simulated_hapgen-!{num_participants}ind.gen
    mv !{chr}-simulated_hapgen-!{num_participants}ind.controls.sample !{chr}-simulated_hapgen-!{num_participants}ind.sample

    # Update/correct the output files:
    # (1) Replace fake chromosome names (hapgen2 outputs: "snp_0", "snp_1" instead of a unique chromosome name)
    # (2) Remove the dash from the sample names (but not the header) - required for downstream PLINK steps
    awk '$1="!{chr}"' !{chr}-simulated_hapgen-!{num_participants}ind.gen > !{chr}-simulated_hapgen-!{num_participants}ind-updated.gen
    sed '1d' !{chr}-simulated_hapgen-!{num_participants}ind.sample | sed 's/id1_/id/g' | sed 's/id2_/id/g' | awk 'BEGIN{print "ID_1 ID_2 missing pheno"}{print}' > !{chr}-simulated_hapgen-!{num_participants}ind-updated.sample
    '''
}



/*-----------------------------------------------------
  Simulating VCF files (based on simulated .gen files) 
-------------------------------------------------------*/

if (params.simulate_vcf){
  process simulate_vcf {

    input:
    tuple file(gen), file(sample) from simulated_gen_for_vcf_ch

    output:
    file("*") into not_compressed_and_indexed_simulated_vcf_results_ch
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

    if( params.sample_ids ) {
      process compress_index_reheader_vcf {
        publishDir "${params.outdir}/simulated_vcf/compressed_and_indexed", mode: "copy"

        input:
        file(vcf) from not_compressed_and_indexed_simulated_vcf_ch
        file(sample_ids) from ch_sample_ids

        output:
        file("*") into compressed_and_indexed_simulated_vcf_ch

        script:
        if( params.sample_ids )
        """
        # Compress the VCF file
        bcftools view -I ${vcf} -Oz -o ${vcf}.gz

        # Temp move to different name to reheader sample ids
        mv ${vcf}.gz temp_${vcf}.gz

        # Reheader
        bcftools reheader --samples ${sample_ids} --output ${vcf}.gz temp_${vcf}.gz
        rm temp_${vcf}.gz

        # Index the compressed VCFc file
        bcftools index ${vcf}.gz
        """
      }
    }

    if( !params.sample_ids ) {
      process compress_and_index_vcf {
        publishDir "${params.outdir}/simulated_vcf/compressed_and_indexed", mode: "copy"

        input:
        file(vcf) from not_compressed_and_indexed_simulated_vcf_ch

        output:
        file("*") into compressed_and_indexed_simulated_vcf_ch

        script:

        """
        # Compress the VCF file
        bcftools view -I ${vcf} -Oz -o ${vcf}.gz

        # Index the compressed VCFc file
        bcftools index ${vcf}.gz
        """
      }
    }
}



/*-----------------------------------------------------
  Simulating PLINK files (based on simulated .gen files) 
-------------------------------------------------------*/

if (params.simulate_plink){
    process simulate_plink {
        publishDir "${params.outdir}/simulated_plink", mode: "copy",
        saveAs: { filename -> 
            if (filename.endsWith('.bed')) "$filename"
            else if (filename.endsWith('.bim')) "$filename"
            else if (filename.endsWith('.fam')) "$filename"
            else if (filename.endsWith('.log')) "logs/$filename"
        }

        input:
        tuple file(gen), file(sample) from simulated_gen_for_plink_ch

        output:
        file("*") into simulated_plink_results_ch
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

// Check that --gwas_cases_proportion is bigger than 0 and no larger than 1
if (params.gwas_cases_proportion <= 0 | params.gwas_cases_proportion > 1) {
  exit 1, "The proportion of cases (--gwas_cases_proportion) supplied is invalid. \
  \nPlease set --gwas_cases_proportion to a value bigger than 0 and up to 1. For example, --gwas_cases_proportion 0.4."
}

if ( params.simulate_plink && params.simulate_gwas_sum_stats && params.gwas_cases_proportion){

  process simulate_gwas_sum_stats {
    publishDir "${params.outdir}/simulated_gwas_sum_stats", mode: "copy",
    saveAs: { filename -> 
        if (filename.endsWith('.snplist')) "$filename"
        else if (filename.endsWith('.par')) "$filename"
        else if (filename.endsWith('.phen')) "$filename"
        else if (filename.endsWith('.log')) "logs/$filename"
    }

    input:
    tuple file(bed), file(bim), file(fam) from simulated_plink_ch
    val gwas_cases_proportion from params.gwas_cases_proportion
    val num_participants from ch_num_participants

    output:
    file("*") into simulated_gwas_sum_stats_ch

    shell:
    // Calculate number of cases based on --gwas_cases_proportion.
    // Then round the number down to represent a real number of participants (i.e. an integer).
    // Then determine number of controls based off of it.
    proportion_cases = gwas_cases_proportion
    total_participants = num_participants
  
    cases_num = proportion_cases * total_participants
    rounded_case_num = (int)cases_num
  
    controls_num = total_participants - rounded_case_num

    // Obtain name of binary PLINK file and chromosome 
    bfile_name = bed.baseName
    chr = bfile_name.split("-")[0]

    '''
    # Create list of causal SNPs required by GCTA
    cut -f2 !{bim} | head -n 10 > !{chr}-causal.snplist

    # Run GCTA
    gcta64 \
    --bfile !{bfile_name} \
    --simu-cc !{rounded_case_num} !{controls_num} \
    --simu-causal-loci !{chr}-causal.snplist \
    --out !{chr}-gwas-statistics \
    !{extra_gcta_flags}
    '''
  }
}



/*---------------------------
  Simulating CB output data   
-----------------------------*/

// Check that a YAML file was provided to perform the simulation
if (params.simulate_cb_output && !params.simulate_cb_output_config) {
  exit 1, "In order to simulate cohort browser (CB) output data, you must first simulate supply a YAML configuration file. \
  \nPlease use both --simulate_cb_output and --simulate_cb_output_config."
}

if (params.simulate_cb_output && params.simulate_cb_output_config) {
  
  Channel
    .fromPath("${params.simulate_cb_output_config}")
    .set { cohort_browser_yaml_config_ch }

  process simulate_cb_output{
    publishDir "${params.outdir}/simulated_cohort_browser_data", mode: 'copy'

    input:
    file config from cohort_browser_yaml_config_ch

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


