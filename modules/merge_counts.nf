#!/usr/bin/env nextflow

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    PROCESO DE CONSOLIDACIÓN DE CONTEOS EN UNA MATRIZ GLOBAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/

process MERGE_COUNTS {

    container "community.wave.seqera.io/library/pandas_python:75380848c527810f"

    input:
    path counts_files

    output:
    path "gene_counts_matrix.txt", emit: matrix

    script:
    """
    #!/usr/bin/env python3
    import pandas as pd
    import os

    # Lista para almacenar los dataframes de cada muestra
    dfs = []

    # Leemos la lista de archivos que nos pasa Nextflow
    files = "${counts_files}".split()

    for f in files:
        # featureCounts deja las primeras 6 líneas como comentarios informativos, las saltamos con skiprows=1
        df = pd.read_csv(f, sep='\\t', skiprows=1)
        
        # Nos quedamos solo con la columna Geneid (id del gen) y la última columna (los conteos de la muestra)
        # La columna de conteos suele llamarse igual que el archivo BAM, así que la renombramos con el nombre de la muestra limpio
        sample_name = f.replace(".counts.txt", "")
        df = df.iloc[:, [0, -1]]
        df.columns = ['Geneid', sample_name]
        
        dfs.append(df)

    # Fusionamos todos los dataframes por la columna 'Geneid'
    final_matrix = dfs[0]
    for next_df in dfs[1:]:
        final_matrix = pd.merge(final_matrix, next_df, on='Geneid')

    # Guardamos la matriz global en un archivo de texto listo para R / DESeq2
    final_matrix.to_csv("gene_counts_matrix.txt", sep='\\t', index=False)
    """
}