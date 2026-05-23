module RoadToRubykaigi
  class RingBuffer
    attr_reader :size, :capacity

    # @yield expected to return a fresh slot value; called capacity times.
    def initialize(capacity, &block)
      @capacity = capacity
      @head = 0
      @size = 0
      @buffer = []
      i = 0
      while i < capacity
        @buffer << block.call
        i += 1
      end
    end

    def write
      idx = (@head + @size) % @capacity
      if @size < @capacity
        @size += 1
      else
        @head = (@head + 1) % @capacity
      end
      @buffer[idx]
    end

    # i-th slot from the oldest (0 = oldest, size-1 = newest).
    def at(i)
      @buffer[(@head + i) % @capacity]
    end

    def first
      return nil if @size == 0
      @buffer[@head]
    end

    def last
      return nil if @size == 0
      @buffer[(@head + @size - 1) % @capacity]
    end

    def empty?
      @size == 0
    end

    # Drops the oldest entry. Does not free the slot; just advances head.
    def shift
      return if @size == 0
      @head = (@head + 1) % @capacity
      @size -= 1
    end
  end
end
