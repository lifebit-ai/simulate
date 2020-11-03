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
    nextflow run main.nf --num_participants 10

    Essential parameters:
    --num_participants              number of participants to simulate (default: 10)

    Optional parameters:
    --effective_population_size     population size (for hapgen2)
    --mutation_rate                 mutation rate (for hapgen2)
    --simulate_vcf                  whether you wish to simulate VCF files (default: false)
    --simulate_plink                whether you wish to simulate PLINK files (default: false)           

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

summary['reference_1000G_dir']        = params.reference_1000G_dir
summary['legend_for_hapgen2']         = params.legend_for_hapgen2
summary['num_participants']           = params.num_participants
summary['effective_population_size']  = params.effective_population_size
summary['mutation_rate']              = params.mutation_rate
summary['simulate_vcf']               = params.simulate_vcf
summary['simulate_plink']             = params.simulate_plink

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

// Optional hapgen2 options
if ( params.effective_population_size ) { extra_hapgen2_flags += " -Ne ${params.effective_population_size}" }
if ( params.mutation_rate ) { extra_hapgen2_flags += " -theta ${params.mutation_rate}" }



/*-------------------------------
  Setting up legend hapgen2 files  
---------------------------------*/

Channel
  .fromPath("${params.legend_for_hapgen2}/*leg")
  .map { file -> 
       def key = file.name.toString().tokenize('-').get(0)
       return tuple(key, file)
   }
  .set { legend_for_hapgen2_ch }



/*-------------------------------------------
  Download 1000G data needed to run hapgen2  
---------------------------------------------*/

process download_1000G {
    label "high_memory"
    publishDir "${params.outdir}/1000G-data", mode: "copy"
    
    output:
    file("*combined_b37.txt") into downloaded_1000G_genetic_map_ch
    file("*impute.hap.gz") into downloaded_1000G_hap_ch

    script:
    """
    wget ${params.reference_1000G_dir}
    tar zxvf ALL_1000G_phase1integrated_v3_impute.tgz --strip-components 1
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
    sed '1d' !{chr}-simulated_hapgen.sample | sed 's/_//g' | awk 'BEGIN{print "ID_1 ID_2 missing pheno"}{print}' > !{chr}-simulated_hapgen-updated.sample
    '''
}



/*-----------------------------------------------------
  Simulating VCF files (based on simulated .gen files) 
-------------------------------------------------------*/

if (params.simulate_vcf){
    process simulate_vcf {
        publishDir "${params.outdir}/simulated_vcf", mode: "copy"

        input:
        tuple file(gen), file(sample) from simulated_gen_for_vcf_ch

        output:
        file("*") into simulated_vcf_ch

        shell:
        '''
        plink2 \
        --gen !{gen} ref-unknown \
        --sample !{sample} \
        --recode vcf \
        --out !{gen} \
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
        '''
        plink2 \
        --gen !{gen} ref-unknown \
        --sample !{sample} \
        --make-bed \
        --out !{gen} \
        '''
    }
}


