# How It Works
Hussar built on away, a by-signal thread scheduler for Lua. So we must start by away’s internal.

## How away works
Away is a "by-signal scheduler", which means it just a scheduler for the Lua's built-in `coroutine`: it maintains a signal queue, and eat then one by one to run the targeted thread as the signal described.

When a scheduler is started (by `:run()` or `:runforever()`), it will enter a loop. In each turn of the loop, the scheduler will move all the signals in public queue to internal queue, then do something depends on them one by one.

A signal must be self-described. That means, it must have all the required infomation for one `resume` of targeted thread. And the scheduler will not leak any infomation more than a field `source_thread` (to identify which thread is source of the signal) to the signal.

Although away is built on `coroutine`, it must be careful to use with built-in `coroutine` library. For example, if you use away calls (`get_current_thread`, `schedule_thread`, and others. `wakeback_later` combined two away calls) in a thread, it's a bad idea to use `coroutine.resume` when it will run away calls. You will get nothing and the thread will fail silently. The reason is the away call depends on `coroutine.yield`, and the scheduler only can catch it when the thread is resumed by the scheduler (you may see the `scheduler:run_thread`).

To learn more about away, please go to its homepage: https://github.com/thislight/away

### How to play with away correctly
These rules will helps you avoid many problems:
- In one turn of loop, the public signal queue must have a signal for one targeted thread, that means you could not push many signals to run one thread. There is a debugger function to check that.
- If you want to use `coroutine.resume` on a thread, make sure it will as your expected yield before it run into any code required the away scheduler context. Including away calls and signal yielding.

## Hussar's Core: Managing Thread
Hussar's core is in `hussar` namespace, it provides interfaces to combine sources and handler.

````lua
local away = require "away"
local hussar = require "hussar"
local fake_source = require "hussar.source.fake"
local co = coroutine

local server = hussar:create()
server.handler = function(conn, frame, pubframe)
    conn:write("HTTP/1.1 200 OK\r\n\r\n")
    conn:close()
end

local source = fake_source:create()

server:attach_source(source)

away.scheduler:run(function()
    server:run()
end)
````

When you use `:run()`, it starts a thread we called "managing thread". Managing thread repeat its running in queue by `wakeback_later`.

Then, when a new connection come from any "source" (you attach it to hussar instance by `:attach_source()`), the source will call `:add_connection()` of hussar instance.
````
source get new connection -> hussar instance's :add_connection(new_connection) -> call handler in executor -> set the connection managed
````

Managing thread will walkthough the managed connections in each turn of scheduler's loop, wakeback the thread if connection need a wakeback (`connection:require_wakeback()`) and maintain the managed connections' list when is needed.

Notice: managing thread only can wakeback the binded thread which binded to connection (`__binded_thread` can set automatically or manually. Hussar will set it to the executor thread when calling handler for one connection and set to `nil` when the running is end). Ff you need to read something from connection out of hussar, `connection:read_and_wait()` will wakeback repeatly and check until the connection has data to return. `connection:read()` just yield and wait for wakeback from managing thread.

In most cases, managing thread just do the most part of things on the HTTPConnections, sources should still do something on the raw connections by themselves:

- Close raw connections if it's opened but no activities for a while
- Walkthough inactive keep-alive connections, add to hussar when new data is recviced.

## HTTPUtil: HTTP Toolkit
Hussar does not provide a "must use" implementation of HTTP, but there is a default library to deal with HTTP connection. It's `hussar.httputil`.

Under this namespace:
- wait_for_request
- wait_for_headers
- request
- response
- headers
- status2code (table)
- code2status (table)
- default_methods (table)
- read_fixed_body
- read_chunked_body
- respond
- respond_on

If you want to get a http request from a connection, you will use `wait_for_request`. It uses `connection:read()` to read strings from connection and parse them as http protocol described. `wait_for_request` is partical lazy: it only read body (by `request[1]`) when you actually need it. It provide this functionality by metatable, so it may cause performance problem when you are in heavy traffic.

If you just need headers (everything but body), `wait_for_headers` it's a good choice.

The results of `wait_for_request` and `wait_for_headers` are familiar:
````lua
{
    method = "GET",
    path = "/",
    minor_version = 1,
    headers = {
        {"X-Request", "GET, POST"},
        {"X-Powered-By", "Hussar/Lua"},
    },
    "This is body", -- (only exists when using `wait_for_request`)
}
````

`read_body` helps you read complete body. (You also can read body from connection by youself)

`request` and `response` can help you build HTTP request and response in HTTP/1.0 and HTTP/1.1 style.

````lua
local function handler(request, frame, pub)
    return httputil.response {
        status = 200,
        "Happy",
    }
end
````

`headers` is a small library to deal with headers.
````lua
-- request is a HTTP request get from wait_for_headers
local etag = headers.get_last_of(request.headers, "ETag")
local accepted_content_type = headers.search(request.headers, "Accept-Content-Type")

local response = {
    status = 200,
}
headers.insert2response(response, "Non-Accept-CPU-band", "Intel Core")
header.insert2response(response, "Non-Accept-CPU-band", "Apple M1")
````

After doing anything, you must `respond` on connection. `respond_on` is a pretty hand of `respond`.
````lua
respond(conn, { status=200 })
respond_on(conn) {
    status = 200,
    "body"
}
````

(TBD...)
