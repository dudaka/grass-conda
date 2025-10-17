#!/usr/bin/env bash
# Quick build and test script for GRASS GIS conda package
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRASS_ROOT="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "GRASS GIS 8.4.1 Conda Package Builder"
echo "========================================="
echo ""

# Function to build with Docker
build_docker() {
    echo "Building GRASS conda package using Docker..."
    cd "$GRASS_ROOT"
    
    # Build the package
    docker build -f docker/conda-build.Dockerfile --target builder -t grass-conda:latest .
    
    # Extract the package
    mkdir -p output
    docker run --rm -v "$(pwd)/output:/output" grass-conda:latest \
        bash -c "cp /opt/conda/conda-bld/linux-64/grass-*.tar.bz2 /output/"
    
    echo ""
    echo "✅ Package built successfully!"
    ls -lh output/grass-*.tar.bz2
    echo ""
}

# Function to build locally
build_local() {
    echo "Building GRASS conda package locally..."
    cd "$GRASS_ROOT"
    
    conda build recipe -c conda-forge --no-anaconda-upload --no-test
    
    echo ""
    echo "✅ Package built successfully!"
    ls -lh ~/miniconda*/conda-bld/linux-64/grass-*.tar.bz2 2>/dev/null || \
    ls -lh ~/.conda/envs/*/conda-bld/linux-64/grass-*.tar.bz2 2>/dev/null
    echo ""
}

# Function to setup test environment
setup_test_env() {
    echo "Setting up test environment..."
    
    # Check if environment exists
    if conda env list | grep -q "^grass-test "; then
        echo "Environment 'grass-test' already exists. Remove it? (y/n)"
        read -r response
        if [[ "$response" == "y" ]]; then
            conda env remove -n grass-test -y
            conda create -n grass-test python=3.12 -y
        fi
    else
        conda create -n grass-test python=3.12 -y
    fi
    
    echo "✅ Test environment ready!"
}

# Function to install package
install_package() {
    local PACKAGE_PATH="$1"
    
    if [[ ! -f "$PACKAGE_PATH" ]]; then
        echo "❌ Package not found: $PACKAGE_PATH"
        echo "Please build the package first."
        exit 1
    fi
    
    echo "Installing GRASS package and dependencies..."
    
    # Activate environment
    eval "$(conda shell.bash hook)"
    conda activate grass-test
    
    # Install package
    conda install -c conda-forge -y "$PACKAGE_PATH"
    
    # Install runtime dependencies
    echo "Installing runtime dependencies..."
    conda install -c conda-forge -y \
        gdal geos proj proj-data sqlite libpq postgresql \
        readline ncurses cairo freetype fontconfig \
        zlib bzip2 zstd libiconv
    
    echo "✅ Package and dependencies installed!"
}

# Function to run tests
run_tests() {
    echo "Running GRASS tests..."
    
    # Activate environment
    eval "$(conda shell.bash hook)"
    conda activate grass-test
    
    echo ""
    echo "Test 1: Check version"
    echo "====================="
    grass --version
    echo ""
    
    echo "Test 2: System information"
    echo "=========================="
    grass --tmp-project EPSG:4326 --exec g.version -rge
    echo ""
    
    # Check if test data exists
    if [[ -d "$HOME/nc_basic_spm_grass7" ]]; then
        echo "Test 3: North Carolina dataset test"
        echo "===================================="
        cd "$HOME/nc_basic_spm_grass7"
        grass --text user1 --exec g.region -p
        echo ""
        
        echo "Test 4: List raster maps"
        echo "========================"
        grass --text user1 --exec g.list type=raster | head -10
        echo ""
    else
        echo "⚠️  North Carolina test dataset not found."
        echo "Download it from: https://grass.osgeo.org/sampledata/north_carolina/nc_basic_spm_grass7.zip"
    fi
    
    echo "✅ All tests completed!"
}

# Function to download test data
download_testdata() {
    echo "Downloading North Carolina test dataset..."
    
    cd "$HOME"
    if [[ ! -f nc_basic_spm_grass7.zip ]]; then
        wget https://grass.osgeo.org/sampledata/north_carolina/nc_basic_spm_grass7.zip
    fi
    
    if [[ ! -d nc_basic_spm_grass7 ]]; then
        unzip nc_basic_spm_grass7.zip
    fi
    
    echo "✅ Test data ready at: $HOME/nc_basic_spm_grass7"
}

# Main menu
show_menu() {
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "  1) Build package (Docker) - Recommended"
    echo "  2) Build package (Local conda-build)"
    echo "  3) Setup test environment"
    echo "  4) Install package and dependencies"
    echo "  5) Run tests"
    echo "  6) Download test dataset"
    echo "  7) Complete workflow (build + test)"
    echo "  8) Exit"
    echo ""
    echo -n "Enter choice [1-8]: "
}

# Complete workflow
complete_workflow() {
    build_docker
    setup_test_env
    
    # Find the package
    PACKAGE=$(ls -t "$GRASS_ROOT/output"/grass-*.tar.bz2 2>/dev/null | head -1)
    
    if [[ -z "$PACKAGE" ]]; then
        echo "❌ Package not found in output directory"
        exit 1
    fi
    
    install_package "$PACKAGE"
    
    # Ask about test data
    if [[ ! -d "$HOME/nc_basic_spm_grass7" ]]; then
        echo ""
        echo "Download test dataset? (y/n)"
        read -r response
        if [[ "$response" == "y" ]]; then
            download_testdata
        fi
    fi
    
    run_tests
    
    echo ""
    echo "========================================="
    echo "✅ Complete workflow finished!"
    echo "========================================="
    echo ""
    echo "Package: $PACKAGE"
    echo "Environment: grass-test"
    echo ""
    echo "To use GRASS:"
    echo "  conda activate grass-test"
    echo "  grass --version"
}

# Main loop
if [[ $# -gt 0 ]]; then
    # Non-interactive mode
    case $1 in
        build|build-docker)
            build_docker
            ;;
        build-local)
            build_local
            ;;
        test)
            run_tests
            ;;
        all|workflow)
            complete_workflow
            ;;
        *)
            echo "Usage: $0 [build|build-local|test|all]"
            exit 1
            ;;
    esac
else
    # Interactive mode
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                build_docker
                ;;
            2)
                build_local
                ;;
            3)
                setup_test_env
                ;;
            4)
                echo "Enter package path (or press Enter for latest in output/):"
                read -r pkg_path
                if [[ -z "$pkg_path" ]]; then
                    pkg_path=$(ls -t "$GRASS_ROOT/output"/grass-*.tar.bz2 2>/dev/null | head -1)
                fi
                install_package "$pkg_path"
                ;;
            5)
                run_tests
                ;;
            6)
                download_testdata
                ;;
            7)
                complete_workflow
                ;;
            8)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid choice. Please enter 1-8."
                ;;
        esac
    done
fi
