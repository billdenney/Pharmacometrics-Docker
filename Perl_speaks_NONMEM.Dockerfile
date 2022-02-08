# Dockerfile to build Perl-speaks-NONMEM version 5.2.6

# Build with the following command:
# docker build \
#  -t humanpredictions/psn:5.2.6-1 \
#  -t humanpredictions/psn:latest \
#  -f Perl_speaks_NONMEM.Dockerfile .

# Start from the NMQual installation
FROM humanpredictions/nonmem:latest

# Dockerfile Maintainer
MAINTAINER William Denney <wdenney@humanpredictions.com>

# First, install perl libraries required for PsN, then install R and
# required libraries, then install python (then clean up the image as
# much as possible).
RUN ln -fs /usr/share/zoneinfo/UCT /etc/localtime \
    && apt-get update \
    && apt-get install --yes --no-install-recommends \
       libmath-random-perl \
       libmoose-perl \
       libmoosex-params-validate-perl \
       libstatistics-distributions-perl \
       libarchive-zip-perl \
       libfile-copy-recursive-perl \
       libtest-exception-perl \
       libyaml-libyaml-perl \
       libinline-perl \
       expect \
       \
       r-base pandoc \
       libpq-dev libcairo2-dev libssl-dev libcurl4-openssl-dev \
       libmariadb-dev libgmp-dev libmpfr-dev libxml2-dev \
       libudunits2-dev libblas-dev liblapack-dev libmagick++-dev \
       make \
       \
       python3 python3-venv python3-dev \
    && rm -rf /var/lib/apt/lists/ \
              /var/cache/apt/archives/ \
              /usr/share/doc/ \
              /usr/share/man/ \
              /usr/share/locale/ \
              /etc/apt/sources.list.d/multi.list

## Install and test PsN
ENV PSN_VERSION_MAJOR=5
ENV PSN_VERSION_MINOR=2
ENV PSN_VERSION_PATCH=6
ENV PSN_VERSION=${PSN_VERSION_MAJOR}.${PSN_VERSION_MINOR}.${PSN_VERSION_PATCH}
ENV PSN_VERSION_UNDERSCORE=${PSN_VERSION_MAJOR}_${PSN_VERSION_MINOR}_${PSN_VERSION_PATCH}
ARG PSNURL=https://github.com/UUPharmacometrics/PsN/releases/download/v${PSN_VERSION}/PsN-${PSN_VERSION}.tar.gz
ARG NMTHREADS=4

## For PsN Installation
ENV R_LIBS_SITE=/opt/PsN/${PSN_VERSION}/PsN_${PSN_VERSION_UNDERSCORE}/Rlib
ENV R_LIBS_USER=${R_LIBS_SITE}

## The echo command provides inputs to setup.pl
## A 120 second timeout is used for python installation, and it may
## take longer on some systems.

RUN cd /mnt \
    && wget --no-show-progress --no-check-certificate -O psn.tar.gz ${PSNURL} \
    && tar zxf psn.tar.gz \
    && cd PsN-Source \
    && mkdir -p ${R_LIBS_SITE} \
    && Rscript -e "install.packages(c('renv', 'remotes'), lib='${R_LIBS_SITE}', repos='https://cloud.r-project.org')" \
    && Rscript -e ".libPaths(c('${R_LIBS_SITE}', .libPaths())); options(renv.consent=TRUE); renv::settings\$use.cache(FALSE); renv::restore(library='${R_LIBS_SITE}', lockfile='PsNR/renv.lock')" \
    && expect -c "set timeout { 120 exit }; \
       spawn perl setup.pl; \
       expect -ex \"PsN Utilities installation directory \[/usr/local/bin\]:\"; \
       send \"/opt/PsN/${PSN_VERSION}/bin\r\"; \
       expect -ex \"does not exist. Would you like to create it?\[y/n\]\"; \
       send \"y\r\"; \
       expect -ex \"Path to perl binary used to run Utilities \[/usr/bin/perl\]:\"; \
       send \"/usr/bin/perl\r\"; \
       expect -ex \"PsN Core and Toolkit installation directory \[\"; \
       send \"/opt/PsN/${PSN_VERSION}\r\"; \
       expect -ex \"Would you like this script to check Perl modules \[y/n\]?\"; \
       send \"y\r\"; \
       expect -ex \"Continue installing PsN (installing is possible even if modules are missing)\[y/n\]?\"; \
       send \"y\r\"; \
       expect -ex \"Would you like to continue anyway\"; \
       send \"y\r\"; \
       expect -ex \"Would you like to install the PsNR R package\"; \
       send \"y\r\"; \
       expect -ex \"install the pharmpy python package\"; \
       send \"y\r\"; \
       expect -ex \"Would you like to install the PsN test library?\"; \
       send \"y\r\"; \
       expect -ex \"PsN test library installation directory \[\"; \
       send \"/opt/PsN/${PSN_VERSION}/test\r\"; \
       expect -ex \"Would you like help to create a configuration file?\"; \
       send \"y\r\"; \
       expect -ex \"Would you like to add another one\"; \
       send \"n\r\"; \
       expect -ex \"or press ENTER to use the name\"; \
       send \"nm_current\r\"; \
       expect -ex \"installation program.\"; \
       send \"\r\";" \
    && mv /opt/PsN/${PSN_VERSION}/PsN_${PSN_VERSION_UNDERSCORE}/psn.conf /mnt/psn.conf \
    && cat /mnt/psn.conf | \
           sed 's/threads=5/threads='$NMTHREADS'/' > \
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
    && prove -r unit \
    && prove -r system \
    && rm -r /opt/PsN/${PSN_VERSION}/test \
    && rm -rf mnt/*

RUN ln -s /opt/PsN/${PSN_VERSION} /opt/PsN/current

ENV PATH /opt/PsN/${PSN_VERSION}/bin:$PATH

## Run execute to run a NONMEM model
CMD ["/opt/PsN/current/bin/execute"]
