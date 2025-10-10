namespace :branding do
  desc "Convert a logo image to a transparent PNG (requires ImageMagick). USAGE: rake branding:transparent_logo SOURCE=app/assets/images/logo.jpg TARGET=app/assets/images/logo.png"
  task :transparent_logo do
    src = ENV["SOURCE"] || "app/assets/images/logo.jpg"
    dst = ENV["TARGET"] || "app/assets/images/logo.png"
    fuzz = ENV["FUZZ"] || "10%"
    white = ENV["COLOR"] || "white"
    unless File.exist?(src)
      puts "Source not found: #{src}"
      exit 1
    end
    cmd = ["convert", src, "-fuzz", fuzz, "-transparent", white, dst].join(" ")
    puts "Running: #{cmd}"
    system(cmd) || abort("ImageMagick convert failed")
    puts "Wrote: #{dst}"
  end
end
