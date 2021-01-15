FROM continuumio/miniconda3@sha256:456e3196bf3ffb13fee7c9216db4b18b5e6f4d37090b31df3e0309926e98cfe2

LABEL description="Docker image containing all requirements for lifebit-ai/simulate" \
      author="magda@lifebit.ai"

RUN apt-get update -y  \ 
    && apt-get install -y wget zip procps gawk \
    && rm -rf /var/lib/apt/lists/*

COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/simulate/bin:$PATH

# Install hapgen2
RUN mkdir hapgen2 \
    && cd hapgen2 \
    && wget https://mathgen.stats.ox.ac.uk/genetics_software/hapgen/download/builds/x86_64/v2.1.2/hapgen2_x86_64.tar.gz \
    && tar -xzvf hapgen2_x86_64.tar.gz

ENV PATH /hapgen2:$PATH

# Install plink 2
RUN wget http://s3.amazonaws.com/plink2-assets/alpha2/plink2_linux_x86_64.zip \
    && unzip plink2_linux_x86_64.zip -d plink2 \
    && rm plink2_linux_x86_64.zip

ENV PATH /plink2:$PATH

# Install gcta
RUN wget https://cnsgenomics.com/software/gcta/bin/gcta_1.93.2beta.zip \
   && unzip gcta_1.93.2beta.zip -d gcta \
   && rm gcta_1.93.2beta.zip

ENV PATH /gcta/gcta_1.93.2beta:$PATH

RUN mkdir /opt/bin
COPY bin/* /opt/bin/

RUN find /opt/bin/ -type f -iname "*.py" -exec chmod +x {} \; && \
    find /opt/bin/ -type f -iname "*.R" -exec chmod +x {} \; && \
    find /opt/bin/ -type f -iname "*.sh" -exec chmod +x {} \; && \
    find /opt/bin/ -type f -iname "*.css" -exec chmod +x {} \; && \
    find /opt/bin/ -type f -iname "*.Rmd" -exec chmod +x {} \;

ENV PATH="$PATH:/opt/bin/"

USER root

WORKDIR /data/

CMD ["bash"]


