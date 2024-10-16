--!nonstrict
--!optimize 2

type Queue<T> = {
    _buffer: { T },
    _head: number,
    _tail: number,
    _size: number,
    _capacity: number,
    new: (n: number?) -> Queue<T>,
    Enqueue: (self: Queue<T>, item: T) -> (),
    Dequeue: (self: Queue<T>) -> T?,
    Peek: (self: Queue<T>) -> T?,
    Clear: (self: Queue<T>) -> (),
    Size: (self: Queue<T>) -> number,
    Capacity: (self: Queue<T>) -> number,
    IsEmpty: (self: Queue<T>) -> boolean,
    Iter: (self: Queue<T>) -> () -> (number?, T?),
    _Resize: (self: Queue<T>, capacity: number) -> ()
}

local Queue = {}
Queue.__index = Queue

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

function Queue.new<T>(n: number?): Queue<T>
   local self = setmetatable({}, Queue)
   self._capacity = Next(n or 32)
   self._buffer = table.create(self._capacity) :: { T? }
   self._head = 0
   self._tail = 0
   self._size = 0
   return self :: Queue<T>
end

function Queue.Enqueue<T>(self: Queue<T>, item: T): ()
    if self._size == self._capacity then
        self:_Resize(self._capacity * 2)
    end
    self._buffer[self._tail + 1] = item
    self._tail = bit32.band(self._tail + 1, self._capacity - 1)
    self._size += 1
end

function Queue.Dequeue<T>(self: Queue<T>): T?
    if self._size == 0 then
        return nil
    end
    local item = self._buffer[self._head + 1]
    self._buffer[self._head + 1] = nil
    self._head = bit32.band(self._head + 1, self._capacity - 1)
    self._size -= 1
    if self._size < self._capacity // 8 and self._capacity > 32 then
        self:_Resize(self._capacity // 2)
    end
    return item
end

function Queue.Peek<T>(self: Queue<T>): T?
    return self._size > 0 and self._buffer[self._head + 1] or nil
end

function Queue.Clear<T>(self: Queue<T>): ()
    table.clear(self._buffer)
    self._head = 0
    self._tail = 0
    self._size = 0
end

function Queue.Size<T>(self: Queue<T>): number
    return self._size
end

function Queue.Capacity<T>(self: Queue<T>): number
    return self._capacity
end

function Queue.IsEmpty<T>(self: Queue<T>): boolean
    return self._size == 0
end

function Queue._Resize<T>(self: Queue<T>, newCapacity: number): ()
    newCapacity = Next(newCapacity)
    if newCapacity == self._capacity then 
        return 
    end
    
    local newBuffer = table.create(newCapacity)
    if self._tail > self._head then
        table.move(self._buffer, self._head + 1, self._tail, 1, newBuffer)
    else
        local firstPart = self._capacity - self._head
        table.move(self._buffer, self._head + 1, self._capacity, 1, newBuffer)
        table.move(self._buffer, 1, self._tail, firstPart + 1, newBuffer)
    end
    
    self._buffer = newBuffer
    self._head = 0
    self._tail = self._size
    self._capacity = newCapacity
end

function Queue.Iter<T>(self: Queue<T>): () -> (number?, T?)
    local i = 0
    local size = self._size
    return function(): (number?, T?)
        if i < size then
            i += 1
            local index = bit32.band(self._head + i - 1, self._capacity - 1) + 1
            return i, self._buffer[index]
        end
        return nil, nil
    end
end

return Queue
