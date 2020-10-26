# Hussar
[![pipeline status](https://gitlab.com/thislight/hussar/badges/master/pipeline.svg)](https://gitlab.com/thislight/hussar/-/pipelines) 
[![coverage report](https://gitlab.com/thislight/hussar/badges/master/coverage.svg)](https://gitlab.com/thislight/hussar/-/pipelines)  
Toolkit, to go. Hussar is a powerful HTTP server toolkit.

## Installation
`luarocks install hussar`

## Package Structure
- `hussar` is core library to help managing connections.
- `hussar.httputil` contains set of helpers to deal with http connection.
- `hussar.source.fake` keeps a "source" (of connections), but it can set up new connection, which is not created by real clients, by programming.
- `hussar.wrapline` is a small library helping to wrap a function by a set of functions ("wrappers")
- `hussar.wrap_thread` is a function to help you wrap the handler for hussar to run in a new thread for every called
- `hussar.terr` is a small library to create errors are friendly to both code and human
- `hussar.request_router` can route the request to different handlers by checkers, which checks request and private frame and tell router if one handler to be called
- `hussar.request_router.checkers` is a small library keeps functions to create new checkers or to use provided checkers. Provided checkers: HOST, PATH, CUSTOM, HOST_AND_PATH.

## Documents

- API References (TBD)
- Contribution Guide (TBD)
- Test Containers Description (TBD)
- How It Works (TBD)
- Basic Usages (TBD)

## Examples
See `example/` directory.

## Running Tests
Use [busted](http://olivinelabs.com/busted/): `busted`.

There are some predefined docker images for running tests, they are configured to contains the basic concepts to run the tests with `busted`. You can build the images from `test_containers`, or just use private registry on gitlab.com:

- `registry.gitlab.com/thislight/hussar:alpine3d12_lua54`
- `registry.gitlab.com/thislight/hussar:debian11_lua53`
- `registry.gitlab.com/thislight/hussar:alpine3d12_lua54_git` (`git` included)
- `registry.gitlab.com/thislight/hussar:debian11_lua53` (`git` included)

You need to specify `bash` to start bash, or you will get some version infomation, for example: `podman -it registry.gitlab.com/thislight/hussar:debian11_lua53 bash`. These images have included `busted`.

They are just environments, you still need cloning files and running `luarocks make` to install all required packages before you run anything.

## License
GNU General Public License, version 3 or later.  
Tips: you can include this library for online service without open source. this is not a legal advice.
