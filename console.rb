require 'irb'
require 'dotenv'
require 'json'

path = File.expand_path('models', File.dirname(__FILE__))
Dir[path+"/**/*.rb"].each {|file| require file}

APP_ENV = ARGV[0] || "development"

Dotenv.load(".#{APP_ENV}.env", "private-conf/.env")

puts "Console loaded with env : #{APP_ENV}"
puts "to run in production: ruby console.rb production" if APP_ENV == "development"

module IRB
  def self.start_session(binding)
    unless @__initialized
      args = ARGV
      ARGV.replace(ARGV.dup)
      IRB.setup(nil)
      ARGV.replace(args)
      @__initialized = true
    end

    workspace = WorkSpace.new(binding)

    irb = Irb.new(workspace)

    @CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
    @CONF[:MAIN_CONTEXT] = irb.context

    catch(:IRB_EXIT) do
      irb.eval_input
    end
  end
end

IRB.start_session(binding)
