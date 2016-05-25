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

## NMQual 8.3.3

A dockerfile to build a gfortran-run NONMEM 7.3.0 with NMQual 8.3.3.
It will require a NONMEM license file (in the same directory
nonmem.lic).  If you will be installing both NONMEM and NMQual, see
the instructions in the comments of the file for how to speed up the
run (and minimize download time).

https://bitbucket.org/metrumrg/nmqual/

## Perl-speaks-NONMEM

A dockerfile to build a Perl-speaks-NONMEM (PsN) 4.6.0 installation on top
of the NMQual docker image.  You must build the NMQual image first to
build the PsN image.

http://psn.sourceforge.net/
