insulate("hussar.source.fake", function()
    local fake = require "hussar.source.fake"
    describe("can created as a object", function()
        local obj = fake:create()
        assert.is.truthy(obj)
    end)
end)