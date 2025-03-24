#! /bin/bash

##############################################################################
###
### @(#)machinedetails 1.0.0
###
### Display MachineDetails for macOS as GitHub Workflow action
###
##############################################################################

## Bash options
if [[ "$RUNNER_DEBUG" == "1" ]]; then
  set -o xtrace         # set -x
fi
set -o errexit          # set -e
set -o errtrace         # set -E
set -o nounset          # set -u
set -o pipefail

## POSIX constants
declare -ir EXIT_SUCCESS=0
declare -ir EXIT_FAILURE=1

## Metadata
declare -r pkgdesc="GitHub Workflow action"
declare -r pkgname="action"
declare -r scriptname="$( basename ${0%.*} )"
declare -r version="0.1.0"           # major.minor.bug


##
## MAIN
##

##-----------------------------------------------------------------------------
Main() {

  ## Print [script] version
  echo "::group:: Print version"
    Version
  echo '::endgroup::'

  ## Ensure we can run
  echo '::group::Ensure we can run
    ## Ensure operating system
    local unameOS="$(uname -s)"
    if [[ "${unameOS}" != "Darwin" ]]; then
      local detail="Unsupported OS ${unameOS}. Only macOS is currently supported by the action"
      echo "::error file=${scriptname},line=${LINENO}::${detail}"
      exit ${EXIT_FAILURE}"
      ## NOTREACHED
    fi

    VerifyUserInput
  echo '::endgroup::'

  ## Display hardware information, if requested
  if [[ "${INPUT_SHOW_HARDWARE}" == "true"  ]]; then
    echo "::group::Hardware Info"
      GetHardwareInfo
      DisplayHardwareInfo
    echo "::endgroup::"
  fi

  ## Display software information, if requested
  if [[ "${INPUT_SHOW_SOFTWARE}" == "true" ]]; then
    echo "::group::Software Info"
      GetSoftwareInfo
      DisplaySoftwareInfo
    echo "::endgroup::"
  fi

  ## Display environment, if requested
  if [[ "${INPUT_SHOW_ENVIRONMENT}" == "true" ]]; then
    echo "::group::Environment"
      DisplayEnvironment
    echo "::endgroup::"
  fi

  exit ${EXIT_SUCCESS}
}

##
## Functions
##

#-----------------------------------------------------------------------------
VerifyUserInput() {
  local detail

  ## Verify SHOW_HARDWARE
  if ! [[ "${INPUT_SHOW_HARDWARE}" == "true" || \
          "${INPUT_SHOW_HARDWARE}" == "false" ]]; then
    detail="'SHOW_HARDWARE' must be either 'true' or 'false'"
    echo "::error file=${scriptname},line=${LINENO}::${detail}"
    exit ${EXIT_FAILURE}"
    ## NOTREACHED
  fi
  
  ## Verify SHOW_SOFTWARE
  if ! [[ "${INPUT_SHOW_SOFTWARE}" == "true" || \
          "${INPUT_SHOW_SOFTWARE}" == "false" ]]; then
    detail="'SHOW_SOFTWARE' must be either 'true' or 'false'"
    echo "::error file=${scriptname},line=${LINENO}::${detail}"
    exit ${EXIT_FAILURE}"
    ## NOTREACHED
  fi

   ## Verify SHOW_ENVIRONMENT
  if ! [[ "${INPUT_SHOW_ENVIRONMENT}" == "true" || \
          "${INPUT_SHOW_ENVIRONMENT}" == "false" ]]; then
    detail="'SHOW_ENVIRONMENT' must be either 'true' or 'false'"
    echo "::error file=${scriptname},line=${LINENO}::${detail}"
    exit ${EXIT_FAILURE}"
    ## NOTREACHED
  fi

  ## Ensure something can be output
  if [[ "${INPUT_SHOW_HARDWARE}" == "false" && \
        "${INPUT_SHOW_SOFTWARE}" == "false" && \
        "${INPUT_SHOW_ENVIRONMENT}" == "false" ]]; then
    detail="All least one type of output must be enabled"
    echo "::error file=${scriptname},line=${LINENO}::${detail}"
    exit ${EXIT_FAILURE}"
    ## NOTREACHED
  fi 
}
      
