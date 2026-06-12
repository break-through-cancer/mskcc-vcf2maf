nextflow.enable.dsl=2

params.outdir = "vcf2maf_out"
params.input_vcf = null

params.vep_path = "/usr/local/bin"
params.vep_data = "/root/.vep"
params.ref_fasta = "/root/.vep/homo_sapiens/112_GRCh37/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.gz"

process VCF2MAF {
    tag "${sample_id}"

    container "ghcr.io/jchen1095/vcf2maf-vep112-grch37:latest"

    publishDir "${params.outdir}", mode: "copy"

    input:
    tuple val(sample_id), path(vcf)

    output:
    path "${sample_id}.maf"
    path "${sample_id}.diagnostics.txt"

    script:
    """
    set -euo pipefail

    DIAG="${sample_id}.diagnostics.txt"

    echo "===== BASIC INFO =====" > "\$DIAG"
    echo "PWD: \$(pwd)" >> "\$DIAG"
    echo "Input VCF: ${vcf}" >> "\$DIAG"
    echo "Sample ID: ${sample_id}" >> "\$DIAG"

    echo "" >> "\$DIAG"
    echo "===== TOOL PATHS =====" >> "\$DIAG"
    echo "vcf2maf: \$(which vcf2maf.pl || true)" >> "\$DIAG"
    echo "vep: \$(which vep || true)" >> "\$DIAG"

    echo "" >> "\$DIAG"
    echo "===== VEP DATA =====" >> "\$DIAG"
    echo "VEP path: ${params.vep_path}" >> "\$DIAG"
    echo "VEP data: ${params.vep_data}" >> "\$DIAG"
    echo "Ref FASTA: ${params.ref_fasta}" >> "\$DIAG"
    ls -lh "${params.ref_fasta}" >> "\$DIAG" || true
    find "${params.vep_data}/homo_sapiens/112_GRCh37" -maxdepth 1 | head -30 >> "\$DIAG" || true

    echo "" >> "\$DIAG"
    echo "===== VCF REFERENCE HEADER =====" >> "\$DIAG"
    grep "^##reference" "${vcf}" >> "\$DIAG" || true
    grep "^##contig" "${vcf}" | head -20 >> "\$DIAG" || true

    echo "" >> "\$DIAG"
    echo "===== FIRST VARIANT CHROMOSOMES =====" >> "\$DIAG"
    grep -v "^#" "${vcf}" | head -50 | cut -f1 | sort -u >> "\$DIAG" || true

    echo "" >> "\$DIAG"
    echo "===== RUNNING VCF2MAF =====" >> "\$DIAG"

    vcf2maf.pl \
        --input-vcf "${vcf}" \
        --output-maf "${sample_id}.maf" \
        --ncbi-build GRCh37 \
        --ref-fasta "${params.ref_fasta}" \
        --vep-path "${params.vep_path}" \
        --vep-data "${params.vep_data}" \
        --vep-params "--no_sift --no_polyphen"
    """
}

workflow {
    println "params.input_vcf = ${params.input_vcf}"
    println params.dump()

    if (!params.input_vcf) {
        error "Missing required parameter: --input_vcf"
    }

    vcf_ch = Channel.fromPath(params.input_vcf, checkIfExists: true)
        .map { vcf_file ->
            def sample_id = vcf_file.simpleName
            tuple(sample_id, vcf_file)
        }

    VCF2MAF(vcf_ch)
}
// process VCF2MAF {
//     tag "${sample_id}"
//     container 'cgrlab/vcf2maf'
//     publishDir "${params.outdir}", mode: "copy"

//     input:
//     tuple val(sample_id), path(vcf)

//     output:
//     path "${sample_id}.maf"
//     path "${sample_id}.diagnostics.txt"

//     script:
//     """
//     set -euo pipefail

//     DIAG="${sample_id}.diagnostics.txt"

//     echo "===== BASIC INFO =====" > "\$DIAG"
//     echo "PWD: \$(pwd)" >> "\$DIAG"
//     echo "Input VCF: ${vcf}" >> "\$DIAG"
//     echo "Sample ID: ${sample_id}" >> "\$DIAG"

//     echo "" >> "\$DIAG"
//     echo "===== TOOL PATHS =====" >> "\$DIAG"
//     VCF2MAF=\$(find / -name vcf2maf.pl 2>/dev/null | head -n 1)
//     VEP_SCRIPT=\$(find / -name variant_effect_predictor.pl 2>/dev/null | head -n 1)

//     echo "VCF2MAF: \$VCF2MAF" >> "\$DIAG"
//     echo "VEP_SCRIPT: \$VEP_SCRIPT" >> "\$DIAG"
//     echo "PARAM VEP path: ${params.vep_path}" >> "\$DIAG"
//     echo "PARAM VEP data: ${params.vep_data}" >> "\$DIAG"

