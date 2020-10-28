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

    To simulate a single set of PLINK files (1 bed, 1 bim, 1 fam):
    nextflow run main.nf --plink_sim_settings_file testdata/plink/wgas.sim

    Options:
    --simulate_vcf           Simulate a single multisample VCF (the set of PLINK files get converted)
    --simulate_plink_assoc   Simulate GWAS association summary statistics directly from the simulate PLINK files             

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
summary['data_hapgen2']               = params.data_hapgen2

summary['plink_sim_settings_file']  = params.plink_sim_settings_file
summary['simulate_ncases']          = params.simulate_ncases
summary['simulate_ncontrols']       = params.simulate_ncontrols
summary['simulate_prevalence']      = params.simulate_prevalence
summary['simulate_plink_assoc']     = params.simulate_plink_assoc
summary['simulate_vcf']             = params.simulate_vcf

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

// Setting up input settings for simulated PLINK files

/* Channel
  .fromPath(params.plink_sim_settings_file, checkIfExists: true)
  .ifEmpty { exit 1, "Simulation settings file to generate PLINK files not found: ${params.plink_sim_settings_file}" }
  .set { plink_sim_settings_ch } */



/*-----------------------
  Setting up extra flags
-------------------------*/

// Initialise variable to store optional parameters
// extra_flags = ""

// Setting up extra PLINK flags

/* if ( params.simulate_ncases ) { extra_flags += " --simulate-ncases ${params.simulate_ncases} " }
if ( params.simulate_ncontrols ) { extra_flags += " --simulate-ncontrols ${params.simulate_ncontrols} " }
if ( params.simulate_prevalence ) { extra_flags += " --simulate-prevalence ${params.simulate_prevalence} " }
if ( params.simulate_plink_assoc ) { extra_flags += " --assoc  " }
 */



/*------------------------------------------------
  Simulating .gen and .sample files using Hapgen2  
--------------------------------------------------*/

process simulate_gen_and_sample {
    publishDir "${params.outdir}/simulated_hapgen_original", mode: "copy"

    input:
    tuple file(data), val(chromosome) from data_hapgen2_ch
    path(ref_path)

    output:
    file("*") into simulated_gen_ch

    script:
    dir = "$baseDir/testdata/1000G-data/ALL_1000G_phase1integrated_v3_impute/" // Not ideal - hardcoded
    refHapFile = file(dir +  "/" + sprintf(params.refHapFilesPattern, chromosome))
    refGeneticMapFile = file(dir + "/" + sprintf(params.refGeneticMapFilesPattern, chromosome))
    """
    hapgen2  \
    -m $refGeneticMapFile \
    -l $data \
    -h $refHapFile \
    -o chr${chromosome}-simulated_hapgen \
    -n 100 0 \
    -dl 45162 0 0 0 \
    -no_haps_output
    """
}



/*-----------------------------------------------------------------
  Simulating PLINK files (and GWAS summary statistics if requested) 
-------------------------------------------------------------------*/

/* process simulate_plink {
    publishDir "${params.outdir}/simulated_plink", mode: "copy"

    input:
    file settings from plink_sim_settings_ch

    output:
    file("*{bim,bed,fam}") into simulated_plinks_ch

    shell:
    '''
    plink --simulate !{settings} acgt !{extra_flags} --make-bed --out simulated
    '''
} */



/*----------------------
  Simulating VCF files  
------------------------*/

/* if (params.simulate_vcf) {
    process simulate_vcf {
        publishDir "${params.outdir}/simulated_vcf", mode: "copy"

        input: 
        file("*") from simulated_plinks_ch

        output:
        file("*") into simulated_vcf_ch

        script:
        """
        plink --bfile simulated --recode vcf --out simulated
        """
    }
} */



