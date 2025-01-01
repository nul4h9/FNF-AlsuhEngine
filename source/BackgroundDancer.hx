package;

import flixel.FlxSprite;

class BackgroundDancer extends Sprite
{
	public function new(x:Float, y:Float):Void
	{
		super(x, y);

		frames = Paths.getSparrowAtlas('limo/limoDancer');

		animation.addByIndices('danceLeft', 'bg dancer sketch PINK', CoolUtil.numberArray(14, 0), '', 24, false);
		animation.addByIndices('danceRight', 'bg dancer sketch PINK', CoolUtil.numberArray(29, 15), '', 24, false);

		playAnim('danceLeft');
	}

	var danceDir:Bool = false;

	public function dance():Void
	{
		danceDir = !danceDir;

		if (danceDir)
			playAnim('danceRight', true);
		else
			playAnim('danceLeft', true);
	}
}