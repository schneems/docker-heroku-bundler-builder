#!/usr/bin/env ruby

require 'tmpdir'
require 'fileutils'
require 'uri'

# Arguments set by default args in Dockerfile
# the output directory is volume mounted to local /builds
# via the `-v` command in `build.sh`
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

  install_from_rubygems(bundler_version)
  # install_from_github(
  #   repo: "schneems/bundler",
  #   bundler_name: bundler_name,
  #   branch: "schneems/bundler-1-17-3-stable"
  # )

  run("rm -rf #{workspace_dir}/cache/#{bundler_name}.gem") # smaller output
  run("mkdir #{bundler_name}")
  run("tar -cvzf #{output_dir}/#{bundler_name}.tgz -C #{workspace_dir} .")
end


def install_from_rubygems(bundler_version)
  # calling `ruby -S` to avoid getting strange
  # shebang lines like `#!/usr/bin/env ruby2.5`
  puts run("ruby -S gem install bundler -v #{bundler_version} --env-shebang --no-ri --no-rdoc")
end

def install_from_github(repo: "bundler/bundler", branch: nil, cherry_pick: nil, bundler_name: )
  puts run("git clone https://github.com/#{repo}")
  Dir.chdir("bundler") do
    puts run("git checkout #{branch}") if branch

    if cherry_pick
      run('git config --global user.email "you@example.com"')
      run('git config --global user.name "Your Name"')
      puts run("git cherry-pick #{cherry_pick}")
    end

    # calling `ruby -S` to avoid getting strange
    # shebang lines like `#!/usr/bin/env ruby2.5`
    puts run("ruby -S gem build -V bundler.gemspec")
    puts run("ruby -S gem install ./#{bundler_name}.gem --local --env-shebang --no-ri --no-rdoc")
  end
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
