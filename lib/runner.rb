require 'logger'
require_relative 'parser_visitable'
require_relative 'file_validator'
require_relative 'log_entry'
require_relative 'css/reader'
require_relative 'css/parser'
require_relative 'css/rule/check_list_rule'
require_relative 'css/rule/check_file_name_rule'
require_relative 'css/rule/check_compression_rule'
require_relative 'html/parser'


module XRay

  class Runner

    CSS = XRay::CSS
  
    def initialize(opt={})
      @opt = {
        :encoding => 'utf-8',
        :debug    => false
      }.merge opt

      @logger = Logger.new(STDOUT)
      @logger.level = @opt[:debug] ? Logger::INFO : Logger::WARN
      @results = []
    end

    def check_css(css, opt={})
      @text = css
      parser = CSS::Parser.new(css, @logger)
      visitor = CSS::Rule::CheckListRule.new( opt )

      parser.add_visitor visitor

      begin
        parser.parse_stylesheet
      rescue ParseError => e
        puts "#{e.message}#{e.position}"
      ensure
        @results = parser.results
      end

      [!e && success? , @results]
    end

    def check_css_file( file, opt={} )
      file_results, syntax_results, other_results = [],[],[]
      begin
        file_val = FileValidator.new @opt.merge(opt)
        file_val.add_validator CSS::Rule::FileNameChecker.new( @opt.merge opt )
        file_val.add_validator CSS::Rule::CompressionChecker.new( @opt.merge opt )
        file_good, file_results = file_val.validate file
        @source = CSS::Reader.read( file, @opt )
        syntax_good, syntax_results = check_css @source, opt.merge({
          :scope => file =~ /[\\\/]lib[\\\/]/ ? 'lib' : 'page'
        })
        [file_good && syntax_good, file_results + syntax_results]
      rescue  EncodingError => e
        other_results = [LogEntry.new( "File can't be read as #{@opt[:encoding]} charset", :fatal)]
      rescue => e
        other_results = [LogEntry.new( e.to_s, :fatal )]
      ensure
        @results = file_results + syntax_results + other_results
      end
      [@results.empty?, @results]
    end

    def check_js(text)
      true
    end

    def check_js_file(file)
      true
    end

    def check_html(text)
      @text = text
      parser = HTML::Parser.new(text, @logger)
      #visitor = HTML::Rule::CheckListRule.new( opt )
      #parser.add_visitor visitor

      begin
        parser.parse_html
      rescue ParseError => e
        puts "#{e.message}#{e.position}"
      ensure
        @results = parser.results
      end

      [!e && success? , @results]
    end

    def check_html_file(file)
      true
    end

    def check_file( file )
      send( :"check_#{Runner.file_type file}_file", file ) if Runner.style_file? file
    end

    def print_results( opt={} )
      opt = @opt.merge opt
      prf = opt[:prefix] || ''
      suf = opt[:suffix] || ''
      @results.each do |r|
        t = r.send( opt[:colorful] ? :to_color_s : :to_s )
        puts prf + t + suf
      end
    end

    def print_results_with_source( opt={} )
      opt = @opt.merge opt
      if @source
        lines = @source.gsub(/\r\n/, "\n").gsub(/\r/, "\n").split("\n")
        prf = opt[:prefix] || ''
        suf = opt[:suffix] || ''
        @results.each do |r|
          col = r.column
          row = r.row
          t = r.send( opt[:colorful] ? :to_color_s : :to_s )
          if row
            line_t = lines[row]
            left = col - 50
            right = col + 50
            left = 0 if left < 0
            puts prf + lines[row][left..right]
            puts prf + ' ' * (col - left) << '^ ' << t
            puts "\n"
          else
            puts t + suf + "\n"
          end
        end
      else
        print_results
      end
    end

    def valid_file? file
      is_style = Runner.style_file?(file)
      type_match = Runner.file_type(file) == @opt[:type] || !@opt[:type]
      is_style and type_match
    end

    def success?
      @results.each do |r|
        if %w(fatal error warn).include? r.level.to_s
          return false
        end
      end
      true
    end

    def self.file_type( name )
      f = File.extname( name )
      if f =~ /\.css$/i
        'css'
      elsif f =~ /\.js/i
        'js'
      else
        'html'
      end
    end

    def self.style_file?( name )
      File.extname( name ) =~ /(css|js|html?)$/i
    end

  end
end
