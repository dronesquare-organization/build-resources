#!/usr/bin/env bash
# Build minimal FFmpeg *shared libraries* (libav*) for PyAV, into /usr/local.
# Mirrors .github/ffmpeg/Dockerfile codec allowlist (geolog: video thumbnail + capture_date) but as a
# LIBRARY build (--enable-shared --disable-programs --enable-pic) so the PyAV C extension links against it
# and auditwheel bundles the libs into a self-contained wheel. Runs inside the cibuildwheel
# manylinux_2_28 (AlmaLinux 8) container (see av.yml CIBW_BEFORE_ALL_LINUX).
# LGPLv3 + mbedTLS (https presigned-URL input). av1/dav1d intentionally excluded (graceful degradation).
set -eux

: "${FFMPEG_VERSION:?FFMPEG_VERSION required}"
: "${MBEDTLS_VERSION:?MBEDTLS_VERSION required}"
PREFIX=/usr/local

# nasm: FFmpeg x86 asm. (yasm/pkgconfig/cmake already in manylinux_2_28.)
dnf install -y nasm

cd /tmp

# mbedTLS: static + PIC, linked into the shared libav* (no extra runtime .so to bundle).
echo "=== mbedTLS ${MBEDTLS_VERSION} ==="
curl -fsSL "https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-${MBEDTLS_VERSION}/mbedtls-${MBEDTLS_VERSION}.tar.bz2" | tar xj
cmake -S "mbedtls-${MBEDTLS_VERSION}" -B build-mbedtls \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DUSE_SHARED_MBEDTLS_LIBRARY=OFF \
    -DUSE_STATIC_MBEDTLS_LIBRARY=ON \
    -DENABLE_TESTING=OFF -DENABLE_PROGRAMS=OFF
cmake --build build-mbedtls --target install --parallel
rm -rf build-mbedtls "mbedtls-${MBEDTLS_VERSION}"
ldconfig

# FFmpeg: shared libs, --disable-everything + the geolog allowlist (identical to .github/ffmpeg/Dockerfile).
echo "=== FFmpeg ${FFMPEG_VERSION} ==="
curl -fsSL "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz" | tar xJ
cd "ffmpeg-${FFMPEG_VERSION}"
./configure \
    --prefix="${PREFIX}" \
    --enable-shared --disable-static --enable-pic \
    --disable-programs --disable-doc --disable-debug --disable-autodetect \
    --disable-everything \
    --enable-network \
    --enable-protocol=file,pipe,http,https,tcp,tls \
    --enable-demuxer=mov,matroska,avi \
    --enable-decoder=h264,hevc,mpeg4,vp8,vp9,mjpeg \
    --enable-parser=h264,hevc,mpeg4video,vp8,vp9,mjpeg \
    --enable-bsf=h264_mp4toannexb,hevc_mp4toannexb,extract_extradata \
    --enable-filter=scale,format,null,copy \
    --enable-encoder=mjpeg \
    --enable-muxer=image2,image2pipe,mjpeg \
    --enable-swscale --enable-swresample \
    --enable-version3 --enable-mbedtls \
    --pkg-config-flags=--static \
    --extra-cflags="-I${PREFIX}/include" \
    --extra-ldflags="-L${PREFIX}/lib"
make -j"$(nproc)"
make install
cd /tmp
rm -rf "ffmpeg-${FFMPEG_VERSION}"
ldconfig

echo "=== installed libav* (verify https protocol present) ==="
ls -la "${PREFIX}/lib"/libav*.so* "${PREFIX}/lib"/libsw*.so*
pkg-config --modversion libavcodec libavformat libavutil libavfilter libswscale libswresample
