package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import openfl.errors.Error;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

using StringTools;

class FreeplayMenuState extends MusicBeatState
{
	private static var curSelected:Int = -1;
	private static var lastDifficultyName:String = '';

	var curDifficulty:Int = -1;

	private var songsArray:Array<SongMetaData> = [];
	private var curSong:SongMetaData;

	var scoreBG:Sprite;
	var scoreText:FlxText;
	var diffText:FlxText;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var grpIcons:FlxTypedGroup<HealthIcon>;

	var bg:Sprite;

	var startingTweenBGColor:Bool = true;
	var startColor:FlxColor = FlxColor.WHITE;
	var intendedColor:FlxColor;
	var colorTween:FlxTween;

	override function create():Void
	{
		PlayState.gameMode = 'freeplay';
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus"); // Updating Discord Rich Presence
		#end

		if (FlxG.sound.music != null && (!FlxG.sound.music.playing || FlxG.sound.music.volume == 0)) {
			FlxG.sound.playMusic(Paths.getMusic('freakyMenu'));
		}

		for (i in 0...WeekData.weeksList.length)
		{
			if (WeekData.weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.getFromFileName(WeekData.weeksList[i]);

			WeekData.setDirectoryFromWeek(leWeek);

			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song.color;

				if (colors == null || colors.length < 3) {
					colors = [146, 113, 253];
				}

				var newSong:SongMetaData = new SongMetaData(song.songID, song.songName, i, song.icon, FlxColor.fromRGB(colors[0], colors[1], colors[2]));
				newSong.difficulties = song.difficulties;
				newSong.defaultDifficulty = song.defaultDifficulty;
				songsArray.push(newSong);
			}
		}

		Paths.loadTopMod();

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

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		grpIcons = new FlxTypedGroup<HealthIcon>();
		add(grpIcons);

		for (i in 0...songsArray.length)
		{
			if (curSelected < 0) curSelected = i;
			var leSong:SongMetaData = songsArray[i];

			var songText:Alphabet = new Alphabet(90, 320, leSong.songName, true);
			songText.isMenuItem = true;
			songText.targetY = i - curSelected;
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.setPosition(0, (70 * i) + 30);

			Paths.currentModDirectory = leSong.folder;

			var icon:HealthIcon = new HealthIcon(leSong.songCharacter);
			icon.sprTracker = songText;
			icon.ID = i;
			grpIcons.add(icon);
		}

		Paths.loadTopMod();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, RIGHT);
		add(scoreText);

		scoreBG = new Sprite(scoreText.x - 6, 0);
		scoreBG.makeGraphic(1, 66, 0x99000000);
		insert(members.indexOf(scoreText), scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, '', 24);
		diffText.setFormat(Paths.getFont('vcr.ttf'), 24, FlxColor.WHITE);
		add(diffText);

		var textBG:Sprite = new Sprite(0, FlxG.height);
		textBG.makeGraphic(FlxG.width, 26, FlxColor.BLACK);
		textBG.alpha = 0.6;
		add(textBG);

