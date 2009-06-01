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

module AnimotoFilmStrip
  class FramesToVideo

    def initialize(output_path, logger = nil)
      @output_path = output_path
      @logger = logger || Logger.new(output_path + '/video.log')
      FileUtils.mkdir_p(@output_path)
    end
    
    # HACK.  Figure out a better way to do this -- force output frames to be .argb?
    def frames
      Dir["#{@output_path}/0*"]
    end

    def id
      @id = "filmstripVideo"
    end
    
    # convert all ARGB bitmapdata's to jpg
    def convert_to_jpeg
      # input image is ARGB, so first flip "A" (weird part of convert)
      # then shift all channels up one to convert ARGB => RGBA
      # TODO: could probably just kill the first channel and recombine in RGB (don't need alpha)

      frames.each do |image_id|
        FileUtils.chdir(@output_path)
        cmd = "convert -depth 8 -channel A -negate -channel ARGB -separate -swap 0,1 -swap 1,2 -swap 2,3 -combine -size 648x360 rgba:#{image_id} #{image_id}.jpg"
        @logger.info { "#convert_to_jpeg: #{cmd}"}
        `#{cmd}`
      end
    end

    def encode_to_mp4
     # convert_to_jpeg
      2.times do |pass|
        cmd = "ffmpeg -y -s 648x360 -i %04d.jpg -vcodec libx264 -vpre hq -pass #{pass+1} -b 1M -bt 1M -r 24 #{id}.mp4"
        @logger.info { "#encode_to_mp4: #{cmd}"}
        `#{cmd}`
      end
      
      # remove all image files
      #frames.each{ |f| FileUtils.rm_f(f) }
      #FileUtils.rm_f('*.jpg')
    end
    
  end
  
end

output_path = '/Users/moses/Documents/FilmStripOutput/dice_demo_1/'
render = AnimotoFilmStrip::FramesToVideo.new(output_path)
render.encode_to_mp4 rescue nil

