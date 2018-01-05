# Dockerfile to build Intel FORTRAN 2016 Update 3

# Build with the following command:
# docker build \
#  --build-arg IFORTSERIAL=[your serial number] \
#  -t humanpredictions/ifort:2016.3 \
#  -t humanpredictions/ifort:latest \
#  -f ifort_2016.3.Dockerfile .

# Set the base image to a long-term Ubuntu release
FROM ubuntu:16.04

# Dockerfile Maintainer
MAINTAINER William Denney

ARG IFORTSERIAL

# Install ca-certificates (for wget to securely connect to Intel) wget
# (to gather the required files), linux-headers (to run ifort
# installer), make (to install ifort), cpio (to install ifort), and
# unzip (to decompress NONMEM).  then clean up the image as much as
# possible)

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
       ca-certificates \
       cpio \
       g++ \
       linux-headers-$(uname -r) \
       make \
       unzip \
       wget \
    && rm -rf /var/lib/apt/lists/ \
              /var/cache/apt/archives/ \
	      /usr/share/doc/ \
	      /usr/share/man/ \
	      /usr/share/locale/

## Note: The contents of the config file have been confirmed as the
## minimum requirements by Intel Support:
## https://software.intel.com/en-us/comment/1876639

COPY ifort_2016.3.cfg /tmp/ifort_base.cfg

RUN cd /tmp \
    && wget http://registrationcenter-download.intel.com/akdlm/irc_nas/9065/parallel_studio_xe_2016_update3_online.sh \
    && chmod 755 parallel_studio_xe_2016_update3_online.sh \
    && (cat ifort_base.cfg | sed s/KERNELVER/$(uname -r)/ | sed s/INTELSERIAL/$IFORTSERIAL/ > ifort.cfg) \
    && ./parallel_studio_xe_2016_update3_online.sh -s ifort.cfg \
    && rm -rf /tmp/* \
              /opt/intel/ism \
	      /opt/intel/documentation* \
	      /opt/intel/ide* \
	      /opt/intel/samples*

ENV PATH /opt/intel/bin:$PATH

CMD ["/opt/intel/bin/ifort"]