		#if PRELOAD_ALL
		var leText:String = "Press SPACE to listen to the Song | Press CTRL to open the Gameplay Changers Menu | Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press CTRL to open the Gameplay Changers Menu | Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end

		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.getFont('vcr.ttf'), size, FlxColor.WHITE, RIGHT);
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
		changeDifficulty();

		super.create();
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

		#if !switch
		intendedScore = Highscore.getScore(curSong.songID, curDifficulty);
		intendedAccuracy = Highscore.getAccuracy(curSong.songID, curDifficulty);
		#end

		if (startingTweenBGColor)
		{
			var newColor:FlxColor = curSong.color;

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

	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;

	public static function destroyFreeplayVocals():Void
	{
		if (vocals != null)
		{
			vocals.stop();
			vocals.destroy();
		}

		vocals = null;

		if (opponentVocals != null)
		{
			opponentVocals.stop();
			opponentVocals.destroy();
		}

		opponentVocals = null;
	}

	var instPlaying:Int = -1;

	var holdTime:Float = 0;
	var holdTimeDiff:Float = 0;

	var lerpScore:Float = 0;
	var lerpAccuracy:Float = 0;

	var intendedScore:Float = 0;
	var intendedAccuracy:Float = 0;

	override function update(elapsed:Float):Void
	{
		if (FlxG.sound.music.volume < 0.7) {
			FlxG.sound.music.volume += 0.5 * elapsed;
		}

		lerpScore = FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24));
		lerpAccuracy = FlxMath.lerp(intendedAccuracy, lerpAccuracy, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10) {
			lerpScore = intendedScore;
		}

		if (Math.abs(lerpAccuracy - intendedAccuracy) <= 0.01) {
			lerpAccuracy = intendedAccuracy;
		}

		var accuracySplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpAccuracy * 100, 2)).split('.');

		if (accuracySplit.length < 2) { // No decimals, add an empty space
			accuracySplit.push('');
		}

		while (accuracySplit[1].length < 2) { // Less than 2 decimals in it, add decimals then
			accuracySplit[1] += '0';
		}

		scoreText.text = "PERSONAL BEST:" + Math.round(lerpScore) + ' (' + accuracySplit.join('.') + '%)';
		positionHighscore();

		if (controls.BACK_P)
		{
			persistentUpdate = false;

			if (colorTween != null) {
				colorTween.cancel();
			}

			FlxG.sound.play(Paths.getSound('cancelMenu'));
			FlxG.switchState(new MainMenuState());
		}

		if (CoolUtil.difficultyStuff.length > 1)
		{
			if (controls.UI_RIGHT_P)
			{
				changeDifficulty(1);
				holdTimeDiff = 0;
			}

			if (controls.UI_LEFT_P)
			{
				changeDifficulty(-1);
				holdTimeDiff = 0;
			}

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

		if (songsArray.length > 1)
		{
			var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

			if (controls.UI_DOWN_P)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if (controls.UI_UP_P)
			{
				changeSelection(-shiftMult);
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

			if (FlxG.mouse.wheel != 0 && !FlxG.mouse.pressedMiddle) {
				changeSelection(-1 * FlxG.mouse.wheel);
			}
		}

		if (FlxG.keys.justPressed.CONTROL)
		{
			if (colorTween != null) {
				colorTween.active = false;
			}

			persistentUpdate = false;
			openSubState(new GameplayChangersSubState());
		}

		if (controls.RESET_P)
		{
			if (colorTween != null) {
				colorTween.active = false;
			}

			persistentUpdate = false;

			openSubState(new ResetScoreSubState(curSong.songName, curDifficulty, curSong.songCharacter));
			FlxG.sound.play(Paths.getSound('scrollMenu'));
		}

		#if PRELOAD_ALL
		if (FlxG.keys.justPressed.SPACE)
		{
			if (instPlaying != curSelected)
			{
				var songLowercase:String = curSong.songID;
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

					var instPath:String = Paths.getInst(PlayState.SONG.songID, CoolUtil.difficultyStuff[curDifficulty][2], true);

					var characterFile = Character.getCharacterFile(PlayState.SONG.player1);
					var postfix:String = ((characterFile != null && characterFile.vocals_file != null && characterFile.vocals_file.length > 0) ? characterFile.vocals_file : 'Player');
					var playerVocalPath:String = Paths.getVoices(PlayState.SONG.songID, CoolUtil.difficultyStuff[curDifficulty][2], postfix, true);

					if (!Paths.fileExists(playerVocalPath, SOUND)) {
						playerVocalPath = Paths.getVoices(PlayState.SONG.songID, CoolUtil.difficultyStuff[curDifficulty][2], true);
					}

					var characterFile = Character.getCharacterFile(PlayState.SONG.player2);
					var postfix:String = ((characterFile != null && characterFile.vocals_file != null && characterFile.vocals_file.length > 0) ? characterFile.vocals_file : 'Opponent');
					var opponentVocalPath:String = Paths.getVoices(PlayState.SONG.songID, CoolUtil.difficultyStuff[curDifficulty][2], postfix, true);

					if (Paths.fileExists(instPath, SOUND))
					{
						destroyFreeplayVocals();

						FlxG.sound.music.volume = 0;
						Paths.currentModDirectory = curSong.folder;

						FlxG.sound.playMusic(Paths.getInst(PlayState.SONG.songID, CoolUtil.difficultyStuff[curDifficulty][2]), 0.7);

						if (Paths.fileExists(playerVocalPath, SOUND) && PlayState.SONG.needsVoices)
						{
							vocals = new FlxSound();
							vocals.loadEmbedded(Paths.getVoices(PlayState.SONG.songID, CoolUtil.difficultyStuff[curDifficulty][2], 'Player'));
							vocals.persist = true;
							vocals.looped = true;
							vocals.volume = 0.7;
							vocals.play();
						}

						if (Paths.fileExists(opponentVocalPath, SOUND) && PlayState.SONG.needsVoices)
						{
							opponentVocals = new FlxSound();
							opponentVocals.loadEmbedded(Paths.getVoices(PlayState.SONG.songID, CoolUtil.difficultyStuff[curDifficulty][2], 'Opponent'));
							opponentVocals.persist = true;
							opponentVocals.looped = true;
							opponentVocals.volume = 0.7;
							opponentVocals.play();
						}

						instPlaying = curSelected;
					}
					else {
						Debug.logError('Inst sound file of song with id "' + PlayState.SONG.songID + '" not found.');
					}
				}
				else {
					Debug.logError('Error on loading data file with id "' + songLowercase + '": File not found');
				}
			}
		}
		else #end if (controls.ACCEPT_P || (FlxG.mouse.justPressed && FlxG.mouse.overlaps(grpSongs.members[curSelected])))
		{
			var songLowercase:String = curSong.songID;
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

				PlayState.lastDifficulty = curDifficulty;

				if (colorTween != null) {
					colorTween.cancel();
				}

				var diffName:String = CoolUtil.difficultyStuff[PlayState.lastDifficulty][1];
				var weekName:String = WeekData.getCurrentWeek().weekName;

				Debug.logInfo('Loading song "' + PlayState.SONG.songName + '" on difficulty "' + diffName + '" into week "' + weekName + '".');

				LoadingState.loadAndSwitchState(new PlayState(), true);

				#if (DISCORD_ALLOWED && MODS_ALLOWED)
				DiscordClient.loadModRPC();
				#end
			}
			else {
				Debug.logError('Error on loading data file with id "' + songLowercase + '": File not found');
			}
		}

		super.update(elapsed);
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, songsArray.length - 1);
		curSong = songsArray[curSelected];

		var bullShit:Int = 0;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}

		for (icon in grpIcons)
		{
			icon.alpha = 0.6;

			if (icon.ID == curSelected) {
				icon.alpha = 1;
			}
		}

		if (!startingTweenBGColor)
		{
			var newColor:FlxColor = curSong.color;

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

		Paths.currentModDirectory = curSong.folder;
		PlayState.storyWeek = curSong.week;

		var leWeek:WeekData = WeekData.getCurrentWeek();

		if (curSong.difficulties != null && curSong.difficulties.length > 0) {
			CoolUtil.copyDifficultiesFrom(curSong.difficulties);
		}
		else if (leWeek.difficulties != null && leWeek.difficulties.length > 0) {
			CoolUtil.copyDifficultiesFrom(leWeek.difficulties);
		}
		else {
			CoolUtil.resetDifficulties();
		}

		if (CoolUtil.difficultyExists(curSong.defaultDifficulty)) {
			curDifficulty = Math.round(Math.max(0, CoolUtil.getDifficultyIndex(curSong.defaultDifficulty)));
		}
		else if (CoolUtil.difficultyExists(leWeek.defaultDifficulty)) {
			curDifficulty = Math.round(Math.max(0, CoolUtil.getDifficultyIndex(leWeek.defaultDifficulty)));
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
		FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, CoolUtil.difficultyStuff.length - 1);
		lastDifficultyName = CoolUtil.difficultyStuff[curDifficulty][0];

		#if !switch
		intendedScore = Highscore.getScore(curSong.songID, curDifficulty);
		intendedAccuracy = Highscore.getAccuracy(curSong.songID, curDifficulty);
		#end

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = '< ' + CoolUtil.difficultyString() + ' >';

		positionHighscore();
	}

	function positionHighscore():Void
	{
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - scoreBG.scale.x / 2;

		diffText.x = Std.int(scoreBG.x + scoreBG.width / 2);
		diffText.x -= (diffText.width / 2);
	}
}

class SongMetaData
{
	public var songID:String = '';
	public var songName:String = '';
	public var week:Int = 0;
	public var songCharacter:String = '';
	public var color:FlxColor = FlxColor.WHITE;
	public var folder:String = '';
	public var difficulties:Array<Array<String>>;
	public var defaultDifficulty:String;

	public function new(songID:String, songName:String, week:Int, songCharacter:String, color:FlxColor):Void
	{
		this.songID = songID;
		this.songName = songName;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;

		folder = Paths.currentModDirectory;
		if (folder == null) folder = '';
	}
}