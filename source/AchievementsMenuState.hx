package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

#if ACHIEVEMENTS_ALLOWED
import Achievements;
#end

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;

using StringTools;

#if ACHIEVEMENTS_ALLOWED
class AchievementsMenuState extends MusicBeatState
{
	final MAX_PER_ROW:Int = 4;

	public var curSelected:Int = 0;

	public var curAchieve:Achievement = null;
	public var achievements:Array<Achievement> = [];
	public var grpAchievements:FlxTypedSpriteGroup<AchievementSprite>;

	var camFollow:FlxObject;

	public var nameText:FlxText;
	public var descText:FlxText;
	public var progressTxt:FlxText;
	public var progressBar:Bar;

	var bg:Sprite;
	var intendedColor:FlxColor;
	var colorTween:FlxTween;

	override function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Achievements Menu");
		#end

		persistentUpdate = true;

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		bg = new Sprite();

		if (Paths.fileExists('images/menuDesat.png', IMAGE)) {
			bg.loadGraphic(Paths.getImage('menuDesat'));
		}
		else {
			bg.loadGraphic(Paths.getImage('bg/menuDesat'));
		}

		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);

		grpAchievements = new FlxTypedSpriteGroup<AchievementSprite>();
		grpAchievements.scrollFactor.x = 0;

		Achievements.load();

		for (i in 0...Achievements.achievementList.length)
		{
			var daAchieve:Achievement = Achievements.get(Achievements.achievementList[i]);

			if (daAchieve.hidden == false || Achievements.isUnlocked(daAchieve.save_tag))
			{
				daAchieve.curProgress = daAchieve.maxScore > 0 ? Achievements.getScore(daAchieve.save_tag) : 0;
				daAchieve.maxProgress = daAchieve.maxScore > 0 ? daAchieve.maxScore : 0;
				daAchieve.decProgress = daAchieve.maxScore > 0 ? daAchieve.maxDecimals : 0;

				achievements.push(daAchieve);
			}
		}

		for (i in 0...achievements.length)
		{
			var achieve:Achievement = achievements[i];

			var spr:AchievementSprite = new AchievementSprite(0, Math.floor(grpAchievements.members.length / MAX_PER_ROW) * 180, achieve.save_tag);
			spr.scrollFactor.x = 0;
			spr.screenCenter(X);
			spr.x += 180 * ((grpAchievements.members.length % MAX_PER_ROW) - MAX_PER_ROW / 2) + spr.width / 2 + 15;
			spr.ID = grpAchievements.members.length;
			grpAchievements.add(spr);

			Paths.loadTopMod();
		}

		var newColor:FlxColor = 0xFF1B1B41;

		if (Achievements.isUnlocked(achievements[curSelected].save_tag))
		{
			var col:Array<Int> = achievements[curSelected].color;
			newColor = FlxColor.fromRGB(col[0], col[1], col[2]);
		}

		bg.color = newColor;

		var box:FlxSprite = new FlxSprite(0, -30);
		box.makeGraphic(1, 1, FlxColor.BLACK);
		box.scale.set(grpAchievements.width + 60, grpAchievements.height + 60);
		box.updateHitbox();
		box.alpha = 0.6;
		box.scrollFactor.x = 0;
		box.screenCenter(X);
		add(box);

		add(grpAchievements);

		var box:FlxSprite = new FlxSprite(0, 570).makeGraphic(1, 1, FlxColor.BLACK);
		box.scale.set(FlxG.width, FlxG.height - box.y);
		box.updateHitbox();
		box.alpha = 0.6;
		box.scrollFactor.set();
		add(box);

		nameText = new FlxText(50, box.y + 10, FlxG.width - 100, "", 32);
		nameText.setFormat(Paths.getFont("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		nameText.scrollFactor.set();

		descText = new FlxText(50, nameText.y + 38, FlxG.width - 100, "", 24);
		descText.setFormat(Paths.getFont("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();

		progressBar = new Bar(0, descText.y + 52);
		progressBar.screenCenter(X);
		progressBar.scrollFactor.set();
		progressBar.enabled = false;
		
		progressTxt = new FlxText(50, progressBar.y - 6, FlxG.width - 100, "", 32);
		progressTxt.setFormat(Paths.getFont("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		progressTxt.scrollFactor.set();
		progressTxt.borderSize = 2;

		add(progressBar);
		add(progressTxt);
		add(descText);
		add(nameText);

		changeSelection();

		super.create();

		FlxG.camera.follow(camFollow, null, 9);
		FlxG.camera.snapToTarget();
	}

	var goingBack:Bool = false;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.BACK_P)
		{
			FlxG.camera.followLerp = 0;

			goingBack = true;
			persistentUpdate = false;

			if (colorTween != null) {
				colorTween.cancel();
			}

			if (barTween != null) {
				barTween.cancel();
			}

			FlxG.sound.play(Paths.getSound('cancelMenu'));
			FlxG.switchState(new MainMenuState());
		}

		if (controls.RESET_P && (Achievements.isUnlocked(curAchieve.save_tag) || curAchieve.curProgress > 0))
		{
			persistentUpdate = false;
			openSubState(new ResetAchievementSubState());
		}

		if (!goingBack && achievements.length > 1)
		{
			var add:Int = 0;

			if (controls.UI_LEFT_P) add = -1;
			else if (controls.UI_RIGHT_P) add = 1;

			if (add != 0)
			{
				var oldRow:Int = Math.floor(curSelected / MAX_PER_ROW);
				var rowSize:Int = Std.int(Math.min(MAX_PER_ROW, achievements.length - oldRow * MAX_PER_ROW));
				
				curSelected += add;

				var curRow:Int = Math.floor(curSelected / MAX_PER_ROW);
				if (curSelected >= achievements.length) curRow++;

				if (curRow != oldRow)
				{
					if (curRow < oldRow) curSelected += rowSize;
					else curSelected = curSelected -= rowSize;
				}

				changeSelection();
			}

			if (achievements.length > MAX_PER_ROW)
			{
				var add:Int = 0;

				if (controls.UI_UP_P) add = -1;
				else if (controls.UI_DOWN_P) add = 1;

				if (add != 0)
				{
					var diff:Int = curSelected - (Math.floor(curSelected / MAX_PER_ROW) * MAX_PER_ROW);
					curSelected += add * MAX_PER_ROW;

					if (curSelected < 0)
					{
						curSelected += Math.ceil(achievements.length / MAX_PER_ROW) * MAX_PER_ROW;
						if (curSelected >= achievements.length) curSelected -= MAX_PER_ROW;
					}

					if (curSelected >= achievements.length) {
						curSelected = diff;
					}

					changeSelection();
				}
			}
		}
	}

	override function openSubState(SubState:FlxSubState):Void
	{
		super.openSubState(SubState);

		if (colorTween != null) {
			colorTween.active = false;
		}
	}

	override function closeSubState():Void
	{
		super.closeSubState();

		if (colorTween != null) {
			colorTween.active = true;
		}
	}

	public var barTween:FlxTween = null;

	public function changeSelection(change:Int = 0):Void
	{
		curAchieve = achievements[curSelected];

		nameText.text = (Achievements.isUnlocked(curAchieve.save_tag)) ? curAchieve.name : '???';

		descText.alpha = (curAchieve.desc != null && curAchieve.desc.trim().length > 0) ? 1 : FlxMath.EPSILON;
		descText.text = curAchieve.desc.trim();

		var hasProgress:Bool = curAchieve.maxProgress != null && curAchieve.maxProgress > 0;
		progressBar.alpha = hasProgress ? 1 : FlxMath.EPSILON;
		progressTxt.alpha = hasProgress ? 1 : FlxMath.EPSILON;

		if (barTween != null) barTween.cancel();

		var newColor:FlxColor = 0xFF1B1B41;

		if (Achievements.isUnlocked(curAchieve.save_tag))
		{
			var col:Array<Int> = curAchieve.color;
			newColor = FlxColor.fromRGB(col[0], col[1], col[2]);
		}

		if (newColor != intendedColor)
		{
			if (colorTween != null) {
				colorTween.cancel();
			}

			intendedColor = newColor;

			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor,
			{
				onComplete: function(twn:FlxTween):Void {
					colorTween = null;
				}
			});
		}

		if (barTween != null) barTween.cancel();

		if (hasProgress)
		{
			var val1:Float = curAchieve.curProgress;
			var val2:Float = curAchieve.maxProgress;
			progressTxt.text = CoolUtil.floorDecimal(val1, curAchieve.decProgress) + ' / ' + CoolUtil.floorDecimal(val2, curAchieve.decProgress);

			barTween = FlxTween.tween(progressBar, {percent: (val1 / val2) * 100}, 0.5,
			{
				ease: FlxEase.quadOut,
				onComplete: function(twn:FlxTween):Void progressBar.updateBar(),
				onUpdate: function(twn:FlxTween):Void progressBar.updateBar()
			});
		}
		else progressBar.percent = 0;

		var maxRows:Int = Math.floor(grpAchievements.members.length / MAX_PER_ROW);

		if (maxRows > 0)
		{
			var camY:Float = FlxG.height / 2 + (Math.floor(curSelected / MAX_PER_ROW) / maxRows) * Math.max(0, grpAchievements.height - FlxG.height / 2 - 50) - 100;
			camFollow.setPosition(0, camY);
		}
		else camFollow.setPosition(0, grpAchievements.members[curSelected].getGraphicMidpoint().y - 100);

		grpAchievements.forEach(function(spr:Sprite):Void {
			spr.alpha = (spr.ID == curSelected) ? 1 : 0.6;
		});

		FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);
	}
}

