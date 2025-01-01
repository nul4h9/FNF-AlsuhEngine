package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

#if ACHIEVEMENTS_ALLOWED
import Achievements;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

using StringTools;

#if ACHIEVEMENTS_ALLOWED
class AchievementsMenuState extends MusicBeatState
{
	public static var curSelected:Int = 0;

	public var curAchieve:Achievement = null;
	public var achievements:Array<Achievement> = [];

	public var grpTexts:FlxTypedGroup<Alphabet>;
	public var grpAchievements:FlxTypedGroup<AttachedAchievement>;

	private var descBox:Sprite;
	private var descText:FlxText;

	var bg:Sprite;

	var startingTweenBGColor:Bool = true;
	var startColor:FlxColor = FlxColor.WHITE;
	var intendedColor:FlxColor;
	var colorTween:FlxTween;

	override function create():Void
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Achievements Menu");
		#end

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
		bg.color = startColor;
		add(bg);

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		grpAchievements = new FlxTypedGroup<AttachedAchievement>();
		add(grpAchievements);

		Achievements.load();

		for (i in 0...Achievements.achievementList.length)
		{
			var daAchieve:Achievement = Achievements.get(Achievements.achievementList[i]);

			if (!daAchieve.hidden || Achievements.isUnlocked(daAchieve.save_tag)) {
				achievements.push(daAchieve);
			}
		}

		for (i in 0...achievements.length)
		{
			var daAchieve:Achievement = achievements[i];
			var unlocked:Bool = Achievements.isUnlocked(daAchieve.save_tag);

			if (daAchieve.folder != null) {
				Paths.currentModDirectory = daAchieve.folder;
			}

			var leText:Alphabet = new Alphabet(280, 270, unlocked ? daAchieve.name : '?', false);
			leText.isMenuItem = true;
			leText.targetY = i - curSelected;
			leText.setPosition(280, (100 * i) + 210);
			leText.hasIcon = true;
			grpTexts.add(leText);

			var icon:AttachedAchievement = new AttachedAchievement(leText.x - 105, leText.y, daAchieve.save_tag);
			icon.sprTracker = leText;
			icon.ID = i;
			grpAchievements.add(icon);

			Paths.currentModDirectory = '';
		}

		if (curSelected >= achievements.length) curSelected = 0;

		descBox = new Sprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		changeSelection();

		super.create();
	}

	var holdTime:Float = 0;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.BACK_P)
		{
			persistentUpdate = false;

			if (colorTween != null) {
				colorTween.cancel();
			}

			FlxG.sound.play(Paths.getSound('cancelMenu'));
			FlxG.switchState(new MainMenuState());
		}

		if (controls.RESET_P && Achievements.isUnlocked(curAchieve.save_tag)) {
			openSubState(new ResetAchievementSubState());
		}

		if (achievements.length > 1)
		{
			var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

			if (controls.UI_UP_P)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}

			if (controls.UI_DOWN_P)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if (controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}
			}

			if (FlxG.mouse.wheel != 0) {
				changeSelection(-shiftMult * FlxG.mouse.wheel);
			}
		}
	}

	override function openSubState(SubState:FlxSubState):Void
	{
		super.openSubState(SubState);

		if (!startingTweenBGColor && colorTween != null) {
			colorTween.active = false;
		}
	}

	override function closeSubState():Void
	{
		super.closeSubState();

		if (startingTweenBGColor)
		{
			var newColor:FlxColor = 0xFF1B1B41;

			if (Achievements.isUnlocked(curAchieve.save_tag))
			{
				var col:Array<Int> = curAchieve.color;
				newColor = FlxColor.fromRGB(col[0], col[1], col[2]);
			}

			if (intendedColor != newColor)
			{
				if (colorTween != null) {
					colorTween.cancel();
				}

				intendedColor = newColor;

				colorTween = FlxTween.color(bg, 1, startColor, intendedColor,
				{
					onComplete: function(twn:FlxTween):Void {
						colorTween = null;
					}
				});
			}

			startingTweenBGColor = false;
		}
		else
		{
			if (colorTween != null) {
				colorTween.active = true;
			}
		}
	}

	public function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, achievements.length - 1);

		var bullShit:Int = 0;

		for (item in grpTexts.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}

		curAchieve = achievements[curSelected];

		if (!startingTweenBGColor)
		{
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
		}

		for (achievement in grpAchievements)
		{
			achievement.alpha = 0.6;

			if (achievement.ID == curSelected) {
				achievement.alpha = 1;
			}
		}

		var desc:String = curAchieve.desc;
		var visible:Bool = desc != null && desc.length > 0;

		descText.text = desc;
		descText.screenCenter(Y);
		descText.y += 270;

		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();

		descText.visible = visible;
		descBox.visible = visible;

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

				state.grpAchievements.members[AchievementsMenuState.curSelected].reloadAchievementImage();
				state.grpTexts.members[AchievementsMenuState.curSelected].text = '?';

				state.changeSelection();

				Achievements.save();
				@:privateAccess
				Achievements._save.flush();

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