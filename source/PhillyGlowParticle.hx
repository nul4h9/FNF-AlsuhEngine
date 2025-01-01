package;

import flixel.FlxG;
import flixel.util.FlxColor;

class PhillyGlowParticle extends Sprite
{
	var lifeTime:Float = 0;
	var decay:Float = 0;
	var originalScale:Float = 1;

	public function new(x:Float, y:Float, color:FlxColor):Void
	{
		super(x, y);

		this.color = color;

		loadGraphic(Paths.getImage('philly/particle'));

		lifeTime = FlxG.random.float(0.6, 0.9);
		decay = FlxG.random.float(0.8, 1);

		if (!ClientPrefs.flashingLights)
		{
			decay *= 0.5;
			alpha = 0.5;
		}

		originalScale = FlxG.random.float(0.75, 1);
		scale.set(originalScale, originalScale);

		scrollFactor.set(FlxG.random.float(0.3, 0.75), FlxG.random.float(0.65, 0.75));
		velocity.set(FlxG.random.float(-40, 40) * PlayState.instance.playbackRate, FlxG.random.float(-175, -250) * PlayState.instance.playbackRate);
		acceleration.set(FlxG.random.float(-10, 10) * PlayState.instance.playbackRate, 25 * PlayState.instance.playbackRate);
	}

	override function update(elapsed:Float):Void
	{
		lifeTime -= elapsed * PlayState.instance.playbackRate;

		if (lifeTime < 0)
		{
			lifeTime = 0;
			alpha -= decay * elapsed * PlayState.instance.playbackRate;

			if (alpha > 0) {
				scale.set(originalScale * alpha, originalScale * alpha);
			}
		}

		super.update(elapsed);
	}
}