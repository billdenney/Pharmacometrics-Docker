# Dockerfile to build NMQual 8.3.3 with NONMEM 7.3.0 and MPI

# Build with the following command:
# docker build \
#  --build-arg NONMEMZIPPASS=[your password] \
#  -t humanpredictions/nmqual:7.3.0_8.3.3-gfortran-2 \
#  -t humanpredictions/nmqual:latest \
#  -f NONMEM_7.3.0-nmqual_8.3.3.Dockerfile .

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
#  --build-arg NMQUALURL=http://example.com/nmqual-8.3.3.zip \
#  -t humanpredictions/nmqual:7.3.0_8.3.3 \
#  -t humanpredictions/nmqual:latest \
#  -f NONMEM_7.3.0-nmqual_8.3.3.Dockerfile .
#
# Other build-arg values are available to set the number of nodes for
# MPI to use for parallel operation by default (NMNODES) and to set
# the level of NMQual testing (NMQUALTESTLEVEL).  See below for
# details.

# Set the base image to a long-term Ubuntu release
FROM ubuntu:16.04

# Dockerfile Maintainer
MAINTAINER William Denney <wdenney@humanpredictions.com>

ARG NONMEMURL=https://nonmem.iconplc.com/nonmem730/NONMEM7.3.0.zip
ARG NONMEMZIPPASS
# The number of nodes to use for parallel execution
ARG NMNODES=4
ARG NMQUALURL=https://bitbucket.org/metrumrg/nmqual/downloads/nmqual-8.3.3.zip
# This is the level of testing to run: "qualify" for full testing,
# "regress" for a reduced testing set, or "psntest" to test PsN
# installation.
ARG NMQUALTESTLEVEL=qualify

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

## Copy the current NONMEM license file into the image
COPY nonmem.lic /mnt

## Install and test NONMEM using nmqual

## sed line comments:
## 
## Give the correct location for mpich library.
## Ensure that parent directories are created with mkdir.
##
## Note sed's allows for any delimiter to be used (not just
## the most common '/').  I am using a space here because there
## are no spaces in the filenames.

## autolog qualify line comments:
## Some compiler warnings are expected in the qualify step:
## http://www.cognigencorp.com/nonmem/current/2015-February/5439.html

RUN cd /mnt \
    && echo "Get and uncompress the files for installation" \
    && wget --no-show-progress --no-check-certificate ${NONMEMURL} \
    && unzip -P ${NONMEMZIPPASS} NONMEM7.3.0.zip \
    && wget --no-show-progress --no-check-certificate ${NMQUALURL} \
    && unzip nmqual-8.3.3.zip \
    && echo "Update the NMQual configuration for this Docker installation" \
    && sed 's /usr/local/mpich3gf/lib/libmpich.a /usr/lib/mpich/lib/libmpich.a ;s/mkdir/mkdir -p/;s/cp mpicha/ln -sf mpicha/' \
         nmqual-8.3.3/nix/nm73gf.xml > nmqual-8.3.3/nix/nm73gf_docker.xml \
    && echo "Install NONMEM and NMQual" \
    && perl nmqual-8.3.3/autolog.pl nmqual-8.3.3/nix/nm73gf_docker.xml install \
    && perl nmqual-8.3.3/autolog.pl nmqual-8.3.3/nix/nm73gf_docker.xml $NMQUALTESTLEVEL \
    && echo $NMQUALTESTLEVEL > /opt/NONMEM/nm73gf/nmqual/testlevel \
    && echo "Update the default number of nodes for parallel NONMEM in the mpilinux.pnm file" \
    && sed 's/\[nodes\]=8/\[nodes\]='$NMNODES'/' /opt/NONMEM/nm73gf/run/mpilinux8.pnm > /opt/NONMEM/nm73gf/run/mpilinux.pnm \
    && rm -r /mnt/* \
    && (cd /opt/NONMEM/nm73gf/ && \
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

## Run the NMQual version of nmfe73
CMD ["/opt/NONMEM/nm73gf/util/nmfe73"]
