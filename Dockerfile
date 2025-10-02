ARG DEBIAN_DIST=bookworm
FROM debian:bookworm

ARG DEBIAN_DIST
ARG TIGERBEETLE_VERSION
ARG BUILD_VERSION
ARG FULL_VERSION
ARG ARCH
ARG TIGERBEETLE_RELEASE

RUN mkdir -p /output/usr/local/bin
RUN mkdir -p /output/usr/share/doc/tigerbeetle
RUN mkdir -p /output/DEBIAN
RUN mkdir -p /output/lib/systemd/system

COPY ${TIGERBEETLE_RELEASE}/* /output/usr/local/bin/
COPY output/DEBIAN/control /output/DEBIAN/
COPY output/DEBIAN/postinst /output/DEBIAN/
COPY output/DEBIAN/prerm /output/DEBIAN/
COPY output/DEBIAN/postrm /output/DEBIAN/
COPY output/copyright /output/usr/share/doc/tigerbeetle/
COPY output/changelog.Debian /output/usr/share/doc/tigerbeetle/
COPY output/README.md /output/usr/share/doc/tigerbeetle/
COPY output/tigerbeetle.service /output/lib/systemd/system/
COPY output/tigerbeetle-pre-start.sh /output/usr/local/bin/

RUN chmod +x /output/usr/local/bin/tigerbeetle-pre-start.sh
RUN chmod +x /output/DEBIAN/postinst
RUN chmod +x /output/DEBIAN/prerm
RUN chmod +x /output/DEBIAN/postrm

RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/usr/share/doc/tigerbeetle/changelog.Debian
RUN sed -i "s/FULL_VERSION/$FULL_VERSION/" /output/usr/share/doc/tigerbeetle/changelog.Debian
RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/DEBIAN/control
RUN sed -i "s/TIGERBEETLE_VERSION/$TIGERBEETLE_VERSION/" /output/DEBIAN/control
RUN sed -i "s/BUILD_VERSION/$BUILD_VERSION/" /output/DEBIAN/control
RUN sed -i "s/SUPPORTED_ARCHITECTURES/$ARCH/" /output/DEBIAN/control

RUN dpkg-deb --build /output /tigerbeetle_${FULL_VERSION}.deb
