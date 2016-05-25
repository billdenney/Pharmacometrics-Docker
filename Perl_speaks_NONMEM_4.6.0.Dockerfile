# Dockerfile to build Perl-speaks-NONMEM version 4.6.0

# Build with the following command:
# docker build \
#  -t humanpredictions/psn:4.6.0 \
#  -t humanpredictions/psn:latest \
#  -f Perl_speaks_NONMEM_4.6.0.Dockerfile .

# Start from the NMQual installation
FROM humanpredictions/nmqual:latest

# Dockerfile Maintainer
MAINTAINER William Denney

ARG PSNURL=https://sourceforge.net/projects/psn/files/PsN-4.6.0.tar.gz/download?use_mirror=superb-sea2
ARG NMTHREADS=4

# Install perl libraries required for PsN (then clean up
# the image as much as possible).  libstorable-perl is automatically
# installed with perl.  multiverse repository is required for
# libmath-random-perl.
RUN echo "deb http://archive.ubuntu.com/ubuntu/ xenial multiverse" > \
       /etc/apt/sources.list.d/multi.list \
    && apt-get update \
    && apt-get install --yes --no-install-recommends \
       libmath-random-perl \
       libstatistics-distributions-perl \
       libarchive-zip-perl \
       libfile-copy-recursive-perl \
       libmoose-perl \
       libmoosex-params-validate-perl \
       libtest-exception-perl \
    && rm -rf /var/lib/apt/lists/ \
              /var/cache/apt/archives/ \
              /usr/share/doc/ \
              /usr/share/man/ \
              /usr/share/locale/ \
              /etc/apt/sources.list.d/multi.list

## Install and test PsN using nmqual

## The echo command provides inputs to setup.pl

RUN mkdir -p /mnt \
    && cd /mnt \
    && wget --no-show-progress --no-check-certificate -O psn.tar.gz ${PSNURL} \
    && tar zxf psn.tar.gz \
    && cd PsN-Source \
    && sed 's/return($input)/print $input."\n";return($input);/' setup.pl > setup-updated.pl \
    && echo "/opt/PsN/4.6.0/bin\n\
y\n\
/usr/bin/perl\n\
/opt/PsN/4.6.0\n\
y\n\
y\n\
n\n\
y\n\
/opt/PsN/4.6.0/test\n\
y\n\
n\n\
nm73gf\n\
\n\
" | perl setup-updated.pl \
    && mv /opt/PsN/4.6.0/PsN_4_6_0/psn.conf /mnt/psn.conf \
    && sed 's/nmfe=1/nmqual=1/;s/threads=5/threads='$NMTHREADS'/' \
         /mnt/psn.conf > /opt/PsN/4.6.0/PsN_4_6_0/psn.conf \
    && cd /opt/PsN/4.6.0/test/PsN_test_4_6_0 \
    && prove -r unit \
    && prove -r system \
    && rm -rf mnt/*

ENV PATH /opt/PsN/4.6.0/bin:$PATH

## Run execute to run a NONMEM model
CMD ["/opt/PsN/4.6.0/bin/execute"]
