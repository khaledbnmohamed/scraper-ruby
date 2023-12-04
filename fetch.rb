#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'date'
require 'yaml'

def fetch_and_save(url)
  begin
    base_uri = URI.parse(url)
    html = URI.open(url).read
    filename = File.join(Dir.pwd, "#{base_uri.host}#{base_uri.path == '/' ? '' : base_uri.path.gsub(/[^0-9A-Za-z]/, '_')}.html")

    File.open(filename, 'w') { |file| file.write(html) }
    doc = Nokogiri::HTML(html)
    begin
      download_assets(base_uri, doc)
    rescue StandardError => e
      puts "Error downloading assets for #{url}: #{e.message}"
    end
    begin
      create_meta_data_file(doc, filename, url)
    rescue StandardError => e
      puts "Error creating metadata file for #{url}: #{e.message}"
    end
    File.open(filename, 'w') { |file| file.write(doc.to_html) }

    puts "Successfully fetched and saved: #{url}"
  rescue StandardError => e
    puts "Error fetching #{url}: #{e.message}"
  end
end

def download_assets(base_uri, doc)
  puts "Downloading assets for #{base_uri}"
  assets_dir = File.join(Dir.pwd, "#{base_uri.host}_assets")
  Dir.mkdir(assets_dir) unless Dir.exist?(assets_dir)

  doc.css('link[href], script[src], img[src]').each do |element|
    asset_url = URI.join(base_uri, element['href'] || element['src']).to_s
    asset_filename = File.join(assets_dir, "#{File.basename(asset_url)}")

    if !File.exist?(asset_filename)
      asset_content = URI.open(asset_url).read
      File.open(asset_filename, 'w') { |file| file.write(asset_content) }
      puts "Downloaded and saved asset: #{asset_url}"
    else
      puts "Asset already exists: #{asset_url}"
    end

    element['href'] = "./#{base_uri.host}_assets/#{File.basename(asset_url)}" if element['href']
    element['src'] = "./#{base_uri.host}_assets/#{File.basename(asset_url)}" if element['src']
  end

end

def create_meta_data_file(doc, filename, url)
  puts "Creating metadata file for #{url}"

  num_links = doc.css('a').count
  num_images = doc.css('img').count
  last_fetch = DateTime.now
  puts "Debug Filename: #{filename}"
  puts "Debug URL: #{url}"
  puts "Debug num_links: #{num_links}"
  puts "Debug num_images: #{num_images}"
  metadata = {
    site: url,
    num_links: num_links,
    images: num_images,
    last_fetch: last_fetch.strftime('%a %b %d %Y %H:%M:%S UTC')
  }

  File.open("#{filename}.metadata", 'w') { |file| file.write(metadata.to_yaml) }
end

def fetch_urls(urls)
  urls.each { |url| fetch_and_save(url) }
end

def fetch_with_metadata(url)
  fetch_and_save(url)
  base_uri = URI.parse(url)
  puts "Waiting for metadata file for #{base_uri}"
  metadata_filename = File.join(Dir.pwd, "#{base_uri.host}#{base_uri.path == '/' ? '' : base_uri.path.gsub(/[^0-9A-Za-z]/, '_')}.html.metadata")
  if File.exist?(metadata_filename)
    metadata = YAML.load_file(metadata_filename)
    puts "Metadata for #{metadata}"
    puts "site: #{metadata[:site]}"
    puts "num_links: #{metadata[:num_links]}"
    puts "images: #{metadata[:images]}"
    puts "last_fetch: #{metadata[:last_fetch]}"
  else
    puts "Metadata not found for #{url}"
  end
end

## TODO - proper handling
# def await_metadata(url)
#   base_uri = URI.parse(url)

#   puts "Waiting for metadata file for #{base_uri}"
#   metadata_filename = File.join(Dir.pwd, "#{base_uri.host}#{base_uri.path == '/' ? '' : base_uri.path.gsub(/[^0-9A-Za-z]/, '_')}.html.metadata")
#   counter = 0
#   max_attempts = 3
#   while !File.exist?(metadata_filename) && counter < max_attempts
#     sleep(1)
#     counter += 1
#   end
#   unless File.exist?(metadata_filename)
#     puts "Metadata file not found after waiting."
#     exit
#   end
# end

if ARGV.empty?
  puts 'Check the README for usage instructions.'
  exit
end

metadata_flag = ARGV.include?('--metadata')
urls = ARGV.reject { |arg| arg == '--metadata' }

if metadata_flag
  urls.each { |url| fetch_with_metadata(url) }
else
  fetch_urls(urls)
end
