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

    Options:           

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

summary['Max Resources']    = "$params.max_memory memory, $params.max_cpus cpus, $params.max_time time per job"
summary['Output dir']       = params.outdir
summary['Launch dir']       = workflow.launchDir
summary['Working dir']      = workflow.workDir
summary['Script dir']       = workflow.projectDir
summary['User']             = workflow.userName

summary['reference_1000G_dir']  = params.reference_1000G_dir
summary['genetic_map_pattern']  = params.genetic_map_pattern
summary['hapmap_pattern']       = params.hapmap_pattern
summary['legend_for_hapgen2']   = params.legend_for_hapgen2

log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"



/*------------------
  Setting up inputs  
--------------------*/

// Define range of chromosomes

listofchromosomes = 1..22

// Make variable based on name of directory

ref_path = file(params.reference_1000G_dir)

// Setting up legend hapgen2 files

Channel
  .fromPath(params.legend_for_hapgen2, checkIfExists: true)
  .ifEmpty { exit 1, "Legend files for running Hapgen2 not found: ${params.legend_for_hapgen2}" }
  .set { legend_for_hapgen2_ch }



/*------------------------------------------------
  Simulating .gen and .sample files using hapgen2  
--------------------------------------------------*/

process simulate_gen_and_sample {
    publishDir "${params.outdir}/simulated_hapgen", mode: "copy"
    errorStrategy 'ignore' // WILL NEED TO REMOVE ONLY PRESENT FOR LOCAL TESTING
    
    input:
    file(legend) from legend_for_hapgen2_ch
    path(ref_path)

    output:
    file("*{simulated_hapgen-updated.gen,simulated_hapgen-updated.sample}") into simulated_gen_ch

    shell:
    chromosome = legend.baseName.replaceAll("chr","").split("-")[0]
    position = legend.baseName.split("-")[1]

    dir = "$baseDir/testdata/1000G-data/ALL_1000G_phase1integrated_v3_impute/" // Not ideal - hardcoded
    hapfile = file(dir +  "/" + sprintf(params.hapmap_pattern, chromosome))
    genetic_map_file = file(dir + "/" + sprintf(params.genetic_map_pattern, chromosome))
    '''
    # Gunzip the relevant hap file
    if [ ! -f !{hapfile} ]; then
        gunzip !{hapfile}.gz
    fi
    
    # Run hapgen2
    hapgen2  \
    -m !{genetic_map_file} \
    -l !{legend} \
    -h !{hapfile} \
    -o chr!{chromosome}-simulated_hapgen \
    -n 10 0 \
    -dl !{position} 0 0 0 \
    -no_haps_output

    # Rename output files (phenotypes are not relevant at this stage)
    mv chr!{chromosome}-simulated_hapgen.controls.gen chr!{chromosome}-simulated_hapgen.gen
    mv chr!{chromosome}-simulated_hapgen.controls.sample chr!{chromosome}-simulated_hapgen.sample

    # Update/correct the output files:
    # (1) Replace fake chromosome names (hapgen2 outputs: "snp_0", "snp_1" instead of a unique chromosome name)
    # (2) Remove the dash from the sample names (but not the header) - required for downstream PLINK steps
    awk '$1=!{chromosome}' chr!{chromosome}-simulated_hapgen.gen > chr!{chromosome}-simulated_hapgen-updated.gen
    sed '1d' chr!{chromosome}-simulated_hapgen.sample | sed 's/_//g' | awk 'BEGIN{print "ID_1 ID_2 missing pheno"}{print}' > chr!{chromosome}-simulated_hapgen-updated.sample
    '''
}



/*-----------------------------------------------------
  Simulating VCF files (based on simulated .gen files) 
-------------------------------------------------------*/

/* process simulate_vcf {
    publishDir "${params.outdir}/simulated_vcf", mode: "copy"

    input:
    tuple file(gen), file(sample) from simulated_gen_ch

    output:
    file("*") into simulated_vcf_ch

    shell:
    '''
    plink2 \
    --gen !{gen} \
    --sample !{sample} \
    --oxford-single-chr \
    --recode vcf \
    --out !{gen} \
    '''
} */


