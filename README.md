# OCurrent website

This repository contains the source code for [ocurrent.org][ocurrent.org],
which describes the [OCurrent workflow specification language][ocurrent] and
contains tutorials for getting started with OCurrent.

### Building the website locally

The website is generated using [GatsbyJS][gatsby]. The following commands run an instance of the
website locally:

```shell
git clone https://github.com/ocurrent/ocurrent.org
cd ocurrent.org

yarn install    # Install build dependencies
yarn run build  # Build the website
yarn run serve  # Serve the build at `localhost:9000`
```

When working on the website, an incremental development server can be run with `yarn run develop`,
but beware that this may show stale artefacts.

### Running tests/linting

- The source code is formatted with [Prettier][prettier].
- Any incorrectly formatted code will be reported by `yarn run lint`.
- Use `yarn run format` to apply the changes.

[ocurrent]: https://github.com/ocurrent/ocurrent/
[ocurrent.org]: https://ocurrent.org/
[prettier]: https://github.com/prettier/prettier/
[gatsby]: https://www.gatsbyjs.org/

