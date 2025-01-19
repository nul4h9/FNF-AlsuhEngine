package;

import flixel.FlxG;
import flixel.FlxBasic;

#if VIDEOS_ALLOWED
#if (cpp && !html5)
import hxcodec.flixel.FlxVideo as VideoHandler;
#else
import openfl.media.Video;
import openfl.net.NetStream;
import openfl.net.NetConnection;
import openfl.events.NetStatusEvent;
#end
#end

using StringTools;

#if VIDEOS_ALLOWED
class FlxVideo extends FlxBasic
{
	#if html5
	var netStream:NetStream;
	#end

	public var finishCallback:FlxVideo->Void;

	/**
	 * Doesn't actually interact with Flixel shit, only just a pleasant to use class    
	 */
	public function new(vidSrc:String, ?finishCallback:FlxVideo->Void):Void
	{
		this.finishCallback = finishCallback;

		super();

		var newPath:String = Paths.getVideo(vidSrc);

		if (newPath.contains(':')) {
			newPath = newPath.substring(newPath.indexOf(':') + 1, newPath.length);
		}

		#if cpp
		var video:VideoHandler = new VideoHandler();
		video.play(newPath);
		video.onEndReached.add(function():Void
		{
			video.dispose();
			finishVideo();
		});
		#elseif html5
		var video:Video = new Video();
		video.x = 0;
		video.y = 0;
		FlxG.addChildBelowMouse(video);

		var netConnection:NetConnection = new NetConnection();
		netConnection.connect(null);

		netStream = new NetStream(netConnection);
		netStream.client = {
			onMetaData: function():Void {
				video.attachNetStream(netStream);
				video.width = FlxG.width;
				video.height = FlxG.height;
			}
		};

		netConnection.addEventListener(NetStatusEvent.NET_STATUS, function(event:NetStatusEvent):Void
		{
			if (event.info.code == 'NetStream.Play.Complete')
			{
				netStream.dispose();
				FlxG.removeChild(video);

				finishVideo();
			}
		});

		netStream.play(newPath);
		updateVolume();
		#end
	}

	override function update(elapsed:Float):Void
	{
		#if html5
		updateVolume();
		#end

		super.update(elapsed);
	}

	#if html5
	function updateVolume():Void
	{
		@:privateAccess
		if (netStream != null && netStream.__video != null) {
			netStream.__video.volume = FlxG.sound.volume;
		}
	}
	#end

	public function finishVideo():Void
	{
		if (finishCallback != null) {
			finishCallback(this);
		}

		kill();
	}
}
#end