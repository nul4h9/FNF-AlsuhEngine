package;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;

using StringTools;

class OutdatedState extends MusicBeatState
{
	#if CHECK_FOR_UPDATES
	public static var leftState:Bool = false;

	public static var updateVersion:String = '';
	public static var updateChanges:String = '';

	var bg:Sprite;
	var warnText:FlxText;

	override function create():Void
	{
		bg = new Sprite();
		bg.loadGraphic(Paths.getImage('bg/menuDesat'));
		bg.screenCenter();
		bg.color = 0xFF222222;
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width,
			"Your Alsuh Engine is outdated!\nYou are on "
			+ MainMenuState.alsuhEngineVersion
			+ "\nwhile the most recent version is "
			+ updateVersion
			+ "."
			+ "\n\nWhat's new:\n\n"
			+ updateChanges
			+ "\n\nPress ACCEPT to download a new version\nor BACK to ignore this.",
			32);
		warnText.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, CENTER);
		warnText.borderColor = FlxColor.BLACK;
		warnText.borderSize = 2;
		warnText.borderStyle = FlxTextBorderStyle.OUTLINE;
		warnText.screenCenter();
		add(warnText);

		super.create();
	}

	override function update(elapsed:Float):Void
	{
		if (!leftState)
		{
			if (controls.ACCEPT)
			{
				leftState = true;
				CoolUtil.browserLoad("https://github.com/nul4h9/FNF-AlsuhEngine/releases/latest");
			}
			else if (controls.BACK) {
				leftState = true;
			}

			if (leftState)
			{
				FlxG.sound.play(Paths.getSound('cancelMenu'));

				FlxTween.tween(bg, {alpha: 0}, 0.5);
				FlxTween.tween(warnText, {alpha: 0}, 1,
				{
					onComplete: function(twn:FlxTween):Void {
						FlxG.switchState(new MainMenuState());
					}
				});
			}
		}

		super.update(elapsed);
	}
	#end
}