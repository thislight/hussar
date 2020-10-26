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

(TBD...)
