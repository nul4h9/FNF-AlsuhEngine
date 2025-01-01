package;

import flixel.FlxG;
import flixel.util.FlxColor;

using StringTools;

class ResetScoreSubState extends MusicBeatSubState
{
	var bg:Sprite;
	var alphabetArray:Array<Alphabet> = [];
	var icon:HealthIcon;
	var onYes:Bool = false;
	var yesText:Alphabet;
	var noText:Alphabet;

	var song:String;
	var difficulty:Int;
	var week:Int; // Week -1 = Freeplay

	public function new(song:String, difficulty:Int, character:String, week:Int = -1):Void
	{
		this.song = song;
		this.difficulty = difficulty;
		this.week = week;

		super();

		var name:String = song;

		if (week > -1) {
			name = WeekData.getFromFileName(WeekData.weeksList[week]).weekName;
		}

		name += ' (' + CoolUtil.difficultyStuff[difficulty][1] + ')?';

		bg = new Sprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var tooLong:Float = (name.length > 18) ? 0.8 : 1; // Fucking Winter Horrorland

		var text:Alphabet = new Alphabet(0, 180, "Reset the score of", true);
		text.screenCenter(X);
		alphabetArray.push(text);
		text.alpha = 0;
		add(text);

		var text:Alphabet = new Alphabet(0, text.y + 90, name, true);
		text.scaleX = tooLong;
		text.screenCenter(X);
		if (week == -1) text.x += 60 * tooLong;

		alphabetArray.push(text);
		text.alpha = 0;
		add(text);

		if (week == -1)
		{
			icon = new HealthIcon(character);
			icon.setGraphicSize(Std.int(icon.width * tooLong));
			icon.updateHitbox();
			icon.setPosition(text.x - icon.width + (10 * tooLong), text.y - 30);
			icon.alpha = 0;
			add(icon);
		}

		yesText = new Alphabet(0, text.y + 150, 'Yes', true);
		yesText.screenCenter(X);
		yesText.x -= 200;
		add(yesText);

		noText = new Alphabet(0, text.y + 150, 'No', true);
		noText.screenCenter(X);
		noText.x += 200;
		add(noText);

		updateOptions();
	}

	var holdTime:Float = 0;

	override function update(elapsed:Float):Void
	{
		bg.alpha += elapsed * 1.5;
		if (bg.alpha > 0.6) bg.alpha = 0.6;

		for (i in 0...alphabetArray.length)
		{
			var spr:Alphabet = alphabetArray[i];
			spr.alpha += elapsed * 2.5;
		}

		if (week == -1) icon.alpha += elapsed * 2.5;

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			holdTime = 0;
			switchYes();
		}

		if (controls.UI_LEFT || controls.UI_RIGHT)
		{
			var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapsed;
			var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

			if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
				switchYes();
			}
		}

		if (controls.BACK_P)
		{
			FlxG.sound.play(Paths.getSound('cancelMenu'));
			close();
		}
		else if (controls.ACCEPT_P)
		{
			if (onYes)
			{
				if (week == -1) {
					Highscore.resetSong(song, difficulty);
				}
				else {
					Highscore.resetWeek(WeekData.weeksList[week], difficulty);
				}
			}

			FlxG.sound.play(Paths.getSound('cancelMenu'));
			close();
		}

		super.update(elapsed);
	}

	function switchYes():Void
	{
		FlxG.sound.play(Paths.getSound('scrollMenu'));
		onYes = !onYes;
		updateOptions();
	}

	function updateOptions():Void
	{
		var scales:Array<Float> = [0.75, 1];
		var alphas:Array<Float> = [0.6, 1.25];
		var confirmInt:Int = onYes ? 1 : 0;

		yesText.alpha = alphas[confirmInt];
		yesText.scale.set(scales[confirmInt], scales[confirmInt]);

		noText.alpha = alphas[1 - confirmInt];
		noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);

		if (week == -1) icon.animation.curAnim.curFrame = confirmInt;
	}
}