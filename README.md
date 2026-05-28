<p align="center">
  <img src="assets/cover.png" alt="GIF Generator Banner" style="width:100%">
</p>

<div align="center">
  <h1><span style="color: #31d2a5;">Flujo de trabajo bioinformático automatizado, reproducible y escalable para el procesamiento, alineamiento y cuantificación de datos de RNA-Seq</span></h1>

  <hr style="border:none; height:0.3px; background-color:#777; width:65%; margin:30px auto 35px auto;">

  <p>
    <a href="https://www.nextflow.io/"><img src="https://img.shields.io/badge/Nextflow-2C2230?style=flat&logo=nextflow&logoColor=white" alt="Nextflow"></a>
    <a href="https://www.docker.com/"><img src="https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white" alt="Docker"></a>
    <a href="https://apptainer.org/"><img src="https://img.shields.io/badge/Singularity-1E293B?style=flat&logo=singularity&logoColor=white" alt="Singularity"></a>
    <a href="https://docs.conda.io/en/latest/"><img src="https://img.shields.io/badge/Conda-44A833?style=flat&logo=anaconda&logoColor=white" alt="Conda"></a>
    <a href="https://github.com/alexdobin/STAR"><img src="https://img.shields.io/badge/STAR--Aligner-0052CC?style=flat&logo=bioinformatics&logoColor=white" alt="STAR"></a>
    <a href="https://daehwankimlab.github.io/hisat2/"><img src="https://img.shields.io/badge/HISAT2-008080?style=flat&logo=science&logoColor=white" alt="HISAT2"></a>
    <a href="https://multiqc.info/"><img src="https://img.shields.io/badge/MultiQC-48D1CC?style=flat&logo=databricks&logoColor=white" alt="MultiQC"></a>
  </p>

  <p>
    <a href="#section-1">Descripción</a> •
    <a href="#section-2">Estructura</a> •
    <a href="#section-3">Requisitos</a> •
    <a href="#section-4">Instalación</a> •
    <a href="#section-5">Uso</a> •
    <a href="#section-6">Notas</a> •
    <a href="#section-7">Contacto</a>
  </p>
</div>






<br>
<br>

<img src="assets/linea_divisoria_1.png" width="100%" style="border-radius: 10px;">

<h2 id="section-1">1. 📄 Descripción</h2>

Un pipeline en Nextflow diseñado para el **análisis bioinformático de RNA-Seq**, una técnica de secuenciación de alto rendimiento que permite estudiar el **transcriptoma** (la expresión cuantitativa de todos los genes en un momento o condición dada) para descubrir biomarcadores, diferencias entre tejidos o mecanismos de enfermedades.

El pipeline toma como punto de partida **archivos brutos de secuenciación en formato `.fastq.gz`** (ya sean de lectura única *Single-End* o emparejada *Paired-End*), junto con el **genoma de referencia de la especie (`.fa`)** y su correspondiente **archivo de anotación génica (`.gtf.gz`)**.

A partir de estos datos iniciales, el flujo de trabajo ejecuta automáticamente los siguientes procesos:

* **Control de Calidad Inicial:** Ejecuta `FastQC` para evaluar la calidad de las bases secuenciadas por la máquina.  
* **Limpieza y Filtrado:** Utiliza `Trim Galore` para eliminar adaptadores y lecturas de baja calidad que puedan sesgar el análisis.  
* **Alineamiento y Mapeo:** Mapea las lecturas limpias contra el genoma de referencia usando `HISAT2` (creando opcionalmente el índice si no se proporciona).  
* **Cuantificación Génica:** Cuenta cuántas lecturas caen en cada gen con `FeatureCounts` y fusiona las tablas de todas las muestras.  
* **Reporte de Calidad Global:** Consolida las métricas de todos los pasos anteriores en un único informe interactivo de `MultiQC`.  

La herramienta es **completamente reproducible**, ejecutable desde la terminal con un solo comando, y aísla cada software bioinformático dentro de **contenedores Docker o Singularity** según el perfil elegido. Los resultados finales estructurados se guardan automáticamente en la carpeta `results/`.






<br>
<br>

<img src="assets/linea_divisoria_1.png" width="100%" style="border-radius: 10px;">

<h2 id="section-2">2. 📂 Estructura del Repositorio</h2>

