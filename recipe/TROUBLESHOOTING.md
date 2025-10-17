# GRASS GIS Conda Package - Troubleshooting Quick Reference

## Build-Time Issues

### Quick Diagnosis Commands

```bash
# Check what stage failed
docker run --rm grass-conda:builder cat /tmp/build-status.txt

# See recent build output
docker build ... 2>&1 | tail -100

# Search for errors
docker build ... 2>&1 | grep -iE "error:|fatal:|failed"

# Check if package was created
docker run --rm grass-conda:builder ls /opt/conda/conda-bld/linux-64/grass-*.tar.bz2
```

### Common Build Errors (Alphabetical)

| Error Message | Cause | Quick Fix |
|---------------|-------|-----------|
| `configure: error: *** Unable to locate GDAL` | Missing dependency | Add `gdal` to `host:` in meta.yaml |
| `error while loading shared libraries` | Missing runtime lib | Add to `run:` in meta.yaml |
| `Error 1` during make | Compilation failed | Check 20 lines above for actual error |
| `failed to solve: process exited` | Docker build failed | Check step number, retry, or use `--no-cache` |
| `libiconv.so.2, needed by ..., not found` | libiconv not linked | Check ICONVLIB fix in build.sh lines 50-60 |
| `make[3]: *** [file] Error 127` | Missing executable | Install missing build tool |
| `No package file found` | Build didn't complete | Check `/tmp/build-status.txt` |
| `No such file or directory` | Missing header | Add package providing header to `host:` |
| `symbol lookup error` during test | Test dependency issue | Usually OK, build continues |
| `undefined reference to` | Missing library at link | Add `-l<library>` to LIBS in build.sh |

### Build Stage Failures

#### Only "configure-complete" in status file
**Problem:** Make failed  
**Check:** `grep -i error build.log`  
**Solution:** Fix compilation errors, add missing dependencies

#### "configure-complete" and "make-complete" only
**Problem:** Make install failed  
**Check:** Permissions, disk space  
**Solution:** `df -h` to check space, may need sudo

#### All stages complete, no package
**Problem:** Packaging failed  
**Check:** `docker run --rm grass-conda:builder ls /opt/conda/conda-bld/broken/`  
**Solution:** Check conda-build validation errors

### Performance Issues

| Issue | Symptoms | Solution |
|-------|----------|----------|
| Build too slow (>20 min) | High CPU, slow progress | Increase `-j` value in build.sh |
| Build freezes | No CPU usage | Kill and use `-j1`, check memory |
| Out of memory | System swap increases | Reduce parallel jobs, increase Docker memory |
| Disk full | `No space left` error | Clean Docker: `docker system prune -a` |

## Runtime Issues

### Installation Problems

| Error | Cause | Fix |
|-------|-------|-----|
| `undefined symbol: libiconv` | libiconv not installed | `conda install -c conda-forge libiconv` |
| `libgdal.so.37: cannot open` | GDAL not installed | `conda install -c conda-forge gdal` |
| `libproj.so.25: cannot open` | PROJ not installed | `conda install -c conda-forge proj` |
| `libpq.so.5: cannot open` | PostgreSQL not installed | `conda install -c conda-forge libpq` |

### Runtime Execution Problems

| Error | Cause | Fix |
|-------|-------|-----|
| `Unable to access .gislock` | Stale lock file | `rm -f /path/to/mapset/.gislock` |
| `ERROR: Location not found` | Wrong path | Use full path to grassdata |
| `g.proj: error while loading` | Missing dependency | Install all deps from guide |
| Command hangs | Database lock | Remove .gislock, use `--tmp-project` |
| `Permission denied` | File ownership | `chown -R $USER:$USER /path/to/grassdata` |

## Debugging Workflows

### Workflow 1: Build Fails During Make

```bash
# 1. Get full error context
docker build ... 2>&1 | tee build.log
grep -B 30 "Error 1" build.log | grep "error:"

# 2. Identify missing component
# Look for "undefined reference to XXX" or "XXX.h: No such file"

# 3. Find which package provides it
apt-file search XXX.h  # On Ubuntu/Debian
# Or search conda-forge

# 4. Add to meta.yaml
vim recipe/meta.yaml
# Add under host: section

# 5. Rebuild
docker build --no-cache ...
```

### Workflow 2: Package Creates but Doesn't Work

```bash
# 1. Install package
conda install -y /path/to/grass-*.tar.bz2

# 2. Run with verbose error
grass --verbose 2>&1 | tee grass-error.log

# 3. Check missing libraries
ldd $CONDA_PREFIX/grass84/lib/libgrass_gis.8.4.so | grep "not found"

# 4. Install each missing library
conda install -c conda-forge <library-name>

# 5. Test again
grass --version
```

### Workflow 3: Debug Inside Container

