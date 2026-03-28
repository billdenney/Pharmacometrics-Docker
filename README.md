# Pharmacometrics-Docker

Dockerfiles for pharmacometrics-related software: NONMEM and
Perl-speaks-NONMEM

Each of these files is intended to help improve reproducible research
by enabling the use of Docker images to keep all requirements for
execution in a single container.

## NONMEM

A dockerfile to build a gfortran-run NONMEM installation.  It will
require a NONMEM license file (in the same directory, named
`nonmem.lic`).  See the instructions in the comments of the file for
how to speed up the run (and minimize download time).

http://www.iconplc.com/innovation/solutions/nonmem/

### Compatibility Matrix

All combinations were empirically tested by building each image and
recording success or failure.  Results below reflect actual build
outcomes, which differ from prior documentation in several cases.

#### x86-64 (linux/amd64)

`yes` = image builds successfully; `no` = build fails

| NONMEM | 14.04 | 16.04 | 18.04 | 20.04 | 22.04 | 24.04 |
|--------|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
| 7.2.0  | yes   | yes   | yes   | yes   | yes   | yes   |
| 7.3.0  | yes   | yes   | yes   | yes   | yes   | yes   |
| 7.4.1  | yes   | yes   | yes   | yes   | no    | no    |
| 7.4.2  | yes   | yes   | yes   | yes   | no    | no    |
| 7.4.3  | yes   | yes   | yes   | yes   | no    | no    |
| 7.4.4  | yes   | yes   | no*   | yes   | no    | no    |
| 7.5.0  | yes   | yes   | yes   | yes   | no    | no    |
| 7.5.1  | yes   | yes   | yes   | yes   | yes   | yes   |
| 7.6.0  | yes   | yes   | yes   | yes   | yes   | no    |

\* 7.4.4 on Ubuntu 18.04 failed during testing; this may be a transient
failure as the surrounding versions (14.04, 16.04, 20.04) all succeed.

**Notable findings vs. prior documentation:**

- NONMEM 7.2.0 and 7.3.0 build successfully on *all* Ubuntu LTS
  versions including 22.04 and 24.04.  The prior claim that NONMEM
  older than 7.5.1 fails on Ubuntu > 20.04 applies to 7.4.x–7.5.0
  specifically, not to 7.2.x or 7.3.x.
- NONMEM 7.6.0 fails on Ubuntu 24.04 (amd64) despite succeeding on
  22.04.

#### ARM64 (linux/arm64) — Raspberry Pi 4/5 and AWS Graviton2/3/4

The same `linux/arm64` Docker image runs on both Raspberry Pi 4/5 and
AWS Graviton2/3/4; they share the same 64-bit ARM instruction set and
no separate image is needed for Graviton.

NONMEM versions older than 7.5.1 are not attempted for ARM64 because
their setup scripts contain x86-specific assumptions.  Ubuntu 14.04
and 16.04 are also skipped because ARM toolchain support was too
immature in those releases.

| NONMEM | 18.04 | 20.04 | 22.04 | 24.04 |
|--------|:-----:|:-----:|:-----:|:-----:|
| 7.5.1  | no    | no    | yes   | yes   |
| 7.6.0  | no    | no    | yes   | yes   |

ARM64 builds require Ubuntu 22.04 or later; 18.04 and 20.04 fail,
likely due to gfortran or toolchain differences in the older ARM64
userspace.

Raspberry Pi 3 and older (32-bit ARM, linux/arm/v7) are not supported.

### Building the Full Matrix

Use `build_matrix.sh` to build all compatible combinations in parallel
(up to 16 at a time by default):

    # amd64 only (40 combinations)
    ./build_matrix.sh

    # amd64 + arm64 (48 combinations; requires buildx + QEMU — see script header)
    ./build_matrix.sh --arm64

    # Control parallelism
    ./build_matrix.sh --jobs 8

Prerequisites: copy `nonmem_passwords.conf.example` to
`nonmem_passwords.conf` (gitignored) and adjust paths/passwords.
Results are written to `build_matrix.log`.

### Installation

* Copy your nonmem license file (named `nonmen.lic` to the same
  directory as the Dockerfile.
* Have your NONMEM zip file password handy
* See the instructions in the top of the Dockerfile for the command
  to run.
* For NONMEM, automatic download from Icon may be unreliable
  (https://github.com/billdenney/Pharmacometrics-Docker/issues/2).
  Manual download and serving the file from a local webserver is
  recommended.  (See the top of the Dockerfile for instructions.)

### Running

It is recommended to run NONMEM via Perl-speaks-NONMEM (below).  To
run NONMEM directly, you can run the following command:

    docker run --rm --user=$(id -u):$(id -g) -v $(pwd):/data -w /data humanpredictions/nonmem /opt/NONMEM/nm_current/run/nmfe CONTROL.mod CONTROL.res

### Updating Your License

To update your license file without requiring a rebuild of the Docker
image, you can mount a directory containing the license file in the
/license directory of your image (note the first -v argument):

    docker run --rm --user=$(id -u):$(id -g) -v /opt/NONMEM/license:/opt/NONMEM/nm_current/license -v $(pwd):/data -w /data humanpredictions/nonmem /opt/NONMEM/nm_current/run/nmfe CONTROL.mod CONTROL.res

## Perl-speaks-NONMEM

A dockerfile to build a Perl-speaks-NONMEM (PsN) installation on top
of the NONMEM docker image.  You must build the NONMEM image first to
build the PsN image.

https://github.com/UUPharmacometrics/PsN/

### Installation

* Install the NONMEM image above (this image starts from that image)
* See the instructions in the top of the Dockerfile for the command
  to run.

### Running

It is recommended to run NONMEM via the dockpsn script.  To run the
dockpsn command, set it up by copying it to a location in the path:

    cp scripts/dockpsn /usr/local/bin/dockpsn

Then you can use it by running it followed by the PsN command of
interest:

    dockpsn execute CONTROL.mod

To run PsN directly, you can use the following command (substitute
`execute` for the PsN command of interest):

    docker run --rm --user=$(id -u):$(id -g) -v $(pwd):/data -w /data humanpredictions/psn execute CONTROL.mod

### Updating Your License

If you use the `dockpsn` command, it will look for an updated license
in the `/opt/NONMEM/license` directory by default.  If none is found
there, it will run with the license used when the image was created.

To update your license file without requiring a rebuild of the Docker
image, you can mount a directory containing the license file in the
/license directory of your image (note the first -v argument):

    docker run --rm --user=$(id -u):$(id -g) -v /opt/NONMEM/license:/opt/NONMEM/nm_current/license -v $(pwd):/data -w /data humanpredictions/psn execute CONTROL.mod

That is automatically done with the `dockpsn` command.
