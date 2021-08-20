#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors

. $CCTK_HOME/lib/make/bash_utils.sh

################################################################################
# Decide which libraries to link with
################################################################################

# Set up names of the libraries based on configuration variables. Also
# assign default values to variables.
# Try to find the library if build isn't explicitly requested
if [ -z "${CUDA_INC_DIRS}" -a -z "${CUDA_LIB_DIRS}" -a -z "${CUDA_LIBS}" ]; then
    find_lib CUDA cuda 1 1.0 "cuda cudart" "cuda.h" "$CUDA_DIR"
fi

THORN=CUDA
if [ -n "$CUDA_DIR" ]; then
    DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
    if [ ! -e ${DONE_FILE} ]; then
        mkdir ${SCRATCH_BUILD}/done 2> /dev/null || true
        date > ${DONE_FILE}
    fi

    # Fortran modules may be located in the lib directory
    CUDA_INC_DIRS="$CUDA_LIB_DIRS $CUDA_INC_DIRS"
    # pkg-config does not add cudart to the required libs on all systems
    # eg not on Debian 11
    if ! [ print %s "${CUDA_LIBS}" | grep -q 'cudart' ] ; then
      CUDA_LIBS="${CUDA_LIBS} cudart"
    fi
else
    echo 'BEGIN ERROR'
    echo 'ERROR in CUDA configuration: Could not find library.'
    echo 'END ERROR'
    exit 1
fi

################################################################################
# Check for additional libraries
################################################################################


################################################################################
# Configure Cactus
################################################################################

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "CUDA_DIR            = ${CUDA_DIR}"
echo "CUDA_INC_DIRS       = ${CUDA_INC_DIRS}"
echo "CUDA_LIB_DIRS       = ${CUDA_LIB_DIRS}"
echo "CUDA_LIBS           = ${CUDA_LIBS}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(CUDA_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(CUDA_LIB_DIRS)'
echo 'LIBRARY           $(CUDA_LIBS)'
