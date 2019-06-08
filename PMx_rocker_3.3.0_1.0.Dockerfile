## Emacs, make this -*- mode: sh; -*-

# Build with the following command:
# docker build \
#  -t humanpredictions/pmxrocker:3.3.0_1.0 \
#  -t humanpredictions/pmxrocker:latest \
#  -f PMx_rocker_3.3.0_1.0.Dockerfile .

# Typically run with the following command:
# docker run --rm -v "$(pwd)":/tmp -w /tmp \
#  humanpredictions/psn R CMD BATCH myrfile.R

FROM ubuntu:18.04

MAINTAINER William Denney

## Set a default user. Available via runtime flag `--user docker` Add
## user to 'staff' group, granting them write privileges to
## /usr/local/lib/R/site.library User should also have & own a home
## directory (for rstudio or linked volumes to work properly).
RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

RUN apt-get update \ 
    && apt-get install -y --no-install-recommends \
               ed \
	       locales \
	       wget \
	       ca-certificates \
    && rm -rf /var/lib/apt/lists/ \
          /var/cache/apt/archives/ \
          /usr/share/doc/ \
          /usr/share/man/

## Configure default locale, see
## https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV R_BASE_VERSION 3.3.0

## Now install R, littler, and external dependencies.  Then, create a
## link for littler in /usr/local/bin Also set a default CRAN repo,
## and make sure littler knows about it too.
RUN echo "deb http://cran.r-project.org/bin/linux/ubuntu xenial/" > /etc/apt/sources.list.d/cran.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
               littler \
               r-cran-littler \
               r-base=${R_BASE_VERSION}* \
               r-base-dev=${R_BASE_VERSION}* \
               r-recommended=${R_BASE_VERSION}* \
               aspell \
               aspell-en \
               default-jdk \
               default-jre \
               ghostscript \
               imagemagick \
	       libcairo-dev \
	       libcurl4-openssl-dev \
	       libssh2-1-dev \
	       libssl-dev \
	       libxml2-dev \
    && echo 'options(repos = c(CRAN = "https://cran.rstudio.com/"), download.file.method = "libcurl")' >> /etc/R/Rprofile.site \
    && echo 'source("/etc/R/Rprofile.site")' >> /etc/littler.r \
    && ln -s /usr/share/doc/littler/examples/install.r \
          /usr/local/bin/install.r \
    && ln -s /usr/share/doc/littler/examples/install2.r \
          /usr/local/bin/install2.r \
    && ln -s /usr/share/doc/littler/examples/installGithub.r \
          /usr/local/bin/installGithub.r \
    && ln -s /usr/share/doc/littler/examples/testInstalled.r \
          /usr/local/bin/testInstalled.r \
    && install.r docopt \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    && rm -rf /var/lib/apt/lists/* \
              /var/cache/apt/archives/ \
              /usr/share/doc/ \
              /usr/share/man/

## Install the locally requested package list
COPY PMx_rocker/packages.csv PMx_rocker/package_installer.R /tmp/
RUN cd /tmp \
    && Rscript package_installer.R \
    && rm -rf /tmp/*

CMD ["R"]
