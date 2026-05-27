#!/usr/bin/env nextflow

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    PROCESO DE CUANTIFICACIÓN DE GENES CON FEATURECOUNTS (PAIRED-END)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/

process FEATURECOUNTS {

    // Mantenemos tu contenedor que ya funciona perfectamente
    container "community.wave.seqera.io/library/subread:2.1.1--0ac4d7e46cd0c5d7"

    input:
    path bam
    path bam_index  // Lo pedimos para asegurar que Nextflow espera a que exista
    path gtf_zip

    output:
    // El archivo principal con la tabla de conteos
    path "${bam.simpleName}.counts.txt", emit: counts
    // El resumen estadístico de la cuantificación (muy útil para MultiQC)
    path "${bam.simpleName}.counts.txt.summary", emit: summary

    script:
    """
    # Descomprimimos el GTF físicamente para curarnos en salud
    gunzip -c ${gtf_zip} > annotation_real.gtf

    # Ejecutamos featureCounts usando el archivo físico
    # -T: número de hilos (cpus)
    # -p: LA MAGIA DEL PAIRED-END. Cuenta fragmentos en lugar de lecturas individuales.
    # -a: archivo de anotación (GTF)
    # -o: archivo de salida
    
    featureCounts -T ${task.cpus} \\
        -p \\
        -a annotation_real.gtf \\
        -o ${bam.simpleName}.counts.txt \\
        ${bam}

    # Borramos el GTF temporal para mantener el disco limpio
    rm annotation_real.gtf
    """
}