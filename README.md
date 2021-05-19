# monero-patches
Patches that are not meant to be integrated or are not yet integrated. They can still serve as useful ad-hoc solutions.
Please be aware of the following points:
- they are not yet fully approved by the Monero Maintainers and must not enter the Monero's master branch. For this reason, before opening a PR, please unpatch your branch (read below how to do it)
- some of them may be unmaintained

# Usage

Assuming that your monero fork is cloned into a directory below the current one, clone this project to a sibling directory. Next enter your fork's directory. From within, whether or after you perform your own changes in your branch, apply a given patch via:

```bash
git apply ../monero-patches/src/[SOME_PATCH]
git commit -am "Apply patch [SOME_PATCH]"
```

After you are ready with your own changes to your branch and having benefited from the improvements delivered by the patch, it's time to unpatch the branch with:

```bash
git apply -R ../monero-patches/src/[SOME_PATCH]
git commit -am "Revert patch [SOME_PATCH]"
```

Please refrain from pushing the patched branches to an open PR, because this will greatly confuse the reviewers. While a PR is open, you may still patch and unpatch your branch multiple times between the push cycles.

# Description of the patches

## Common developers' use cases

### Testing
- `core-tests-cache.patch`: Cache `core_tests` data, so that the tests can be ran in 6 minutes, rather than an entire hour. The first run of the `core_tests` will generate the temporary data, while the second will reuse it. This is done under the hood, if you just execute `ctest -R core_tests` (or just `ctest` to run all tests) from within the build directory.
- `core-tests-cache-Makefile.patch`: Same as above, but adds Makefile changes, to be able to build the tests with the above change via the `release-all` Makefile target
- `core-speed-up-gen.patch`: Speeds up the data generation part of the `core_tests` by 10%
- `parallel-tests.patch`: Use the `tests/run-tests-parallel.sh` script to run the tests from the current build directory. The parallelism speeds up the tests by 20% when applied alone and a whooping 75% when combined with the `core-tests-cache.patch`

### Compilation
- `icecc-multihost-compilation.patch`: Use targets `release-all-icecc` and `debug-all-icecc` to leverage networked parallel compilation, able to reduce the compilation time by about 70%, depending on your network. You need to setup your hosts first, which is described via the accompanying changes to the main `README.md`
- `cmake-precompiled-headers.patch`: Use the flag `USE_PCH=ON` for your compilation script, in order to avoid compiling large chunks of headers, that rarely change, but are frequently used (typically library headers like Boost). The overall compilation time reduction, when tests are compiled, is 11.5%. The best use case for this feature is working on a single feature and its tests, so Test Driven Development.
- `cmake-unity-build.patch`: Use the flag `USE_UNITY=ON` for your compilation script. A good candidate for a unity build is a target with many source files, where some clusters of the files include the same headers, like `core_tests`. CMake automatically clusters these files to provide an optimal solution. In practice, each such cluster becomes a new temporary .cpp file, with the original files concatenated into the one mentioned cpp file. The second best candidate is `unit_tests`. The overall compilation time reduction, when tests are compiled, is  21.73%. `core_tests` build 50% faster, while `unit_tests` build 36% faster. The best use case for this feature is when you plan to change a number of headers or a header that's included many times.


## CI maintainers' use cases
- `ci-tests-on-mac.patch`: execute all tests under Mac OSX
- `functional-win-mac.patch`: execute functional tests under Mac OSX and Windows
- `schedule.patch`: Run GitHub's Actions (cli) on schedule, rather than on push
