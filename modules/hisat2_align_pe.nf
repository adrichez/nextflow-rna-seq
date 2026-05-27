#!/usr/bin/env nextflow

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    PROCESO DE ALINEAMIENTO DE LAS LECTURAS DE ENTRADA CON HISAT2 (PAIRED-END)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/

process HISAT2_ALIGN {

    container "community.wave.seqera.io/library/hisat2_samtools:5e49f68a37dc010e"

    input:
    tuple path(read1), path(read2)
    path index_zip

    output:
    path "${read1.simpleName}.sorted.bam", emit: bam
    path "${read1.simpleName}.sorted.bam.bai", emit: bai
    path "${read1.simpleName}.hisat2.log", emit: log

    script:
    """
    tar -xzvf ${index_zip}

    # Extraemos ambas lecturas (que están comprimidas en .gz) a archivos físicos temporales
    gunzip -c ${read1} > read1_uncompressed.fq
    gunzip -c ${read2} > read2_uncompressed.fq

    # HISAT2 alinea y pasa los datos (|) directamente a samtools sort. 
    # El guion (-) al final le dice a samtools que lea desde la tubería.
    hisat2 -x ${index_zip.simpleName} -1 read1_uncompressed.fq -2 read2_uncompressed.fq \\
        --new-summary --summary-file ${read1.simpleName}.hisat2.log | \\
        samtools sort -@ ${task.cpus} -o ${read1.simpleName}.sorted.bam -

    # Indexamos el BAM recién ordenado
    samtools index -@ ${task.cpus} ${read1.simpleName}.sorted.bam

    # Borramos los archivos físicos temporales para mantener limpio el disco
    rm read1_uncompressed.fq read2_uncompressed.fq
    """
}