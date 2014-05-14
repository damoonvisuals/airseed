# Make sure your permissions are set for execution:
  chmod 755 extraction.rb

# To run the test enter the right HTML file:
  ./extraction.rb <enter filename here>.html

# The program is set to print on the command line
  dasun@bulletbill:~/Applications/jobs/Airseed$ ./extraction.rb seamless.html
  [{"quantity"=>"1", "item description"=>"Hong Kong-Style Noodle", "price"=>"$8.95"}, {"quantity"=>"1", "item description"=>"Beef with Broccoli", "price"=>"$10.50"}, {"quantity"=>"1", "item description"=>"Cilantro Shrimp Dumpling", "price"=>"$5.95"}]

### Configuraton Options ###

# To output to file, uncomment the lines:
  # log = File.open("results.txt", "w")
  # log.write(str)
  # log.close


# To change the default output keys, edit the method process_entry(row_node)
  hash_output = {
    "quantity" => quantity,
    "item description" => item_description,
    "price" => price
  }


# To change key formatting (from scraping), edit the regex in the format_key(string) method
  def format_key(string)
    string.gsub(/[~=:;+-_.]/, '')
  end


# To change how fields are processed (skips HTML node on is_format_invalid?), edit the method to include more cases:
  def is_invalid_field?(string)
    return true if string.empty? || string == '=' # Can Add a Regex Check as well
    return false
  end