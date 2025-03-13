# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

FROM ruby:3.4

LABEL "repository"="https://github.com/zerocracy/pages-action"
LABEL "maintainer"="Yegor Bugayenko"
LABEL "version"="0.0.0"

# hadolint ignore=DL3008
RUN apt-get update -y --fix-missing \
  && apt-get -y install --no-install-recommends \
    openjdk-17-jdk \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# hadolint ignore=DL3008
RUN rm -rf /usr/lib/node_modules \
  && curl -sL -o /tmp/nodesource_setup.sh https://deb.nodesource.com/setup_18.x \
  && bash /tmp/nodesource_setup.sh \
  && apt-get update -y --fix-missing \
  && apt-get -y install --no-install-recommends \
    nodejs \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# hadolint ignore=DL3008
RUN apt-get update -y --fix-missing \
  && apt-get -y install --no-install-recommends \
    tidy \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /home
COPY Makefile /home
COPY .stylelintrc.json /home
COPY Gemfile /home
COPY judges /home/judges
COPY sass /home/sass
COPY xsl /home/xsl
COPY js /home/js
COPY eslint.config.js /home
RUN make --directory=/home --no-silent install assets

COPY entry.sh /home

ENTRYPOINT ["/home/entry.sh", "/home"]
