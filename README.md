# build-resources

Pre-built, self-contained build artifacts for [dronesquare-backend](https://github.com/dronesquare-organization/dronesquare-backend) — resources that need a heavy or non-trivial build, produced once in CI and published to [Releases](https://github.com/dronesquare-organization/build-resources/releases). Backend `docker build` / CI / local installs then pull a ready binary instead of building from source.

## Resources

### PDAL python wheels — [`.github/workflows/pdal.yml`](.github/workflows/pdal.yml)

Self-contained PDAL wheels (native libpdal/libgdal/libgeos/libproj/libgeotiff bundled). PyPI ships only an sdist (~10-min source build + system deps), so we build via [cibuildwheel](https://github.com/pypa/cibuildwheel) and publish per-platform wheels.

- **Linux x86_64 / aarch64** (manylinux_2_28) — source build of PROJ/GEOS/libgeotiff/GDAL/PDAL, `auditwheel repair`.
- **macOS arm64** (Apple Silicon) — `brew install`, `delocate-wheel`.

Consumed by backend `pyproject.toml` `[tool.uv.sources] pdal`.

### PyAV (av) wheels — [`.github/workflows/av.yml`](.github/workflows/av.yml)

Self-contained [PyAV](https://github.com/PyAV-Org/PyAV) wheels (FFmpeg `libav*` bundled) for geolog video thumbnail + capture_date — **in-process libav**, replacing the ffmpeg/ffprobe subprocess path. PyPI ships only `cp314t` (free-threaded) wheels for 3.14, so standard-GIL 3.14 would fall back to an sdist source build (needs FFmpeg dev libs); we build per-platform via cibuildwheel and bundle.

- **Linux x86_64 / aarch64** (manylinux_2_28) — minimal FFmpeg libs source build (inline `CIBW_BEFORE_ALL_LINUX` in `av.yml`, codec allowlist with `--enable-shared --disable-programs --enable-pic`), `auditwheel repair`. LGPLv3 + mbedTLS.
- **macOS arm64** (Apple Silicon) — `brew install ffmpeg`, `delocate-wheel` (dev wheel; full codec set).
- Decode h264/hevc/mpeg4/vp8/vp9/mjpeg; demux mov(mp4/m4v)/mkv/webm/avi; encode mjpeg. (av1 excluded.)

Consumed by backend `pyproject.toml` `[tool.uv.sources] av`.

## Updating

Each resource is built by a manual `workflow_dispatch` with version inputs. See [Releases](https://github.com/dronesquare-organization/build-resources/releases).
