local away = require "away"
local httputil = require "hussar.httputil"
local table_deep_copy = require("hussar.utils").table_deep_copy
local powerlog = require "powerlog"
local utils = require "hussar.utils"
local co = coroutine
local insert = table.insert

local function hussar_managing_thread(hussar)
    local logger = hussar.logger:create("managing_thread")
    logger:info("hussar managing thread started")
    while true do
        away.wakeback_later()
        local remove_later_index = {}
        local current_time = hussar.time_provider()
        for i, ds in ipairs(hussar.managed_descriptors) do
            local conn, promised_deadline, frame, binded_thread = table.unpack(ds)
            if not conn:is_keepalive() and current_time > promised_deadline then
                conn:close('timeout')
                table.insert(remove_later_index, i)
            end
        end
        for _, index in ipairs(remove_later_index) do
            table.remove(hussar.managed_descriptors, index)
        end
        logger:debugf("%d descriptor(s) removed", #remove_later_index)
    end
end

local hussar = {
    managed_descriptors = {},
    time_provider = function()
        return os.time()
    end,
    pubframe = {},
    handler = function(conn, frame, pubframe)
        httputil.respond_on(conn) {
            status = 500,
            "Gateway could not handle your request: missing handler. Hussar Web Server/Lua"
        }
    end,
    sources = {},
    logger = powerlog:create("hussar"),
    connection_timeout = 30,
}

function hussar:clone_to(t)
    return table_deep_copy(self, t)
end

function hussar:attach_source(source)
    table.insert(self.sources, source)
end

function hussar:create()
    return self:clone_to {}
end

function hussar:add_connection(connection)
    local priframe = {}
    local promised_deadline = self.time_provider() + self.connection_timeout
    local newthread = self.handler(connection, priframe, self.pubframe)
    insert(self.managed_descriptors, {connection, promised_deadline, priframe, newthread})
    away.schedule_thread(newthread)
    self.logger:infof("new connection")
end

local function prepare_sources(sources, ...)
    for i, v in ipairs(sources) do
        if v.prepare then
            v:prepare(...)
        end
    end
end

local function start_managing_thread(...)
    local thread = coroutine.create(hussar_managing_thread)
    coroutine.resume(thread, ...)
end

function hussar:start()
    assert(self.handler, "handler is not set")
    prepare_sources(self.sources, self)
    start_managing_thread(self)
end

return hussar
