nextflow.enable.dsl=2

params.outdir = "vcf2maf_out"
params.vep_path = "/opt/vep"
params.vep_data = "/root/.vep"
process VCF2MAF {
    tag "${vcf.simpleName}"

    publishDir params.outdir, mode: "copy"

    container "cgrlab/vcf2maf"

    input:
    path vcf

    output:
    path "${vcf.simpleName}.maf"

    script:
    """
    set -euo pipefail

    echo "PWD:"
    pwd

    echo "Files staged:"
    ls -lh

    echo "Input VCF: ${vcf}"
    echo "Output MAF: ${vcf.simpleName}.maf"

    VCF2MAF=\$(find / -name vcf2maf.pl 2>/dev/null | head -n 1)

    echo "Using vcf2maf: \$VCF2MAF"

    if [ -z "\$VCF2MAF" ]; then
        echo "ERROR: Could not find vcf2maf.pl inside container"
        find / -name "*vcf2maf*" 2>/dev/null || true
        exit 1
    fi

    echo "Searching for VEP script..."
    find / -name variant_effect_predictor.pl 2>/dev/null || true
    perl "\$VCF2MAF" \
        --input-vcf "${vcf}" \
        --output-maf "${vcf.simpleName}.maf" \
        --vep-path "${params.vep_path}" \
        --vep-data "${params.vep_data}"
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