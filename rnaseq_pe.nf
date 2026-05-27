#!/usr/bin/env nextflow

/*
#############################################################################################################################################################
    PIPELINE DE ANÁLISIS DE RNA-SEQ (LECTURAS PAIRED-END)
#############################################################################################################################################################
*/

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    IMPORTACIÓN DE MÓDULOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/

include { FASTQC } from './modules/fastqc_pe.nf'
include { TRIM_GALORE } from './modules/trim_galore_pe.nf'
include { HISAT2_INDEX } from './modules/hisat2_index.nf'
include { HISAT2_ALIGN } from './modules/hisat2_align_pe.nf'
include { FEATURECOUNTS } from './modules/featurecounts_pe.nf'
include { MERGE_COUNTS } from './modules/merge_counts.nf'
include { MULTIQC } from './modules/multiqc.nf'










/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    DEFINICIÓN DE PARÁMETROS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/

// Escribirlos aquí en el caso de fuera necesario.










/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    WORKFLOW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/

workflow {

    /*
    ≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠
        FLUJO PRINCIAL
    ≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠
    */

    main:

    //=======================================================================================================================
    // 0. LECTURA DEL CSV DE ENTRADA
    //=======================================================================================================================

    // Crear canal de entrada a partir del contenido de un archivo CSV
    read_ch = channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row -> [file(row.fastq_1), file(row.fastq_2)] }






    //=======================================================================================================================
    // 1. CONTROL DE CALIDAD INICIAL
    //=======================================================================================================================

    // Control de calidad inicial
    FASTQC(read_ch)






    //=======================================================================================================================
    // 2. LIMPIDEZA DE ADAPTADORES Y CALIDAD POSTERIOR
    //=======================================================================================================================

    // Recorte de adaptadores y control de calidad posterior al recorte
    TRIM_GALORE(read_ch)




    //=======================================================================================================================
    // 3. ALINEAMIENTO CONTRA EL GENOMA DE REFERENCIA
    //=======================================================================================================================

    //-----------------------------------------------------------------------------------------------------------
    // 3.1. CONSTRUCCIÓN DEL ÍNDICE DE HISAT2 (SI ES NECESARIO)
    //-----------------------------------------------------------------------------------------------------------

    // Inicializamos las variables vacías por seguridad
    index_ch = null
    hisat2_index_out_ch = channel.empty()

    if ( params.hisat2_index_zip ) {
        // ESCENARIO A: El usuario aporta el .tar.gz ya precalculado.
        // Lo convertimos en un canal de valor para que se reutilice en cada muestra.
        index_ch = channel.value(file(params.hisat2_index_zip))

    } else if ( params.genome_fasta_zip ) {
        // ESCENARIO B: El usuario aporta el .fasta. Lo construimos desde cero.
        fasta_ch = channel.fromPath(params.genome_fasta_zip)
        HISAT2_INDEX(fasta_ch)
        
        // Pasamos la salida al canal genérico y la guardamos para exportarla
        hisat2_index_out_ch = HISAT2_INDEX.out.index_archive.first()
        index_ch = hisat2_index_out_ch

    } else {
        // ESCENARIO C: Faltan archivos críticos
        error "¡ERROR! Debes proporcionar obligatoriamente 'params.genome_fasta_zip' o 'params.hisat2_index_zip'."
    }




    //-----------------------------------------------------------------------------------------------------------
    // 3.2. ALINEAMIENTO CON HISAT2
    //-----------------------------------------------------------------------------------------------------------

    // Alignment to a reference genome
    HISAT2_ALIGN(TRIM_GALORE.out.trimmed_reads, index_ch)






    //=======================================================================================================================
    // 4. CUANTIFICACIÓN Y CONSOLIDACIÓN DE CONTEOS
    //=======================================================================================================================

    //-----------------------------------------------------------------------------------------------------------
    // 4.1. CUANTIFICACIÓN INDIVIDUAL DE GENES POR MUESTRA
    //-----------------------------------------------------------------------------------------------------------

    // Creamos un canal de valor para el archivo GTF del usuario
    gtf_zip_ch = channel.value(file(params.gtf_zip))

    // Ejecutamos la cuantificación independiente por cada BAM generado
    FEATURECOUNTS(HISAT2_ALIGN.out.bam, HISAT2_ALIGN.out.bai, gtf_zip_ch)




    //-----------------------------------------------------------------------------------------------------------
    // 4.2. CONSOLIDACIÓN EN MATRIZ DE CONTEOS GLOBAL
    //-----------------------------------------------------------------------------------------------------------

    // Juntamos todos los archivos de conteo individuales en una única lista
    all_counts_ch = FEATURECOUNTS.out.counts.collect()

    // Le pasamos la lista unificada al fusionador
    MERGE_COUNTS(all_counts_ch)






    //=======================================================================================================================
    // 5. GENERACIÓN DE UN REPORTE DE CONTROL DE CALIDAD INTEGRADO CON MULTIQC
    //=======================================================================================================================

    // Comprehensive QC report generation
    multiqc_files_ch = channel.empty().mix(
        FASTQC.out.zip,
        FASTQC.out.html,
        TRIM_GALORE.out.trimming_reports,
        TRIM_GALORE.out.fastqc_reports_1,
        TRIM_GALORE.out.fastqc_reports_2,
        HISAT2_ALIGN.out.log,
    )
    multiqc_files_list = multiqc_files_ch.collect()

    MULTIQC(multiqc_files_list, params.report_id)






    /*
    ≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠
        PUBLICACIÓN DE RESULTADOS
    ≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠
    */
    
    publish:

    // 1. Control de calidad inicial (datos crudos)
    fastqc_zip = FASTQC.out.zip
    fastqc_html = FASTQC.out.html


    // 2. Limpieza de adaptadores y calidad posterior
    trimmed_reads = TRIM_GALORE.out.trimmed_reads
    trimming_reports = TRIM_GALORE.out.trimming_reports
    trimming_fastqc_1 = TRIM_GALORE.out.fastqc_reports_1
    trimming_fastqc_2 = TRIM_GALORE.out.fastqc_reports_2


    // 3. Alineamiento contra el genoma de referencia
    hisat2_index_archive = hisat2_index_out_ch

    bam = HISAT2_ALIGN.out.bam
    bam_index = HISAT2_ALIGN.out.bai
    align_log = HISAT2_ALIGN.out.log


    // 4. Cuantificación y consolidación de conteos
    counts_summary = FEATURECOUNTS.out.summary

    gene_matrix = MERGE_COUNTS.out.matrix


    // 5. Reporte global unificado
    multiqc_report = MULTIQC.out.report
    multiqc_data = MULTIQC.out.data
}