```plaintext
nexflow-rna-seq
├── assets
│   ├── cover.png
│   ├── linea_divisoria_1.png
│   ├── linea_divisoria_2.png
│   └── linea_divisoria_3.png
├── data
│   ├── genome
│   │   ├── annotation
│   │   │   └── annotation.gtf.gz
│   │   ├── fasta
│   │   │   └── genome.fa
│   │   └── index
│   │       ├── bowtie2
│   │       ├── hisat2
│   │       │   └── genome_index.tar.gz
│   │       └── star
│   ├── metadata
│   │   ├── paired_end.csv
│   │   └── single_end.csv
│   └── reads
│       ├── ENCSR000COQ1_1.fastq.gz
│       ├── ENCSR000COQ1_2.fastq.gz
│       ├── ENCSR000COQ2_1.fastq.gz
│       ├── ENCSR000COQ2_2.fastq.gz
│       ├── ENCSR000COR1_1.fastq.gz
│       ├── ENCSR000COR1_2.fastq.gz
│       ├── ENCSR000COR2_1.fastq.gz
│       ├── ENCSR000COR2_2.fastq.gz
│       ├── ENCSR000CPO1_1.fastq.gz
│       ├── ENCSR000CPO1_2.fastq.gz
│       ├── ENCSR000CPO2_1.fastq.gz
│       └── ENCSR000CPO2_2.fastq.gz
├── modules
│   ├── fastqc_pe.nf
│   ├── fastqc_se.nf
│   ├── featurecounts_pe.nf
│   ├── featurecounts_se.nf
│   ├── hisat2_align_pe.nf
│   ├── hisat2_align_se.nf
│   ├── hisat2_index.nf
│   ├── merge_counts.nf
│   ├── multiqc.nf
│   ├── trim_galore_pe.nf
│   └── trim_galore_se.nf
├── clean_nextflow.sh
├── enviroment.yml
├── LICENSE
├── nextflow.config
├── params.yaml
├── README.md
├── rnaseq_pe.nf
└── rnaseq_se.nf
```

El repositorio se organiza de la siguiente manera:

* **`assets/`** &rArr; Contiene recursos gráficos y multimedia utilizados en la documentación del proyecto (ej. `cover.png`).
* **`data/`** &rArr; Directorio opcional que contiene datos y referencias de prueba para este caso específico. *Nota: No es obligatorio almacenar tus archivos aquí; el pipeline permite apuntar los parámetros directamente a cualquier otra ruta local o del clúster donde residan tus secuencias y genomas reales.*
* **`modules/`** &rArr; Archivos de Nextflow modulares (`.nf`). Cada archivo representa una herramienta bioinformática aislada (un proceso), divididos por el tipo de lectura (*Single-End* o *Paired-End*) para mantener el código limpio y mantenible.
* **`clean_nextflow.sh`** &rArr; Un script auxiliar ejecutable desde la terminal para eliminar de forma segura los archivos temporales generados por Nextflow (`work/` y `.nextflow/`) tras finalizar el análisis.
* **`enviroment.yml`** &rArr; Archivo de configuración de Conda para construir el entorno virtual mínimo y necesario para ejecutar Nextflow.
* **`nextflow.config`** &rArr; Configuración central del pipeline. Define los perfiles de infraestructura (`docker`, `singularity`) y la asignación de recursos hardware.
* **`params.yaml`** &rArr; Archivo de texto plano donde el usuario define las rutas de sus archivos de entrada y los directorios de salida del pipeline de forma centralizada.
* **`rnaseq_pe.nf`** y **`rnaseq_se.nf`** &rArr; Los scripts principales (*workflows*) que orquestan e invocan los módulos correspondientes para ejecutar el pipeline completo en modo Paired-End o Single-End, respectivamente.






<br>
<br>

<img src="assets/linea_divisoria_1.png" width="100%" style="border-radius: 10px;">

<h2 id="section-3">3. ⚙️ Requisitos</h2>

* **Conda** o **Mamba** instalado en el sistema para la gestión del entorno base.
* **Nextflow 25.10.2** o superior (gestionado automáticamente a través del archivo `enviroment.yml`).
* Un motor de contenedores activo y accesible en el sistema:
  * **Docker** (recomendado para ejecuciones en entornos locales o personales).
  * **Singularity** / **Apptainer** (recomendado para entornos multiusuario o clústeres HPC).
* **Conexión a Internet** (necesaria únicamente durante la primera ejecución para que Nextflow descargue de forma automática las imágenes de Docker/Singularity desde los registros públicos).

Todas las herramientas bioinformáticas pesadas (`FastQC`, `Trim Galore`, `HISAT2`, `FeatureCounts` y `MultiQC`) están **completamente encapsuladas dentro de los contenedores**, por lo que no es necesario instalarlas de forma nativa en tu máquina ni configurarlas en el PATH.






<br>
<br>

<img src="assets/linea_divisoria_1.png" width="100%" style="border-radius: 10px;">

<h2 id="section-4">4. 💻 Instalación</h2>

