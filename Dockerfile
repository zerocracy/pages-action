# MIT License
#
# Copyright (c) 2024 Zerocracy
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

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

WORKDIR /home
COPY Makefile /home
COPY Gemfile /home
COPY entry.sh /home
COPY judges /home/judges
COPY sass /home/sass
COPY xsl /home/xsl
COPY js /home/js
RUN make --directory=/home --no-silent install assets

ENTRYPOINT ["/home/entry.sh", "/home"]
