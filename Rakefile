require 'rake'
require 'rspec/core/rake_task'

task :spec => 'spec:all'
task :default => :spec

hosts = File.read('hosts').split("\n")

namespace :spec do
  task :all => hosts.map {|h| 'spec:' + h }
  hosts.each do |host|

    desc "Run serverspec to #{host}"
    RSpec::Core::RakeTask.new(host) do |t|
      ENV['TARGET_HOST'] = host
      t.pattern = "spec/*/*_spec.rb"
    end
  end
end
