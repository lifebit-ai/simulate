FROM ubuntu@sha256:6654ae91f6ffadc48279273becce4ceba3c8f7cd312230f28b3082ecb2d3dec5

LABEL description="Docker image containing all requirements for lifebit-ai/simulate" \
      author="magda@lifebit.ai"

RUN apt-get update -y  \ 
    && apt-get install -y wget zip procps \
    && rm -rf /var/lib/apt/lists/*

# Install hapgen2
RUN cd opt/ \
    && wget https://mathgen.stats.ox.ac.uk/genetics_software/hapgen/download/builds/x86_64/v2.1.2/hapgen2_x86_64.tar.gz \
    && tar -xzvf hapgen2_x86_64.tar.gz

ENV PATH /opt:$PATH

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

USER root

WORKDIR /data/

CMD ["bash"]


