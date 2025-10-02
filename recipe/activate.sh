#!/bin/bash
# Set GRASS-specific environment variables when conda environment is activated

export GISBASE="$CONDA_PREFIX/opt/grass"
export PATH="$GISBASE/bin:$PATH"

# Set GRASS library path
if [ -d "$GISBASE/lib" ]; then
    export LD_LIBRARY_PATH="$GISBASE/lib:${LD_LIBRARY_PATH:-}"
fi

# Set Python path for GRASS modules
if [ -d "$GISBASE/etc/python" ]; then
    export PYTHONPATH="$GISBASE/etc/python:${PYTHONPATH:-}"
fi