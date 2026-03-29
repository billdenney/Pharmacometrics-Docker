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

All combinations were empirically tested by building each Docker image
and recording success or failure.  Image tags encode the exact NONMEM
version, Ubuntu base, gfortran version, and CPU architecture — every
cell in the tables below corresponds to a distinct image tag.

Tag format: `{NM_VERSION}-ubuntu{UBUNTU}-gfortran{GFC}-{arch}`
Example: `7.4.1-ubuntu22.04-gfortran9-amd64`

Legend: `yes` = image builds successfully · `no` = build fails ·
`—` = gfortran version not available in that Ubuntu's standard repos

#### x86-64 (linux/amd64)

##### NONMEM 7.2.0 and 7.3.0 — all gfortran versions succeed

| gfortran | 14.04 | 16.04 | 18.04 | 20.04 | 22.04 | 24.04 |
|:--------:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
| 4.4      | yes   | —     | —     | —     | —     | —     |
| 4.6      | yes   | —     | —     | —     | —     | —     |
| 4.7      | yes   | yes   | —     | —     | —     | —     |
| 4.8      | yes   | yes   | yes   | —     | —     | —     |
| 4.9      | —     | yes   | —     | —     | —     | —     |
| 5        | —     | yes   | yes   | —     | —     | —     |
| 6        | —     | —     | yes   | —     | —     | —     |
| 7        | —     | —     | yes   | yes   | —     | —     |
| 8        | —     | —     | yes   | yes   | —     | —     |
| 9        | —     | —     | —     | yes   | yes   | yes   |
| 10       | —     | —     | —     | yes   | yes   | yes   |
| 11       | —     | —     | —     | —     | yes   | yes   |
| 12       | —     | —     | —     | —     | yes   | yes   |
| 13       | —     | —     | —     | —     | —     | yes   |
| 14       | —     | —     | —     | —     | —     | yes   |

##### NONMEM 7.4.1, 7.4.2, 7.4.3, 7.4.4, and 7.5.0 — gfortran ≥ 10 fails

| gfortran | 14.04 | 16.04 | 18.04 | 20.04 | 22.04 | 24.04 |
|:--------:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
| 4.4      | yes   | —     | —     | —     | —     | —     |
| 4.6      | yes   | —     | —     | —     | —     | —     |
| 4.7      | yes   | yes   | —     | —     | —     | —     |
| 4.8      | yes   | yes   | yes   | —     | —     | —     |
| 4.9      | —     | yes   | —     | —     | —     | —     |
| 5        | —     | yes   | yes   | —     | —     | —     |
| 6        | —     | —     | yes   | —     | —     | —     |
| 7        | —     | —     | yes   | yes   | —     | —     |
| 8        | —     | —     | yes   | yes   | —     | —     |
| 9        | —     | —     | —     | yes   | yes   | yes   |
| 10       | —     | —     | —     | no¹   | no¹   | no¹   |
| 11       | —     | —     | —     | —     | no¹   | no¹   |
| 12       | —     | —     | —     | —     | no¹   | no¹   |
| 13       | —     | —     | —     | —     | —     | no¹   |
| 14       | —     | —     | —     | —     | —     | no¹   |

##### NONMEM 7.5.1 and 7.6.0 — gfortran 4.4 fails

| gfortran | 14.04 | 16.04 | 18.04 | 20.04 | 22.04 | 24.04 |
|:--------:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
| 4.4      | no²   | —     | —     | —     | —     | —     |
| 4.6      | yes   | —     | —     | —     | —     | —     |
| 4.7      | yes   | yes   | —     | —     | —     | —     |
| 4.8      | yes   | yes   | yes   | —     | —     | —     |
| 4.9      | —     | yes   | —     | —     | —     | —     |
| 5        | —     | yes   | yes   | —     | —     | —     |
| 6        | —     | —     | yes   | —     | —     | —     |
| 7        | —     | —     | yes   | yes   | —     | —     |
| 8        | —     | —     | yes   | yes   | —     | —     |
| 9        | —     | —     | —     | yes   | yes   | yes   |
| 10       | —     | —     | —     | yes   | yes   | yes   |
| 11       | —     | —     | —     | —     | yes   | yes   |
| 12       | —     | —     | —     | —     | yes   | yes   |
| 13       | —     | —     | —     | —     | —     | yes   |
| 14       | —     | —     | —     | —     | —     | yes   |