Puedes preparar el entorno del proyecto usando **Conda** (para gestionar Nextflow) junto con un motor de contenedores, o instalar todo de forma **manual en local**. Ambas opciones son posibles, pero se recomienda encarecidamente la primera para asegurar la reproducibilidad.




<br>

<img src="assets/linea_divisoria_2.png" width="100%" style="border-radius: 10px;">

<h3 id="section-4.1">🔹 Opción 1: Instalación usando Conda y Contenedores (recomendada)</h3>

**1. Clonar el repositorio:**

```bash
git clone https://github.com/adrichez/nexflow-rna-seq.git
cd nexflow-rna-seq
```

**2. Crear un entorno Conda:**

```bash
conda env create -f enviroment.yml
```

**3. Activar el entorno:**

```bash
conda activate nextflow-env
```

**4. Verificar gestor de contenedores:**

> [!IMPORTANT]
> Asegúrate de tener instalado y accesible en tu sistema **Docker** (para uso local) o **Singularity/Apptainer** (para clústeres HPC). El entorno Conda solo instala Nextflow; las herramientas bioinformáticas pesadas se descargarán automáticamente como imágenes de contenedores la primera vez que lances el pipeline.




<br>

<img src="assets/linea_divisoria_2.png" width="100%" style="border-radius: 10px;">

<h3 id="section-4.2">🔹 Opción 2: Instalación manual local (no recomendada)</h3>

**1. Instalar Nextflow y Java:**

Si decides no usar Conda, deberás instalar Java (versión 11 o superior) y descargar el ejecutable de **Nextflow** directamente en tu máquina.

**2. Instalar herramientas bioinformáticas:**

```bash
# Ejemplo: Instalación de FastQC, HISAT2, etc. a través del gestor de paquetes de tu OS o desde el código fuente.
```

> [!IMPORTANT]
> Esta opción requiere que instales manualmente todas y cada una de las herramientas (`FastQC`, `Trim Galore`, `HISAT2`, `FeatureCounts`, `MultiQC`) y las añadas al PATH de tu sistema operativo. No se recomienda porque es propenso a errores de versiones y rompe la filosofía de reproducibilidad del pipeline.
> 
> Con cualquiera de las dos opciones (y con tus datos listos), ya se podrá ejecutar el pipeline principal.






<br>
<br>

<img src="assets/linea_divisoria_1.png" width="100%" style="border-radius: 10px;">

<h2 id="section-5">5. 🚀 Uso</h2>

El pipeline se puede ejecutar de dos maneras: descargando el código a tu máquina (**clonando el repositorio**) o invocando el código en la nube (**directamente desde GitHub**, sin descargarlo).

Toda la configuración de rutas y parámetros se gestiona fácilmente a través del archivo `params.yaml`. Para iniciar el análisis, ejecuta el pipeline usando Nextflow:


**Opción A: Ejecución con el repositorio clonado localmente**

```bash
git clone https://github.com/adrichez/nextflow-rna-seq.git
cd nextflow-rna-seq
nextflow run rnaseq_{se/pe}.nf -params-file params.yaml -profile <perfiles>
```


**Opción B: Ejecución directa desde GitHub (sin clonar)**

```bash
nextflow run adrichez/nextflow-rna-seq -main-script rnaseq_{se/pe}.nf -r main -params-file params.yaml -profile <perfiles>
```

Se pueden utilizar dos scripts principales dependiendo de tus datos:

* `rnaseq_se.nf` para lecturas simples (Single-End).
* `rnaseq_pe.nf` para lecturas emparejadas (Paired-End).

* Ingresa las **rutas de los archivos de entrada** (`reads`, `genome`, `annotation`, `hisat2_index`).
* Opcionalmente ajusta:
* El directorio de salida (por defecto `outdir: "results"`)
* Otros parámetros específicos del análisis

Los resultados finales, incluyendo los conteos génicos y los reportes de calidad, se guardarán automáticamente en la carpeta `results/`.

> [!NOTE]
> **Nota sobre la ejecución remota (GitHub):** Si ejecutas el pipeline directamente desde GitHub, el archivo referenciado con `-params-file params.yaml` **será el de tu entorno local**. Esto te permite tener una carpeta que contenga únicamente tu archivo `params.yaml` y ejecutar el código de la nube directamente sobre tus propios datos.

Ejemplo de este archivo `params.yaml`:

```yaml
input: "data/metadata/single_end.csv"
genome_fasta_zip: "data/genome/fasta/Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa.gz"
hisat2_index_zip: "data/genome/index/hisat2/genome_index.tar.gz"
gtf_zip: "data/genome/annotation/Saccharomyces_cerevisiae.R64-1-1.115.gtf.gz"
report_id: "multiqc_report_se"
```

