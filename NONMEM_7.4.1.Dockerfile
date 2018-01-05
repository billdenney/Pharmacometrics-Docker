# Dockerfile to build NONMEM 7.4.1 with MPI

# Build with the following command:
# docker build \
#  --build-arg NONMEMZIPPASS=[your password] \
#  -t humanpredictions/nonmem:7.4.1-gfortran-1 \
#  -t humanpredictions/nonmem:latest \
#  -f NONMEM_7.4.1.Dockerfile .

# Installation can be sped up for multiple installations (like
# nmqual, NONMEM, and PsN) by pre-downloading required zip
# files and then serving them from a local directory:
#
# wget https://nonmem.iconplc.com/nonmem741/NONMEM7.4.1.zip
# wget https://bitbucket.org/metrumrg/nmqual/downloads/nmqual-8.3.3.zip
# python -m SimpleHTTPServer
#
# Then in a separate terminal, give your local server for the
# NONMEMURL and NMQUALURL build arguments:
# docker build \
#  --build-arg NONMEMZIPPASS=[your password] \
#  --build-arg NONMEMURL=http://example.com/NONMEM7.4.1.zip \
#  -t humanpredictions/nonmem:7.4.1-gfortran-1 \
#  -t humanpredictions/nonmem:latest \
#  -f NONMEM_7.4.1.Dockerfile .

# Set the base image to a long-term Ubuntu release
FROM ubuntu:16.04

# Dockerfile Maintainer
MAINTAINER William Denney <wdenney@humanpredictions.com>

# Install gfortran, wget, and unzip (then clean up the image
# as much as possible)
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
ARG NONMEM_MINOR_VERSION=4
ARG NONMEM_PATCH_VERSION=1
ENV NONMEM_VERSION_NO_DOTS=${NONMEM_MAJOR_VERSION}${NONMEM_MINOR_VERSION}${NONMEM_PATCH_VERSION}
ENV NONMEM_VERSION=${NONMEM_MAJOR_VERSION}.${NONMEM_MINOR_VERSION}.${NONMEM_PATCH_VERSION}
ARG NONMEMURL=https://nonmem.iconplc.com/nonmem${NONMEM_VERSION_NO_DOTS}/NONMEM${NONMEM_VERSION}.zip
ARG NONMEMZIPPASS


## Copy the current license file into the image
COPY nonmem.lic /opt/NONMEM/nm${NONMEM_VERSION_NO_DOTS}/license/nonmem.lic

## Install NONMEM and then clean out unnecessary files to shrink
## the image
RUN cd /tmp \
    && wget -nv --no-check-certificate ${NONMEMURL} \
    && unzip -P ${NONMEMZIPPASS} NONMEM${NONMEM_VERSION}.zip \
    && cd /tmp/nm${NONMEM_VERSION_NO_DOTS}CD \
    && bash SETUP${NONMEM_MAJOR_VERSION}${NONMEM_MINOR_VERSION} /tmp/nm${NONMEM_VERSION_NO_DOTS}CD \
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
    && rm -r /tmp/* \
    && rm /opt/nm${NONMEM_VERSION_NO_DOTS}/mpi/mpi_ling/libmpich.a \
    && ln -s /usr/lib/mpich/lib/libmpich.a /opt/nm${NONMEM_VERSION_NO_DOTS}/mpi/mpi_ling/libmpich.a \
    && (cd /opt/nm${NONMEM_VERSION_NO_DOTS} && \
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
    && ln -s /opt/nm${NONMEM_VERSION_NO_DOTS} /opt/NONMEM/nm_current \
    && ln -s /opt/NONMEM/nm_current/run/nmfe${NONMEM_MAJOR_VERSION}${NONMEM_MINOR_VERSION} \
             /opt/NONMEM/nm_current/run/nmfe

# Update the NONMEM license file if it is available in the /license
# directory (/license can be mounted from the host system with the
# -v option to docker)
COPY scripts/CopyFileAndRun.sh /opt/CopyFileAndRun.sh
ENTRYPOINT ["/opt/CopyFileAndRun.sh", "/license/nonmem.lic", "/opt/NONMEM/nm_current/license/nonmem.lic"]
CMD ["/opt/NONMEM/nm_current/run/nmfe"]
