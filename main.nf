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

    Mandatory arguments:

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

summary['plink_sim_settings_file']          = params.plink_sim_settings_file


log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"



/*------------------------------------------------
  Check the hostnames against configured profiles
--------------------------------------------------*/

// Define checkHostname function

def checkHostname() {
    def c_reset = params.monochrome_logs ? '' : "\033[0m"
    def c_white = params.monochrome_logs ? '' : "\033[0;37m"
    def c_red = params.monochrome_logs ? '' : "\033[1;91m"
    def c_yellow_bold = params.monochrome_logs ? '' : "\033[1;93m"
    if (params.hostnames) {
        def hostname = "hostname".execute().text.trim()
        params.hostnames.each { prof, hnames ->
            hnames.each { hname ->
                if (hostname.contains(hname) && !workflow.profile.contains(prof)) {
                    log.error "====================================================\n" +
                            "  ${c_red}WARNING!${c_reset} You are running with `-profile $workflow.profile`\n" +
                            "  but your machine hostname is ${c_white}'$hostname'${c_reset}\n" +
                            "  ${c_yellow_bold}It's highly recommended that you use `-profile $prof${c_reset}`\n" +
                            "============================================================"
                }
            }
        }
    }
}

// Check hostname

checkHostname()

Channel.from(summary.collect{ [it.key, it.value] })
    .map { k,v -> "<dt>$k</dt><dd><samp>${v ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>" }
    .reduce { a, b -> return [a, b].join("\n            ") }
    .map { x -> """
    id: 'metagwas-summary'
    description: " - this information is collected when the pipeline is started."
    section_name: 'lifebit-ai/metagwas Workflow Summary'
    section_href: 'https://github.com/lifebit-ai/metagwas'
    plot_type: 'html'
    data: |
        <dl class=\"dl-horizontal\">
            $x
        </dl>
    """.stripIndent() }
    .set { ch_workflow_summary }



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
    file("simulated*") into simulated_plinks_ch

    shell:
    '''
    plink --simulate !{settings} !{extra_flags} --make-bed --out simulated
    '''
}



// TO CONSIDER
// --chr 1..22
// verbose
// build 38 - from a tool/ 


/*---------------------------------
  Split PLINK files per chromosome 
-----------------------------------*/
