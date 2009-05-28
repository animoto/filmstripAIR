# SETUP:
# Install macports:
#   -follow xcode install stuff
#   -install dmg
#   -if PATH doesn't have /opt/local, add this to .bash_profile:
#   PATH=/opt/local/bin:/opt/local/sbin/:$PATH

# Install apps:
#   sudo port install ffmpeg +lame +libogg +vorbis +faac +faad +xvid +x264 
#   sudo port install imagemagick


# make this a task
# create ~/.ffmpeg dir and download presets
# def install_presets
#   FileUtils.mkdir('~/.ffmpeg')
#   FileUtils.chdir('~/.ffmpeg')
#   %w(default fastfirstpass normal hq max).each do |preset|
#     `wget http://rob.opendot.cl/wp-content/files/libx264-#{preset}.ffpreset`
#   end
# end

require 'benchmark'
require 'fileutils'
require 'logger'

module Animotor
  class AvreRenderer

    # constants required for running our SWF through ADL
    ADL_PATH = '/Applications/Adobe Flex Builder 3/sdks/3.2.0/bin/adl'
    XML_PATH = # '/Users/moses/Documents/Flex Builder 3/AnimotorEditor_2/bin-debug/AnimotorEditor_2-app.xml'
              '/Users/moses/Documents/Flex Builder 3/AnimotorEditor_2/bin-debug/AnimotorEditor_2-app.xml'
    
    # Class method for running a batch of descriptor renders
    # requires path to descriptor files, output path, and optional logger
    def self.batch(descriptor_path, output_root, _logger=nil)
      @@logger = _logger || Logger.new(STDOUT)
      
      # create riff => descriptor_filename hash mapp
      riffs = {}
      Dir[ descriptor_path + '/*.xml' ].each{ |r| riffs[ File.basename(r).to_i] = r }
      
      # loop from oldest to newest
      riffs.sort.reverse.each do |riff, descriptor_filename|
        output_path = output_root + '/' + File.basename(descriptor_filename).chomp('.xml')
        render = Animotor::AvreRenderer.new(descriptor_filename, output_path, @@logger)
        render.start rescue nil
        sleep 2
      end      
    end
    
    def initialize(_descriptor_filename, _output_path, logger = nil)
      @descriptor_filename = _descriptor_filename
      @output_path = _output_path
      @logger = logger || Logger.new(STDOUT)
      FileUtils.mkdir_p(@output_path)
    end
    
    def id
      @id ||= File.basename(@descriptor_filename).chomp('.xml')
    end
    
    def start
      render_frames
#      encode_to_mp4
    end
    
    def render_frames
      @logger.info { "Rendering #{id}"}
      cmd = "'#{ADL_PATH}' '#{XML_PATH}' -- -file all_descriptors/#{File.basename(@descriptor_filename)} -folder #{@output_path}"
      result = ""
      process_time = Benchmark.realtime do
        @logger.info { "CMD: #{cmd}"}
        result = `#{cmd}`
      end
      if $?.success?
        @logger.info{ "#{id}: #{process_time.to_i} seconds, #{frames.length} frames, #{ (frames.length / process_time) } f/s" }
      else
         @logger.info{ "FATAL ERROR: #{result}" }
      end
    end
    
    # HACK.  Figure out a better way to do this -- force output frames to be .argb?
    def frames
      Dir["#{@output_path}/0*"]
    end
    
    # convert all ARGB bitmapdata's to jpg
    def convert_to_jpeg
      # input image is ARGB, so first flip "A" (weird part of convert)
      # then shift all channels up one to convert ARGB => RGBA
      # TODO: could probably just kill the first channel and recombine in RGB (don't need alpha)

      frames.each do |image_id|
        FileUtils.chdir(@output_path)
        cmd = "convert -depth 8 -channel A -negate -channel ARGB -separate -swap 0,1 -swap 1,2 -swap 2,3 -combine -size 864x480 rgba:#{image_id} #{image_id}.jpg"
        @logger.info { "#convert_to_jpeg: #{cmd}"}
        `#{cmd}`
      end
    end

    def encode_to_mp4
      convert_to_jpeg
      2.times do |pass|
        cmd = "ffmpeg -y -s 864x480 -i %04d.jpg -vcodec libx264 -vpre hq -pass #{pass+1} -b 1M -bt 1M -r 24 #{id}.mp4"
        @logger.info { "#encode_to_mp4: #{cmd}"}
        `#{cmd}`
      end

      frames.each{ |f| FileUtils.rm_f(f) }
      FileUtils.rm_f('*.jpg')
    end
    
  end
  
end

descriptor_source = #'/Users/moses/Library/Preferences/AnimotorEditor-2/Local Store/all_descriptors'
 '/Users/moses/Library/Preferences/AnimotorEditor-2/Local Store/select_descriptors'
output_path = #'/Users/moses/code/v6_tests'
 '/Users/moses/Documents/Animotor_Player/riff_tests_v6'
Animotor::AvreRenderer.batch(descriptor_source, output_path, Logger.new(output_path + '/descriptor_renderer.log'))

