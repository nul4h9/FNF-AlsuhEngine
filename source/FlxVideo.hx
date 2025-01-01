package;

import flixel.FlxG;
import flixel.FlxBasic;

#if VIDEOS_ALLOWED
#if desktop
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
	#if web
	var netStream:NetStream;
	#end

	public var finishCallback:Void->Void;

	/**
	 * Doesn't actually interact with Flixel shit, only just a pleasant to use class    
	 */
	public function new(vidSrc:String):Void
	{
		super();

		var newPath:String = Paths.getVideo(vidSrc);

		if (newPath.contains(':')) {
			newPath = newPath.substring(newPath.indexOf(':') + 1, newPath.length);
		}

		#if desktop
		var video:VideoHandler = new VideoHandler();
		video.play(newPath);
		video.onEndReached.add(function():Void
		{
			video.dispose();
			finishVideo();
		});
		#elseif web
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
		#if web
		updateVolume();
		#end

		super.update(elapsed);
	}

	#if web
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
			finishCallback();
		}

		kill();
	}
}
#end