#### Failure footnotes

¹ **gfortran ≥ 10 + NONMEM 7.4.x / 7.5.0**: GCC 10 introduced stricter
enforcement of Fortran standard compliance.  The NONMEM 7.4.x and 7.5.0
Fortran source contains constructs that gfortran 9 (and earlier) accepted
but gfortran 10+ rejects as hard errors: rank mismatches between actual
arguments, INTEGER(8)/INTEGER(4) type mismatches, and index variables
redefined inside DO loops.  NONMEM 7.5.1 corrects these issues and
compiles cleanly with all gfortran versions.  Use gfortran 9 (e.g.,
`-ubuntu22.04-gfortran9-amd64`) if you need NONMEM 7.4.x or 7.5.0 on a
modern Ubuntu base.

² **gfortran 4.4 + NONMEM 7.5.1 / 7.6.0**: The NONMEM 7.5.x and 7.6.x
setup scripts pass `-ffpe-summary=none` to the Fortran compiler.  This
flag was introduced in GCC 4.6; gfortran 4.4 does not recognize it and
fails immediately during resource file compilation.  All gfortran versions
≥ 4.6 succeed with NONMEM 7.5.1 and 7.6.0.

#### ARM64 (linux/arm64) — Raspberry Pi 4/5 and AWS Graviton2/3/4

The same `linux/arm64` Docker image runs on both Raspberry Pi 4/5 and
AWS Graviton2/3/4; they share the same 64-bit ARM instruction set and no
separate image is needed for Graviton.

NONMEM versions older than 7.5.1 are not attempted for ARM64 because
their setup scripts contain x86-specific assumptions.  Ubuntu 14.04 and
16.04 are also skipped because ARM toolchain support was too immature in
those releases.

##### NONMEM 7.5.1 and 7.6.0 — arm64

| gfortran | 18.04 | 20.04 | 22.04 | 24.04 |
|:--------:|:-----:|:-----:|:-----:|:-----:|
| 4.8      | no³   | —     | —     | —     |
| 5        | no³   | —     | —     | —     |
| 6        | no³   | —     | —     | —     |
| 7        | no³   | no³   | —     | —     |
| 8        | no³   | no³   | —     | —     |
| 9        | —     | no³   | yes   | yes   |
| 10       | —     | no³   | yes   | yes   |
| 11       | —     | —     | yes   | yes   |
| 12       | —     | —     | yes   | yes   |
| 13       | —     | —     | —     | yes   |
| 14       | —     | —     | —     | yes   |

³ **arm64 + Ubuntu < 22.04**: ARM64 builds fail on Ubuntu 18.04 and 20.04
regardless of gfortran version, likely due to ABI or runtime library
differences in the older ARM64 userspace.  Ubuntu 22.04 and later work
correctly.

Raspberry Pi 3 and older (32-bit ARM, linux/arm/v7) are not supported.

### Building the Full Matrix

Use `build_matrix.sh` to build all combinations in parallel (up to 16 at
a time by default):

    # amd64 only (243 combinations)
    ./build_matrix.sh

    # amd64 + arm64 (281 combinations; requires buildx + QEMU — see script header)
    ./build_matrix.sh --arm64

    # Control parallelism
    ./build_matrix.sh --jobs 8

Prerequisites: copy `nonmem_passwords.conf.example` to
`nonmem_passwords.conf` (gitignored) and adjust paths/passwords.
Results are written to `build_matrix.log`.

The script uses BuildKit bind mounts (`--build-context
nonmem_zips=...`) to pass the NONMEM zip files into the build without
copying them into any image layer, keeping final image sizes lean.
No local HTTP server is required.

### Installation

* Copy your nonmem license file (named `nonmem.lic`) to the same
  directory as the Dockerfile.
* Have your NONMEM zip file and its password handy.
* Pass the zip file via `--build-context nonmem_zips=/path/to/zips`
  (see the top of the Dockerfile for the full build command).  The zip
  is never baked into the image.

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
