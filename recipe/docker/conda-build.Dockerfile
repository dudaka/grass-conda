# Use micromamba image for lightweight conda builds
FROM mambaorg/micromamba:1.5.10 AS builder

USER root
SHELL ["/bin/bash", "-lc"]

# Create workspace directory
WORKDIR /work

# Install build tools
RUN micromamba install -y -n base -c conda-forge \
    conda-build \
    anaconda-client \
    boa \
    compilers \
    make \
    pkg-config \
    git \
    bison \
    flex && \
    micromamba clean -a -y

# Copy the source tree
COPY --chown=$MAMBA_USER:$MAMBA_USER . /work

# Create a log directory
RUN mkdir -p /work/build-logs

# Build the recipe with verbose output and detailed logging
# Redirect both stdout and stderr to log files
# Skip tests during build to see if package is created
RUN set -x && \
    conda build recipe -c conda-forge --no-anaconda-upload --no-test 2>&1 | tee /work/build-logs/conda-build.log || \
    (echo "=== BUILD FAILED ===" | tee -a /work/build-logs/conda-build.log && \
     echo "Checking conda-build work directory..." | tee -a /work/build-logs/conda-build.log && \
     find /opt/conda/conda-bld -type f -name "*.log" -exec echo "=== {} ===" \; -exec tail -100 {} \; | tee -a /work/build-logs/conda-build.log && \
     echo "Listing built packages:" | tee -a /work/build-logs/conda-build.log && \
     find /opt/conda/conda-bld -name "*.tar.bz2" -o -name "*.conda" | tee -a /work/build-logs/conda-build.log && \
     exit 1)

# Check build log for critical steps
RUN echo "=== Checking build status ===" && \
    cat /tmp/build-status.txt 2>/dev/null || echo "No build status file found - build may have failed early"

# Show built packages
RUN ls -lah /opt/conda/conda-bld/linux-64/

# If no package was created, check the work directory
RUN if [ ! -f /opt/conda/conda-bld/linux-64/grass-*.tar.bz2 ] && [ ! -f /opt/conda/conda-bld/linux-64/grass-*.conda ]; then \
        echo "=== NO PACKAGE FILE FOUND ===" && \
        echo "Checking conda-bld work directories:" && \
        find /opt/conda/conda-bld -type d -name "work" 2>/dev/null && \
        echo "Checking if files were installed to PREFIX:" && \
        find /opt/conda/conda-bld -path "*/work/_h_env*" -type d 2>/dev/null | head -5 && \
        exit 1; \
    fi

FROM mambaorg/micromamba:1.5.10 AS tester
SHELL ["/bin/bash", "-lc"]
WORKDIR /work

# Copy built packages from previous stage
COPY --from=builder /opt/conda/conda-bld /opt/conda/conda-bld

# Create env with the just-built GRASS and runtime deps
RUN micromamba create -y -n test -c conda-forge -c file:///opt/conda/conda-bld \
    grass \
    gdal \
    proj \
    geos \
    sqlite \
    pdal \
    numpy \
    pillow \
    matplotlib && \
    micromamba clean -a -y

ENV MAMBA_DOCKERFILE_ACTIVATE=1
ENV CONDA_DEFAULT_ENV=test
RUN echo "conda activate test" >> ~/.bashrc

# Smoke tests
RUN conda run -n test grass --version && \
    conda run -n test grass --tmp-project EPSG:4326 --exec g.version -rge
