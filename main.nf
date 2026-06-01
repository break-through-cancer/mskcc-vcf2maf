nextflow.enable.dsl=2

params.vcf = null
params.outdir = "vcf2maf_out"

params.vep_path = "/opt/vep"
params.vep_data = "/root/.vep"

process VCF2MAF {
    tag "${vcf.simpleName}"

    publishDir params.outdir, mode: "copy"

    container "vcf2maf-vep:latest"

    input:
    path vcf

    output:
    path "${vcf.simpleName}.maf"

    script:
    """
    set -euo pipefail

    VCF2MAF=\$(find / -name vcf2maf.pl 2>/dev/null | head -n 1)

    echo "Using vcf2maf: \$VCF2MAF"
    echo "Using VEP path: ${params.vep_path}"
    echo "Using VEP data: ${params.vep_data}"

    perl "\$VCF2MAF" \\
        --input-vcf "${vcf}" \\
        --output-maf "${vcf.simpleName}.maf" \\
        --vep-path "${params.vep_path}" \\
        --vep-data "${params.vep_data}"
    """
}

workflow {
    if (!params.vcf) {
        error "Missing required parameter: --vcf"
    }

    VCF2MAF(file(params.vcf))
}