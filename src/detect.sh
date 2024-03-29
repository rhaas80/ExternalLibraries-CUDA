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
    # ths link library required is actually cudart, never mind what pkg-config
    # may report
    find_lib CUDA cuda 1 1.0 "cudart" "cuda.h" "$CUDA_DIR"
    if [ -z "$CUDA_DIR" ]; then
        if nvcc --version &>/dev/null; then
            NVCC_PATH="$(hash -t nvcc)"
	    find_lib CUDA cuda 1 1.0 "cudart" "cuda.h" "${NVCC_PATH%/*/nvcc}"
        fi
    fi
    if [ -n "$CUDA_DIR" ]; then
        NEW_CUDA_LIBS=
        for lib in $CUDA_LIBS; do
            if [ $lib = cuda ]; then
	        lib=cudart
            fi
            NEW_CUDA_LIBS[${#NEW_CUDA_LIBS[@]}]=$lib
        done
        # nvToolExt for timing calls
        CUDA_LIBS="nvToolsExt ${NEW_CUDA_LIBS[@]}"
    fi
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
