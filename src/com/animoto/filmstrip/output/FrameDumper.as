package com.animoto.filmstrip.output
{
	import com.animoto.filmstrip.FilmStrip;
	import com.animoto.filmstrip.FilmStripEvent;
	
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	import mx.graphics.ImageSnapshot;
	import mx.graphics.codec.IImageEncoder;
	import mx.graphics.codec.JPEGEncoder;
	import mx.graphics.codec.PNGEncoder;

	public class FrameDumper extends EventDispatcher
	{
		public function get folderPath():String {
			return folderName;
		}
		
		protected var filmStrip: FilmStrip;
		protected var folderName:String;
		protected var extension: String;
		protected var step:Number = 0;
		protected var encoder:IImageEncoder;
		protected var encode:Boolean = false;
		protected var width:Number;
		protected var height:Number;
		protected var frameRate: Number;
		protected var fileBase:File;
		
		public function FrameDumper(filmStrip:FilmStrip, folderName:String, extension:String="") {
			this.filmStrip = filmStrip;
			this.folderName = File.documentsDirectory.nativePath + "/FilmStripOutput/" + folderName;
			if (extension == null) {
				extension = "";
			}
			else if (extension.length>0) {
				if (extension.charAt(0)!=".") {
					extension = extension.slice(1);
				}
				encode = true;
				switch (extension) {
					case ".png": encoder = new PNGEncoder(); break;
					case ".jpg": encoder = new JPEGEncoder(100); break;
				}
			}
			this.extension = extension;
			init();
		}
		
		public function init():void
		{
			filmStrip.addEventListener(FilmStripEvent.FRAME_RENDERED, addFrame);
			filmStrip.addEventListener(FilmStripEvent.RENDER_STOPPED, logStats);
			
			fileBase = new File(folderName);
			if (fileBase.exists) {
				trace("** Moving old FrameDumper directory to trash ('"+ folderName +"') **");
				fileBase.moveToTrash();
			}
			fileBase.createDirectory();
			
			var infoFile:File = fileBase.resolvePath("_info.txt");
			var fs:FileStream = new FileStream(); 
			fs.open(infoFile, FileMode.WRITE);
			fs.writeUTF("filmstrip render: "+filmStrip.width+"x"+filmStrip.height+" @ "+filmStrip.frameRate+"fps"); 
			fs.close();
		}
		
		protected function addFrame(event:FilmStripEvent):void {
			var zeros:String = "0000";
			var path:String = String(step);
			path = zeros.slice(path.length) + path;
			//path = folderName + "/" + ProjectModel.inst().projectName + extension;
			path = folderName + "/" + path + extension;
			var file:File = fileBase.resolvePath(path); 
			var fs:FileStream = new FileStream(); 
			fs.open(file, FileMode.WRITE);
			if (encode) {
				var i:ImageSnapshot = ImageSnapshot.captureImage(event.data, 0, encoder);
				var imagedata:ByteArray = i.data;
				fs.writeBytes(imagedata, 0, imagedata.length);
			}
			else {
				fs.writeBytes(event.data.getPixels(event.data.rect));
			}
			fs.close();
			step++;
		}
		
		protected function logStats(event:FilmStripEvent): void {
			var stats:String = event.stats;
			if (stats!=null && stats.length==0) {
				var statsFile:File = fileBase.resolvePath("_stats.txt");
				var fs:FileStream = new FileStream(); 
				fs.open(statsFile, FileMode.WRITE);
				fs.writeUTF(stats); 
				fs.close();
			}
		}
	}
}