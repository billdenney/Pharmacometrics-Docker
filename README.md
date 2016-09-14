# Pharmacometrics-Docker

Dockerfiles for pharmacometrics-related software: NONMEM, NMQual, and
Perl-speaks-NONMEM

Each of these files is intended to help improve reproducible research
by enabling the use of Docker images to keep all requirements for
execution in a single container.

## NONMEM 7.3.0

A dockerfile to build a gfortran-run NONMEM 7.3.0 installation.  It
will require a NONMEM license file (in the same directory nonmem.lic).
If you will be installing both NONMEM and NMQual, see the instructions
in the comments of the file for how to speed up the run (and minimize
download time).

http://www.iconplc.com/innovation/solutions/nonmem/

### Installation

* Copy your nonmem license file (named `nonmen.lic` to the same
  directory as the Dockerfile.
* Have your NONMEM zip file password handy
* See the instructions in the top of the Dockerfile for the command
  to run.

## NMQual 8.3.3

A dockerfile to build a gfortran-run NONMEM 7.3.0 with NMQual 8.3.3.
It will require a NONMEM license file (in the same directory
nonmem.lic).  If you will be installing both NONMEM and NMQual, see
the instructions in the comments of the file for how to speed up the
run (and minimize download time).

https://bitbucket.org/metrumrg/nmqual/

### Installation

* Copy your nonmem license file (named `nonmen.lic` to the same
  directory as the Dockerfile.
* Have your NONMEM zip file password handy
* See the instructions in the top of the Dockerfile for the command
  to run.

## Perl-speaks-NONMEM

A dockerfile to build a Perl-speaks-NONMEM (PsN) 4.6.0 installation on top
of the NMQual docker image.  You must build the NMQual image first to
build the PsN image.

http://psn.sourceforge.net/

### Installation

* Install the NMQual image above (this image starts from that image)
* See the instructions in the top of the Dockerfile for the command
  to run.

## PMx-Rocker

A dockerfile to build R 3.3.0 with added packages from a .csv file.
This is based on the Rocker image.

https://github.com/rocker-org/rocker
https://cran.r-project.org/

### Installation

* Optionally modify the list of packages to install (see [PMxrocker/packages.csv](PMx_rocker/packages.csv))
* See the instructions in the top of the Dockerfile for the command
  to run.
