# Dockerfile to build Intel FORTRAN 2019 Update 4

# Build with the following command:
# docker build \
#  -t humanpredictions/ifort:2019.4 \
#  -t humanpredictions/ifort:latest \
#  -f ifort_2019.4.Dockerfile .
#
# Optionally host the installer file locally
# --build-arg PARALLELSTUDIOURL=http://example.com/file.tgz

# Set the base image to a long-term Ubuntu release
FROM ubuntu:18.04

# Dockerfile Maintainer
MAINTAINER William Denney

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
       cpio \
       g++ \
       make \
       wget \
    && rm -rf /var/lib/apt/lists/ \
              /var/cache/apt/archives/ \
	      /usr/share/doc/ \
	      /usr/share/man/ \
	      /usr/share/locale/

# Generate a new cfg file with ./install.sh --duplicate=ifort_2019.4.cfg
COPY ifort_2019.4.cfg /tmp/ifort.cfg
COPY intel_l_mpi_2019.4.cfg /tmp/mpi.cfg
COPY ifort.lic /tmp/ifort.lic
ARG PARALLELSTUDIOURL=http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15539/parallel_studio_xe_2019_update4_composer_edition_for_fortran.tgz
ARG MPIURL=http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15553/l_mpi_2019.4.243.tgz

RUN cd /tmp \
    && wget --quiet -O compiler.tgz ${PARALLELSTUDIOURL} \
    && wget --quiet -O mpi.tgz ${MPIURL} \
    && tar -xf compiler.tgz \
    && tar -xf mpi.tgz \
    && cd p* \
    && ./install.sh --silent /tmp/ifort.cfg \
    && echo "Intel Fortran installation complete" \
    && cd ../l_mpi* \
    && ./install.sh --silent /tmp/mpi.cfg \
    && echo "Intel MPI installation complete" \
    && rm -rf /tmp/* \
	      /opt/intel/documentation* \
	      /opt/intel/samples* \
	      /opt/intel/licenses/*

# You must put a license file into /opt/intel/licenses for the compiler
# to work.

ENV PATH /opt/intel/bin:$PATH

CMD ["/opt/intel/bin/ifort"]
