#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'

# Takes in a Nokogiri Node Element
def parse_rows(rows)
  consecutive_elements = 0
  key_count = 0
  previous_count = rows[0].elements.count
  key_row = previous_row = rows[0]

  rows.each do |row|
    row_count = row.elements.count

    if (previous_count == row_count)
      # puts "reaches here"
      consecutive_elements += 1

      if (consecutive_elements > 1 && previous_count > key_count)
        key_count = previous_count
        key_row = previous_row
      end

    else
      consecutive_elements = 1
      previous_row = row
    end

    previous_count = row_count

    # puts "#{row.elements.count} --- previous_count: #{previous_count}, consecutive_elements: #{consecutive_elements}, key_count: #{key_count}"
  end

  return key_count, key_row
end

# Add to the gsub for more flexibility
def format_key(string)
  string.gsub(/[~=:;+-_.]/, '')
end

def is_invalid_field?(string)
  return true if string.empty? || string == '=' # Can Add a Regex Check as well
  return false
end

# Sorts quantity, item description, price based on regex and returns hash
def process_entry(row_node)
  price = row_node.to_s.match(/(\$[0-9,]+(\.[0-9]{2})?)/).to_s
  # price = price[1..price.length-1] # Strips the dollar sign

  quantity = row_node.to_s.match(/>\d+</).to_s
  if quantity.empty?
    quantity = "1" # Default value for quantity
  else
    quantity = quantity[1..quantity.length-2] # Strips the HTML tags off the ends
  end

  item_description = ""
  largest_length = 0

  # Find largest cell content for item description
  row_node.css('td').each do |item|
    if item.content.length > largest_length
      largest_length = item.content.length
      item_description = item.content.split.join(" ")
    end
  end


  hash_output = {
    "quantity" => quantity,
    "item description" => item_description,
    "price" => price
  }

  return hash_output
end


# Program should be able to parse order confirmations from any vendor
if ARGV[0].length > 0
  doc = Nokogiri::HTML(open(ARGV[0])) do |config|
    config.noblanks # Removes blank nodes
  end
else
  # Handle case of invalid input
end

# LOOK AT NUMBER OF TD OBJECTS WITHIN TR < 1, AND HAS MATCHING DATA TR LENGTH !!!!!
json_output = []
keys = []

# Invariance of the problem, guarantees that the series will have at least 3 fields (quantity, item, price)
rows = doc.css('tr').select{|row| row.elements.count > 2 and !row.content.split.join(" ").empty? }#and row.content =~ /\$/}

# Debugging output
# rows.each do |row|
#   puts "#{row.elements.count} #{row.content.split.join(" ")}"
# end
key_count, key_row = parse_rows(rows)
# puts "key_count: #{key_count}"
# puts "key_row: #{key_row}"

key_row_contains_money = key_row.content =~ /\$/

if key_row_contains_money # This mean there were no 'series' headers
  keys = ["quantity", "item description", "price"]

  rows = rows.select{|row| row.content =~ /\$/}
  value_count, value_row = parse_rows(rows)
  # Debugging output
  # rows.each do |row|
  #   puts "#{row.elements.count} #{row.content.split.join(" ")}"
  # end

else
  key_row.css('td').each do |key|
    formatted_key = format_key(key.content.split.join(" ").downcase)
    keys << formatted_key unless formatted_key.empty?
  end
  value_row = key_row
  value_count = key_count
end

# Debugging output
# puts "Keys: #{keys.to_s}\n\n"

keys_length = keys.length
counter = 0
consecutive_items = 0
output_hash = {}

search_row_boolean = key_row_contains_money # This boolean indicates whether to search the cells for default fields

# Formats into JSON given array of keys
rows.each do |row|
  # Each row contains cells of the product (item description, quantity, price)
  unless row.elements.count == value_count
    consecutive_items = 0
    next
  end

  unless key_row_contains_money
    key_row_contains_money = true
    next
  end

  if (consecutive_items > 0 or json_output.empty?)
    # Scan row with regex for values
    if search_row_boolean
      # Debugging output
      # puts "#{row}\n\n"

      json_output << process_entry(row)
    else
      row.css('td').each do |item|
        next if is_invalid_field?(item.content.split.join(" "))
        output_hash[keys[counter]] = item.content.split.join(" ")
        counter += 1
        if (counter == keys_length)
          json_output << output_hash
          counter = 0
          output_hash = {}
        end
      end
    end
  end

  consecutive_items += 1
end

str = json_output.to_s

puts str

# log = File.open("results.txt", "w")
# log.write(str)
# log.close