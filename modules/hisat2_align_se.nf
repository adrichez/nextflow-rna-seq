#!/usr/bin/env nextflow

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    PROCESO DE ALINEAMIENTO DE LAS LECTURAS DE ENTRADA CON HISAT2 (SINGLE-END)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/

process HISAT2_ALIGN {

    container "community.wave.seqera.io/library/hisat2_samtools:5e49f68a37dc010e"

    input:
    path reads
    path index_zip

    output:
    path "${reads.simpleName}.sorted.bam", emit: bam
    path "${reads.simpleName}.sorted.bam.bai", emit: bai
    path "${reads.simpleName}.hisat2.log", emit: log

    script:
    """
    tar -xzvf ${index_zip}

    # Descomprimimos para evitar el bug de HISAT2
    gunzip -c ${reads} > lecturas_reales.fq

    # HISAT2 alinea y pasa los datos (|) directamente a samtools sort. 
    # El guion (-) al final le dice a samtools que lea desde la tubería.
    hisat2 -x ${index_zip.simpleName} -U lecturas_reales.fq \\
        --new-summary --summary-file ${reads.simpleName}.hisat2.log | \\
        samtools sort -@ ${task.cpus} -o ${reads.simpleName}.sorted.bam -

    # Indexamos el BAM recién creado
    samtools index -@ ${task.cpus} ${reads.simpleName}.sorted.bam

    # Limpieza
    rm lecturas_reales.fq
    """
}
