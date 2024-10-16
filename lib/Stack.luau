--!nonstrict
--!optimize 2

type Stack<T> = {
    _buffer: { T },
    _top: number,
    _capacity: number,
    new: (n: number?) -> Stack<T>,
    Push: (self: Stack<T>, item: T) -> (),
    Pop: (self: Stack<T>) -> T?,
    Peek: (self: Stack<T>) -> T?,
    Clear: (self: Stack<T>) -> (),
    Size: (self: Stack<T>) -> number,
    Capacity: (self: Stack<T>) -> number,
    IsEmpty: (self: Stack<T>) -> boolean,
    Iter: (self: Stack<T>) -> () -> (number?, T?),
    _Resize: (self: Stack<T>, capacity: number) -> ()
}

local Stack = {}
Stack.__index = Stack

local function Next(n: number): number
    n = math.max(n, 1)
    n -= 1
    n = bit32.bor(n, bit32.rshift(n, 1))
    n = bit32.bor(n, bit32.rshift(n, 2))
    n = bit32.bor(n, bit32.rshift(n, 4))
    n = bit32.bor(n, bit32.rshift(n, 8))
    n = bit32.bor(n, bit32.rshift(n, 16))
    return n + 1
end

function Stack.new<T>(n: number?): Stack<T>
   local self = setmetatable({}, Stack)
   self._capacity = Next(n or 32)
   self._buffer = table.create(self._capacity) :: { T? }
   self._top = 0
   return self :: Stack<T>
end

function Stack.Push<T>(self: Stack<T>, item: T): ()
    if self._top == self._capacity then
        self:_Resize(self._capacity * 2)
    end
    self._top += 1
    self._buffer[self._top] = item
end

function Stack.Pop<T>(self: Stack<T>): T?
    if self._top == 0 then
        return nil
    end
    local item = self._buffer[self._top]
    self._buffer[self._top] = nil
    self._top -= 1
    if self._top < self._capacity // 8 and self._capacity > 32 then
        self:_Resize(self._capacity // 2)
    end
    return item
end

function Stack.Peek<T>(self: Stack<T>): T?
    return self._top > 0 and self._buffer[self._top] or nil
end

function Stack.Clear<T>(self: Stack<T>): ()
    table.clear(self._buffer)
    self._top = 0
end

function Stack.Size<T>(self: Stack<T>): number
    return self._top
end

function Stack.Capacity<T>(self: Stack<T>): number
    return self._capacity
end

function Stack.IsEmpty<T>(self: Stack<T>): boolean
    return self._top == 0
end

function Stack._Resize<T>(self: Stack<T>, newCapacity: number): ()
    newCapacity = Next(newCapacity)
    if newCapacity == self._capacity then return end
    
    local newBuffer = table.create(newCapacity)
    table.move(self._buffer, 1, self._top, 1, newBuffer)
    
    self._buffer = newBuffer
    self._capacity = newCapacity
end

function Stack.Iter<T>(self: Stack<T>): () -> (number?, T?)
    local i = self._top + 1
    return function(): (number?, T?)
        i -= 1
        if i > 0 then
            return i, self._buffer[i]
        end
        return nil, nil
    end
end

return Stack