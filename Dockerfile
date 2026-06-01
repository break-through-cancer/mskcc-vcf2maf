FROM cgrlab/vcf2maf

USER root

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    perl \
    cpanminus \
    build-essential \
    libdbi-perl \
    libdbd-mysql-perl \
    libarchive-zip-perl \
    libjson-perl \
    libwww-perl \
    libmodule-build-perl \
    libset-intervaltree-perl \
    libperlio-gzip-perl \
    libbio-db-hts-perl \
    tabix \
    samtools \
    bcftools \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN git clone https://github.com/Ensembl/ensembl-vep.git /opt/vep

WORKDIR /opt/vep

RUN perl INSTALL.pl \
    --AUTO a \
    --NO_TEST \
    --NO_UPDATE \
    --NO_HTSLIB \
    --SPECIES homo_sapiens \
    --ASSEMBLY GRCh38

ENV PATH="/opt/vep:/opt/vcf2maf:${PATH}"
ENV VEP_PATH="/opt/vep"
ENV VEP_DATA="/root/.vep"

WORKDIR /data