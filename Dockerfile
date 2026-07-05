FROM --platform=$BUILDPLATFORM swift:6.3.3-noble AS build
ARG TARGETARCH
WORKDIR /build

RUN case "$TARGETARCH" in \
		amd64) echo x86_64 > /tmp/target-arch ;; \
		arm64) echo aarch64 > /tmp/target-arch ;; \
		*) echo "unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;; \
	esac

# Download Swift SDK
RUN swift sdk install \
		https://download.swift.org/swift-6.3.3-release/static-sdk/swift-6.3.3-RELEASE/swift-6.3.3-RELEASE_static-linux-0.1.0.artifactbundle.tar.gz \
		--checksum 87c3eaf908e67c0e13a84367119e12273cec1d2cd3d81f7d74bb36722d6b607b

# Build SQLite
ADD --checksum=sha256:646421e12aac110282ef8cc68f1a62d4bb15fc7b8f09da0b53e29ee690500431 \
	https://sqlite.org/2026/sqlite-amalgamation-3530300.zip /tmp/sqlite.zip
RUN apt-get update && apt-get install -y --no-install-recommends unzip && rm -rf /var/lib/apt/lists/* \
	&& unzip -q /tmp/sqlite.zip -d /tmp \
	&& ARCH=$(cat /tmp/target-arch) \
	&& SYSROOT=$(echo /root/.swiftpm/swift-sdks/swift-*_static-linux-*.artifactbundle/*/swift-linux-musl/musl-*.sdk/$ARCH) \
	&& mkdir -p /musl-sqlite/include /musl-sqlite/lib \
	&& cp /tmp/sqlite-amalgamation-*/sqlite3.h /tmp/sqlite-amalgamation-*/sqlite3ext.h /musl-sqlite/include/ \
	&& clang --target=$ARCH-unknown-linux-musl --sysroot=$SYSROOT -O2 \
		-DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_RTREE -DSQLITE_ENABLE_COLUMN_METADATA -DSQLITE_OMIT_LOAD_EXTENSION \
		-c /tmp/sqlite-amalgamation-*/sqlite3.c -o /tmp/sqlite3.o \
	&& llvm-ar rcs /musl-sqlite/lib/libsqlite3.a /tmp/sqlite3.o

# Resolve Packages
COPY Package.swift Package.resolved ./
RUN swift package resolve

# Build
COPY src ./src
COPY tests ./tests
RUN ARCH=$(cat /tmp/target-arch) \
	&& swift build -c release --product HonkBackend --swift-sdk $ARCH-swift-linux-musl \
		-Xcc -I/musl-sqlite/include -Xlinker -L/musl-sqlite/lib \
	&& cp .build/$ARCH-swift-linux-musl/release/HonkBackend /HonkBackend \
	&& (llvm-strip /HonkBackend || strip /HonkBackend) \
	&& mkdir -p /data && chown 65532:65532 /data

# Runtime
FROM scratch
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build --chown=65532:65532 /data /data
COPY --from=build /HonkBackend /HonkBackend

USER 65532:65532
ENV HTTP_HOST=0.0.0.0 HTTP_PORT=8080 DATABASE_PATH=/data/database.sqlite
VOLUME /data
EXPOSE 8080

ENTRYPOINT ["/HonkBackend"]
