nextflow.enable.dsl=2

params.outdir = "vcf2maf_out"
params.vep_path = "/opt/vep"
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
    
    echo "[PREPROCESS] Generating hg19 to GRCh37 chromosome mapping file..."
    for c in {1..22} X Y; do
        echo "chr\${c} \${c}" >> chr_map.txt
    done
    echo "chrM MT" >> chr_map.txt

    echo "[PREPROCESS] Stripping 'chr' prefixes from ${vcf}..."
    # Note: Using bcftools (which is usually bundled or available in genomic containers)
    # If bcftools is missing in this specific container, we can use a lightweight awk fallback instead.
    bcftools annotate --rename-chrs chr_map.txt ${vcf} -Oz -o grch37_compatible.vcf.gz
    bcftools index -t grch37_compatible.vcf.gz

    VCF2MAF=\$(find / -name vcf2maf.pl 2>/dev/null | head -n 1)
    
    echo "Using vcf2maf: \$VCF2MAF"
    echo "Running annotation on remapped GRCh37 VCF..."

    perl "\$VCF2MAF" \
        --input-vcf "grch37_compatible.vcf.gz" \
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

    vcf_ch = Channel.fromPath(params.input_vcf, checkIfExists: true)
    VCF2MAF(vcf_ch)
}