#!/usr/bin/env nextflow

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    PROCESO DE CUANTIFICACIÓN DE GENES CON FEATURECOUNTS (SINGLE-END)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/

process FEATURECOUNTS {

    // Contenedor oficial con el paquete Subread (incluye featureCounts)
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
    # y evitar cualquier bug con archivos comprimidos en Apptainer
    gunzip -c ${gtf_zip} > annotation_real.gtf

    # Ejecutamos featureCounts usando el archivo físico
    # -T: número de hilos (cpus)
    # -a: archivo de anotación (GTF)
    # -o: archivo de salida
    # -t: tipo de característica a contar (por defecto 'exon')
    # -g: atributo para agrupar (por defecto 'gene_id')
    
    featureCounts -T ${task.cpus} \\
        -a annotation_real.gtf \\
        -o ${bam.simpleName}.counts.txt \\
        ${bam}

    # Borramos el GTF temporal para mantener el disco limpio
    rm annotation_real.gtf
    """
}