//     echo "" >> "\$DIAG"
//     echo "===== VEP CACHE / DATA =====" >> "\$DIAG"
//     find "${params.vep_data}" -maxdepth 4 -type d 2>/dev/null >> "\$DIAG" || true

//     echo "" >> "\$DIAG"
//     echo "===== VCF REFERENCE HEADER =====" >> "\$DIAG"
//     grep "^##reference" "${vcf}" >> "\$DIAG" || true
//     grep "^##contig" "${vcf}" | head -20 >> "\$DIAG" || true

//     echo "" >> "\$DIAG"
//     echo "===== FIRST VARIANT CHROMOSOMES =====" >> "\$DIAG"
//     grep -v "^#" "${vcf}" | head -50 | cut -f1 | sort -u >> "\$DIAG" || true

//     echo "" >> "\$DIAG"
//     echo "===== FIRST 5 VARIANTS =====" >> "\$DIAG"
//     grep -v "^#" "${vcf}" | head -5 >> "\$DIAG" || true

//     echo "" >> "\$DIAG"
//     echo "===== RUNNING VCF2MAF =====" >> "\$DIAG"

//     echo "Using vcf2maf: \$VCF2MAF"
//     echo "Using VEP script: \$VEP_SCRIPT"
//     echo "Using VEP path: ${params.vep_path}"
//     echo "Using VEP data: ${params.vep_data}"

//     perl "\$VCF2MAF" \
//         --input-vcf "${vcf}" \
//         --output-maf "${sample_id}.maf" \
//         --vep-path "${params.vep_path}" \
//         --vep-data "${params.vep_data}" \
//         --ncbi-build GRCh38
//     """
// }
// workflow {
//     println "params.input_vcf = ${params.input_vcf}"
//     println params.dump()

//     if (!params.input_vcf) {
//         error "Missing required parameter: --input_vcf"
//     }

//     // Step 1: Create the baseline path channel
//     // Step 2: Use .map to transform each file path into a [ sample_id, file_path ] tuple
//     vcf_ch = Channel.fromPath(params.input_vcf, checkIfExists: true)
//         .map { vcf_file ->
//             // Extracts the file name without extensions (e.g., "DFCI3-S4-L2.mutectv2.final")
//             def sample_id = vcf_file.simpleName
            
//             // Return the structured tuple expected by VCF2MAF input
//             return tuple(sample_id, vcf_file)
//         }

//     // Pass the properly structured tuple channel into the process
//     VCF2MAF(vcf_ch)
// }


// nextflow.enable.dsl=2

// params.outdir = "vcf2maf_out"
// params.input_vcf = null
// params.vep_data = "/root/.vep"

// process VCF2MAF {
//     tag "${sample_id}"
//     container 'cgrlab/vcf2maf'
//     publishDir "${params.outdir}", mode: "copy"

//     input:
//     tuple val(sample_id), path(vcf)

//     output:
//     path "${sample_id}.maf", optional: true
//     path "tool_paths.txt"

//     script:
//     """
//     set -euo pipefail

//     echo "PWD:" > tool_paths.txt
//     pwd >> tool_paths.txt

//     echo "" >> tool_paths.txt
//     echo "Input VCF: ${vcf}" >> tool_paths.txt

//     echo "" >> tool_paths.txt
//     echo "Searching for vcf2maf.pl..." >> tool_paths.txt
//     find / -name vcf2maf.pl 2>/dev/null | tee -a tool_paths.txt || true

//     echo "" >> tool_paths.txt
//     echo "Searching for variant_effect_predictor.pl..." >> tool_paths.txt
//     find / -name variant_effect_predictor.pl 2>/dev/null | tee -a tool_paths.txt || true

//     echo "" >> tool_paths.txt
//     echo "Searching for VEP directories..." >> tool_paths.txt
//     find / -iname "*vep*" 2>/dev/null | head -200 | tee -a tool_paths.txt || true

//     echo "" >> tool_paths.txt
//     echo "Checking VEP data:" >> tool_paths.txt
//     ls -R ${params.vep_data} 2>/dev/null | head -200 >> tool_paths.txt || true
//     """
// }

// workflow {
//     if (!params.input_vcf) {
//         error "Missing required parameter: --input_vcf"
//     }

//     vcf_ch = Channel.fromPath(params.input_vcf, checkIfExists: true)
//         .map { vcf_file ->
//             tuple(vcf_file.simpleName, vcf_file)
//         }

//     VCF2MAF(vcf_ch)
// }