#-----------------------------------------------------------------------------
GetHardwareInfo() {
  declare arch="Unknown"
  declare chip="Unknown"
  declare cpu="Unknown"
  declare cpuspeed="Unknown"
  declare memory="Unknown"
  declare modelname="Unknown"
  declare ncores="Unknown"
  declare ncpus="Unknown"

  ## Basic system information retrieved, first 4 lines deleted, any blank lines,
  ## left-whitespace trimmed, then result copied to clipboard
  system_profiler SPHardwareDataType \
    | sed '1,4d'                     \
    | sed '/./!d'                    \
    | sed 's/^[ \t]*//'              \
    | head -n 10                     \
    | pbcopy
  if [[ "$RUNNER_DEBUG" = "1" ]]; then
    pbpaste
  fi
  
  ## Parse each invidual detail
  modelname="$( pbpaste | awk -F':' '/Model Name/ { print substr($2, 2) }' )"
  arch="$( uname -p )"
  ncores="$( pbpaste | awk -F':' '/Total Number of Cores/ { print sprintf("%d", $2) }' )"
  memory="$( pbpaste | awk -F':' '/Memory/ { print substr($2, 2) }' )"
  ## Naturally, some are different between architectures
  if [[ "${arch}" == "i386" ]]; then
    chip="Intel Core"    # not completely accurate as it's a chip brand
    cpu="$( pbpaste | awk -F':' '/Processor Name/ { print substr($2, 2) }' )"
    cpuspeed="$( pbpaste | awk -F':' '/Processor Speed/ { print substr($2, 2) }' )"
    ncpus="$( pbpaste | awk -F':' '/Number of Processors/ { print sprintf("%d", $2) }' )"
  elif [[ "${arch}" == "arm" ]]; then
    chip="$( pbpaste | awk -F':' '/Chip/ { print substr($2, 2) }' )"
  fi
} 
          
##-----------------------------------------------------------------------------
GetSoftwareInfo() {
  declare prodname
  declare prodvers
  declare build
  declare os
  declare os_rel
  declare applescript
          
  ## Now export all the software-related variables
  prodname="$( sw_vers -productName )"
  prodvers="$( sw_vers -productVersion )"
  build="$( sw_vers -buildVersion )"
  os="$( uname -s )"
  os_rel="$( uname -r )"
  applescript="$( osascript -e 'version of AppleScript' )"
}

#-----------------------------------------------------------------------------
DisplayEnvironment() {
  env | sort | sed 's/^/  /'
}

#-----------------------------------------------------------------------------
DisplayHardwareInfo() {
  local width=18

  printf "%-${width}s %s\n"  "ModelName:"         "${modelname}"
  if [[ "${arch}" == "i386" ]]; then
    printf "%-${width}s %s\n"  "Chip:"            "${chip}"
    printf "%-${width}s %s\n"  "CPU:"             "${cpu}"
    printf "%-${width}s %s\n"  "Architecture:"    "${arch}"
    printf "%-${width}s %s\n"  "InstructionSet:"  "${isa}"
    printf "%-${width}s %s\n"  "ProcessorSpeed:"  "${cpuspeed}"
    printf "%-${width}s %s\n"  "#CPUs:"           "${ncpus}"
  elif [[ "${arch}" == "arm" ]]; then
    printf "%-${width}s %s\n"  "Chip:"            "${chip}"
    printf "%-${width}s %s\n"  "Architecture:"    "${arch}"
    printf "%-${width}s %s\n"  "InstructionSet:"  "${isa}"
  fi
  printf "%-${width}s %s\n"  "#Cores:"            "${ncores}"
  printf "%-${width}s %s\n"  "Memory:"            "${memory}"
}

#-----------------------------------------------------------------------------
DisplaySoftwareInfo() {
  local width=18

  printf "%-${width}s %s\n"  "ProductName:"     "${prodname}"
  printf "%-${width}s %s\n"  "ProductVersion:"  "${prodvers}"
  printf "%-${width}s %s\n"  "Build:"           "${build}"
  printf "%-${width}s %s\n"  "OperatingSystem:" "${os}"
  printf "%-${width}s %s\n"  "Release:"         "${os_rel}"
  printf "%-${width}s %s\n"  "AppleScript:"     "${applescript}"
}

##-----------------------------------------------------------------------------
Version() {
  echo "${scriptname} (${pkgdesc}) ${version}"
}


##
## << RUN >>
##

Main "$@"
