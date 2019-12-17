# Homebrew ClickHouse Tap

This is an unofficial Homebrew repository for the Yandex's [ClickHouse](https://clickhouse.yandex/) DBMS.

Stable version is 19.17.5.18 and it is building fine on the Mojave. It is built without MySQL support (post Issue if you need it).
Clickhouse must be compiled with *Clang* on Mac OS X, so we did switched from gcc. That means you need xCode to be installed.

It is relatively new and isn't tested well.  
Please consider appending the `--verbose` and `--debug` parameters to the `brew install` command to make it easier to debug the package installation.  
If you are having any problems with the precompiled binaries (bottles), append the `--build-from-source` parameter.

Issues and pull requests are always welcome!

## Note on the test (development) build

The dev version is v19.19.1.1902-testing and it was not tested yet.

## Usage

Add this repository:
```
brew tap deem0n/clickhouse
```

To install the latest `stable` release, run:
```
brew install clickhouse
```

Or, to install the `testing` release, run:

```
brew install clickhouse --devel
```

## Run the server

Make sure that you've increased the maxfiles parameter as described in [here](https://github.com/yandex/ClickHouse/blob/master/MacOS.md).  
Then, to run the server, run:
```
brew services start clickhouse
```
