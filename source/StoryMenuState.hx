package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import openfl.errors.Error;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;

using StringTools;

class StoryMenuState extends MusicBeatState
{
	private static var curSelected:Int = -1;
	private static var lastDifficultyName:String = '';

	var curDifficulty:Int = -1;

	private var weeksArray:Array<WeekData> = [];
	private var curWeek:WeekData;

	var bgSprite:Sprite;

	var scoreText:FlxText;
	var txtWeekTitle:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpLocks:FlxTypedGroup<AttachedSprite>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	var txtTracklist:FlxText;

	var sprDifficulty:Sprite;
	var leftArrow:Sprite;
	var rightArrow:Sprite;

	override function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		PlayState.gameMode = 'story';
		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);

		if (curSelected >= WeekData.weeksList.length) curSelected = 0;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus"); // Updating Discord Rich Presence
		#end

		if (FlxG.sound.music != null && (!FlxG.sound.music.playing || FlxG.sound.music.volume == 0)) {
			FlxG.sound.playMusic(Paths.getMusic('freakyMenu'));
		}

		persistentUpdate = persistentDraw = true;

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		grpLocks = new FlxTypedGroup<AttachedSprite>();
		add(grpLocks);

		var blackBarThingie:Sprite = new Sprite();
		blackBarThingie.makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		scoreText = new FlxText(10, 10);
		scoreText.setFormat(Paths.getFont('vcr.ttf'), 32);
		add(scoreText);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10);
		txtWeekTitle.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;
		add(txtWeekTitle);

		var bgYellow:Sprite = new Sprite(0, 56);
		bgYellow.makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		add(bgYellow);

		bgSprite = new Sprite(0, 56);
		add(bgSprite);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		add(grpWeekCharacters);

		var path:String = 'storymenu/campaign_menu_UI_assets';
		if (Paths.fileExists('images/campaign_menu_UI_assets.png', IMAGE)) path = 'campaign_menu_UI_assets';

		var num:Int = 0;

		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.getFromFileName(WeekData.weeksList[i]);
			var isLocked:Bool = WeekData.weekIsLocked(WeekData.weeksList[i]);

			if (!isLocked || !weekFile.hiddenUntilUnlocked)
			{
				if (curSelected < 0) curSelected = num;

				weeksArray.push(weekFile);
				WeekData.setDirectoryFromWeek(weekFile);

				var weekThing:MenuItem = new MenuItem(0, bgYellow.y + 396, weekFile.itemFile);
				weekThing.y += ((weekThing.height + 20) * num);
				weekThing.targetY = num;
				grpWeekText.add(weekThing);

				weekThing.screenCenter(X);
				weekThing.itemColor = FlxColor.fromRGB(weekFile.itemColor[0], weekFile.itemColor[1], weekFile.itemColor[2]);

				if (isLocked) // Needs an offset thingie
				{
					var lock:AttachedSprite = new AttachedSprite(path, 'lock');
					lock.xAdd = weekThing.width + 10;
					lock.sprTracker = weekThing;
					lock.copyAlpha = false;
					grpLocks.add(lock);
				}

				weekThing.snapToPosition();

				num++;
			}
		}

		Paths.loadTopMod();

		var charArray:Array<String> = weeksArray[0].weekCharacters;

		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		var tracksSprite:Sprite = new Sprite(FlxG.width * 0.07, bgYellow.y + 425);

		var path2:String = 'storymenu/Menu_Tracks';
		if (Paths.fileExists('images/Menu_Tracks.png', IMAGE)) path2 = 'Menu_Tracks';

		tracksSprite.loadGraphic(Paths.getImage(path2));
		add(tracksSprite);

		txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60);
		txtTracklist.setFormat(Paths.getFont('vcr.ttf'), 32, 0xFFe55777, CENTER);
		add(txtTracklist);

		var ui_tex:FlxFramesCollection = Paths.getSparrowAtlas(path);

		leftArrow = new Sprite(872, 462);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', 'arrow left', 24, false);
		leftArrow.animation.addByPrefix('press', 'arrow push left', 24, false);
		leftArrow.playAnim('idle');
		add(leftArrow);

		sprDifficulty = new Sprite(0, leftArrow.y);
		add(sprDifficulty);

		rightArrow = new Sprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right', 24, false);
		rightArrow.animation.addByPrefix('press', 'arrow push right', 24, false);
		rightArrow.playAnim('idle');
		add(rightArrow);

		var textBG:Sprite = new Sprite(0, FlxG.height);
		textBG.makeGraphic(FlxG.width, 26, FlxColor.BLACK);
		textBG.alpha = 0.6;
		add(textBG);

		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, "Press CTRL to open the Gameplay Changers Menu | Press RESET to Reset your Score.", 18);
		text.setFormat(Paths.getFont('vcr.ttf'), 18, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);

		FlxTween.tween(textBG, {y: FlxG.height - 26}, 2, {ease: FlxEase.circOut});
		FlxTween.tween(text, {y: FlxG.height - 26 + 4}, 2, {ease: FlxEase.circOut});

		CoolUtil.resetDifficulties();

		if (lastDifficultyName == '') {
			lastDifficultyName = Paths.formatToSongPath(CoolUtil.defaultDifficulty);
		}

		curDifficulty = Math.round(Math.max(0, CoolUtil.getDifficultyIndex(lastDifficultyName)));

		changeSelection();

		for (item in grpWeekText.members) {
			item.snapToPosition();
		}

		super.create();
	}

	override function closeSubState():Void
	{
		persistentUpdate = true;
		changeSelection();

		super.closeSubState();
	}

	var blockedInput:Bool = false;

	var holdTime:Float = 0;
	var holdTimeDiff:Float = 0;

	var lerpScore:Float = 0;
	var intendedScore:Float = 0;

	override function update(elapsed:Float):Void
	{
		lerpScore = FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 30));
		if (Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;

		scoreText.text = "WEEK SCORE:" + Math.round(lerpScore);

		if (!blockedInput)
		{
			if (controls.BACK_P)
			{
				blockedInput = true;

				FlxG.sound.play(Paths.getSound('cancelMenu'));
				FlxG.switchState(new MainMenuState());
			}

			if (CoolUtil.difficultyStuff.length > 1)
			{
				if (controls.UI_LEFT_P || (FlxG.mouse.overlaps(leftArrow) && FlxG.mouse.justPressed))
				{
					leftArrow.playAnim('press');

					changeDifficulty(-1);
					holdTimeDiff = 0;
				}
				else if (controls.UI_LEFT_R || (FlxG.mouse.overlaps(leftArrow) && FlxG.mouse.justReleased)) leftArrow.playAnim('idle');

				if (controls.UI_RIGHT_P || (FlxG.mouse.overlaps(rightArrow) && FlxG.mouse.justPressed))
				{
					rightArrow.playAnim('press');

					changeDifficulty(1);
					holdTimeDiff = 0;
				}
				else if (controls.UI_RIGHT_R || (FlxG.mouse.overlaps(rightArrow) && FlxG.mouse.justReleased)) rightArrow.playAnim('idle');

				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					var checkLastHold:Int = Math.floor((holdTimeDiff - 0.5) * 10);
					holdTimeDiff += elapsed;
					var checkNewHold:Int = Math.floor((holdTimeDiff - 0.5) * 10);
	
					if (holdTimeDiff > 0.5 && checkNewHold - checkLastHold > 0) {
						changeDifficulty((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
					}
				}
	
				if (FlxG.mouse.wheel != 0 && FlxG.mouse.pressedMiddle) {
					changeDifficulty(-1 * FlxG.mouse.wheel);
				}
			}

			var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 10 : 1;

			if (weeksArray.length > 1)
			{
				var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;

					FlxG.sound.play(Paths.getSound('scrollMenu'));
				}

				if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;

					FlxG.sound.play(Paths.getSound('scrollMenu'));
				}

				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
	
					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
						FlxG.sound.play(Paths.getSound('scrollMenu'));
					}
				}
	
				if (FlxG.mouse.wheel != 0 && !FlxG.mouse.pressedMiddle)
				{
					changeSelection(-1 * FlxG.mouse.wheel);
					FlxG.sound.play(Paths.getSound('scrollMenu'));
				}
			}

			if (FlxG.keys.justPressed.CONTROL)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubState());
			}

			if (controls.RESET_P)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState('', curDifficulty, '', curSelected));
			}

			if (controls.ACCEPT_P || (FlxG.mouse.justPressed && FlxG.mouse.overlaps(grpWeekText.members[curSelected])))
			{
				if (!WeekData.weekIsLocked(curWeek.fileName))
				{
					var songArray:Array<String> = [for (i in curWeek.songs) i.songID];

					var songLowercase:String = Paths.formatToSongPath(songArray[0]);
					var poop:String = CoolUtil.formatSong(songLowercase, curDifficulty);
					var path:String = Paths.getJson('data/$songLowercase/$poop');

					if (Paths.fileExists(path, TEXT))
					{
						try {
							PlayState.SONG = Song.loadFromJson(poop, songLowercase);
						}
						catch (e:Error)
						{
							Debug.logError('Error on loading data file with id "' + songLowercase + '": ' + e);

							super.update(elapsed);
							return;
						}

						blockedInput = true;

						PlayState.firstSong = songLowercase;

						PlayState.storyPlaylist = songArray;
						PlayState.storyDifficulty = curDifficulty;
						PlayState.lastDifficulty = curDifficulty;

						PlayState.campaignScore = 0;
						PlayState.campaignMisses = 0;

						var diffName:String = CoolUtil.difficultyStuff[PlayState.storyDifficulty][1];
						Debug.logInfo('Loading song "' + PlayState.SONG.songName + '" on difficulty "' + diffName + '" into week "' + curWeek.weekName + '".');

						FlxG.sound.play(Paths.getSound('confirmMenu'));

						var weekItem:MenuItem = grpWeekText.members[curSelected];
						weekItem.startFlashing();

						for (char in grpWeekCharacters.members)
						{
							if (char.character != '' && char.hasConfirmAnimation) {
								char.animation.play('confirm');
							}
						}

						new FlxTimer().start(1, function(tmr:FlxTimer):Void {
							LoadingState.loadAndSwitchState(new PlayState(), true);
						});

						#if (DISCORD_ALLOWED && MODS_ALLOWED)
						DiscordClient.loadModRPC();
						#end
					}
					else {
						Debug.logError('Error on loading data file with id "' + songLowercase + '": File not found');
					}
				}
				else {
					FlxG.sound.play(Paths.getSound('cancelMenu'));
				}
			}
		}

		super.update(elapsed);
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, weeksArray.length - 1);
		curWeek = weeksArray[curSelected];

		WeekData.setDirectoryFromWeek(curWeek);

		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.targetY = bullShit++ - curSelected;
			item.alpha = (item.targetY == 0 && !WeekData.weekIsLocked(curWeek.fileName) ? 1 : 0.6);
		}

		PlayState.storyWeek = curSelected;

		if (curWeek.difficulties != null && curWeek.difficulties.length > 0) {
			CoolUtil.copyDifficultiesFrom(curWeek.difficulties);
		}
		else {
			CoolUtil.resetDifficulties();
		}

		if (CoolUtil.difficultyExists(curWeek.defaultDifficulty)) {
			curDifficulty = Math.round(Math.max(0, CoolUtil.getDifficultyIndex(curWeek.defaultDifficulty)));
		}
		else if (CoolUtil.difficultyExists(Paths.formatToSongPath(CoolUtil.defaultDifficulty))) {
			curDifficulty = Math.round(Math.max(0, CoolUtil.getDifficultyIndex(Paths.formatToSongPath(CoolUtil.defaultDifficulty))));
		}
		else {
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.getDifficultyIndex(lastDifficultyName);

		if (newPos > -1) {
			curDifficulty = newPos;
		}

		changeDifficulty();
		updateText();
	}

	function updateText():Void
	{
		var leName:String = curWeek.storyName;
		txtWeekTitle.text = leName.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		var assetName:String = curWeek.weekBackground;

		if (assetName == null || assetName.length < 1) {
			bgSprite.visible = false;
		}
		else
		{
			bgSprite.visible = true;

			if (Paths.fileExists('images/menubackgrounds/menu_' + assetName + '.png', IMAGE)) {
				bgSprite.loadGraphic(Paths.getImage('menubackgrounds/menu_' + assetName));
			}
			else if (Paths.fileExists('images/storymenu/menubackgrounds/menu_' + assetName + '.png', IMAGE)) {
				bgSprite.loadGraphic(Paths.getImage('storymenu/menubackgrounds/menu_' + assetName));
			}
			else {
				bgSprite.visible = false;
			}
		}

		var weekArray:Array<String> = curWeek.weekCharacters;

		for (i in 0...grpWeekCharacters.length) {
			grpWeekCharacters.members[i].changeCharacter(weekArray[i]);
		}

		txtTracklist.text = [for (i in curWeek.songs) i.songName.toUpperCase()].join('\n');
		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		var unlocked:Bool = !WeekData.weekIsLocked(curWeek.fileName);

		sprDifficulty.visible = unlocked;
		leftArrow.visible = unlocked && CoolUtil.difficultyStuff.length > 1;
		rightArrow.visible = unlocked && CoolUtil.difficultyStuff.length > 1;
	}

	var tweenDifficulty:FlxTween;

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, CoolUtil.difficultyStuff.length - 1);

		var diff:String = CoolUtil.difficultyStuff[curDifficulty][0];

		var path:String = 'storymenu/menudifficulties/' + diff;
		if (Paths.fileExists('images/menudifficulties/' + diff + '.png', IMAGE)) path = 'menudifficulties/' + diff;

		var newImage:FlxGraphic = Paths.getImage(path);

		if (sprDifficulty.graphic != newImage)
		{
			sprDifficulty.loadGraphic(newImage);
			sprDifficulty.x = leftArrow.x + 60;
			sprDifficulty.x += (308 - sprDifficulty.width) / 2;
			sprDifficulty.alpha = 0;
			sprDifficulty.y = leftArrow.y - 15;

			if (tweenDifficulty != null) tweenDifficulty.cancel();

			tweenDifficulty = FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07,
			{
				onComplete: function(twn:FlxTween):Void {
					tweenDifficulty = null;
				}
			});
		}

		lastDifficultyName = diff;

		#if !switch
		intendedScore = Highscore.getWeekScore(curWeek.weekID, curDifficulty);
		#end
	}
}