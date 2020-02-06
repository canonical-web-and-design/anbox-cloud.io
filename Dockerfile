# syntax=docker/dockerfile:experimental

# Build stage: Install python dependencies
# ===
FROM ubuntu:bionic AS python-dependencies
RUN apt-get update && apt-get install --no-install-recommends --yes python3-pip python3-setuptools
ADD requirements.txt /tmp/requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip pip3 install --user --requirement /tmp/requirements.txt


# Build stage: Install yarn dependencies
# ===
FROM node:10-slim AS yarn-dependencies
WORKDIR /srv
ADD package.json .
RUN --mount=type=cache,target=/usr/local/share/.cache/yarn yarn install

# Build stage: Run "yarn run build-js"
# ===
FROM yarn-dependencies AS build-js
ADD static/js static/js
ADD webpack.config.js .
RUN yarn run build-js

# Build stage: Run "yarn run build-css"
# ===
FROM yarn-dependencies AS build-css
ADD static/sass static/sass
RUN yarn run build-css

# Build the production image
# ===
FROM ubuntu:bionic

ADD . .
# Install python and import python dependencies
RUN apt-get update && apt-get install --no-install-recommends --yes python3-lib2to3 python3-pkg-resources ca-certificates libsodium-dev
COPY --from=python-dependencies /root/.local/lib/python3.6/site-packages /root/.local/lib/python3.6/site-packages
COPY --from=python-dependencies /root/.local/bin /root/.local/bin
ENV PATH="/root/.local/bin:${PATH}"

# Set up environment
ENV LANG C.UTF-8
ENV SECRET_KEY="secret_key"
WORKDIR /srv

# Import code, build assets and mirror list
ADD . .
RUN rm -rf package.json yarn.lock .babelrc webpack.config.js
COPY --from=build-css /srv/static/css static/css

# Set revision ID
ARG BUILD_ID
ENV TALISKER_REVISION_ID "${BUILD_ID}"

# Setup commands to run server
ENTRYPOINT ["./entrypoint"]
CMD ["0.0.0.0:80"]


# FROM ubuntu:bionic

# # Set up environment
# ENV LANG C.UTF-8
# WORKDIR /srv

# # System dependencies
# RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-setuptools python3-pip

# # Set git commit ID
# ARG COMMIT_ID
# ENV COMMIT_ID "${COMMIT_ID}"
# ENV TALISKER_REVISION_ID "${COMMIT_ID}"

# # Import code, install code dependencies
# COPY . .
# RUN python3 -m pip install --no-cache-dir -r requirements.txt

# # Setup commands to run server
# ENTRYPOINT ["./entrypoint"]
# CMD ["0.0.0.0:80"]
