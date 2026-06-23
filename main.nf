nextflow.enable.dsl=2

params.outdir = "vcf2maf_out"
params.input_vcf = null

params.vep_path = "/usr/local/bin"
params.vep_data = "/root/.vep"
params.ref_fasta = "/root/.vep/homo_sapiens/112_GRCh37/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.gz"

process VCF2MAF {
    tag "${sample_id}"

    container "ghcr.io/jchen1095/vcf2maf-vep112-grch37-polyphen-sift:latest"

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
    echo "===== PERL MODULES =====" >> "\$DIAG"
    perl -MDBI -e 'print "DBI works\\n"' >> "\$DIAG"
    perl -MDBD::SQLite -e 'print "SQLite works\\n"' >> "\$DIAG"

    echo "" >> "\$DIAG"
    echo "===== POLYPHEN/SIFT FILES =====" >> "\$DIAG"
    find "${params.vep_data}" -iname "*polyphen*" -o -iname "*sift*" -o -iname "*.db" | head -50 >> "\$DIAG" || true

    echo "" >> "\$DIAG"
    echo "===== VEP DATA =====" >> "\$DIAG"
    echo "VEP path: ${params.vep_path}" >> "\$DIAG"
    echo "VEP data: ${params.vep_data}" >> "\$DIAG"
    echo "Ref FASTA: ${params.ref_fasta}" >> "\$DIAG"
    ls -lh "${params.ref_fasta}" >> "\$DIAG"

    echo "" >> "\$DIAG"
    echo "===== VCF REFERENCE HEADER =====" >> "\$DIAG"
    grep "^##reference" "${vcf}" >> "\$DIAG" || true
    grep "^##contig" "${vcf}" | head -20 >> "\$DIAG" || true

    echo "" >> "\$DIAG"
    echo "===== FIRST VARIANT CHROMOSOMES =====" >> "\$DIAG"
    grep -v "^#" "${vcf}" | head -50 | cut -f1 | sort -u >> "\$DIAG" || true

    echo "" >> "\$DIAG"
    echo "===== RUNNING VCF2MAF =====" >> "\$DIAG"

    echo "vcf2maf: \$(command -v vcf2maf.pl || true)" >> "\$DIAG"
    echo "vep: \$(command -v vep || true)" >> "\$DIAG"
    ls -lh /usr/local/bin/vcf2maf.pl >> "\$DIAG" || true
    ls -lh /usr/local/bin/vep >> "\$DIAG" || true

    perl /usr/local/bin/vcf2maf.pl \
        --input-vcf "${vcf}" \
        --output-maf "${sample_id}.maf" \
        --ncbi-build GRCh37 \
        --ref-fasta "${params.ref_fasta}" \
        --vep-path "${params.vep_path}" \
        --vep-data "${params.vep_data}" \
        >> "\$DIAG" 2>&1

    echo "" >> "\$DIAG"
    echo "===== OUTPUT CHECK =====" >> "\$DIAG"
    ls -lh "${sample_id}.maf" >> "\$DIAG"
    grep -n "^Hugo_Symbol" "${sample_id}.maf" >> "\$DIAG" || true
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