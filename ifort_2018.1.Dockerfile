# Dockerfile to build Intel FORTRAN 2016 Update 3

# Build with the following command:
# docker build \
#  -t humanpredictions/ifort:2018.1 \
#  -t humanpredictions/ifort:latest \
#  -f ifort_2018.1.Dockerfile .

# Set the base image to a long-term Ubuntu release
FROM ubuntu:16.04

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

COPY ifort_2018.1.cfg /tmp/ifort_base.cfg

RUN cd /tmp \
    && wget -O compiler.tgz http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/12374/parallel_studio_xe_2018_update1_cluster_edition_online.tgz \
    && tar zxvf compiler.tgz \
    && cd p* \
    && ./install.sh --silent /tmp/ifort_base.cfg \
    && rm -rf /tmp/* \
              /opt/intel/ism \
	      /opt/intel/documentation* \
	      /opt/intel/ide* \
	      /opt/intel/samples* \
	      /opt/intel/licenses/*

# You must put a license file into /opt/intel/licenses for the compiler
# to work.

ENV PATH /opt/intel/bin:$PATH

CMD ["/opt/intel/bin/ifort"]
