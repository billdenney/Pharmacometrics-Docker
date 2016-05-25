# Dockerfile to build NONMEM 7.3.0

# Set the base image to a long-term Ubuntu release
FROM ubuntu:16.04

# Dockerfile Maintainer
MAINTAINER William Denney

ARG NONMEMURL=https://nonmem.iconplc.com/nonmem730/NONMEM7.3.0.zip
ARG NONMEMZIPPASS

# Install gfortran, wget, and unzip (then clean up the image
# as much as possible)
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
       gfortran \
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
    && rm -rf /tmp \
    && (cd /opt/nm730 && \
        rm -r \
	  examples/ \
	  guides/ \
	  help/ \
	  html/ \
	  *.pdf \
	  *.txt \
          *.zip \
	  SETUP* \
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
	  run/garbage.out \
	  run/gfortran.txt \
	  util/*.LNK \
	  util/*.bat \
	  util/*.exe \
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
