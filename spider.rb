require 'net/http'

# Crawl the Hype Machine for links to blog posts.
# Crawls using search terms if provided, else crawls what's popular.
# Crawls each blog post for links to MP3 files. 
# Creates a directory for each blog post, stores a link to the post, 
# and downloads and stores the MP3 files in the directory.

# Invoke:
#     stebbi$ ruby spider.rb
# or
#     stebbi$ ruby spider.rb "tom waits"
#
# Run the script in the desired download directory. 

# This script doesn't store the artist and track names. 

class HypeLover 

  # Crawls the hype machine to find blog posts.
  def crawl_hype(terms = nil)
  	print 'Crawling ' << (terms ? terms : '') << "\n"
    scan_html_for_links(
      'http://hypem.com/' + (terms ? 'search/' + terms : 'popular'), 
      /<a.*href=\"(http[\S]*)\".*>read &#187;<\/a>/i
    ) { |u| crawl_blog(u) } 
    nil
  end

  # Crawls a blog post, saves link and MP3 files to disk.
  # Don't leave files lying around, they may get in the way of directory creation!
  def crawl_blog(u)
    print 'Scanning ' << u << "\n"
    begin
      fn = uri_to_dirname(u)
      Dir.mkdir(fn) unless File.exists?(fn)
      Dir.chdir(fn) do 
        save_webloc(u)
        scan_html_for_links(u, /href="([^"]*\.mp3)"/i) { |v| download_song(v) }
      end
    rescue Exception => x 
      fail(u, x) 
    end
  end

  # Only works if the regex payload is in the first capturing group!
  # If regex payload is relative it is made absolute using the # parameter URL.
  # Takes a block and invokes for each regex match.
  def scan_html_for_links(u, rx)
    print 'Scanning ' << u << "\n"
    m = Net::HTTP.get_response(URI.parse(URI.escape(u))).body.scan(rx)
    m.each_index do |i| 
      pl = m[i][0]
      pl = pl.index('http://') ? pl : u.match(/http:\/\/[^\/]*/i)[0] + pl 
      yield(pl)
    end
  end

  # Download the resource behind a given URL and save it to disk.
  def download_song(u)
    print 'Downloading ' << u << "\n"
    begin
      r = Net::HTTP.get_response(URI.parse(URI.escape(u)))
      write_file(uri_to_filename(u), r.body)
      sleep(2 * 60) # Sleep 2 minutes between songs
    rescue Exception => x 
      fail(u, x) 
    end
  end

  def save_webloc(u) 
    webloc = <<WEBLOC
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>URL</key>
    <string>#{u}</string>
  </dict>
</plist>
WEBLOC
    write_file(uri_to_webloc_filename(u), webloc)
  end

  def uri_to_filename(u)
    URI.unescape(u).sub(/[^\?]*\//i, '').sub(/\?.*/i, '')
  end

  def uri_to_dirname(u)
    URI.unescape(u).sub(/http:\/\//i, '').sub(/\?.*/i, '').gsub(/\//, ':')
  end

  def uri_to_webloc_filename(u)
    uri_to_dirname(u) + '.webloc'
  end

  def write_file(filename, data)
    f = File.new(filename, File::CREAT|File::TRUNC|File::RDWR, 0644)
    f.write(data)
    f.close
  end

  # Be apologetic :)
  def fail(u, x)
    print "\t" << u << "\n\t" << x.message << "\n"
  end
end

HypeLover.new().crawl_hype(ARGV.size > 0 ? ARGV[0] : nil)
