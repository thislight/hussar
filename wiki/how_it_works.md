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
    return co.create(function()
        conn:write("HTTP/1.1 200 OK\r\n\r\n")
        conn:close()
    end)
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
source get new connection -> hussar instance's :add_connection(new_connection) -> call handler (handler may return a thread) -> save descriptor
````
A descriptor include the connection, the deadline, the binded thread related to the connection (return by handler) and the related frame (saves user values).

Managing thread will scan the descriptors in each turn of scheduler's loop, wakeback the thread if connection need a wakeback (`connection:require_wakeback()`).

Notice: managin thread only can wakeback the binded thread which included in descriptor, if you need to read something from connection out of hussar, `connection:read_and_wait()` will wakeback repeatly and check until the connection has data to return. `connection:read()` just yield and wait for wakeback from managing thread.

(TBD...)
