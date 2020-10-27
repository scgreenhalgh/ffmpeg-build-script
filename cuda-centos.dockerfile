ARG VER=8

FROM nvidia/cuda:11.1-devel-centos${VER} AS build

ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,video

RUN yum group install -y "Development Tools" \
    && yum install -y curl libva-devel \
    && rm -rf /var/cache/yum/* \
    && yum clean all

WORKDIR /app
COPY ./build-ffmpeg /app/build-ffmpeg

RUN SKIPINSTALL=yes /app/build-ffmpeg --build


FROM centos:${VER}

# install va-driver
RUN yum install -y libva \
    && rm -rf /var/cache/yum/* \
    && yum clean all

# Copy libnpp
COPY --from=build /usr/local/cuda-11.1/targets/x86_64-linux/lib/libnppc.so.11 /lib64/libnppc.so.11
COPY --from=build /usr/local/cuda-11.1/targets/x86_64-linux/lib/libnppig.so.11 /lib64/libnppig.so.11
COPY --from=build /usr/local/cuda-11.1/targets/x86_64-linux/lib/libnppicc.so.11 /lib64/libnppicc.so.11
COPY --from=build /usr/local/cuda-11.1/targets/x86_64-linux/lib/libnppidei.so.11 /lib64/libnppidei.so.11

# Copy ffmpeg
COPY --from=build /app/workspace/bin/ffmpeg /usr/bin/ffmpeg
COPY --from=build /app/workspace/bin/ffprobe /usr/bin/ffprobe

RUN ldd /usr/bin/ffmpeg ; exit 0
RUN ldd /usr/bin/ffprobe ; exit 0

CMD         ["--help"]
ENTRYPOINT  ["/usr/bin/ffmpeg"]