```bash
# 1. Start interactive container
docker run -it --rm grass-conda:builder bash

# 2. Navigate to build directory
cd /tmp/conda-bld/work

# 3. Try manual build
./configure --prefix=/tmp/test --with-gdal=/opt/conda/bin/gdal-config
make -j1 2>&1 | tee manual.log

# 4. Check specific issue
grep -i "error" manual.log
cat error.log

# 5. Test fix
export LIBS="-liconv"
make clean && make -j1

# 6. Exit when done
exit
```

## Emergency Fixes

### Nuclear Option 1: Complete Clean Rebuild

```bash
# Remove all Docker images and containers
docker system prune -a --volumes

# Remove build artifacts
cd /home/dudaka/opt/grass-8.4.1
make distclean
rm -rf output/*.tar.bz2

# Rebuild from scratch
docker build --no-cache -f docker/conda-build.Dockerfile -t grass-conda .
```

### Nuclear Option 2: Build Outside Docker

```bash
# Skip Docker entirely
conda create -n build-env conda-build -y
conda activate build-env
cd /home/dudaka/opt/grass-8.4.1
conda build recipe -c conda-forge --no-test

# Package at: ~/miniconda/conda-bld/linux-64/grass-*.tar.bz2
```

### Nuclear Option 3: Manual Build

```bash
# Build GRASS traditionally (not conda package)
./configure --prefix=$HOME/grass84
make -j$(nproc)
make install
export PATH=$HOME/grass84/bin:$PATH
grass --version
```

## Log Interpretation

### Good Build Log Patterns

```
✅ configure: GRASS is now configured for: x86_64-conda-linux-gnu
✅ Making all in lib
✅ Making install in lib
✅ BUILD START: ['grass-8.4.1-py312h3fd9d12_0.tar.bz2']
✅ configure-complete
✅ make-complete  
✅ make-install-complete
✅ all-complete
✅ -rw-r--r-- 1 root root 47M ... grass-8.4.1-py312h3fd9d12_0.tar.bz2
```

### Bad Build Log Patterns

```
❌ configure: error: *** Unable to locate ...
❌ make[3]: *** [target] Error 1
❌ /usr/bin/ld: cannot find -lXXX
❌ fatal error: XXX.h: No such file or directory
❌ undefined reference to `XXX'
❌ ERROR: Unable to load ...
❌ No package file found
```

## Prevention Checklist

Before building, verify:

- [ ] Docker has 4GB+ RAM allocated
- [ ] 10GB+ free disk space
- [ ] Internet connection stable
- [ ] recipe/meta.yaml has all dependencies
- [ ] recipe/build.sh has ICONVLIB fix
- [ ] No uncommitted changes in source (if using git source)

## Environment Checks

```bash
# Check Docker resources
docker info | grep -E "CPUs|Total Memory"

# Check disk space
df -h /var/lib/docker
df -h ~

# Check conda-build version
conda list conda-build

# Check if conda-forge channel accessible
conda search --channel conda-forge gdal

# Verify recipe syntax
conda build recipe --check
```

## Getting More Help

### Capture Diagnostic Info

```bash
# Create diagnostic bundle
{
  echo "=== System Info ==="
  uname -a
  docker --version
  conda --version
  
  echo -e "\n=== Disk Space ==="
  df -h
  
  echo -e "\n=== Build Status ==="
  docker run --rm grass-conda:builder cat /tmp/build-status.txt 2>/dev/null || echo "N/A"
  
  echo -e "\n=== Recent Build Log ==="
  tail -200 build.log
  
  echo -e "\n=== Error Log ==="
  docker run --rm grass-conda:builder cat /tmp/conda-bld/work/error.log 2>/dev/null || echo "N/A"
  
} > diagnostic-info.txt
```

### Where to Ask

1. **GRASS GIS Community:**
   - Mailing list: https://lists.osgeo.org/mailman/listinfo/grass-user
   - GitHub: https://github.com/OSGeo/grass/issues

2. **Conda-Forge:**
   - Gitter: https://gitter.im/conda-forge/conda-forge
   - Discourse: https://conda.discourse.group/

3. **Stack Overflow:**
   - Tag: `[grass-gis] [conda]`
   - Search first: https://stackoverflow.com/questions/tagged/grass-gis

## Quick Reference Commands

```bash
# View build status
docker run --rm grass-conda:builder cat /tmp/build-status.txt

# Check package exists
docker run --rm grass-conda:builder ls -lh /opt/conda/conda-bld/linux-64/

# Extract package
docker run --rm -v "$(pwd)/output:/output" grass-conda:builder \
    bash -c "cp /opt/conda/conda-bld/linux-64/grass-*.tar.bz2 /output/"

# Test package linkage
tar -xOf output/grass-*.tar.bz2 grass84/lib/libgrass_gis.8.4.so > /tmp/test.so
readelf -d /tmp/test.so | grep NEEDED

# Clean Docker
docker system prune -a

# Rebuild fresh
docker build --no-cache -f docker/conda-build.Dockerfile -t grass-conda .
```

---

**Last Updated:** October 17, 2025  
**For detailed explanations, see:** BUILD_AND_TEST_GUIDE.md  
**For complete technical details, see:** PROJECT_SUMMARY.md
