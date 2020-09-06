# extconf.rb is used as an install hook for pure ruby gems ONLY
# Create a blank makefile (Required)
# and then use cmake to build the CRT library and copy it to the
# expected location in the gem's bin directory
require 'mkmf'

abort 'Missing cmake' unless find_executable 'cmake'

# create a dummy  makefile
create_makefile ''

# Build bin and copy to expected location
require_relative '../lib/aws-crt/platforms'

Dir.chdir('../') do
  native_dir = File.expand_path('./native')
  build_dir = File.expand_path('build', native_dir)
  FileUtils.mkdir_p(build_dir)
  Dir.chdir(build_dir) do
    config_cmd = "cmake #{native_dir}"
    libcrypto_lib = ENV['LibCrypto_LIBRARY']
    config_cmd += " -DLibCrypto_LIBRARY=\"#{libcrypto_lib}\"" if libcrypto_lib
    libcrypto_include = ENV['LibCrypto_INCLUDE_DIR']
    config_cmd += " -DLibCrypto_LIBRARY=\"#{libcrypto_include}\"" if libcrypto_include
    sh config_cmd
    system "cmake --build #{build_dir}"
  end

  platform = local_platform
  binary_name = crt_bin_name(platform)
  src_name = crt_build_out_path(platform)
  dest_name = "bin/#{platform.cpu}/#{binary_name}"
  FileUtils.mkdir_p("bin/#{platform.cpu}")
  FileUtils.cp(src_name, dest_name, verbose: true)
end
