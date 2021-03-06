require 'strscan'

require_relative 'node'
require_relative 'parse_error'
require_relative 'position_info'
require_relative 'encoding_error'

module XRay
  
  class BaseParser

    attr_reader :log

    def initialize(text, log = nil)
      super()

      @log = log
      text = filter_text(prepare_text(text))
      @pos_info = PositionInfo.new text
      @scanner = StringScanner.new text
    end

    def skip_empty
      @scanner.skip /\s*/
    end
      
    def skip(pattern)
      skip_empty
      unless @scanner.skip pattern
        parse_error "skip fail: #{pattern}"
      end
    end
      
    def scan(pattern)
      skip_empty
      pos = @pos_info.locate(@scanner.pos)
      text = @scanner.scan pattern
      text ? Node.new(text, pos) : parse_error("scan fail: #{pattern}")
    end
      
    def batch(name, &block)
      result = []
      while !@scanner.eos? && (block ? block.call : true) && item = send(name)
        result << item
      end
      result
    end
    
    def to_s
      self.class.to_s
    end

    def reset
      @scanner.reset
    end

    protected
    
    def filter_text(text)
      text
    end
    
    def parse_warn(message)
      pos = scanner_pos
      log "#{message}#{pos}", :warn
    end

    def parse_error(message)
      pos = scanner_pos
      log "#{message}#{pos}", :error
      raise ParseError.new(message, pos)
    end
      
    def log(message, level = :info)
      @log && @log.send(level, self.to_s + ': ' + message)
    end

    private

    def prepare_text(text)
      text.gsub(/\r\n/, "\n").gsub(/\r/, "\n")
    end

    def scanner_pos
      pos = @scanner.pos
      @pos_info.locate(@scanner.eos? ? pos -1 : pos)
    end

  end

end
