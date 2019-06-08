# Dockerfile to build NMQual 8.4.0 with NONMEM 7.4.3 and MPI

# Build with the following command:
# docker build \
#  --build-arg NONMEMZIPPASS=[your password] \
#  -t humanpredictions/nmqual:7.4.3_8.4.0-gfortran-1 \
#  -t humanpredictions/nmqual:latest \
#  -f NONMEM_7.4.3-nmqual_8.4.0.Dockerfile .

# Installation can be sped up for multiple installations (like
# nmqual, NONMEM, and PsN) by pre-downloading required zip
# files and then serving them from a local directory:
#
# wget https://nonmem.iconplc.com/nonmem743/NONMEM7.4.3.zip
# wget https://bitbucket.org/metrumrg/nmqual/downloads/nmqual-8.4.0.zip
# python -m SimpleHTTPServer
#
# Then in a separate terminal, give your local server for the
# NONMEMURL and NMQUALURL build arguments:
# docker build \
#  --build-arg NONMEMZIPPASS=[your password] \
#  --build-arg NONMEMURL=http://example.com/NONMEM7.4.3.zip \
#  --build-arg NMQUALURL=http://example.com/nmqual-8.4.0.zip \
#  -t humanpredictions/nmqual:7.4.3_8.4.0-gfortran-1 \
#  -t humanpredictions/nmqual:latest \
#  -f NONMEM_7.4.3-nmqual_8.4.0.Dockerfile .
#
# Other build-arg values are available to set the level of NMQual
# testing (NMQUALTESTLEVEL).  See below for details.

# Set the base image to a long-term Ubuntu release
FROM ubuntu:18.04

# Dockerfile Maintainer
MAINTAINER William Denney <wdenney@humanpredictions.com>

# Install:
# gfortran,
# MPI,
# wget,
# and unzip
# (then clean up the image as much as possible)
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
       gfortran \
       libmpich-dev \
       mpich \
       wget \
       unzip \
    && rm -rf /var/lib/apt/lists/ \
              /var/cache/apt/archives/ \
              /usr/share/doc/ \
              /usr/share/man/ \
              /usr/share/locale/

# Install perl libraries Archive::Zip and XML::XPath (then clean up
# the image as much as possible).  This is a separate step so that
# the previous step can be shared with the standard NONMEM installation.
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
       libarchive-zip-perl \
       libxml-xpath-perl \
       patch \
    && rm -rf /var/lib/apt/lists/ \
              /var/cache/apt/archives/ \
              /usr/share/doc/ \
              /usr/share/man/ \
              /usr/share/locale/

ARG NONMEM_MAJOR_VERSION=7
ARG NONMEM_MINOR_VERSION=4
ARG NONMEM_PATCH_VERSION=3
ENV NONMEM_VERSION_NO_DOTS=${NONMEM_MAJOR_VERSION}${NONMEM_MINOR_VERSION}${NONMEM_PATCH_VERSION}
ENV NONMEM_VERSION=${NONMEM_MAJOR_VERSION}.${NONMEM_MINOR_VERSION}.${NONMEM_PATCH_VERSION}
ARG NONMEMURL=https://nonmem.iconplc.com/nonmem${NONMEM_VERSION_NO_DOTS}/NONMEM${NONMEM_VERSION}.zip
ARG NONMEMZIPPASS

ARG NMQUAL_MAJOR_VERSION=8
ARG NMQUAL_MINOR_VERSION=4
ARG NMQUAL_PATCH_VERSION=0
ENV NMQUAL_VERSION_NO_DOTS=${NMQUAL_MAJOR_VERSION}${NMQUAL_MINOR_VERSION}${NMQUAL_PATCH_VERSION}
ENV NMQUAL_VERSION=${NMQUAL_MAJOR_VERSION}.${NMQUAL_MINOR_VERSION}.${NMQUAL_PATCH_VERSION}

ENV GFEXTENSION=gf
ENV NMQUAL_XML_ORIGINAL=/mnt/nmqual-${NMQUAL_VERSION}/nix/nm${NONMEM_MAJOR_VERSION}${NONMEM_MINOR_VERSION}${GFEXTENSION}.xml
ENV NMQUAL_XML_DOCKER=/mnt/nmqual-${NMQUAL_VERSION}/nix/nm${NONMEM_MAJOR_VERSION}${NONMEM_MINOR_VERSION}_docker.xml
ENV MPIPATH=/usr/lib/mpich/lib/libmpich.a

ARG NMQUALURL=https://bitbucket.org/metrumrg/nmqual/downloads/nmqual-${NMQUAL_VERSION}.zip
# This is the level of testing to run: "qualify" for full testing,
# "regress" for a reduced testing set, or "psntest" to test PsN
# installation.
ARG NMQUALTESTLEVEL=qualify

## Copy the current NONMEM license file into the image
COPY nonmem.lic /mnt
ENV NMLICENSEPATH=/mnt/nonmem.lic