/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    DEFINICIÓN DE SALIDAS PUBLICADAS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/

output {

    // 1. Control de calidad inicial (datos crudos)
    fastqc_zip {
        path '01_fastqc'
        mode 'copy'
    }
    fastqc_html {
        path '01_fastqc'
        mode 'copy'
    }


    // 2. Limpieza de adaptadores y calidad posterior
    trimmed_reads {
        path '02_trimming/clean_fastq'
        mode 'copy'
    }
    trimming_reports {
        path '02_trimming/trimming_logs'
        mode 'copy'
    }
    trimming_fastqc_1 {
        path '02_trimming/fastqc_post_trim/read1'
        mode 'copy'
    }
    trimming_fastqc_2 {
        path '02_trimming/fastqc_post_trim/read2'
        mode 'copy'
    }


    // 3. Alineamiento contra el genoma de referencia
    hisat2_index_archive {
        path '03_align/hisat2_index'
        mode 'copy'
    }

    bam {
        path '03_align/bam_files'
        mode 'copy'
    }
    bam_index {
        path '03_align/bam_files'
        mode 'copy'
    }
    align_log {
        path '03_align/alignment_logs'
        mode 'copy'
    }


     // 4. Cuantificación y consolidación de conteos
    gene_matrix {
        path '04_expression_matrix'
        mode 'copy'
    }

    counts_summary {
        path '04_expression_matrix/logs'
        mode 'copy'
    }


     // 5. Reporte global unificado
    multiqc_report {
        path '04_multiqc'
        mode 'copy'
    }
    multiqc_data {
        path '04_multiqc'
        mode 'copy'
    }

}
