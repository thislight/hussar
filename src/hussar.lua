local away = require "away"
local httputil = require "hussar.httputil"
local table_deep_copy = require("hussar.utils").table_deep_copy
local powerlog = require "powerlog"
local utils = require "hussar.utils"

local hussar = {}

function hussar:clone_to(new_t)
    return table_deep_copy(self, new_t)
end

local function new_error_thread(f, hussar_t)
    local th = coroutine.create(f)
    coroutine.resume(th, hussar_t)
    return th
end

function hussar:create()
    local r = self:clone_to {
        sources = {},
        td = {},
        pubframe = {},
        timeout = 15,
        logger = powerlog:create('hussar'),
        error_thread = new_error_thread(function(self)
            local logger = self.logger:create("error_thread")
            while true do
                local signal = coroutine.yield()
                logger:error("user thread error", nil, signal.err)
                httputil.respond_on(signal.connection) {
                    status_code = 500,
                    "Server Internal Error"
                }
            end
        end),
    }
    r.logger.accept_level = 40
    return r
end

function hussar:attach_source(source)
    table.insert(self.sources, source)
    if source.prepare then
        source:prepare(self)
    end
end

local function conn_hander(conn, frame, pubframe, handler, error_thread)
    coroutine.yield() -- break point, only run handler after scheduled
    local stat, err = pcall(handler, conn, frame, pubframe)
    if not stat then
        coroutine.yield {
            target_thread = error_thread,
            connection = conn,
            err = err,
            frame = frame,
            pubframe = pubframe,
            handler = handler,
        }
    else
        if not conn:set_keep_alive() then
            conn:close()
        end
    end
end

function hussar:start_connection_thread(conn, promised_endtime)
    local new_thread = coroutine.create(conn_hander)
    local descriptor = self:register_connection(conn, new_thread, promised_endtime)
    local frame = descriptor[4]
    coroutine.resume(new_thread, conn, frame, self.pubframe, self.handler, self.error_thread)
    away.schedule_thread(new_thread)
end

function hussar:register_connection(conn, target_thread, promised_endtime)
    local frame = {}
    local descriptor = {conn, target_thread, promised_endtime, frame}
    table.insert(self.td, descriptor)
    return descriptor
end

function hussar:pull()
    local result = {}
    for _, source in ipairs(self.sources) do
        if source.pull then
            local new_conns = source:pull()
            table.move(new_conns, 1, #new_conns, #result+1, result)
        end
    end
    return result
end

local function hussar_thread(self, self_thread)
    local timeout = self.timeout
    local user_handler = self.handler
    local logger = self.logger
    logger:debugf("main thread have been started")
    while true do
        utils.yield_wakeback()
        logger:debugf("make sure wakeback")
        local curr_time = os.clock() -- TODO: user-defined time provider
        ---- Check Old Connections ----
        do
            local to_removes = {}
            local insert = table.insert
            local unpack = table.unpack
            local costatus = coroutine.status
            for i, D in ipairs(self.td) do
                local conn, thread, promised_endtime = unpack(D)
                if promised_endtime and promised_endtime >= curr_time then
                    if conn:is_keep_alive() then
                        D[3] = nil
                    elseif conn:is_alive() then
                        conn:write(httputil.response {
                            status_code = 504,
                            "Gateway Timeout."
                        })
                        conn:close('timeout')
                    end
                end
                if (not conn:is_alive()) or (costatus(thread) == "dead") then
                    insert(to_removes, i)
                end
            end
            local remove = table.remove
            for _, real_i in ipairs(to_removes) do
                remove(self.td, real_i)
            end
            logger:debugf("%d connections have been removed", #to_removes)
        end
        ---- Pull New Connections Back ----
        local promised_deadline = curr_time + timeout
        if user_handler then
            logger:debugf("pulling new connections")
            local new_connections = self:pull()
            for _, conn in ipairs(new_connections) do
                self:start_connection_thread(conn, promised_deadline)
            end
            if #new_connections > 0 then
                logger:debugf("pulled %d new connection(s)", #new_connections)
            end
        end
    end
end

function hussar:start_main_thread()
    self.main_thread = coroutine.create(hussar_thread)
    local stat, err = coroutine.resume(self.main_thread, self, self.main_thread)
    if not stat then
        self.logger:crash("main thread have been exited", nil, err)
    end
end

function hussar:start()
    self.logger:infof("server is starting")
    if not self.handler then
        self.logger:warnf("handler have not been set, you should use pull() and register_connection() to manage new connection manually.")
    end
    self:start_main_thread()
end

return hussar