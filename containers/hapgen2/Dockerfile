FROM ubuntu@sha256:6654ae91f6ffadc48279273becce4ceba3c8f7cd312230f28b3082ecb2d3dec5

LABEL description="Docker image containing all requirements for hapgen2" \
      author="magda@lifebit.ai"

RUN apt-get update -y  \ 
    && apt-get install -y wget zip procps \
    && rm -rf /var/lib/apt/lists/*

RUN cd opt/ \
    && wget https://mathgen.stats.ox.ac.uk/genetics_software/hapgen/download/builds/x86_64/v2.1.2/hapgen2_x86_64.tar.gz \
    && tar -xzvf hapgen2_x86_64.tar.gz

ENV PATH /opt:$PATH

USER root

WORKDIR /data/

CMD ["bash"]


