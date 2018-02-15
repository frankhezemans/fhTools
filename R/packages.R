#' @title Conveniently load and install packages
#'
#' @description \code{packages} loads and, if necessary, installs packages.
#' Adapted from the \href{https://github.com/russellpierce/repsych/blob/master/R/glibrary.R}{glibrary} function in the repsych package.
#' Packages can be installed from both CRAN and GitHub.
#'
#' @param ... comma seperated package names and/or GitHub repository address.
#' In case of the latter, ensure that you enter the address as a character in the format \code{username/repo} (or \code{username/repo/subdir} if necessary).
#' @param repos URL of the repository to use, see \code{\link{install.packages}}.
#' @param dep logical indicating whether to also install packages which the requested packages depend on / link to / import / suggest. See \code{\link{install.packages}}.
#' @param lib.loc character vector describing the location of \code{R} library trees to search for, or NULL. See \code{\link{require}}.
#' @param quietly logical indicating whether warning / error messages from \code{\link{install.packages}}, \code{\link{install_github}}, and \code{\link{require}} should be printed.
#' @param warn.conflicts logical indicating whether \code{\link{require}} warnings about conflicts from attaching a new package should be printed.
#'
#' @author Frank H. Hezemans, \email{Frank.Hezemans@@mrc-cbu.cam.ac.uk}
#' @seealso \code{\link{install.packages}}, \code{\link[devtools]{install_github}}, \code{\link{require}}
#'
#' @examples 
#' packages(ggplot2) # Install and load from CRAN
#' packages(ggplot2, "hrbrmstr/hrbrthemes") # Load packages from CRAN and GitHub in one line
#' 
#' @export
#'
packages <- function(..., repos = "http://cran.r-project.org", dep = TRUE, lib.loc = NULL, quietly = FALSE, warn.conflicts = TRUE){
  
  # Create a character vector from the package names
  pkgs <- unlist(lapply(as.list(substitute(.(...)))[-1],as.character))
  # Save a temporary copy of pkgs, from which we will remove the GitHub usernames
  pkgs_temp <- pkgs

  # Check if this list contains GitHub repositories
  if (any(grep("/", pkgs_temp))){
    # return index of those elements that contain the forward slash symbol (i.e. are GitHub repositories)
    index_gh <- grep("/", pkgs_temp)
    # remove the username(s) from these elements
    pkgs_temp[index_gh] <- sub(".*/", "", pkgs_temp[index_gh]) # replace everything before slash with ""
  }

  # Check which packages have already been installed and loaded
  sesh <- sessionInfo()
  loaded <- c(sesh$basePkgs,names(sesh$otherPkgs))
  # Disregard packages that have already been installed and loaded
  pkgs <- pkgs[!pkgs_temp %in% loaded] # compare currently loaded packages to pkgs_temp because it doesn't include the GitHub usernames
  # Stop if there's nothing to load
  if (length(pkgs)==0) {return(invisible(TRUE))}
  rm(pkgs_temp) # remove redundant vector

  # Check if the remaining package list contains GitHub repositories
  if (any(grep("/", pkgs))){
    index_gh <- grep("/", pkgs)
    # Save the full GitHub repository address(es) in a seperate vector
    gh_addresses <- pkgs[index_gh]
    # Remove the GitHub username(s) from the overall pkgs list
    pkgs[index_gh] <- sub(".*/", "", pkgs[index_gh]) # replace everything before slash with ""
    # Save the (now username-less) GitHub repositories in a seperate vector
    gh_repo <- pkgs[index_gh]
    # Save the CRAN packages in a seperate vector
    cran_pkgs <- pkgs[-index_gh]
    rm(index_gh)
  } else {cran_pkgs <- pkgs}

  # Check if any packages need to be installed from CRAN
  if (length(cran_pkgs) > 0){
    installNeeded <- !cran_pkgs %in% installed.packages()[,"Package"]

    if (any(installNeeded)){
      # Install packages that are on CRAN
      sapply(cran_pkgs[installNeeded], install.packages, repos = repos, dependencies = dep, quiet = quietly)
      # Check if install was succesful
      installNeeded <- !cran_pkgs %in% installed.packages()[,"Package"]
      # If any packages failed to be installed, throw up an error
      if (any(installNeeded)){
        stop(paste0("Could not download and/or install: ", paste(cran_pkgs[installNeeded], collapse = ", ")), " from CRAN.")
      }
    }
  }
  rm(cran_pkgs) # remove redundant vector

  # If any of the requested packages are GitHub repositories...
  if (exists("gh_addresses")){
    # Check if any packages need to be installed from GitHub
    installNeeded <- !gh_repo %in% installed.packages()[,"Package"]

    if (any(installNeeded)){
      # Install packages from GitHub
      sapply(gh_addresses[installNeeded], devtools::install_github, quiet = quietly)
      # Check if install was succesful
      installNeeded <- !gh_repo %in% installed.packages()[,"Package"]
      # If any packages failed to be installed, throw up an error
      if (any(installNeeded)){
        stop(paste0("Could not download and/or install: ", paste(gh_repo[installNeeded], collapse = ", ")), " from GitHub.")
      }
    }
    rm(gh_addresses, gh_repo, installNeeded) # remove redundant objects
  }

  # Now load the packages using require()
  loading <- sapply(pkgs, require, lib.loc = lib.loc, quietly = quietly, warn.conflicts = warn.conflicts, character.only = TRUE)
  if(length(loading) != length(pkgs)) {stop("For at least one package, we're missing a logical indicating whether it was loaded properly.")}

  if (all(loading)){
    return(invisible(TRUE))
  } else {
    stop(paste0("\nCould not load: ", paste(pkgs[!loading])))
  }
}
