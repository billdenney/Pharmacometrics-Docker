# Dockerfile to build NONMEM 7.5.1 with MPI

# Build with the following command:
# docker build \
#  --build-arg NONMEMZIPPASS=[your password] \
#  -t humanpredictions/nonmem:7.5.1-gfortran-1 \
#  -t humanpredictions/nonmem:latest \
#  -f NONMEM.Dockerfile .

# Installation can be sped up for multiple installations (like
# nmqual, NONMEM, and PsN) by pre-downloading required zip
# files and then serving them from a local directory:
#
# wget --auth-no-challenge https://nonmem.iconplc.com/nonmem751/NONMEM751.zip
# python3 -m http.server
#
# Then in a separate terminal, give your local server for the
# NONMEMURL and NMQUALURL build arguments:
# docker build \
#  --build-arg NONMEMZIPPASS=[your password] \
#  --build-arg NONMEMURL=http://example.com/NONMEM7.5.1.zip \
#  -t humanpredictions/nonmem:7.5.1-gfortran-1 \
#  -t humanpredictions/nonmem:latest \
#  -f NONMEM.Dockerfile .

# Set the base image to a long-term Ubuntu release
FROM ubuntu:22.04

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

ARG NONMEM_MAJOR_VERSION=7
ARG NONMEM_MINOR_VERSION=5
ARG NONMEM_PATCH_VERSION=1
ENV NONMEM_VERSION_NO_DOTS=${NONMEM_MAJOR_VERSION}${NONMEM_MINOR_VERSION}${NONMEM_PATCH_VERSION}
ENV NONMEM_VERSION=${NONMEM_MAJOR_VERSION}.${NONMEM_MINOR_VERSION}.${NONMEM_PATCH_VERSION}
ARG NONMEMURL=https://nonmem.iconplc.com/nonmem${NONMEM_VERSION_NO_DOTS}/NONMEM${NONMEM_VERSION_NO_DOTS}.zip
ARG NONMEMZIPPASS

## Copy the current license file into the image
COPY nonmem.lic /opt/NONMEM/nm${NONMEM_VERSION_NO_DOTS}/license/nonmem.lic

## Install NONMEM and then clean out unnecessary files to shrink
## the image

# the "if [ ! -d "/tmp/nm${NONMEM_VERSION_NO_DOTS}CD" ] ; then ln -s . nm${NONMEM_VERSION_NO_DOTS}CD ; fi"
# line is for NONMEM 7.2.0
RUN cd /tmp \
    && wget \
	 -nv --no-check-certificate --auth-no-challenge \
         -O /tmp/NONMEM.zip \
	 ${NONMEMURL} \
    && unzip -P ${NONMEMZIPPASS} NONMEM.zip \
    && ls /tmp \
    && if [ ! -d "/tmp/nm${NONMEM_VERSION_NO_DOTS}CD" ] ; then ln -s . nm${NONMEM_VERSION_NO_DOTS}CD ; fi \
    && cd /tmp/nm${NONMEM_VERSION_NO_DOTS}CD \
    && bash \
         SETUP${NONMEM_MAJOR_VERSION}${NONMEM_MINOR_VERSION} \
         /tmp/nm${NONMEM_VERSION_NO_DOTS}CD \
       	 /opt/NONMEM/nm${NONMEM_VERSION_NO_DOTS} \
         gfortran \
         y \
         /usr/bin/ar \
         same \
         rec \
         q \
         unzip \
         nonmem${NONMEM_MAJOR_VERSION}${NONMEM_MINOR_VERSION}e.zip \
         nonmem${NONMEM_MAJOR_VERSION}${NONMEM_MINOR_VERSION}r.zip \
    && ln -s /opt/NONMEM/nm${NONMEM_VERSION_NO_DOTS} /opt/NONMEM/nm_current \
    && ln -s /opt/NONMEM/nm_current/util/nmfe${NONMEM_MAJOR_VERSION}${NONMEM_MINOR_VERSION} \
             /opt/NONMEM/nm_current/util/nmfe \
    && rm -r /tmp/* \
    && rm -f /opt/NONMEM/nm_current/mpi/mpi_ling/libmpich.a \
    && ln -s \
        /usr/lib/x86_64-linux-gnu/libmpich.a \
	/opt/NONMEM/nm_current/mpi/mpi_ling/libmpich.a \
    && echo "Update the default number of nodes for parallel NONMEM in the mpilinux_XX.pnm file" \
    && for NMNODES in 2 4 6 8 10 12 14 16 18 20 22 24 28 32 48 64 128; do \
         sed 's/\[nodes\]=8/\[nodes\]='$NMNODES'/' \
           /opt/NONMEM/nm_current/run/mpilinux8.pnm > \
           /opt/NONMEM/nm_current/run/mpilinux_$NMNODES.pnm ; \
       done \
    && (cd /opt/NONMEM/nm_current && \
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

# Update the NONMEM license file if it is available in the /license
# directory (/opt/NONMEM/nm_current/license should be mounted from the
# host system with the -v option to docker)
CMD ["/opt/NONMEM/nm_current/util/nmfe"]
