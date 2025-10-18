# GRASS GIS 8.4.1 Conda Package - Quick Reference

## Build Commands

### Using Docker (Recommended)
```bash
cd /home/dudaka/opt/grass-conda
docker build -f docker/conda-build.Dockerfile --target builder -t grass-conda:latest .
mkdir -p output
docker run --rm -v "$(pwd)/output:/output" grass-conda:latest \
    bash -c "cp /opt/conda/conda-bld/linux-64/grass-*.tar.bz2 /output/"
```

### Using Interactive Script
```bash
./build_and_test.sh all
```

### Using Local Conda-Build
```bash
conda build recipe -c conda-forge --no-anaconda-upload --no-test
```

## Installation Commands

```bash
# Create environment
conda create -n grass-test python=3.12 -y
conda activate grass-test

# Install package
conda install -c conda-forge -y /path/to/grass-8.4.1-*.tar.bz2

# Install dependencies
conda install -c conda-forge -y \
    gdal geos proj proj-data sqlite libpq postgresql \
    readline ncurses cairo freetype fontconfig libiconv
```

## Test Commands

```bash
# Basic tests
grass --version
grass --tmp-project EPSG:4326 --exec g.version -rge

# With North Carolina dataset
cd ~/nc_basic_spm_grass7
grass --text user1 --exec g.region -p
grass --text user1 --exec g.list type=raster
grass --text user1 --exec r.info elevation
```

## File Locations

- **Package:** `output/grass-8.4.1-py312h3fd9d12_0.tar.bz2`
- **Recipe:** `recipe/meta.yaml`
- **Build Script:** `recipe/build.sh`
- **Full Guide:** `BUILD_AND_TEST_GUIDE.md`
- **Summary:** `PROJECT_SUMMARY.md`

## Key Features

✅ Complete GRASS GIS 8.4.1  
✅ ~400 modules included  
✅ Python API available  
✅ libiconv issue fixed  
✅ ~47MB package size  
✅ 10-15 min build time  

## Quick Troubleshooting

| Error | Solution |
|-------|----------|
| `undefined symbol: libiconv` | `conda install -c conda-forge libiconv` |
| `libgdal.so not found` | `conda install -c conda-forge gdal` |
| `libproj.so not found` | `conda install -c conda-forge proj` |
| `.gislock error` | `rm -f /path/to/location/mapset/.gislock` |

## Documentation

📖 [BUILD_AND_TEST_GUIDE.md](BUILD_AND_TEST_GUIDE.md) - Complete guide  
📋 [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Technical details  
📝 [README.md](README.md) - Quick start  

## Support

- GRASS Docs: https://grass.osgeo.org/grass84/manuals/
- Conda-Forge: https://conda-forge.org/docs/
- GitHub: https://github.com/OSGeo/grass
