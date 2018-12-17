#!/usr/bin/env ruby

require 'tmpdir'
require 'fileutils'
require 'uri'

workspace_dir = ARGV[0]
output_dir    = ARGV[1]
cache_dir     = ARGV[2]

# Main method
def call(workspace_dir, output_dir, cache_dir)
  bundler_version = "1.17.2".chomp
  bundler_name    = "bundler-#{bundler_version}"

  ENV["LANG"] = "en_US.UTF-8"
  ENV["GEM_HOME"] = workspace_dir


  bootstrap_ruby(cache_dir: cache_dir)

  puts run("ruby -v")
  puts run("which ruby")

  # calling `ruby -S` to avoid getting strange
  # shebang lines like `#!/usr/bin/env ruby2.5`
  puts run("ruby -S gem install bundler --env-shebang -v #{bundler_version} --no-ri --no-rdoc")

  run("rm -rf #{workspace_dir}/cache/#{bundler_name}.gem") # smaller output
  run("mkdir #{bundler_name}")
  run("tar -cvzf #{output_dir}/#{bundler_name}.tgz -C #{workspace_dir} .")
end

def run(cmd)
  puts "Running: #{cmd.inspect}"
  out = `#{cmd}`
  raise "Error: #{out.inspect}" unless $?.success?
  out
end

def fetch(url, name = nil)
  uri    = URI.parse(url)
  binary = uri.to_s.split("/").last
  if File.exists?(binary)
    puts "Using #{binary}"
  else
    puts "Fetching #{binary}"
    if name
      run "curl #{uri} -s -o #{name}"
    else
      run "curl #{uri} -s -O"
    end
  end
end

def bootstrap_ruby(cache_dir:, ruby_version: '2.5.3')
  FileUtils.mkdir_p(cache_dir)

  ruby_name = "ruby-#{ruby_version}"
  Dir.chdir(cache_dir) do
    vendor_url = "https://s3.amazonaws.com/heroku-buildpack-ruby"
    fetch("#{vendor_url}/heroku-18/#{ruby_name}.tgz")

    run("tar zxf #{ruby_name}.tgz") unless File.exists?('bin/ruby')
  end
  ENV["PATH"] = "#{File.join(cache_dir, "bin")}:#{ENV["PATH"]}"
end

call(workspace_dir, output_dir, cache_dir)
