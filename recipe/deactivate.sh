#!/bin/bash
# Unset GRASS-specific environment variables when conda environment is deactivated

unset GISBASE

# Remove GRASS paths from PATH
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "opt/grass/bin" | tr '\n' ':' | sed 's/:$//')

# Clean up LD_LIBRARY_PATH
if [ -n "$LD_LIBRARY_PATH" ]; then
    export LD_LIBRARY_PATH=$(echo "$LD_LIBRARY_PATH" | tr ':' '\n' | grep -v "opt/grass/lib" | tr '\n' ':' | sed 's/:$//')
    if [ -z "$LD_LIBRARY_PATH" ]; then
        unset LD_LIBRARY_PATH
    fi
fi

# Clean up PYTHONPATH
if [ -n "$PYTHONPATH" ]; then
    export PYTHONPATH=$(echo "$PYTHONPATH" | tr ':' '\n' | grep -v "opt/grass/etc/python" | tr '\n' ':' | sed 's/:$//')
    if [ -z "$PYTHONPATH" ]; then
        unset PYTHONPATH
    fi
fi