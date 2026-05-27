#!/usr/bin/env nextflow

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    PROCESO DE CONSTRUCCIÓN DEL ÍNDICE DEL GENOMA CON HISAT2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/

process HISAT2_INDEX {

    container "community.wave.seqera.io/library/hisat2_samtools:5e49f68a37dc010e"

    input:
    path genome_fasta_zip

    output:
    path "genome_index.tar.gz", emit: index_archive

    script:
    """
    # Descomprimimos físicamente el FASTA para evitar problemas con Apptainer
    gunzip -c ${genome_fasta_zip} > genome_real.fa

    # Construir el índice de HISAT2 a partir del FASTA descomprimido
    hisat2-build genome_real.fa genome_index

    # Comprimir todos los archivos generados (.ht2) en un único archivo
    tar -czvf genome_index.tar.gz genome_index.*.ht2

    # Limpieza: eliminamos los archivos individuales y el FASTA temporal
    rm genome_index.*.ht2 genome_real.fa
    """
}