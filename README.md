# monero-patches
Patches that are not meant to be integrated or are not yet integrated. They can still serve as useful ad-hoc solutions.
Please be aware, that some of them may be unmaintained.

# Usage
From within your Monero repo, write:
```bash
git apply ../monero-patches/src/[SOME_PATCH]
```

# Patches description
[TODO - incomplete]

- `core-tests-cache.patch`: Cache core_tests data, so that it can be ran in 6 minutes, rather than an entire hour
- `core-tests-cache-Makefile.patch`: Same as above, but adds Makefile changes, to be able to build the tests with `release-all` Makefile target
- `functional-win-mac.patch`: execute functional tests under Mac OSX
- `schedule.patch`: Run GitHub's Actions (cli) on schedule, rather than on push
