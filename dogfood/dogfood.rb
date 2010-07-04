puts "<<<<<<<<<<<<<< woof >>>>>>>>>>>>>>>>>>>"

require 'test/unit'

if defined?(SERFS)
  puts "-----------------------------------------------"
  puts "Running embedded...."
  puts "-----------------------------------------------"
  if File.exist?('_SerfsDirInfo_')
    load '_SerfsDirInfo_'
    require "FakeDirSupport"
    Dir.add_fake('Serfs', SerfsDirInfo)
  end

  require 'test_dir_public_class_methods'
end

if defined?(Vendorize)
  puts "-----------------------------------------------"
  puts "Running Vendorize...."
  puts "-----------------------------------------------"
  Vendorize.add_requirable('FakeDirSupport')
  Vendorize.add_requirable('test_dir_public_class_methods')
end
