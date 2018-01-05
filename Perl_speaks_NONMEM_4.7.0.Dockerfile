# Dockerfile to build Perl-speaks-NONMEM version 4.7.0

# Build with the following command:
# docker build \
#  -t humanpredictions/psn:4.7.0-1 \
#  -t humanpredictions/psn:latest \
#  -f Perl_speaks_NONMEM_4.7.0.Dockerfile .

# Start from the NMQual installation
FROM humanpredictions/nmqual:latest

# Dockerfile Maintainer
MAINTAINER William Denney <wdenney@humanpredictions.com>

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
       libyaml-tiny-perl \
       expect \
    && rm -rf /var/lib/apt/lists/ \
              /var/cache/apt/archives/ \
              /usr/share/doc/ \
              /usr/share/man/ \
              /usr/share/locale/ \
              /etc/apt/sources.list.d/multi.list

## Install and test PsN using nmqual
ENV PSN_VERSION_MAJOR=4
ENV PSN_VERSION_MINOR=7
ENV PSN_VERSION_PATCH=0
ENV PSN_VERSION=${PSN_VERSION_MAJOR}.${PSN_VERSION_MINOR}.${PSN_VERSION_PATCH}
ENV PSN_VERSION_UNDERSCORE=${PSN_VERSION_MAJOR}_${PSN_VERSION_MINOR}_${PSN_VERSION_PATCH}
ARG PSNURL=https://github.com/UUPharmacometrics/PsN/releases/download/${PSN_VERSION}/PsN-${PSN_VERSION}.tar.gz
ARG NMTHREADS=4

## The echo command provides inputs to setup.pl

RUN cd /mnt \
    && wget --no-show-progress --no-check-certificate -O psn.tar.gz ${PSNURL} \
    && tar zxf psn.tar.gz \
    && cd PsN-Source \
    && expect -c "set timeout { 2 exit }; \
       spawn perl setup.pl; \
       expect -ex \"PsN Utilities installation directory \[/usr/local/bin\]:\"; \
       send \"/opt/PsN/${PSN_VERSION}/bin\r\"; \
       expect -ex \"does not exist. Would you like to create it?\[y/n\]\"; \
       send \"y\r\"; \
       expect -ex \"Path to perl binary used to run Utilities \[/usr/bin/perl\]:\"; \
       send \"/usr/bin/perl\r\"; \
       expect -ex \"PsN Core and Toolkit installation directory \[/usr/local/share/perl\"; \
       send \"/opt/PsN/${PSN_VERSION}\r\"; \
       expect -ex \"Would you like this script to check Perl modules \[y/n\]?\"; \
       send \"y\r\"; \
       expect -ex \"Continue installing PsN (installing is possible even if modules are missing)\[y/n\]?\"; \
       send \"y\r\"; \
       expect -ex \"Would you like to copy the PsN documentation to a file system location of your choice?\"; \
       send \"n\r\"; \
       expect -ex \"Would you like to install the PsN test library?\"; \
       send \"y\r\"; \
       expect -ex \"PsN test library installation directory \[/usr/local/share/perl/\"; \
       send \"/opt/PsN/${PSN_VERSION}/test\r\"; \
       expect -ex \"Would you like help to create a configuration file?\"; \
       send \"y\r\"; \
       expect -ex \"Enter the *complete* path of the NM-installation directory:\"; \
       send \"/opt/NONMEM/nm_current/\r\"; \
       expect -ex \"Would you like to add another one\"; \
       send \"n\r\"; \
       expect -ex \"or press ENTER to use the name\"; \
       send \"nm_current\r\"; \
       expect -ex \"installation program.\"; \
       send \"\r\";" \
    && mv /opt/PsN/${PSN_VERSION}/PsN_${PSN_VERSION_UNDERSCORE}/psn.conf /mnt/psn.conf \
    && cat /mnt/psn.conf | \
           sed 's/nmfe=1/nmqual=1/;s/threads=5/threads='$NMTHREADS'/' > \
           /opt/PsN/${PSN_VERSION}/PsN_${PSN_VERSION_UNDERSCORE}/psn.conf \
    && PSN_NONMEM_VERSION=$(echo $NONMEM_VERSION | sed 's/\.[0-9]$//g') \
    && MPICOUNT=$(echo $(for MPINAME in /opt/NONMEM/nm_current/run/mpilinux_[0-9]*.pnm; do echo $(basename $MPINAME | sed 's/[^0-9]*//g'); done) | sort -n) \
    && for PARACOUNT in $MPICOUNT ; do \
           printf "parallel${PARACOUNT}=/opt/NONMEM/nm_current,${PSN_NONMEM_VERSION}\n" >> \
                /opt/PsN/${PSN_VERSION}/PsN_${PSN_VERSION_UNDERSCORE}/psn.conf ; \
       done \
    && printf "\n\n" >> \
            /opt/PsN/${PSN_VERSION}/PsN_${PSN_VERSION_UNDERSCORE}/psn.conf \
    && for PARACOUNT in $MPICOUNT ; do \
               printf "[default_options_parallel${PARACOUNT}]\nparafile=/opt/NONMEM/nm_current/run/mpilinux_${PARACOUNT}.pnm\n" >> \
                    /opt/PsN/${PSN_VERSION}/PsN_${PSN_VERSION_UNDERSCORE}/psn.conf ; \
        done \
    && cd /opt/PsN/${PSN_VERSION}/test/PsN_test_${PSN_VERSION_UNDERSCORE} \
    #&& prove -r unit \
    && prove -r system \
    && rm -r /opt/PsN/${PSN_VERSION}/test \
    && rm -rf mnt/*

ENV PATH /opt/PsN/${PSN_VERSION}/bin:$PATH

## Run execute to run a NONMEM model
CMD ["/opt/PsN/${PSN_VERSION}/bin/execute"]
