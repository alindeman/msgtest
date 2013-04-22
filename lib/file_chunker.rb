class FileChunker
  include Enumerable

  def initialize(io)
    @io = io
  end

  def each
    while chunk = @io.read(25 * 1024)
      yield chunk
    end
  end
end
