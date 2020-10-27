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

    nextflow run main.nf --plink_sim_settings_file testdata/plink/wgas.sim

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
if (workflow.containerEngine) summary['Container'] = "$workflow.containerEngine - $workflow.container"

summary['Output dir']       = params.outdir
summary['Launch dir']       = workflow.launchDir
summary['Working dir']      = workflow.workDir
summary['Script dir']       = workflow.projectDir
summary['User']             = workflow.userName

summary['plink_sim_settings_file']  = params.plink_sim_settings_file
summary['simulate_ncases']          = params.simulate_ncases
summary['simulate_ncontrols']       = params.simulate_ncontrols
summary['simulate_prevalence']      = params.simulate_prevalence
summary['assoc']                    = params.assoc

log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"



/*------------------
  Setting up inputs  
--------------------*/

// Setting up input settings for simulated PLINK files

Channel
  .fromPath(params.plink_sim_settings_file, checkIfExists: true)
  .ifEmpty { exit 1, "Simulation settings file to generate PLINK files not found: ${params.plink_sim_settings_file}" }
  .set { plink_sim_settings_ch }



/*-----------------------
  Setting up extra flags
-------------------------*/

// Initialise variable to store optional parameters
extra_flags = ""

// Setting up extra PLINK flags

if ( params.simulate_ncases ) { extra_flags += " --simulate-ncases ${params.simulate_ncases} " }
if ( params.simulate_ncontrols ) { extra_flags += " --simulate-ncontrols ${params.simulate_ncontrols} " }
if ( params.simulate_prevalence ) { extra_flags += " --simulate-prevalence ${params.simulate_prevalence} " }
if ( params.assoc ) { extra_flags += " --assoc  " }



/*-----------------------------------------------------------------
  Simulating PLINK files (and GWAS summary statistics if requested) 
-------------------------------------------------------------------*/

process simulate_plink {
    publishDir "${params.outdir}/simulated_plink", mode: "copy"

    input:
    file settings from plink_sim_settings_ch

    output:
    file("*{bim,bed,fam}") into simulated_plinks_ch

    shell:
    '''
    plink --simulate !{settings} !{extra_flags} --make-bed --out simulated
    '''
}



/*----------------------
  Simulating VCF files  
------------------------*/

if (params.simulate_vcf) {
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
}



// TO CONSIDER
// --chr 1..22
// verbose
// build 38 - from a tool/ 


/*---------------------------------
  Split PLINK files per chromosome 
-----------------------------------*/
