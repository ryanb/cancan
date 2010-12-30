require 'rubygems'
require 'rake'
require 'rspec/core/rake_task'

desc "Run RSpec"
RSpec::Core::RakeTask.new do |t|
  t.verbose = false
end

desc "Run specs for all adapters"
task :spec_all do
  %w[active_record data_mapper mongoid].each do |model_adapter|
    puts "MODEL_ADAPTER = #{model_adapter}"
    system "rake spec MODEL_ADAPTER=#{model_adapter}"
  end
end

task :default => :spec
