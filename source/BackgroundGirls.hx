package;

class BackgroundGirls extends Sprite
{
	var isPissed:Bool = true;

	public function new(x:Float, y:Float):Void
	{
		super(x, y);

		frames = Paths.getSparrowAtlas('weeb/bgFreaks'); // BG fangirls dissuaded

		antialiasing = false;
		swapDanceType();

		setGraphicSize(Std.int(width * PlayState.daPixelZoom));
		updateHitbox();

		playAnim('danceLeft');
	}

	var danceDir:Bool = false;

	public function swapDanceType():Void
	{
		isPissed = !isPissed;

		if (!isPissed) //Gets unpissed
		{
			animation.addByIndices('danceLeft', 'BG girls group', CoolUtil.numberArray(14), "", 24, false);
			animation.addByIndices('danceRight', 'BG girls group', CoolUtil.numberArray(30, 15), "", 24, false);
		}
		else // Pisses
		{
			animation.addByIndices('danceLeft', 'BG fangirls dissuaded', CoolUtil.numberArray(14), "", 24, false);
			animation.addByIndices('danceRight', 'BG fangirls dissuaded', CoolUtil.numberArray(30, 15), "", 24, false);
		}

		dance();
	}

	public function dance():Void
	{
		danceDir = !danceDir;

		if (danceDir) {
			playAnim('danceRight', true);
		}
		else {
			playAnim('danceLeft', true);
		}
	}
}
