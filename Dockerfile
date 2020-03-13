# To set multiarch build for Docker hub automated build.
FROM golang:alpine AS builder

WORKDIR /go
RUN apk add curl --no-cache

RUN set -eux; \
	\
	mkdir overture; \
	cd overture; \
	tag_url="https://api.github.com/repos/shawn1m/overture/releases"; \
	new_ver=`curl -s ${tag_url} --connect-timeout 10| grep 'tag_name' | head -n 1 | cut -d\" -f4`; \
	new_ver="v${new_ver##*v}"; \
	wget https://github.com/shawn1m/overture/releases/download/${new_ver}/overture-linux-amd64.zip; \
	unzip overture-linux-amd64.zip; \
	mv overture-linux-amd64 overture; \
	rm -f overture-linux-amd64.zip

FROM alpine

# RUN echo "https://mirror.tuna.tsinghua.edu.cn/alpine/v3.11/main/" > /etc/apk/repositories

COPY --from=builder /go/overture/* /etc/overture/
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
CMD ["overture", "-c", "/etc/overture/config.json"]