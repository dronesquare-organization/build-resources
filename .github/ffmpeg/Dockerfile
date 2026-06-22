# syntax=docker/dockerfile:1
# Minimal static ffmpeg/ffprobe for dronesquare-backend geolog (video thumbnail + capture_date only).
# `--disable-everything` + a narrow validated allowlist -> ~4.5 MB each, fully static (vs +299 MB apt).
# LGPLv3 + mbedTLS (https presigned-URL input). Extract for the host arch:
#   docker build --target export -o dist .github/ffmpeg   # -> dist/ffmpeg, dist/ffprobe

FROM alpine:3.21 AS build
RUN apk add --no-cache \
    build-base cmake pkgconf nasm yasm coreutils \
    mbedtls-dev mbedtls-static \
    zlib-dev zlib-static \
    bzip2-static xz-dev xz-static \
    curl tar file
ARG FFMPEG_VERSION=7.1.1
WORKDIR /src
RUN curl -fsSL "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz" | tar xJ --strip-components=1
# Input space = drone geolog video (validation.py allowlist: mp4/mov/m4v/avi/mkv/webm).
# Decoders/demuxers are native (cheap); the size win is cutting all encoders except mjpeg + everything unused.
# `pipe` protocol is required for `-f image2pipe -` (stdout). av1/dav1d intentionally excluded.
RUN ./configure \
      --prefix=/out \
      --disable-shared --enable-static \
      --pkg-config-flags=--static \
      --extra-cflags=-Os \
      --extra-ldflags=-static \
      --enable-small \
      --disable-debug \
      --disable-doc \
      --disable-autodetect \
      --disable-programs --enable-ffmpeg --enable-ffprobe \
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
      --enable-version3 \
      --enable-mbedtls
RUN make -j"$(nproc)" && make install && strip /out/bin/ffmpeg /out/bin/ffprobe
RUN file /out/bin/ffmpeg /out/bin/ffprobe \
    && file /out/bin/ffmpeg  | grep -q 'statically linked' \
    && file /out/bin/ffprobe | grep -q 'statically linked' \
    && /out/bin/ffmpeg  -hide_banner -protocols | grep -q https \
    && /out/bin/ffmpeg  -hide_banner -version \
    && /out/bin/ffprobe -hide_banner -version

FROM scratch AS export
COPY --from=build /out/bin/ffmpeg  /ffmpeg
COPY --from=build /out/bin/ffprobe /ffprobe
