# Hussar
[![pipeline status](https://gitlab.com/thislight/hussar/badges/master/pipeline.svg)](https://gitlab.com/thislight/hussar/-/pipelines) 
[![coverage report](https://gitlab.com/thislight/hussar/badges/master/coverage.svg)](https://gitlab.com/thislight/hussar/-/pipelines)  
Toolkit, to go. Hussar is a powerful HTTP server toolkit.

## Installation
`luarocks install hussar`

## Package Structure
- `hussar` is core library to help managing connections.
- `hussar.httputil` contains set of helpers to deal with http connection.
- `hussar.source.fake` keeps a "source" (of connections), but it can set up new connection by programming which it's not created by real clients.
- `hussar.wrapline` is a small library helping to wrap a function by a set of functions ("wrapper")
- `hussar.wrap_thread` is a function to help you wrap the handler for hussar to run in a new thread for every called
- `hussar.terr` is a small library to create errors are friendly to both code and human
- `hussar.request_router` can route the request to different handler by checker, which checks request and private frame and tell router if the handler to be called
- `hussar.request_router.checkers` is a small library keeps functions to create new checkers or to use provided checkers. Provided checkers: HOST, PATH, CUSTOM, HOST_AND_PATH
