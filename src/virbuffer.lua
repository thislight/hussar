local away = require "away"
local terr = require "hussar.terr"

local buffer = {
    read = function(self)
        local new_pos = self.pointer + 1
        if #self >= new_pos then
            self.pointer = new_pos
            return self[new_pos]
        else
            self.wakeback_flag = true
            if self.__read then
                self:__read()
            end
            return self:read()
        end
    end,
    has_new_data = function(self)
        return self[self.pointer+1] ~= nil
    end,
    write = function(self, value)
        if self.alive then
            table.insert(self, value)
            self.wakeback_flag = true
            if self.__write then
                self:__write(value)
            end
        else
            terr.errorT('buffer', 'closed', self.closed_reason)
        end
    end,
    is_alive = function(self)
        if self.__is_alive then
            local result = self:__is_alive()
            self.alive = result
            return result
        else
            return self.alive
        end
    end,
    close = function(self, reason)
        self.alive = false
        self.closed_reason = reason
        if self.__closed then
            self:__closed(reason)
        end
    end,
    set_keep_alive = function(self, enable)
        if self.__set_keep_alive then
            self.keep_alive = self:__set_keep_alive(enable)
        else
            self.keep_alive = enable
        end
    end,
    is_keep_alive = function(self)
        if self.__is_keep_alive then
            local result = self:__is_keep_alive()
            self.keep_alive = result
            return result
        else
            return self.keep_alive
        end
    end,
    require_wakeback = function(self)
        local flag = (#self > self.pointer) and self.wakeback_flag
        self.wakeback_flag = false
        return flag
    end,
    gc = function(self)
        for i=1, self.pointer do
            table.remove(self, i)
        end
    end,
}

function buffer.new(options)
    return setmetatable({
        pointer = 0,
        alive = true,
        keep_alive = false,
        wakeback_flag = false,
        __closed = options.__closed,
        __is_alive = options.__is_alive,
        __write = options.__write,
        __read = options.__read,
        __set_keep_alive = options.__set_keep_alive,
        __is_keep_alive = options.__is_keep_alive,
    }, { __index=buffer })
end

return buffer
