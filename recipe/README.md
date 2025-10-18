# Building GRASS GIS 8.4.1 Conda Package

This repository contains everything needed to build GRASS GIS 8.4.1 as a conda package.

## Quick Start

### Option 1: Interactive Script (Easiest)

```bash
./build_and_test.sh
```

Follow the menu to build and test the package.

### Option 2: One-Line Command

```bash
# Build and test everything automatically
./build_and_test.sh all
```

### Option 3: Manual Docker Build

```bash
# Build the package
docker build -f docker/conda-build.Dockerfile --target builder -t grass-conda:latest .

# Extract the package
mkdir -p output
docker run --rm -v "$(pwd)/output:/output" grass-conda:latest \
    bash -c "cp /opt/conda/conda-bld/linux-64/grass-*.tar.bz2 /output/"

# Package will be at: output/grass-8.4.1-py312h3fd9d12_0.tar.bz2
```

## Documentation

📖 **Full Guide:** [BUILD_AND_TEST_GUIDE.md](BUILD_AND_TEST_GUIDE.md)

The comprehensive guide includes:
- Detailed build instructions
- Testing procedures
- Build-time and runtime troubleshooting
- Package publishing guidelines
- Advanced configuration options

🔧 **Troubleshooting:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Quick reference for common errors
- Diagnostic commands
- Debug workflows
- Emergency fixes

📋 **Quick Reference:** [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- All essential commands in one page
- Fast command lookup

---

After installing the package:

```bash
# Activate your test environment
conda activate grass-test

# Run a quick test
grass --version

# Test with sample data (North Carolina dataset)
cd ~/nc_basic_spm_grass7
grass --text user1 --exec g.region -p
```

## Package Information

- **Version:** 8.4.1
- **Python:** 3.12
- **Platform:** linux-64
- **Size:** ~47MB
- **Build Time:** ~10-15 minutes

## Recipe Structure

```
recipe/
├── meta.yaml              # Package metadata and dependencies
├── build.sh               # Build script
├── run_test.sh           # Installation tests
├── build_and_test.sh     # Interactive build/test script
└── BUILD_AND_TEST_GUIDE.md   # Comprehensive documentation

docker/
└── conda-build.Dockerfile # Docker build environment
```

## Key Features

✅ Complete GRASS GIS installation with all modules  
✅ Python API included  
✅ All major dependencies (GDAL, GEOS, PROJ, etc.)  
✅ libiconv linkage issue resolved  
✅ Tested with real datasets  
✅ Ready for conda-forge submission  

## Requirements

- Docker (for Docker build method)
- OR conda-build (for local build method)
- 10GB free disk space
- Internet connection

## Support

For issues or questions:
- Check the [troubleshooting section](BUILD_AND_TEST_GUIDE.md#troubleshooting)
- Review GRASS GIS docs: https://grass.osgeo.org/
- Check conda-forge guidelines: https://conda-forge.org/docs/

## License

GRASS GIS is licensed under GPL v2+. See [GPL.TXT](GPL.TXT) for details.
