# Hubot code-generator v0.4
# docker run --rm -it -v `pwd`:/app pottava/hubot:0.4-codegen

FROM node:9.2.0-alpine

ENV HUBOT_VERSION=0.4.0 \
    YO_VERSION=2.0.0

RUN apk --no-cache add ca-certificates \

    # Install hubot & yo
    && npm install --global "generator-hubot@${HUBOT_VERSION}" \
    && npm install --global "yo@${YO_VERSION}" \

    # Clean up
    && rm -rf /root/.npm \
    && find / -depth -type f -name *.yml -exec rm -f {} \;

RUN addgroup worker && adduser -s /bin/bash -D -G worker worker
USER worker

WORKDIR /app

CMD ["yo", "--no-insight", "hubot"]