El archivo `nextflow.config` incluye perfiles preconfigurados para adaptar el pipeline a tu infraestructura y simplificar las fases de prueba. Puedes combinar un perfil de entorno con un perfil de prueba separándolos por comas.

* `local_docker`: Ejecuta los procesos directamente en tu máquina local utilizando **Docker** para el aislamiento del software.
* `cluster_apptainer`: Diseñado para servidores o clústeres compartidos. Utiliza **Apptainer (Singularity)** de forma segura (sin privilegios de root) pero ejecuta las tareas secuencialmente sin gestor de colas.
* `slurm_apptainer`: Diseñado para clústeres **HPC administrados por SLURM**. Envía las tareas a las colas del clúster utilizando **Apptainer** y optimiza dinámicamente los recursos hardware (ej. 8 CPUs base para tareas genéricas y 16 CPUs dedicadas para el proceso `HISAT2_ALIGN`).

* `test_se_fasta`: Prueba rápida para datos *Single-End* partiendo del genoma bruto en FASTA (construye el índice desde cero).
* `test_se_index`: Prueba rápida para datos *Single-End* cargando un índice de HISAT2 ya pregenerado en formato `.tar.gz`.
* `test_pe_fasta`: Prueba rápida para datos *Paired-End* partiendo del genoma bruto en FASTA (construye el índice desde cero).
* `test_pe_index`: Prueba rápida para datos *Paired-End* cargando un índice de HISAT2 ya pregenerado en formato `.tar.gz`.


**Ejemplo de ejecución (test) con repositorio clonado:**

```bash
nextflow run rnaseq_pe.nf -profile test_pe_index,local_docker
```


**Ejemplo de ejecución (test) directa desde GitHub:**

```bash
nextflow run adrichez/nextflow-rna-seq -main-script rnaseq_pe.nf -r main -profile test_pe_index,local_docker
```


**Ejemplo de ejecución (parámetros definidos) con repositorio clonado:**

```bash
nextflow run rnaseq_pe.nf -params-file params.yaml -profile slurm_apptainer
```

**Ejemplo de ejecución (parámetros definidos) directa desde GitHub:**

```bash
nextflow run adrichez/nextflow-rna-seq -main-script rnaseq_pe.nf -r main -params-file params.yaml -profile slurm_apptainer
```

Si has optado por clonar el repositorio localmente, puedes ejecutar el siguiente **script de limpieza** para liberar espacio en el caso de que lo consideres necesario:

```bash
bash clean_nextflow.sh
```

o bien:

```bash
./clean_nextflow.sh
```

El script eliminará automáticamente los directorios temporales `work/` y `.nextflow/`, así como los logs intermedios, conservando únicamente tus resultados finales en `results/`.

> [!NOTE]
> Durante todo el proceso, Nextflow mostrará un **registro de progreso** en la terminal indicando el estado de cada tarea y, al finalizar, se muestra el **tiempo total empleado** y el estado de la ejecución.






<br>
<br>

<img src="assets/linea_divisoria_1.png" width="100%" style="border-radius: 10px;">

<h2 id="section-6">6. 📝 Notas</h2>

* El pipeline detecta automáticamente si estás procesando datos *Single-End* o *Paired-End* ejecutando el workflow correspondiente (`rnaseq_se.nf` o `rnaseq_pe.nf`).
* Las imágenes de Docker y Apptainer se descargan **únicamente en la primera ejecución**; las ejecuciones posteriores utilizarán la caché local, eliminando la necesidad de conexión a Internet.
* Para el perfil de clúster, el directorio de caché de Apptainer está fijado por defecto en la ruta absoluta de tu servidor (`/mnt/beegfs/...`), asegurando que todos los nodos compartan las mismas imágenes `.sif`.
* No se requiere ingresar rutas manuales para cada paso intermedio, todas las herramientas vuelcan sus resultados de forma organizada en la carpeta centralizada `results/`.
* Compatible con cualquier archivo de lecturas en formato comprimido `.fastq.gz` que cumpla con la estructura de metadatos o el patrón de nombres especificado.






<br>
<br>

<img src="assets/linea_divisoria_1.png" width="100%" style="border-radius: 10px;">

<h2 id="section-7">7. 📬 Contacto</h2>

Si quieres contactar conmigo:  

- 📧 Email: [asanca33@gmail.com](mailto:asanca33@gmail.com)  
- 📞 Teléfono: [+34 673 49 99 51](tel:+34673499951)  
- 📍 Ubicación: Granada, España.

¡Estaré encantado de ayudarte con cualquier duda o sugerencia! 😊