## Install and test NONMEM using nmqual

## sed line comments:
## 
## Give the correct location for mpich library.
## Ensure that parent directories are created with mkdir.
##
## Note sed's allows for any delimiter to be used (not just the most
## common '/').  I am using a pipe here because there are no spaces
## and slashes in the replacements.

## autolog qualify line comments:
## Some compiler warnings are expected in the qualify step:
## http://www.cognigencorp.com/nonmem/current/2015-February/5439.html

RUN cd /mnt \
    && echo "Get and uncompress the files for installation" \
    && wget -nv --no-check-certificate ${NONMEMURL} \
    && unzip -P ${NONMEMZIPPASS} NONMEM${NONMEM_VERSION}.zip \
    && wget -nv --no-check-certificate ${NMQUALURL} \
    && unzip nmqual-${NMQUAL_VERSION}.zip \
    && echo "Update the NMQual configuration for this Docker installation" \
    && cat ${NMQUAL_XML_ORIGINAL} | \
       sed 's|/usr/local/mpich3${GFEXTENSION}/lib/libmpich.a|'${MPIPATH}'|; \
            s|741|'${NONMEM_VERSION_NO_DOTS}'|; \
            s|/etc/chef/cookbooks/ifort-nonmem/files/default/nonmem.lic|'${NMLICENSEPATH}'|; \
            s|mkdir|mkdir -p|; \
            s|cp mpicha|ln -sf mpicha|' > \
         ${NMQUAL_XML_DOCKER} \
    && echo "Install NONMEM and NMQual" \
    && cd nmqual-${NMQUAL_VERSION} \
    && perl autolog.pl ${NMQUAL_XML_DOCKER} install \
    && perl autolog.pl ${NMQUAL_XML_DOCKER} $NMQUALTESTLEVEL \
    && echo $NMQUALTESTLEVEL > /opt/NONMEM/nm${NONMEM_MAJOR_VERSION}${NONMEM_MINOR_VERSION}${GFEXTENSION}/nmqual/testlevel \
    && echo "Update the default number of nodes for parallel NONMEM in the mpilinux_XX.pnm file" \
    && for NMNODES in 2 4 8 12 16 20 24 28 32 64 128; do \
         sed 's/\[nodes\]=8/\[nodes\]='$NMNODES'/' \
           /opt/NONMEM/nm${NONMEM_MAJOR_VERSION}${NONMEM_MINOR_VERSION}${GFEXTENSION}/run/mpilinux8.pnm > \
           /opt/NONMEM/nm${NONMEM_MAJOR_VERSION}${NONMEM_MINOR_VERSION}${GFEXTENSION}/run/mpilinux_$NMNODES.pnm ; \
       done \
    && cd / \
    && rm -r /mnt/* \
    && (cd /opt/NONMEM/nm${NONMEM_MAJOR_VERSION}${NONMEM_MINOR_VERSION}${GFEXTENSION}/ && \
        rm -rf \
            examples/ \
            guides/ \
            help/ \
            html/ \
            *.pdf \
            *.txt \
            *.zip \
            install* \
            nonmem.lic \
            SETUP* \
            unzip.SunOS \
            unzip.exe \
            mpi/mpi_lini \
            mpi/mpi_wing \
            mpi/mpi_wini \
            run/*.bat \
            run/*.EXE \
            run/*.LNK \
            run/CONTROL* \
            run/DATA* \
            run/REPORT* \
            run/fpiwin* \
            run/mpiwin* \
            run/FCON \
            run/FDATA \
            run/FREPORT \
            run/FSIZES \
            run/FSTREAM \
            run/FSUBS \
            run/INTER \
            run/computername.exe \
            run/garbage.out \
            run/gfortran.txt \
            run/nmhelp.exe \
            run/psexec.exe \
            runfiles/GAWK.EXE \
            runfiles/GREP.EXE \
            runfiles/computername.exe \
            runfiles/fpiwin* \
            runfiles/mpiwin* \
            runfiles/nmhelp.exe \
            runfiles/psexec.exe \
            util/*.bat \
            util/*~ \
            util/CONTROL* \
            util/F* \
            util/DATA3 \
            util/ERROR1 \
            util/INTER \
            util/finish_Darwin* \
            util/finish_Linux_f95 \
            util/finish_Linux_g95 \
            util/finish_SunOS*)

RUN cd / \
    && mkdir -p /opt/NONMEM \
    && ln -s /opt/NONMEM/nm${NONMEM_MAJOR_VERSION}${NONMEM_MINOR_VERSION}${GFEXTENSION} /opt/NONMEM/nm_current \
    && ln -s /opt/NONMEM/nm_current/util/nmfe${NONMEM_MAJOR_VERSION}${NONMEM_MINOR_VERSION} \
             /opt/NONMEM/nm_current/util/nmfe

## Run the NMQual version of nmfe
CMD ["/opt/NONMEM/nm_current/util/nmfe"]
