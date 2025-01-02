package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxStringUtil;
import flixel.addons.transition.FlxTransitionableState;

using StringTools;

class PauseSubState extends MusicBeatSubState
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var pauseOG:Array<String> = [
		'Resume',
		'Restart Song',
		'Change Difficulty',
		'Options',
		'Exit to menu'
	];
	var difficultyChoices:Array<String> = [];

	var menuItems:Array<String> = [];
	var curSelected:Int = 0;

	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var skipTimeTracker:Alphabet;
	var curTime:Float = Math.max(0, Conductor.songPosition);

	var pauseMusic:FlxSound;

	public static var songName:String = null;

	override function create():Void
	{
		if (CoolUtil.difficultyStuff.length < 2) pauseOG.remove('Change Difficulty'); // No need to change difficulty if there is only one!

		if (PlayState.chartingMode)
		{
			pauseOG.insert(2, 'Leave Charting Mode');

			var num:Int = 0;

			if (!PlayState.instance.startingSong)
			{
				num = 1;
				pauseOG.insert(3, 'Skip Time');
			}

			pauseOG.insert(3 + num, 'End Song');
			pauseOG.insert(4 + num, 'Toggle Practice Mode');
			pauseOG.insert(5 + num, 'Toggle Botplay');
		}

		menuItems = pauseOG;

		for (i in 0...CoolUtil.difficultyStuff.length)
		{
			var diff:String = CoolUtil.difficultyStuff[i][1].toUpperCase();
			difficultyChoices.push(diff);
		}

		difficultyChoices.push('BACK');

		pauseMusic = new FlxSound();

		try
		{
			var pauseSong:String = getPauseSong();
			if (pauseSong != null) pauseMusic.loadEmbedded(Paths.getMusic(pauseSong), true, true);
		}
		catch (e:Dynamic) {}

		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		FlxG.sound.list.add(pauseMusic);

		var bg:Sprite = new Sprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, '', 32);
		levelInfo.text += PlayState.SONG.songName;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.getFont('vcr.ttf'), 32);
		levelInfo.updateHitbox();
		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, '', 32);
		levelDifficulty.text += CoolUtil.difficultyString(true);
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.getFont('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		add(levelDifficulty);

		var blueballedTxt:FlxText = new FlxText(20, 15 + 64, 0, '', 32);
		blueballedTxt.text = 'Blue balled: ' + PlayState.deathCounter;
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.getFont('vcr.ttf'), 32);
		blueballedTxt.updateHitbox();
		blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);
		add(blueballedTxt);

		var chartingText:FlxText = new FlxText(20, 15 + 96, 0, "CHARTING MODE", 32);
		chartingText.scrollFactor.set();
		chartingText.setFormat(Paths.getFont('vcr.ttf'), 32);
		chartingText.x = FlxG.width - (chartingText.width + 20);
		chartingText.updateHitbox();
		chartingText.alpha = 0;
		add(chartingText);

		practiceText = new FlxText(20, 20 + (96 + (PlayState.chartingMode ? 32 : 0)), 0, 'PRACTICE MODE', 32);
		practiceText.scrollFactor.set();
		practiceText.setFormat(Paths.getFont('vcr.ttf'), 32);
		practiceText.x = FlxG.width - (practiceText.width + 20);
		practiceText.updateHitbox();
		practiceText.visible = false;
		add(practiceText);

		levelInfo.alpha = 0;
		levelDifficulty.alpha = 0;
		blueballedTxt.alpha = 0;

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

		if (PlayState.instance.practiceMode)
		{
			practiceText.visible = true;
			practiceText.alpha = 0;
			practiceText.y -= 5;

			FlxTween.tween(practiceText, {alpha: 1, y: practiceText.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: (PlayState.chartingMode ? 1.1 : 0.9)});
		}

		if (PlayState.chartingMode) {
			FlxTween.tween(chartingText, {alpha: 1, y: chartingText.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.9});
		}

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		regenMenu();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		super.create();
	}

	function getPauseSong():String
	{
		var formattedSongName:String = (songName != null ? Paths.formatToSongPath(songName) : '');
		var formattedPauseMusic:String = Paths.formatToSongPath(ClientPrefs.pauseMusic);
		if (formattedSongName == 'none' || (formattedSongName != 'none' && formattedPauseMusic == 'none')) return null;

		return (formattedSongName != '') ? formattedSongName : formattedPauseMusic;
	}

	private function regenMenu():Void
	{
		while (grpMenuShit.members.length > 0) {
			grpMenuShit.remove(grpMenuShit.members[0], true);
		}

		for (i in 0...menuItems.length)
		{
			var item:Alphabet = new Alphabet(90, 320, menuItems[i], true);
			item.isMenuItem = true;
			item.targetY = i;
			grpMenuShit.add(item);

			if (menuItems[i] == 'Skip Time')
			{
				skipTimeText = new FlxText(0, 0, 0, '', 64);
				skipTimeText.setFormat(Paths.getFont('vcr.ttf'), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				skipTimeText.scrollFactor.set();
				skipTimeText.borderSize = 2;
				skipTimeTracker = item;
				add(skipTimeText);

				updateSkipTextStuff();
				updateSkipTimeText();
			}

			item.setPosition(0, (70 * i) + 30);
		}

		curSelected = 0;
		changeSelection();
	}

	var holdTime:Float = 0;
	var holdTimePos:Float = 0;
	var cantUnpause:Float = 0.1;

	override function update(elapsed:Float):Void
	{
		cantUnpause -= elapsed;

		if (pauseMusic != null && pauseMusic.volume < 0.5) {
			pauseMusic.volume += 0.01 * elapsed;
		}

		super.update(elapsed);
		updateSkipTextStuff();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;

		var alphabet:Alphabet = grpMenuShit.members[curSelected];
		var mousePoint:FlxPoint = FlxG.mouse.getScreenPosition(camera);
		var objPoint:FlxPoint = alphabet.getScreenPosition(null, camera);

		var bullShit:Bool = mousePoint.x >= objPoint.x && mousePoint.y >= objPoint.y && mousePoint.x < objPoint.x + alphabet.width && mousePoint.y < objPoint.y + alphabet.height;
		var accepted = controls.ACCEPT_P || (FlxG.mouse.justPressed && bullShit);

		if (menuItems.length > 1)
		{
			if (upP)
			{
				FlxG.sound.play(Paths.getSound('scrollMenu'));
				changeSelection(-1);

				holdTime = 0;
			}

			if (downP)
			{
				FlxG.sound.play(Paths.getSound('scrollMenu'));
				changeSelection(1);

				holdTime = 0;
			}

			if (controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'));
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
				}
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.getSound('scrollMenu'));
				changeSelection(-1 * FlxG.mouse.wheel);
			}
		}

		var daSelected:String = menuItems[curSelected];

		switch (daSelected)
		{
			case 'Skip Time':
			{
				if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);

					curTime -= 1000;
					holdTimePos = 0;
				}

				if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);

					curTime += 1000;
					holdTimePos = 0;
				}

				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTimePos += elapsed;

					if (holdTimePos > 0.5) {
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}

					if (curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
					else if (curTime < 0) curTime += FlxG.sound.music.length;

					updateSkipTimeText();
				}
			}
		}

		if (accepted && cantUnpause <= 0)
		{
			if (menuItems == difficultyChoices)
			{
				if (menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected))
				{
					var name:String = PlayState.SONG.songID;
					var poop:String = CoolUtil.formatSong(name, curSelected);
					var path:String = Paths.getJson('data/$name/$poop');

					if (Paths.fileExists(path, TEXT))
					{
						try {
							PlayState.SONG = Song.loadFromJson(poop, name);
						}
						catch (e:Dynamic)
						{
							Debug.logError('Error on changing difficulty data file with id "' + name + '": ' + e);
							return;
						}

						if (curSelected != PlayState.lastDifficulty)
						{
							PlayState.usedPractice = true;
							PlayState.changedDifficulty = true;
						}

						FlxG.sound.music.volume = 0;
						PlayState.lastDifficulty = curSelected;

						LoadingState.loadAndSwitchState(new PlayState(), true);
					}
					else {
						Debug.logError('Error on loading data file with id "' + name + '": File not found');
					}

					return;
				}

				menuItems = pauseOG;
				regenMenu();
			}

			switch (daSelected)
			{
				case 'Resume': close();
				case 'Restart Song': restartSong();
				case 'Change Difficulty':
				{
					menuItems = difficultyChoices;
					regenMenu();
				}
				case 'Toggle Practice Mode':
				{
					PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
					PlayState.usedPractice = true;

					practiceText.visible = PlayState.instance.practiceMode;
				}
				case 'Leave Charting Mode':
				{
					restartSong();
					PlayState.chartingMode = false;
				}
				case 'Skip Time':
				{
					if (curTime < Conductor.songPosition)
					{
						PlayState.startOnTime = curTime;
						restartSong(true);
					}
					else
					{
						if (curTime != Conductor.songPosition)
						{
							PlayState.instance.clearNotesBefore(curTime);
							PlayState.instance.setSongTime(curTime);
						}

						close();
					}
				}
				case 'End Song':
				{
					close();

					PlayState.instance.notes.clear();
					PlayState.instance.unspawnNotes = [];
					PlayState.instance.finishSong(true);
				}
				case 'Toggle Botplay':
				{
					PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
					PlayState.usedPractice = true;

					PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
					PlayState.instance.botplayTxt.alpha = 1;
					PlayState.instance.botplaySine = 0;
				}
				case 'Options':
				{
					PlayState.instance.paused = true; // For lua
					PlayState.instance.vocals.volume = 0;
					PlayState.instance.opponentVocals.volume = 0;

					FlxG.switchState(new options.OptionsMenuState());

					if (ClientPrefs.pauseMusic != 'None')
					{
						FlxG.sound.playMusic(Paths.getMusic(Paths.formatToSongPath(ClientPrefs.pauseMusic)), pauseMusic.volume);
						FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);

						FlxG.sound.music.time = pauseMusic.time;
					}

					options.OptionsMenuState.onPlayState = true;
				}
				case 'Exit to menu':
				{
					#if DISCORD_ALLOWED
					DiscordClient.resetClientID(); #end

					PlayState.instance.stopMusic();

					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;
					PlayState.chartingMode = false;
					PlayState.usedPractice = false;
					PlayState.changedDifficulty = false;

					Paths.loadTopMod();

					PlayState.firstSong = null;

					switch (PlayState.gameMode)
					{
						case 'story':
							FlxG.switchState(new StoryMenuState());
						case 'freeplay':
							FlxG.switchState(new FreeplayMenuState());
						default:
							FlxG.switchState(new MainMenuState());
					}

					FlxG.camera.followLerp = 0;
				}
			}
		}
	}

	function deleteSkipTimeText():Void
	{
		if (skipTimeText != null)
		{
			skipTimeText.kill();
			remove(skipTimeText);
			skipTimeText.destroy();
		}

		skipTimeText = null;
		skipTimeTracker = null;
	}

	public static function restartSong(noTrans:Bool = false):Void
	{
		PlayState.instance.paused = true; // For lua

		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;
		PlayState.instance.opponentVocals.volume = 0;

		if (noTrans)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
		}

		FlxG.resetState();
	}

	override function destroy():Void
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;

				if (item == skipTimeTracker)
				{
					curTime = Math.max(0, Conductor.songPosition);
					updateSkipTimeText();
				}
			}
		}

		FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);
	}

	function updateSkipTextStuff():Void
	{
		if (skipTimeText == null || skipTimeTracker == null) return;

		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText():Void
	{
		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
	}
}