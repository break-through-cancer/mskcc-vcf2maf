nextflow.enable.dsl=2

params.outdir = "vcf2maf_out"
params.vep_path = "/opt/variant_effect_predictor_85/ensembl-tools-release-85/scripts/variant_effect_predictor"
params.vep_data = "/root/.vep"
// process VCF2MAF {
//     tag "${vcf.simpleName}"

//     publishDir params.outdir, mode: "copy"

//     container "cgrlab/vcf2maf"

//     input:
//     path vcf

//     output:
//     path "${vcf.simpleName}.maf"

//     script:
//     """
//     set -euo pipefail

//     echo "PWD:"
//     pwd

//     echo "Files staged:"
//     ls -lh

//     echo "Input VCF: ${vcf}"
//     echo "Output MAF: ${vcf.simpleName}.maf"

//     VCF2MAF=\$(find / -name vcf2maf.pl 2>/dev/null | head -n 1)

//     echo "Using vcf2maf: \$VCF2MAF"

//     if [ -z "\$VCF2MAF" ]; then
//         echo "ERROR: Could not find vcf2maf.pl inside container"
//         find / -name "*vcf2maf*" 2>/dev/null || true
//         exit 1
//     fi

//     echo "Searching for VEP script..."
//     find / -name variant_effect_predictor.pl 2>/dev/null || true
//     perl "\$VCF2MAF" \
//         --input-vcf "${vcf}" \
//         --output-maf "${vcf.simpleName}.maf" \
//         --vep-path "${params.vep_path}" \
//         --vep-data "${params.vep_data}"
//     """
// }
process VCF2MAF {
    tag "${sample_id}"
    container 'cgrlab/vcf2maf'
    publishDir "${params.outdir}", mode: "copy"

    input:
    tuple val(sample_id), path(vcf)

    output:
    path "${sample_id}.maf"

    script:
    """
    set -euo pipefail

    echo "[PREPROCESS] Stripping 'chr' prefixes from ${vcf}..."
    if [[ "${vcf}" == *.gz ]]; then
        gzip -dc "${vcf}"
    else
        cat "${vcf}"
    fi | awk '
        BEGIN { FS=OFS="\t" }
        /^#/ { print; next }
        {
            gsub(/^chr/, "", \$1)
            if (\$1 == "M") \$1 = "MT"
            print
        }
    ' > grch37_compatible.vcf

    VCF2MAF=$(find / -name vcf2maf.pl 2>/dev/null | head -n 1)

    VEP_SCRIPT=$(find / -name variant_effect_predictor.pl 2>/dev/null | head -n 1)

    if [ -z "$VCF2MAF" ]; then
        echo "ERROR: Could not find vcf2maf.pl"
        exit 1
    fi

    if [ -z "$VEP_SCRIPT" ]; then
        echo "ERROR: Could not find variant_effect_predictor.pl"
        exit 1
    fi

    VEP_PATH=$(dirname "$VEP_SCRIPT")

    echo "Using vcf2maf: $VCF2MAF"
    echo "Using VEP path: $VEP_PATH"

    perl "\$VCF2MAF" \
        --input-vcf "${vcf}" \
        --output-maf "${sample_id}.maf" \
        --vep-path "${params.vep_path}" \
        --vep-data "${params.vep_data}" \
        --ncbi-build GRCh37
    """
}

workflow {
    println "params.input_vcf = ${params.input_vcf}"
    println params.dump()

    if (!params.input_vcf) {
        error "Missing required parameter: --input_vcf"
    }

    // Step 1: Create the baseline path channel
    // Step 2: Use .map to transform each file path into a [ sample_id, file_path ] tuple
    vcf_ch = Channel.fromPath(params.input_vcf, checkIfExists: true)
        .map { vcf_file ->
            // Extracts the file name without extensions (e.g., "DFCI3-S4-L2.mutectv2.final")
            def sample_id = vcf_file.simpleName
            
            // Return the structured tuple expected by VCF2MAF input
            return tuple(sample_id, vcf_file)
        }

    // Pass the properly structured tuple channel into the process
    VCF2MAF(vcf_ch)
}


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
