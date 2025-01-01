package;

import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;

using StringTools;

class RatingSprite extends Sprite
{
	public var rating:String = 'sick';
	public var group:FlxTypedGroup<RatingSprite>;

	public function new(x:Float = 0, y:Float = 0):Void
	{
		super(x, y);
	}

	public function resetSprite(x:Float = 0, y:Float = 0, rating:String = 'sick', ?suffix:String):Void
	{
		setPosition(x, y);

		this.rating = rating;
		reloadImage(rating, suffix);

		antialiasing = ClientPrefs.globalAntialiasing && !PlayState.isPixelStage;

		setGraphicSize(Std.int(width * (PlayState.isPixelStage ? PlayState.daPixelZoom * 0.85 : 0.7)));
		updateHitbox();
	}

	public function reloadImage(rating:String, ?suffix:String):Void
	{
		if ((suffix == null || suffix.trim().length < 1) && PlayState.isPixelStage) suffix = '-pixel';

		var path:String = 'ui/' + rating;

		if (suffix != null && suffix.length > 0)
		{
			path += suffix;
			var pathShit:String = rating + suffix;

			if (Paths.fileExists('images/pixelUI/' + pathShit + '.png', IMAGE) && PlayState.isPixelStage) {
				path = 'pixelUI/' + pathShit;
			}
			else if (Paths.fileExists('images/' + pathShit + '.png', IMAGE)) {
				path = pathShit;
			}
		}
		else
		{
			if (Paths.fileExists('images/pixelUI/' + rating + '.png', IMAGE) && PlayState.isPixelStage) {
				path = 'pixelUI/' + rating;
			}
			else if (Paths.fileExists('images/' + rating + '.png', IMAGE)) {
				path = rating;
			}
		}

		loadGraphic(Paths.getImage(path));
	}

	public function reoffset():Void
	{
		var offset:Array<Int> = ClientPrefs.comboOffset.copy();
		setPosition(x + offset[0], y - offset[1]);
	}

	var _disappearTween:FlxTween;

	public function disappear():Void
	{
		var playbackRate:Float = 1;

		if (PlayState.instance != null) {
			playbackRate = PlayState.instance.playbackRate;
		}

		acceleration.y = 550 * playbackRate * playbackRate;
		velocity.set(velocity.x - (FlxG.random.int(0, 10) * playbackRate), velocity.y - (FlxG.random.int(140, 175) * playbackRate));

		_disappearTween = FlxTween.tween(this, {alpha: 0}, 0.2 / playbackRate,
		{
			startDelay: Conductor.crochet * 0.001 / playbackRate,
			onComplete: function(twn:FlxTween):Void
			{
				try
				{
					kill();
					if (group != null) group.remove(this, true);
				}
				catch (_:Dynamic) {
					if (group != null) group.remove(this, true);
				}
			}
		});
	}

	override function destroy():Void
	{
		if (!destroyed)
		{
			if (_disappearTween != null)
			{
				_disappearTween.cancel();
				_disappearTween = null;
			}

			super.destroy();
		}
	}

	override function set_active(value:Bool):Bool
	{
		if (_disappearTween != null) _disappearTween.active = value;
		return super.set_active(value);
	}
}