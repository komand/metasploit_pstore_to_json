require 'httparty'
require 'pstore'
require 'tempfile'
require 'json'

# So we can deserialize the object (pstore needs the class)
module Msf
  module Modules
    module Metadata
      class Obj
      end
    end
  end
end

content = HTTParty.get('https://github.com/rapid7/metasploit-framework/raw/master/db/modules_metadata_base.pstore')

temp = Tempfile.new('pstore')
temp.write(content)
store = PStore.new(temp.path)

items = []
store.transaction(false) do
  store[:module_metadata].each do |item|
    new_item = {}
    the_item = item[1]
    the_item.instance_variables.each do |var|
      contents = the_item.instance_variable_get(var)
      encoded_contents = contents.to_s.force_encoding("UTF-8")
      new_item[var.to_s.gsub('@', '')] = encoded_contents
    end
    items << new_item.to_json
  end
end

puts "Parsed #{items.size} Metasploit modules"
# Checks if metasploit.json exist if so delete
File.delete("metasploit.json") if File.exist?("metasploit.json")
# Adds an item from items
items.each do |item|
  File.open("metasploit.json","a") do |f|
    f.puts(item)  
  end
end

temp.delete