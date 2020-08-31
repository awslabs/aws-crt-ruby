require 'mkmf'

abort 'Missing cmake' unless find_executable 'cmake'

# create a dummy  makefile
create_makefile ''

# Build bin and copy to expected location
require_relative '../lib/aws-crt/platforms'

Dir.chdir('../') do
  native_dir = File.expand_path('./native')
  build_dir = File.expand_path('build', native_dir)
  if !Dir.exist?(build_dir)
    Dir.mkdir(build_dir)
  end
  Dir.chdir(build_dir) do
    system "cmake #{native_dir}"
    system "cmake --build #{build_dir}"
  end

  platform = local_platform
  binary_name = PLATFORM_BINARIES[platform]
  src_name = "native/build/#{binary_name}"
  dest_name = "bin/#{platform}/#{binary_name}"
  FileUtils.mkdir_p("bin/#{platform}")
  FileUtils.cp(src_name, dest_name, verbose: true)
end
