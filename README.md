# Pages Zerocracy Action

[![test](https://github.com/zerocracy/pages-action/actions/workflows/test.yml/badge.svg)](https://github.com/zerocracy/pages-action/actions/workflows/test.yml)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/zerocracy/pages-action/blob/master/LICENSE.txt)

Add it together with judges-action.

## How to Contribute

In order to test this action, just run (provided, you have
[GNU make](https://www.gnu.org/software/make/) installed):

```bash
make
```

This should build a new Docker image named `pages-action`
and then run the entire cycle
inside a new Docker container. Obviously, you need to have
[Docker](https://docs.docker.com/get-docker/) installed. The Docker image
will be deleted by the end of Make build.
