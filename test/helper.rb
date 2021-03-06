$LOAD_PATH << File.join(File.dirname(__FILE__), '../lib')

require 'test/unit'
require 'node'
require 'log_entry.rb'
require 'runner'
require 'pathname'

FIXTURE_ABS_PATH = File.expand_path(File.join( File.dirname(__FILE__) , '/fixtures' ))
FIXTURE_REL_PATH = Pathname.new(FIXTURE_ABS_PATH).relative_path_from(Pathname.new(File.expand_path '.'))
FIXTURE_PATH = FIXTURE_REL_PATH
