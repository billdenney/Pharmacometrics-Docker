# Dockerfile to build NONMEM 7.3.0 with MPI

# Build with the following command:
# docker build \
#  --build-arg NONMEMZIPPASS=[your password] \
#  -t humanpredictions/nonmem:7.3.0-gfortran-2 \
#  -t humanpredictions/nonmem:latest \
#  -f NONMEM_7.3.0.Dockerfile .

# Installation can be sped up for multiple installations (like
# nmqual, NONMEM, and PsN) by pre-downloading required zip
# files and then serving them from a local directory:
#
# wget https://nonmem.iconplc.com/nonmem730/NONMEM7.3.0.zip
# wget https://bitbucket.org/metrumrg/nmqual/downloads/nmqual-8.3.3.zip
# python -m SimpleHTTPServer
#
# Then in a separate terminal, give your local server for the
# NONMEMURL and NMQUALURL build arguments:
# docker build \
#  --build-arg NONMEMZIPPASS=[your password] \
#  --build-arg NONMEMURL=http://example.com/NONMEM7.3.0.zip \
#  -t humanpredictions/nonmem:7.3.0 \
#  -t humanpredictions/nonmem:latest \
#  -f NONMEM_7.3.0.Dockerfile .

# Set the base image to a long-term Ubuntu release
FROM ubuntu:16.04

# Dockerfile Maintainer
MAINTAINER William Denney <wdenney@humanpredictions.com>

ARG NONMEMURL=https://nonmem.iconplc.com/nonmem730/NONMEM7.3.0.zip
ARG NONMEMZIPPASS

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

## Copy the current license file into the image
COPY nonmem.lic /opt/nm730/license/nonmem.lic

## Install NONMEM and then clean out unnecessary files to shrink
## the image
RUN cd /tmp \
    && wget --no-check-certificate ${NONMEMURL} \
    && unzip -P ${NONMEMZIPPASS} NONMEM7.3.0.zip \
    && cd /tmp/nm730CD \
    && bash SETUP73 /tmp/nm730CD \
       	            /opt/nm730 \
                    gfortran \
                    y \
                    /usr/bin/ar \
                    same \
                    rec \
                    q \
                    unzip \
                    nonmem73e.zip \
                    nonmem73r.zip \
    && rm -r /tmp/* \
    && rm /opt/nm730/mpi/mpi_ling/libmpich.a \
    && ln -s /usr/lib/mpich/lib/libmpich.a /opt/nm730/mpi/mpi_ling/libmpich.a \
    && (cd /opt/nm730 && \
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

CMD ["/opt/nm730/run/nmfe73"]
