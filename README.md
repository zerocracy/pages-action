# Pages Zerocracy Action

[![DevOps By Rultor.com](https://www.rultor.com/b/zerocracy/pages-action)](https://www.rultor.com/p/zerocracy/pages-action)

[![make](https://github.com/zerocracy/pages-action/actions/workflows/make.yml/badge.svg)](https://github.com/zerocracy/pages-action/actions/workflows/make.yml)
[![Hits-of-Code](https://hitsofcode.com/github/zerocracy/pages-action)](https://hitsofcode.com/view/github/zerocracy/pages-action)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/zerocracy/pages-action/blob/master/LICENSE.txt)

This GitHub Actions plugin is supposed to be used
together with [judges-action](https://github.com/zerocracy/judges-action)
(the documentation is over there). This plugin takes a Factbase file generated
by the [judges-action](https://github.com/zerocracy/judges-action) and prints
its content in YAML, XML, and HTML formats. Also, it prints a user-friendly
HTML document with a summary of project status (we call it "vitals" page).
This is how this vitals page looks for
[our team](https://zerocracy.github.io/judges-action/zerocracy-vitals.html).

The following configuration options are supported here:

```yaml
- uses: zerocracy/pages-action@0.2.0
  with:
    factbase: foo.fb
    verbose: true
    output: my-directory
    columns: who,when,repository
    hidden: _id,_time
```

The following options are supported:

* `factbase` (required) is the name of the
[factbase](https://github.com/yegor256/factbase) file;
* `options` (empty by default) is a list of `k=v` options to be sent to
the [judges](https://github.com/yegor256/judges) command line tool;
* `output` (default: `pages`) is the directory where .XML, .YAML,
and .HTML files are supposed to be saved to;
* `logo` (optional) is the URL of the logo to put on the vitals HTML page;
* `columns` (optional) is a comma-separated list of columns
to print in the HTML;
* `hidden` (optional) is a comma-separated list of columns to hide;
* `today` (optional) is ISO-8601 date-time of today;
* `verbose` (default: `false`) turns on a more detailed logging.
* `ads-free` (optional) hides all Zerocracy banners, links, and logos
* `github-token` (optional) is the GitHub token, defaulted to repo-scoped token

More details are in the
[`action.yml`](https://github.com/zerocracy/pages-action/blob/master/action.yml)
file.

## How to Contribute

In order to test this action, just run (provided, you have
[GNU make](https://www.gnu.org/software/make/) installed):

```bash
make
```

Then, you should be able to open the `target/html/simple-vitals.html`
  in a browser.
