# Multistage build to reduce image size and increase security
FROM node:lts-slim AS build

# Install requirements to clone repository and install deps
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -yq git
RUN npm install -g bower

# Create folder for cryptpad
RUN mkdir /cryptpad
WORKDIR /cryptpad

# Get cryptpad from repository submodule
COPY . /cryptpad

RUN sed -i "s@//httpAddress: '::'@httpAddress: '0.0.0.0'@" /cryptpad/config/config.example.js
RUN sed -i "s@installMethod: 'unspecified'@installMethod: 'docker'@" /cryptpad/config/config.example.js

# Install dependencies
RUN npm install --production \
    && npm install -g bower \
    && bower install --allow-root

# Create actual cryptpad image
FROM node:lts-slim

# Create user and group for cryptpad so it does not run as root
RUN groupadd cryptpad -g 4001
RUN useradd cryptpad -u 4001 -g 4001 -d /cryptpad

# Copy cryptpad with installed modules
COPY --from=build --chown=cryptpad /cryptpad /cryptpad
USER cryptpad

# Copy docker-entrypoint.sh script
COPY --chown=cryptpad docker-entrypoint.sh /cryptpad/docker-entrypoint.sh

# Set workdir to cryptpad
WORKDIR /cryptpad

# Create directories
RUN mkdir blob block customize data datastore

# Volumes for data persistence
VOLUME /cryptpad/blob
VOLUME /cryptpad/block
VOLUME /cryptpad/customize
VOLUME /cryptpad/data
VOLUME /cryptpad/datastore

ENTRYPOINT ["/bin/bash", "/cryptpad/docker-entrypoint.sh"]

# Ports
EXPOSE 3000 3001

# Run cryptpad on startup
CMD ["npm", "start"]

