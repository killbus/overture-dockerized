# To set multiarch build for Docker hub automated build.
FROM --platform=$TARGETPLATFORM golang:alpine AS builder
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG VERSION
ARG PRERELEASE

WORKDIR /go
RUN apk add curl jq --no-cache

RUN set -eux; \
    \
    if [ "${TARGETPLATFORM}" = "linux/amd64" ]; then architecture="linux-amd64"; fi; \
    if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then architecture="linux-arm64"; fi; \
    if [ "${TARGETPLATFORM}" = "linux/arm/v7" ]; then architecture="linux-arm"; fi; \
	\
	VERSION=${VERSION:-latest}; \
	[ "$VERSION" != "latest" ] && VERSION="v$(echo ${VERSION##v})"; \
	PRERELEASE=${PRERELEASE:-0}; \
	\
	if [ "$VERSION" != "latest" ]; then download_url=$(curl -L https://api.github.com/repos/shawn1m/overture/releases | jq -r --arg architecture "$architecture" --arg version "$VERSION" '.[] | select(.tag_name==$version) | .assets[] | select (.name | contains($architecture)) | .browser_download_url' -); fi; \
    if [ "$VERSION" = "latest" ] && [ "$PRERELEASE" -ne 0 ]; then download_url=$(curl -L https://api.github.com/repos/shawn1m/overture/releases | jq -r --arg architecture "$architecture" '.[0] | .assets[] | select (.name | contains($architecture)) | .browser_download_url' -); fi; \
	if [ "$VERSION" = "latest" ] && [ "$PRERELEASE" -eq 0 ]; then download_url=$(curl -L https://api.github.com/repos/shawn1m/overture/releases | jq -r --arg architecture "$architecture" '[.[] | select(.prerelease==false)] | first | .assets[] | select (.name | contains($architecture)) | .browser_download_url' -); fi; \
	\
    curl -L $download_url -o overture.zip; \
	unzip -j overture.zip; \
	mv overture-linux-* overture; \
	rm overture.zip;

FROM --platform=$TARGETPLATFORM alpine AS runtime
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# RUN echo "https://mirror.tuna.tsinghua.edu.cn/alpine/v3.11/main/" > /etc/apk/repositories

COPY --from=builder /go/* /etc/overture/
COPY entrypoint.sh /usr/local/bin/

RUN set -eux; \
	\
	mv /etc/overture/overture /usr/local/bin/; \
	apk add --no-cache \
		ca-certificates; \
	\
	rm -rf /var/cache/apk/*; \
	chmod a+x /usr/local/bin/overture; \
	chmod a+x /usr/local/bin/entrypoint.sh

EXPOSE 53/udp

ENTRYPOINT ["entrypoint.sh"]
CMD ["overture", "-c", "/etc/overture/config.yml"]