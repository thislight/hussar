local away = require "away"
local debugger = require "away.debugger"
local RequestRouter = require "hussar.request_router"
local checkers = require "hussar.request_router.checkers"

describe("hussar.checkers", function()
    describe("PATH", function()
        it("return true if request's path is match the rule", function()
            local checker = checkers.PATH("/te(.*)", 'lua')
            local fake_request = {
                path = '/test'
            }
            assert.is.True(checker(fake_request))
        end)
        it("set capture to frame if reuqest's path is match the rule", function()
            local checker = checkers.PATH("/te(.*)", 'lua')
            local fake_request = {
                path = '/test'
            }
            local frame = {}
            assert.is.True(checker(fake_request, frame))
            assert.equals(frame.path_match[1], 'st')
        end)
        it("performance test", function()
            local checker = checkers.PATH("/te(.*)", 'lua')
            local fake_request = {
                path = '/test'
            }
            local fake_request2 = {
                path = '/ptest'
            }
            REPEAT_TIMES = 2^20
            local dataset = {}
            for i=1, REPEAT_TIMES do
                local v = select(math.random(1, 2), fake_request, fake_request2)
                table.insert(dataset, v)
            end
            local t1 = os.time()
            local fake_frame = {}
            local remove = table.remove
            for i=1, REPEAT_TIMES do
                checker(remove(dataset), fake_frame)
            end
            local t2 = os.time()
            local delta = os.difftime(t2, t1)
            -- print(string.format("%s sec for %s requests, %s sec/100 requests", delta, REPEAT_TIMES, delta * 100 / REPEAT_TIMES))
            assert.is.True(delta < 2, string.format("the performance is worst, %s sec for %s requests, %s sec/100 requests", delta, REPEAT_TIMES, delta*100/REPEAT_TIMES))
        end)
    end)
end)
