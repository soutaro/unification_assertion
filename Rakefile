require "bundler/gem_tasks"

desc "Test the library"
task :test do
  ENV['JSON'] = 'pure'
  ENV['RUBYOPT'] = "-Ilib #{ENV['RUBY_OPT']}"
  exec "ruby", *Dir['./test/*.rb']
end
