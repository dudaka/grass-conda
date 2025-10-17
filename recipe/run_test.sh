#!/usr/bin/env bash
set -euxo pipefail

grass --version
grass --tmp-project EPSG:4326 --exec g.version -rge

exit 0
