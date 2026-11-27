#!/usr/bin/env bash
set -euo pipefail
# Use software GL, not the dummy renderer, for ArrayMesh serialization.
export LIBGL_ALWAYS_SOFTWARE=1
rm -rf assets/baked_maps
for args in bake verify; do
  extra=()
  if [[ "$args" == verify ]]; then extra=(-- --verify); fi
  xvfb-run -a godot --audio-driver Dummy --rendering-method gl_compatibility --resolution 64x64 -s tools/bake_maps.gd "${extra[@]}" 2>&1 | tee "baked-maps-$args.log"
  if grep -E 'SCRIPT ERROR|Parse Error|SHADER ERROR|Shader compilation failed|Failed to load script' "baked-maps-$args.log"; then exit 1; fi
done
test "$(find assets/baked_maps -name '*.scn' | wc -l)" -ge 100
du -sh assets/baked_maps
