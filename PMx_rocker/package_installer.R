rm(list=ls())

options(warn=1)
## Should we reinstall packages that are already installed?
reinstall.packages <- FALSE

repos.list <- list(
  CRAN="http://cran.r-project.org",
  RForge="http://R-Forge.R-project.org",
  RStudio="http://cran.rstudio.com")

desired.packages <- read.csv("packages.csv",
                             stringsAsFactors=FALSE,
                             na.strings="")
desired.packages$installed <- FALSE

## See if a list of packages is installed.  Returns TRUE if the
## package is installed and FALSE if it is not installed.
check.installation <- function(pkglist) {
  sapply(pkglist,
         FUN=function(x) {
           suppressMessages(
             suppressWarnings(
               require(x,
                       quietly=TRUE,
                       character.only=TRUE)))
         })
}

## Run all the post-install commands
preinstall <- na.omit(desired.packages$Preinstall.Command)
for (n in preinstall) {
  cat("Running preinstall command: ", n, "\n", sep="")
  eval(parse(text=n))
}

for (n in names(repos.list)) {
  this.set <-
    desired.packages$package.name[desired.packages$repos %in% n]
  if (!reinstall.packages & (length(this.set) > 0)) {
    ## Find out if the package is already installed
    installed <- check.installation(this.set)
    if (any(installed)) {
      cat("The following packages were already installed and will not be reinstalled:\n  ",
          paste(this.set[installed], collapse=", "),
          "\n",
          sep="")
      this.set <- this.set[!installed]
    }
  }
  if (length(this.set) > 0) {
    cat(n, ": Beginning installation of: ",
        paste(this.set, collapse=", "),
    	"\n", sep="")
    install.packages(this.set, repos=repos.list[[n]],
                     dependencies=c("Depends", "Imports", "LinkingTo"))
    successful <- check.installation(this.set)
    cat("Successfully installed the following package(s):\n  ",
        paste(this.set[successful], collapse=", "), "\n",
        sep="")
    if (any(!successful)) {
      stop("Could not install the following package(s):\n  ",
           paste(this.set[!successful], collapse=", "))
    } else {
      cat("All packages successfully installed from repository: ", n,
          " (", repos.list[[n]], ")\n",
          sep="")
    }
  } else {
    cat(n, ": No packages to install (perhaps all were previously installed).\n")
  }
}

library(installr)
install.rtools()

library(devtools)
mask.github <- desired.packages$repos %in% "GitHub"
for (n in desired.packages$package.name[mask.github]) {
  current <- desired.packages[desired.packages$package.name %in% n,]
  if (nrow(current) != 1) {
    stop("Error selecting GitHub package", n)
  }
  install_github(current$repos.note)
}

## Run all the post-install commands
postinstall <- na.omit(desired.packages$Postinstall.Command)
for (n in postinstall) {
  cat("Running postinstall command: ", n, "\n", sep="")
  eval(parse(text=n))
}

q(save="no")
