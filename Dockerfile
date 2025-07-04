# ---------- Stage 1: Build ----------
FROM node:lts as build

# Replace 'python' with 'python-is-python3' to fix Render error
RUN apt-get update \
  && apt-get install -y build-essential python-is-python3 \
  && rm -rf /var/lib/apt/lists/*

# Create Node-RED user
RUN deluser --remove-home node \
  && groupadd --gid 1000 nodered \
  && useradd --gid nodered --uid 1000 --shell /bin/bash --create-home nodered

USER 1000
WORKDIR /data

COPY ./package.json /data/
RUN npm install

# ---------- Stage 2: Final Image ----------
FROM node:lts-slim

RUN apt-get update \
  && apt-get install -y python-is-python3 \
  && rm -rf /var/lib/apt/lists/*

# Create Node-RED user
RUN deluser --remove-home node \
  && groupadd --gid 1000 nodered \
  && useradd --gid nodered --uid 1000 --shell /bin/bash --create-home nodered

RUN mkdir -p /data && chown 1000 /data

USER 1000
WORKDIR /data

# Copy application files
COPY ./server.js /data/
COPY ./settings.js /data/
COPY ./flows.json /data/
COPY ./flows_cred.json /data/
COPY ./package.json /data/
COPY --from=build /data/node_modules /data/node_modules

# Set correct group permissions
USER 0
RUN chgrp -R 0 /data \
  && chmod -R g=u /data
USER 1000

ENV PORT 1880
ENV NODE_ENV=production
ENV NODE_PATH=/data/node_modules

EXPOSE 1880

CMD ["node", "/data/server.js"]