class ResetAchievementSubState extends MusicBeatSubState
{
	var onYes:Bool = false;
	var yesText:Alphabet;
	var noText:Alphabet;

	public function new():Void
	{
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		var text:Alphabet = new Alphabet(0, 180, "Reset Achievement:", true);
		text.screenCenter(X);
		text.scrollFactor.set();
		add(text);

		var state:AchievementsMenuState = cast FlxG.state;

		var text:FlxText = new FlxText(50, text.y + 90, FlxG.width - 100, state.curAchieve.name, 40);
		text.setFormat(Paths.getFont('vcr.ttf'), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.scrollFactor.set();
		text.borderSize = 2;
		add(text);
		
		yesText = new Alphabet(0, text.y + 120, 'Yes', true);
		yesText.screenCenter(X);
		yesText.x -= 200;
		yesText.scrollFactor.set();

		for (letter in yesText.letters) letter.color = FlxColor.RED;

		add(yesText);

		noText = new Alphabet(0, text.y + 120, 'No', true);
		noText.screenCenter(X);
		noText.x += 200;
		noText.scrollFactor.set();
		add(noText);

		updateOptions();
	}

	override function update(elapsed:Float)
	{
		if (controls.BACK)
		{
			close();
			FlxG.sound.play(Paths.getSound('cancelMenu'));

			return;
		}

		super.update(elapsed);

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			onYes = !onYes;
			updateOptions();
		}

		if (controls.ACCEPT)
		{
			if (onYes)
			{
				var state:AchievementsMenuState = cast FlxG.state;
				var achiveve:Achievement = state.curAchieve;

				Achievements.variables.remove(achiveve.save_tag);
				Achievements.achievementsUnlocked.remove(achiveve.save_tag);

				achiveve.curProgress = 0;
				achiveve.name = state.nameText.text = '???';
				if (achiveve.maxProgress > 0) state.progressTxt.text = '0 / ' + achiveve.maxProgress;

				state.grpAchievements.members[state.curSelected].reloadAchievementImage();

				if (state.progressBar.visible)
				{
					if (state.barTween != null) state.barTween.cancel();

					state.barTween = FlxTween.tween(state.progressBar, {percent: 0}, 0.5,
					{
						ease: FlxEase.quadOut,
						onComplete: function(twn:FlxTween):Void state.progressBar.updateBar(),
						onUpdate: function(twn:FlxTween):Void state.progressBar.updateBar()
					});
				}

				Achievements.save();
				@:privateAccess
				Achievements._save.flush();

				state.changeSelection();

				FlxG.sound.play(Paths.getSound('cancelMenu'));
			}

			close();
			return;
		}
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

		FlxG.sound.play(Paths.getSound('scrollMenu'));
	}
}
#end