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

summary['referenceDir']               = params.referenceDir
summary['refGeneticMapFilesPattern']  = params.refGeneticMapFilesPattern
summary['refHapFilesPattern']         = params.refHapFilesPattern
summary['legend_for_hapgen2']         = params.legend_for_hapgen2

log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"



/*------------------
  Setting up inputs  
--------------------*/

// Define range of chromosomes

listofchromosomes = 1..22

// Make variable based on name of directory

ref_path = file(params.referenceDir)

// Setting up input hapgen2 file for simulation

Channel
  .fromPath(params.data_hapgen2, checkIfExists: true)
  .ifEmpty { exit 1, "Simulation data for running Hapgen2 not found: ${params.testdata_hapgen2}" }
  .combine(listofchromosomes)
  .set { data_hapgen2_ch }



/*------------------------------------------------
  Simulating .gen and .sample files using hapgen2  
--------------------------------------------------*/

process simulate_gen_and_sample {
    publishDir "${params.outdir}/simulated_hapgen", mode: "copy"

    input:
    tuple file(data), val(chromosome) from data_hapgen2_ch
    path(ref_path)

    output:
    file("*{simulated_hapgen.gen,simulated_hapgen.sample}") into simulated_gen_ch

    shell:
    dir = "$baseDir/testdata/1000G-data/ALL_1000G_phase1integrated_v3_impute/" // Not ideal - hardcoded
    refHapFile = file(dir +  "/" + sprintf(params.refHapFilesPattern, chromosome))
    refGeneticMapFile = file(dir + "/" + sprintf(params.refGeneticMapFilesPattern, chromosome))
    '''
    
    # Run hapgen2

    hapgen2  \
    -m !{refGeneticMapFile} \
    -l !{data} \
    -h !{refHapFile} \
    -o chr!{chromosome}-simulated_hapgen \
    -n 10 0 \
    -dl 45162 0 0 0 \
    -no_haps_output

    # Rename output files

    for i in chr!{chromosome}-simulated_hapgen.controls.gen
    do
        mv $i chr!{chromosome}-simulated_hapgen.gen
    done

    for i in chr!{chromosome}-simulated_hapgen.controls.sample
    do
        mv $i chr!{chromosome}-simulated_hapgen.sample
    done

    '''
}



/*-----------------------------------------------------
  Simulating VCF files (based on simulated .gen files) 
-------------------------------------------------------*/

process simulate_vcf {
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
}


