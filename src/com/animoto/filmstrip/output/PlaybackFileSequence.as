package com.animoto.filmstrip.output
{
	import flash.desktop.NativeApplication;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import mx.core.Application;
	import mx.core.UIComponent;

	public class PlaybackFileSequence extends UIComponent
	{
		public var timer: Timer = new Timer(0);
		
		public var currentFrame: int = -1;
		
		protected var loader:Loader;
		protected var bitmap:Bitmap = new Bitmap();
		protected var loadStep:int = 0;
		protected var files:Array;
		protected var fileStream:FileStream = new FileStream();
		protected var pausedTF: TextField = new TextField();
		protected var playing:Boolean = false;
		protected var w:int;
		protected var h:int;
		
		public function PlaybackFileSequence()
		{
			timer.addEventListener(TimerEvent.TIMER, addImage);
			browse();
			addChild(bitmap);
			this.addEventListener(MouseEvent.MOUSE_DOWN, togglePlay);
		}
		
		protected function browse():void {
			var file:File = File.documentsDirectory.resolvePath("FilmStripOutput");
			file.addEventListener(Event.SELECT, directorySelected);
			file.browseForDirectory("Pick an image sequence.");
		}

		protected function directorySelected(event:Event):void 
		{
		    var directory:File = event.target as File;
		    files = directory.getDirectoryListing();
			
			var file:File = directory.resolvePath("_info.txt");
			fileStream.open(file, FileMode.READ);
			var info:String = fileStream.readUTF();
			fileStream.close();
			
			// "!filmstrip render: 864x480 @ 30fps"
			var a:Array = info.split(" ");
			var s:Array = a[2].split("x");
			var f:Array = a[4].split("f");
			w = int(s[0]);
			h = int(s[1]);
			var frameRate:int = Math.max(1, int(f[0]));
			trace(w,h,frameRate);
			timer.delay = 1000 / frameRate;
			
			Application.application.width = w;
			Application.application.height = h;
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyPress);
			
		    playVideo();
		}
		
		protected function addImage(e:Event=null):void {
			
			if (++loadStep==files.length) {
			    loadStep = 0;
			}
			
		    var file:File = files[ loadStep ];
		    var b:ByteArray;
			
		    if (file.name!="_info.txt") {
				fileStream.open(file, FileMode.READ);
				b = new ByteArray();
				fileStream.readBytes(b);
				fileStream.close();
				var data:BitmapData = new BitmapData(w, h, false, 0x0);
				data.setPixels(new Rectangle(0,0,w,h), b);
				this.bitmap.bitmapData = data;
		    }
		}
		
		public function playVideo():void {
			playing = true;
			timer.start();
			addImage();
		}
		
		public function togglePlay(e:MouseEvent=null):void {
			if (!playing) {
				playVideo();
				togglePausedTF(false);
			}
			else {
				if (timer.running) {
					timer.stop();
					togglePausedTF(true);
				}
				else {
					timer.start();
					togglePausedTF(false);
				}
			}
		}
		
		protected function togglePausedTF(show:Boolean):void {
			if (this.parent==null)
				return;
			
			if (this.parent.contains(pausedTF))
				this.parent.removeChild(pausedTF);
				
			if (show) {
				pausedTF.text = "PAUSED";
				pausedTF.background = true;
				pausedTF.backgroundColor = 0xFFFFFF;
				pausedTF.setTextFormat(new TextFormat("_sans", 24, 0x0, true));
				pausedTF.selectable = false;
				pausedTF.autoSize = TextFieldAutoSize.LEFT;
				pausedTF.x = NativeApplication.nativeApplication.activeWindow.width / 2 - pausedTF.width / 2;
				pausedTF.y = NativeApplication.nativeApplication.activeWindow.height / 2 - pausedTF.height / 2;
				this.parent.addChild(pausedTF);
			}
		}
		
		protected function handleKeyPress(event:KeyboardEvent):void {
			if ( event.keyCode == Keyboard.SPACE ) {
				togglePlay();
				return;
			}
			if (event.keyCode == Keyboard.RIGHT ) {
				if (timer.running)
					togglePlay();
				if ( ++loadStep == files.length )
					loadStep = 0;
				addImage();
			}
			else if ( event.keyCode == Keyboard.LEFT ) {
				if (timer.running)
					togglePlay();
				if ( (loadStep-=2) < 0 )
					loadStep = files.length-2;
				addImage();
			}
		}
	}
}