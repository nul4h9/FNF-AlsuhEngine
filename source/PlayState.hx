package;

import haxe.Json;
import haxe.io.Path;
import haxe.Exception;
import haxe.Constraints;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import Song;
import Note;
import Conductor;
import StageData;
import Character;
import DialogueBoxPsych;

import HScript;
import FunkinLua;

#if ACHIEVEMENTS_ALLOWED
import Achievements;
#end

#if RUNTIME_SHADERS_ALLOWED
import shaders.WiggleEffect;
import flixel.addons.display.FlxRuntimeShader;
#end

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import openfl.errors.Error;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxSort;
import flixel.util.FlxSave;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.display.BlendMode;
import flixel.util.FlxStringUtil;
import flixel.group.FlxSpriteGroup;
import openfl.events.KeyboardEvent;
import flixel.input.keyboard.FlxKey;
import flixel.addons.effects.FlxTrail;
import flixel.addons.transition.FlxTransitionableState;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X:Float = 49;
	public static var STRUM_X_MIDDLESCROLL:Float = -274;

	public static var ratingStuff:Array<Dynamic> =
	[
		['F', 0.2], //From 0% to 19%
		['E', 0.4], //From 20% to 39%
		['D', 0.5], //From 40% to 49%
		['C', 0.6], //From 50% to 59%
		['B', 0.69], //From 60% to 68%
		['A', 0.7], //69%
		['A+', 0.8], //From 70% to 79%
		['S', 0.9], //From 80% to 89%
		['S+', 1], //From 90% to 99%
		['S++', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];

	public static var SONG:SwagSong = null;
	public static var instance:PlayState = null;
	public static var gameMode:String = 'story';
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var firstSong:String = 'tutorial';
	public static var storyPlaylist:Array<String> = [];
	public static var usedPractice:Bool = false;
	public static var lastDifficulty:Int = 1;
	public static var storyDifficulty:Int = 1;
	public static var changedDifficulty:Bool = false;
	public static var isPixelStage:Bool = false;
	public static var chartingMode:Bool = false;

	public static var Function_Stop:Dynamic = "##NULL_FUNCTIONSTOP";
	public static var Function_Continue:Dynamic = "##NULL_FUNCTIONCONTINUE";
	public static var Function_StopLua:Dynamic = "##NULL_FUNCTIONSTOPLUA";
	public static var Function_StopHScript:Dynamic = "##NULL_FUNCTIONSTOPHSCRIPT";
	public static var Function_StopAll:Dynamic = "##NULL_FUNCTIONSTOPALL";
	public static var instanceStr:Dynamic = "##NULL_STRINGTOOBJ";

	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, Sprite> = new Map<String, Sprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();

	public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();

	#if MODS_ALLOWED
	public var debugMode:Bool = false;
	public var debugTextGroup:FlxTypedGroup<DebugText>;
	#end

	#if LUA_ALLOWED
	public var luaArray:Array<FunkinLua> = [];
	#end

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	#end

	public static var daPixelZoom:Float = 6; // how big to stretch the pixel art assets

	public var inst:FlxSound;
	public var vocals:FlxSound;
	var vocalsFinished:Bool = false;

	public var dad:Character;
	public var opponentCameraOffset:Array<Float> = null;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var dadGroup:FlxTypedSpriteGroup<Character>;
	public var dadMap:Map<String, Character> = new Map<String, Character>();

	public var gf:Character;
	public var girlfriendCameraOffset:Array<Float> = null;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;
	public var gfGroup:FlxTypedSpriteGroup<Character>;
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	public var boyfriend:Character;
	public var boyfriendCameraOffset:Array<Float> = null;
	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var boyfriendGroup:FlxTypedSpriteGroup<Character>;
	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();

	public var spawnTime:Float = 2000;
	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = 'multiplicative';
	public var noteKillOffset:Float = 350;

	// gameplay settings
	public var addScoreOnPractice:Bool = false;
	public var playbackRate(default, set):Float = 1;
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var unspawnNotes:Array<Note>;
	public var eventNotes:Array<EventNote> = [];

	public var isCameraOnForcedPos:Bool = false;

	public var allowPlayCutscene(default, set):Bool = false;

	public var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;

	public var gfSpeed:Int = 1;
	public var combo:Int = 0;
	public var health(default, set):Float = 1;
	public var healthLerp:Float = -1;

	var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = Rating.loadDefault();

	public var paused:Bool = false;
	public var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;

	var updateTime:Bool = true;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var camCustom:FlxCamera;
	public var camNoteCombo:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var songAccuracy:Float = 0;
	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;
	public var ratingName:String = 'N/A';
	public var ratingFC:String;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
	public var defaultCamZoom:Float = 1.05;

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;

	var songLength:Float = 0;

	#if DISCORD_ALLOWED // Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	var keysPressed:Array<Int> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	private var keysArray:Array<String>;

	var doof:DialogueBox = null;

	override public function create():Void
	{
		Paths.clearStoredMemory();

		instance = this; // for lua and stuff

		PauseSubState.songName = null; // Reset to default

		playbackRate = ClientPrefs.getGameplaySetting('songspeed');
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');

		usedPractice = cpuControlled || practiceMode;

		keysArray = [for (i in Note.pointers) 'note_' + i];

		if (FlxG.sound.music != null) {
			FlxG.sound.music.stop();
		}

		FreeplayMenuState.destroyFreeplayVocals();

		camGame = initSwagCamera();

		camCustom = new FlxCamera();
		camCustom.bgColor.alpha = 0;
		FlxG.cameras.add(camCustom, false);

		camNoteCombo = new FlxCamera();
		camNoteCombo.bgColor.alpha = 0;
		FlxG.cameras.add(camNoteCombo, false);

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;
		FlxG.cameras.add(camOther, false);

		persistentUpdate = true;
		persistentDraw = true;

		var mode:String = Paths.formatToSongPath(ClientPrefs.cutscenesOnMode);
		allowPlayCutscene = mode.contains(gameMode) || ClientPrefs.cutscenesOnMode == 'Everywhere';

		if (SONG == null) SONG = Song.loadFromJson('tutorial');

		#if DISCORD_ALLOWED
		initDiscord();
		#end

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		GameOverSubState.resetVariables();

		if (SONG.stage == null || SONG.stage.length < 1) {
			SONG.stage = StageData.vanillaSongStage(SONG.songID);
		}

		createStageAndChars(SONG.stage);

		#if MODS_ALLOWED
		debugTextGroup = new FlxTypedGroup<DebugText>();
		debugTextGroup.cameras = [camOther];
		add(debugTextGroup);
		#end

		#if sys
		var defaultDirectories:Array<String> = [Paths.getLibraryPath()];

		var libraryPath:String = Paths.getLibraryPath('', 'shared');
		defaultDirectories.insert(0, libraryPath.substring(libraryPath.indexOf(':') + 1, libraryPath.length));

		if (Paths.currentLevel != null && Paths.currentLevel.length > 0 && Paths.currentLevel != 'shared')
		{
			var libraryPath:String = Paths.getLibraryPath('', Paths.currentLevel);
			defaultDirectories.insert(0, libraryPath.substring(libraryPath.indexOf(':') + 1, libraryPath.length));
		}

		var foldersToCheck:Array<String> = Paths.directoriesWithFile(defaultDirectories, 'scripts/');

		for (folder in foldersToCheck)
		{
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if (file.toLowerCase().endsWith('.lua')) {
					new FunkinLua(folder + file);
				}
				#end

				#if HSCRIPT_ALLOWED
				if (file.toLowerCase().endsWith('.hx')) {
					initHScript(folder + file);
				}
				#end
			}
		}
		#end

		#if LUA_ALLOWED
		startLuasNamed('stages/' + SONG.stage);
		#end

		#if HSCRIPT_ALLOWED
		startHScriptsNamed('stages/' + SONG.stage);
		#end

		if (!stageData.hide_girlfriend)
		{
			if (SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf'; // Fix for the Chart Editor

			gf = new Character(0, 0, SONG.gfVersion);
			startCharacterPos(gf);
			gfGroup.add(gf);

			startCharacterScripts(gf.curCharacter);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);

		startCharacterScripts(dad.curCharacter);

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);

			if (gf != null) {
				gf.visible = false;
			}
		}

		if (!ClientPrefs.lowQuality && dad.curCharacter.contains('spirit') && SONG.stage == 'schoolEvil')
		{
			var trail:FlxTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
			addBehindDad(trail);
		}

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);

		startCharacterScripts(boyfriend.curCharacter);

		if (boyfriend != null)
		{
			if (boyfriend.deathChar != null && boyfriend.deathChar.trim().length > 0) GameOverSubState.characterName = boyfriend.deathChar;
			if (boyfriend.deathSound != null && boyfriend.deathSound.trim().length > 0) GameOverSubState.deathSoundName = boyfriend.deathSound;
			if (boyfriend.deathMusic != null && boyfriend.deathMusic.trim().length > 0) GameOverSubState.loopSoundName = boyfriend.deathMusic;
			if (boyfriend.deathConfirm != null && boyfriend.deathConfirm.trim().length > 0) GameOverSubState.endSoundName = boyfriend.deathConfirm;
		}

		Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;

		generateSong(SONG);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		FlxG.camera.follow(camFollow, null, 0);
		FlxG.camera.zoom = defaultCamZoom;

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		if (prevCamFollow == null)
		{
			if (gf != null && SONG.gfVersion != 'none') {
				moveCameraToGF(true);
			}
			else
			{
				moveCameraToGF(true);
				cameraMovementSection();
			}
		}
		else {
			snapCamFollowToPos(prevCamFollow.x, prevCamFollow.y);
		}

		startingSong = true;

		createHud();

		#if LUA_ALLOWED
		for (notetype in noteTypes) startLuasNamed('custom_notetypes/' + notetype);
		for (event in eventsPushed) startLuasNamed('custom_events/' + event);
		#end

		#if HSCRIPT_ALLOWED
		for (notetype in noteTypes) startHScriptsNamed('custom_notetypes/' + notetype);
		for (event in eventsPushed) startHScriptsNamed('custom_events/' + event);
		#end

		noteTypes = null;
		eventsPushed = null;

		if (eventNotes.length > 1)
		{
			for (event in eventNotes) event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		#if sys
		var foldersToCheck:Array<String> = Paths.directoriesWithFile([Paths.getPreloadPath()], 'data/' + SONG.songID + '/');

		for (folder in foldersToCheck)
		{
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if (file.toLowerCase().endsWith('.lua')) {
					new FunkinLua(folder + file);
				}
				#end

				#if HSCRIPT_ALLOWED
				if (file.toLowerCase().endsWith('.hx')) {
					initHScript(folder + file);
				}
				#end
			}
		}
		#end

		#if ACHIEVEMENTS_ALLOWED
		Achievements.load();

		for (award in Achievements.achievements)
		{
			#if LUA_ALLOWED
			startLuasNamed('achivements/' + award.save_tag);
			startLuasNamed('achivements/' + award.lua_code);
			#end

			#if HSCRIPT_ALLOWED
			startHScriptsNamed('achivements/' + award.save_tag);
			startHScriptsNamed('achivements/' + award.hx_code);
			#end
		}
		#end

		var mode:String = Paths.formatToSongPath(ClientPrefs.cutscenesOnMode);
		allowPlayCutscene = mode.contains(gameMode) || ClientPrefs.cutscenesOnMode == 'Everywhere';

		if (SONG.songID != firstSong && gameMode == 'story' && !seenCutscene)
		{
			skipArrowStartTween = true;

			if (prevCamFollow != null) {
				cameraMovementSection();
			}
		}

		prevCamFollow = null;

		var file:String = Paths.getTxt('data/' + SONG.songID + '/' + SONG.songID + 'Dialogue');

		if (Paths.fileExists(file, TEXT))
		{
			dialogue = CoolUtil.coolTextFile(file);

			doof = new DialogueBox(false, dialogue);
			doof.cameras = [camHUD];
			doof.scrollFactor.set();
			doof.finishThing = startCountdown;
		}

		if (allowPlayCutscene && !seenCutscene)
		{
			switch (SONG.songID)
			{
				case 'tutorial':
				{
					camHUD.visible = false;
					FlxG.camera.zoom = 2.1;

					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5 / playbackRate,
					{
						ease: FlxEase.quadInOut,
						onComplete: function(twn:FlxTween):Void
						{
							cameraMovementSection();

							camHUD.visible = true;
							startCountdown();
						}
					});
				}
				case 'monster':
				{
					inCutscene = true;
					camHUD.visible = false;

					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					FlxG.sound.play(Paths.getSoundRandom('thunder_', 1, 2))#if FLX_PITCH .pitch = playbackRate #end; // character anims

					if (gf != null) gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

					var whiteScreen:Sprite = new Sprite(); // white flash
					whiteScreen.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					add(whiteScreen);

					FlxTween.tween(whiteScreen, {alpha: 0}, 1 / playbackRate,
					{
						startDelay: 0.1,
						onComplete: function(twn:FlxTween):Void
						{
							new FlxTimer().start(1.25 / playbackRate, function(tmr:FlxTimer):Void
							{
								cameraMovementSection();

								remove(whiteScreen);
								whiteScreen.destroy();
				
								camHUD.visible = true;
								startCountdown();
							});
						}
					});
				}
				case 'winter-horrorland':
				{
					camHUD.visible = false;
					inCutscene = true;
			
					FlxG.sound.play(Paths.getSound('Lights_Turn_On')).pitch = playbackRate;
					FlxG.camera.zoom = 1.5;

					snapCamFollowToPos(400, -2050);

					var blackScreen:Sprite = new Sprite(); // blackout at the start
					blackScreen.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					blackScreen.scrollFactor.set();
					add(blackScreen);

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7 / playbackRate,
					{
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween):Void {
							remove(blackScreen);
						}
					});

					new FlxTimer().start(0.8 / playbackRate, function(tmr:FlxTimer):Void // zoom out
					{
						camHUD.visible = true;

						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5 / playbackRate,
						{
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween):Void
							{
								cameraMovementSection();
								startCountdown();
							}
						});
					});
				}
				case 'senpai' | 'roses' | 'thorns':
				{
					if (SONG.songID == 'roses')
					{
						FlxG.sound.play(Paths.getSound('ANGRY'), 1, false, null, true, function():Void {
							schoolIntro(doof);
						}) #if FLX_PITCH .pitch = playbackRate #end;
					}
					else {
						schoolIntro(doof);
					}
				}
				case 'ugh': ughIntro();
				case 'guns': gunsIntro();
				case 'stress': stressIntro();
				default: startCountdown();
			}

			seenCutscene = true;
		}
		else startCountdown();

		RecalculateRating();

		Paths.getSound('hitsound');

		for (i in 1...4) {
			Paths.getSound('missnote' + i);
		}

		if (ClientPrefs.pauseMusic != 'None') {
			Paths.getMusic(Paths.formatToSongPath(ClientPrefs.pauseMusic));
		}

		Paths.getSound(GameOverSubState.deathSoundName);
		Paths.getMusic(GameOverSubState.loopSoundName);
		Paths.getMusic(GameOverSubState.endSoundName);

		var characterJsonPath:String = 'characters/' + GameOverSubState.characterName + '.json';

		if (Paths.fileExists(characterJsonPath, TEXT))
		{
			try
			{
				var gameOverCharacter:CharacterFile = Character.getCharacterFile(characterJsonPath);
				Paths.getSparrowAtlas(gameOverCharacter.image);
			}
			catch (e:Error) {
				Debug.logError('Cannot precache game over character image file: ' + e);
			}
		}

		if (Paths.fileExists('images/alphabet.png', IMAGE)) {
			Paths.getSparrowAtlas('alphabet');
		}
		else {
			Paths.getSparrowAtlas('ui/alphabet');
		}

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		resetRPC();

		callOnScripts('onCreatePost');

		cacheCountdown();
		cachePopUpScore();

		super.create();

		Paths.clearUnusedMemory();
	}

	public function moveCameraToGF(snap:Bool = false):Void
	{
		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);

		if (gf != null)
		{
			final mid:FlxPoint = gf.getGraphicMidpoint();
			camPos.x += mid.x + gf.cameraPosition[0];
			camPos.y += mid.y + gf.cameraPosition[1];
			mid.put();
		}

		if (snap) {
			snapCamFollowToPos(camPos.x, camPos.y);
		}
		else {
			camFollow.setPosition(camPos.x, camPos.y);
		}

		camPos.put();
	}

	#if DISCORD_ALLOWED
	function initDiscord():Void
	{
		storyDifficultyText = CoolUtil.difficultyStuff[lastDifficulty][1];

		switch (gameMode)
		{
			case 'story': detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
			case 'freeplay': detailsText = "Freeplay";
			default: detailsText = "Unknown";
		}

		detailsPausedText = "Paused - " + detailsText; // String for when the game is paused
	}
	#end

	public var stageData:StageFile;

	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleFog:DadBattleFog;

	var halloweenBG:BGSprite; // week 2 vars
	var halloweenWhite:BGSprite;

	var phillyLightsColors:Array<FlxColor>; // week 3 vars
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:PhillyTrain;
	var curLight:Int = -1;

	var blammedLightsBlack:Sprite; // philly glow events vars
	var phillyGlowGradient:PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlowParticle>;
	var phillyWindowEvent:BGSprite;
	var curLightEvent:Int = -1;

	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>; // week 4 vars
	var fastCar:BGSprite;
	var fastCarCanDrive:Bool = true;

	var limoKillingState:String = 'WAIT'; // kill henchmen vars
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var dancersDiff:Float = 320;

	var upperBoppers:BGSprite; // week 5 vars
	var bottomBoppers:MallCrowd;
	var santa:BGSprite;

	var bgGirls:BackgroundGirls; // week 6 vars
	var bgGhouls:BGSprite;
	#if RUNTIME_SHADERS_ALLOWED
	var wiggle:WiggleEffect = null;
	#end

	var tankWatchtower:BGSprite; // week 7 vars
	var tankGround:BackgroundTank;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;

	private function createStageAndChars(stage:String):Void
	{
		stageData = StageData.getStageFile(stage);

		if (stageData == null) { // Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();
		}

		isPixelStage = stageData.isPixelStage == true;
		defaultCamZoom = stageData.defaultZoom;

		if (stageData.camera_speed != null) {
			cameraSpeed = stageData.camera_speed;
		}

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if (boyfriendCameraOffset == null) boyfriendCameraOffset = [0, 0]; //Fucks sake should have done it since the start :rolling_eyes:

		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if (girlfriendCameraOffset == null) girlfriendCameraOffset = [0, 0];

		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		opponentCameraOffset = stageData.camera_opponent;
		if (opponentCameraOffset == null) opponentCameraOffset = [0, 0];

		switch (stage)
		{
			case 'stage': // Week 1
			{
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);
		
				final stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);

				if (!ClientPrefs.lowQuality)
				{
					final stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);

					final stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);
		
					final stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}

				addChars([GF_X, GF_Y], [DAD_X, DAD_Y], [BF_X, BF_Y]);
			}
			case 'spooky': // Week 2
			{
				if (!ClientPrefs.lowQuality) {
					halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				}
				else {
					halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
				}

				add(halloweenBG);

				addChars([GF_X, GF_Y], [DAD_X, DAD_Y], [BF_X, BF_Y]);

				halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;
				add(halloweenWhite);

				for (i in 1...3) {
					Paths.getSound('thunder_' + i);
				}
			}
			case 'philly': // Week 3
			{
				if (!ClientPrefs.lowQuality)
				{
					var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
					add(bg);
				}
		
				var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);
		
				phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];

				phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
				phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
				phillyWindow.updateHitbox();
				phillyWindow.alpha = 0;
				add(phillyWindow);
		
				if (!ClientPrefs.lowQuality)
				{
					var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
					add(streetBehind);
				}
		
				phillyTrain = new PhillyTrain(2000, 360);
				add(phillyTrain);
		
				phillyStreet = new BGSprite('philly/street', -40, 50);
				add(phillyStreet);

				addChars([GF_X, GF_Y], [DAD_X, DAD_Y], [BF_X, BF_Y]);
			}
			case 'limo': // Week 4
			{
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if (!ClientPrefs.lowQuality)
				{
					limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);
		
					bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);
		
					limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);
		
					limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);
		
					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);
		
					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + dancersDiff + bgLimo.x, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}
		
					limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false); //PRECACHE BLOOD
					particle.alpha = FlxMath.EPSILON;
					grpLimoParticles.add(particle);

					Paths.getSound('dancerdeath');

					resetLimoKill();
				}

				addChars([GF_X, GF_Y], [DAD_X, DAD_Y], [BF_X, BF_Y]);

				fastCar = new BGSprite('limo/fastCarLol', -300, 160);
				fastCar.active = true;
				addBehindGF(fastCar);

				resetFastCar();

				var limo:BGSprite = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);
				addBehindDad(limo); // Shitty layering but whatev it works LOL
			}
			case 'mall': // Week 5 - Cocoa, Eggnog
			{
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);
		
				if (!ClientPrefs.lowQuality)
				{
					upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);
		
					var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}
		
				var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);
		
				bottomBoppers = new MallCrowd(-300, 140);
				add(bottomBoppers);
		
				var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
				add(fgSnow);
		
				santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);

				addChars([GF_X, GF_Y], [DAD_X, DAD_Y], [BF_X, BF_Y]);

				Paths.getSound('Lights_Shut_off');
			}
			case 'mallEvil': // Week 5 - Winter Horrorland
			{
				var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);
		
				var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);
		
				var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
				add(evilSnow);

				addChars([GF_X, GF_Y], [DAD_X, DAD_Y], [BF_X, BF_Y]);
			}
			case 'school': // Week 6 - Senpai, Roses
			{
				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				bgSky.antialiasing = false;
				add(bgSky);

				var repositionShit:Float = -200;
				var widShit:Int = Std.int(bgSky.width * 6);

				bgSky.setGraphicSize(widShit);
				bgSky.updateHitbox();

				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				bgSchool.antialiasing = false;
				bgSchool.setGraphicSize(widShit);
				bgSchool.updateHitbox();
				add(bgSchool);

				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				bgStreet.antialiasing = false;
				bgStreet.setGraphicSize(widShit);
				bgStreet.updateHitbox();
				add(bgStreet);

				if (!ClientPrefs.lowQuality)
				{
					var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					fgTrees.antialiasing = false;
					add(fgTrees);
				}

				var bgTrees:Sprite = new Sprite(repositionShit - 380, -800, isPixelStage);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.playAnim('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));
				bgTrees.updateHitbox();
				add(bgTrees);

				if (!ClientPrefs.lowQuality)
				{
					var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					treeLeaves.antialiasing = false;
					add(treeLeaves);

					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);
					add(bgGirls);
				}

				addChars([GF_X, GF_Y], [DAD_X, DAD_Y], [BF_X, BF_Y]);
			}
			case 'schoolEvil': // Week 6 - Thorns
			{
				var posX:Float = 500;
				var posY:Float = 375;

				var bg:BGSprite = new BGSprite('weeb/evilSchoolBG', posX, posY, 0.7, 0.8);
				bg.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
				bg.antialiasing = false;
				add(bg);

				var fg:BGSprite = new BGSprite('weeb/evilSchoolFG', posX, posY, 0.9, 0.8);
				fg.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
				fg.antialiasing = false;
				add(fg);

				#if RUNTIME_SHADERS_ALLOWED
				if (ClientPrefs.shadersEnabled && !ClientPrefs.lowQuality)
				{
					wiggle = new WiggleEffect(2, 4, 0.017, WiggleEffectType.DREAMY);

					bg.shader = wiggle;
					fg.shader = wiggle;
				}
				#end

				addChars([GF_X, GF_Y], [DAD_X, DAD_Y], [BF_X, BF_Y]);
			}
			case 'tank': // Week 7 - Ugh, Guns, Stress
			{
				for (i in 1...26) {
					Paths.getSound('jeffGameover/jeffGameover-' + i);
				}

				var sky:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
				add(sky);

				if (!ClientPrefs.lowQuality)
				{
					var clouds:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
					clouds.active = true;
					clouds.velocity.x = FlxG.random.float(5, 15);
					add(clouds);

					var mountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
					mountains.setGraphicSize(Std.int(1.2 * mountains.width));
					mountains.updateHitbox();
					add(mountains);

					var buildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.3, 0.3);
					buildings.setGraphicSize(Std.int(1.1 * buildings.width));
					buildings.updateHitbox();
					add(buildings);
				}

				var ruins:BGSprite = new BGSprite('tankRuins',-200,0,.35,.35);
				ruins.setGraphicSize(Std.int(1.1 * ruins.width));
				ruins.updateHitbox();
				add(ruins);

				if (!ClientPrefs.lowQuality)
				{
					var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
					add(smokeLeft);

					var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
					add(smokeRight);

					tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
					add(tankWatchtower);
				}

				tankGround = new BackgroundTank();
				add(tankGround);

				tankmanRun = new FlxTypedGroup<TankmenBG>();
				add(tankmanRun);

				var ground:BGSprite = new BGSprite('tankGround', -420, -150);
				ground.setGraphicSize(Std.int(1.15 * ground.width));
				ground.updateHitbox();
				add(ground);

				addChars([GF_X, GF_Y], [DAD_X, DAD_Y], [BF_X, BF_Y]);

				foregroundSprites = new FlxTypedGroup<BGSprite>();
				add(foregroundSprites);

				var fgTank0:BGSprite = new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']);
				foregroundSprites.add(fgTank0);

				if (!ClientPrefs.lowQuality)
				{
					var fgTank1:BGSprite = new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']);
					foregroundSprites.add(fgTank1);
				}

				var fgTank2:BGSprite = new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']); // just called 'foreground' just cuz small inconsistency no bbiggei
				foregroundSprites.add(fgTank2);

				if (!ClientPrefs.lowQuality)
				{
					var fgTank4:BGSprite = new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']);
					foregroundSprites.add(fgTank4);
				}

				var fgTank5:BGSprite = new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']);
				foregroundSprites.add(fgTank5);

				if (!ClientPrefs.lowQuality)
				{
					var fgTank3:BGSprite = new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']);
					foregroundSprites.add(fgTank3);
				}
			}
			default: addChars([GF_X, GF_Y], [DAD_X, DAD_Y], [BF_X, BF_Y]);
		}
	}

	public function addChars(gfPos:Array<Float>, dadPos:Array<Float>, bfPos:Array<Float>):Void
	{
		gfGroup = new FlxTypedSpriteGroup<Character>(gfPos[0], gfPos[1]);
		add(gfGroup);

		dadGroup = new FlxTypedSpriteGroup<Character>(dadPos[0], dadPos[1]);
		add(dadGroup);

		boyfriendGroup = new FlxTypedSpriteGroup<Character>(bfPos[0], bfPos[1]);
		add(boyfriendGroup);
	}

	public var comboGroup:FlxGroup; // Stores Ratings and Combo Sprites in a group
	public var uiGroup:FlxSpriteGroup; // Stores HUD Objects in a Group
	public var noteGroup:FlxGroup; // Stores Note Objects in a Group

	public var notes:FlxTypedGroup<Note>;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var grpRatings:FlxTypedGroup<RatingSprite>;
	public var grpCombo:FlxTypedGroup<ComboSprite>;
	public var grpComboNumbers:FlxTypedGroup<ComboNumberSprite>;

	public var timeBar:Bar;
	public var timeTxt:FlxText;

	public var healthBar:Bar;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var scoreTxt:FlxText;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	var noteCombo:Sprite;
	var noteComboNumbers:FlxTypedGroup<Sprite>;

	private function createHud():Void
	{
		comboGroup = new FlxGroup();
		comboGroup.cameras = [camHUD];
		add(comboGroup);

		noteGroup = new FlxGroup();
		noteGroup.cameras = [camHUD];
		add(noteGroup);

		uiGroup = new FlxSpriteGroup();
		uiGroup.cameras = [camHUD];
		add(uiGroup);

		grpRatings = new FlxTypedGroup<RatingSprite>();
		grpRatings.memberAdded.add(function(spr:RatingSprite):Void {
			spr.group = grpRatings;
		});
		grpRatings.memberRemoved.add(function(spr:RatingSprite):Void {
			spr.destroy();
		});
		comboGroup.add(grpRatings);

		grpCombo = new FlxTypedGroup<ComboSprite>();
		grpCombo.memberAdded.add(function(spr:ComboSprite):Void {
			spr.group = grpCombo;
		});
		grpCombo.memberRemoved.add(function(spr:ComboSprite):Void {
			spr.destroy();
		});
		comboGroup.add(grpCombo);

		grpComboNumbers = new FlxTypedGroup<ComboNumberSprite>();
		grpComboNumbers.memberAdded.add(function(spr:ComboNumberSprite):Void {
			spr.group = grpComboNumbers;
		});
		grpComboNumbers.memberRemoved.add(function(spr:ComboNumberSprite):Void {
			spr.destroy();
		});
		comboGroup.add(grpComboNumbers);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		noteGroup.add(strumLineNotes);

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		noteGroup.add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash();
		grpNoteSplashes.add(splash);
		splash.alpha = FlxMath.EPSILON; // cant make it invisible or it won't allow precaching

		notes = new FlxTypedGroup<Note>();
		noteGroup.add(notes);

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		updateTime = showTime;

		var path:String = 'ui/healthBar';
		if (Paths.fileExists('images/healthBar.png', IMAGE)) path = 'healthBar';

		timeBar = new Bar(0, (ClientPrefs.downScroll ? FlxG.height - 30 : 8), path, function():Float return songPercent, 0, 1);
		timeBar.screenCenter(X);
		timeBar.scrollFactor.set();
		timeBar.alpha = FlxMath.EPSILON;
		timeBar.visible = updateTime;
		uiGroup.add(timeBar);

		timeTxt = new FlxText(0, timeBar.y + 1, FlxG.width, SONG.songName + ' - ' + CoolUtil.difficultyStuff[lastDifficulty][1], 20);
		timeTxt.setFormat(Paths.getFont('vcr.ttf'), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.borderSize = 1.25;
		timeTxt.alpha = FlxMath.EPSILON;
		timeTxt.visible = showTime;
		uiGroup.add(timeTxt);

		var path:String = 'ui/healthBar';
		if (Paths.fileExists('images/healthBar.png', IMAGE)) path = 'healthBar';

		healthLerp = health;

		healthBar = new Bar(0, FlxG.height * (!ClientPrefs.downScroll ? 0.89 : 0.11), path, function():Float return healthLerp, 0, 2);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		reloadHealthBarColors();
		uiGroup.add(healthBar);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		uiGroup.add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		uiGroup.add(iconP2);

		scoreTxt = new FlxText(0, healthBar.y + 50, FlxG.width, '', 16);
		scoreTxt.setFormat(Paths.getFont('vcr.ttf'), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		updateScore();
		scoreTxt.scrollFactor.set();
		scoreTxt.visible = ClientPrefs.scoreText;
		uiGroup.add(scoreTxt);

		botplayTxt = new FlxText(400, ClientPrefs.downScroll ? timeBar.y - 85 : timeBar.y + 75, FlxG.width - 800, 'BOTPLAY', 32);
		botplayTxt.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled && !addScoreOnPractice;
		botplayTxt.alpha = 0;
		uiGroup.add(botplayTxt);
	}

	function set_allowPlayCutscene(value:Bool):Bool
	{
		setOnScripts('allowPlayCutscene', value);
		return allowPlayCutscene = value;
	}

	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			final ratio:Float = value / songSpeed; // funny word huh

			if (ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}

		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, noteKillOffset / songSpeed * playbackRate);

		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		#if FLX_PITCH
		if (generatedMusic)
		{
			if (vocals != null) vocals.pitch = value;
			FlxG.sound.music.pitch = value;

			final ratio:Float = playbackRate / value; // funny word huh

			if (ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}

		FlxG.animationTimeScale = value;
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * value;

		setOnScripts('playbackRate', value);
		return playbackRate = value;
		#else
		return playbackRate = 1.0;
		#end
	}

	public function addTextToDebug(text:String, color:FlxColor):Void
	{
		#if MODS_ALLOWED
		var newText:DebugText = debugTextGroup.recycle(DebugText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		debugTextGroup.forEachAlive(function(spr:DebugText):Void {
			spr.y += newText.height + 2;
		});

		debugTextGroup.add(newText);
		#end
	}

	public function reloadHealthBarColors():Void
	{
		var left:FlxColor = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
		var right:FlxColor = FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);

		healthBar.setColors(left, right);
	}

	public function addCharacterToList(newCharacter:String, type:Int):Void
	{
		switch (type)
		{
			case 0:
			{
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);

					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = FlxMath.EPSILON;
					startCharacterScripts(newBoyfriend.curCharacter);
				}
			}
			case 1:
			{
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);

					startCharacterPos(newDad, true);
					newDad.alpha = FlxMath.EPSILON;
					startCharacterScripts(newDad.curCharacter);
				}
			}
			case 2:
			{
				if (gf != null && !gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);

					startCharacterPos(newGf);
					newGf.alpha = FlxMath.EPSILON;
					startCharacterScripts(newGf.curCharacter);
				}
			}
		}
	}

	function startCharacterScripts(name:String):Void
	{
		#if LUA_ALLOWED // lua
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name;
		var replacePath:String = Paths.getLua(luaFile);

		if (Paths.fileExists(replacePath, TEXT))
		{
			for (script in luaArray) {
				if (script.scriptName == luaFile + '.lua') return;
			}

			new FunkinLua(replacePath);
		}
		#end

		#if HSCRIPT_ALLOWED // hscript
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name;

		if (Paths.fileExists(scriptFile, TEXT))
		{
			for (hx in hscriptArray)
			{
				if (hx.origin == scriptFile)
				{
					doPush = false;
					break;
				}
			}

			if (doPush) initHScript(scriptFile + '.hx');
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite
	{
		#if LUA_ALLOWED
		if (modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if (variables.exists(tag)) return variables.get(tag);
		#end

		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false):Void
	{
		if (gfCheck && char.curCharacter.startsWith('gf')) //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
		{
			char.setPosition(GF_X, GF_Y);
			char.danceEveryNumBeats = ClientPrefs.danceOffset;
		}

		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startAndEnd():Void
	{
		if (endingSong)
			endSong();
		else
			startCountdown();
	}

	public function startVideo(name:String):Void
	{
		#if VIDEOS_ALLOWED
		if (Paths.fileExists(Paths.getVideo(name), BINARY))
		{
			var video:FlxVideo = new FlxVideo(name);
			video.finishCallback = function():Void
			{
				remove(video, true);
				video.destroy();

				startAndEnd();
			}

			add(video);
		}
		else {
			Debug.logWarn('Couldnt find video file: ' + name);
		}
		#else
		Debug.logWarn('Platform not supported!');
		startAndEnd();
		#end
	}

	var dialogueCount:Int = 0;

	public var psychDialogue:DialogueBoxPsych;

	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void // You don't have to add a song, just saying. You can just do "startDialogue(DialogueBoxPsych.parseDialogue(Paths.getJson(songName + '/dialogue')))" and it should load dialogue.json
	{
		if (psychDialogue != null) return; // TO DO: Make this more flexible, maybe?

		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;

			Paths.getSound('dialogue');
			Paths.getSound('dialogueClose');

			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();

			if (endingSong)
			{
				psychDialogue.finishThing = function():Void
				{
					psychDialogue = null;
					endSong();
				}
			}
			else
			{
				psychDialogue.finishThing = function():Void
				{
					psychDialogue = null;
					startCountdown();
				}
			}
	
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		}
		else
		{
			Debug.logWarn('Your dialogue file is badly formatted!');
			startAndEnd();
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		var black:Sprite = new Sprite(-100, -100);
		black.makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:Sprite = new Sprite(-100, -100);
		red.makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:Sprite = new Sprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += senpaiEvil.width / 5;
		senpaiEvil.antialiasing = false;

		if (SONG.songID == 'roses' || SONG.songID == 'thorns')
		{
			remove(black);

			if (SONG.songID == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3 / playbackRate, function(tmr:FlxTimer):Void
		{
			black.alpha -= 0.15;

			if (black.alpha > 0) {
				tmr.reset(0.3 / playbackRate);
			}
			else
			{
				if (dialogueBox != null)
				{
					inCutscene = true;

					if (SONG.songID == 'thorns')
					{
						senpaiEvil.alpha = 0;
						add(senpaiEvil);

						new FlxTimer().start(0.3 / playbackRate, function(swagTimer:FlxTimer):Void
						{
							senpaiEvil.alpha += 0.15;

							if (senpaiEvil.alpha < 1) {
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.playAnim('idle');

								FlxG.sound.play(Paths.getSound('Senpai_Dies'), 1, false, null, true, function():Void
								{
									remove(senpaiEvil, true);
									remove(red, true);

									cameraMovementSection();
									snapCamFollowToPos(camFollow.x, camFollow.y);

									FlxG.camera.fade(FlxColor.WHITE, 0.5 / playbackRate, true, function():Void
									{
										camHUD.visible = true;
										add(dialogueBox);
									}, true);
								})
								#if FLX_PITCH
								.pitch = playbackRate
								#end ;

								new FlxTimer().start(3.2 / playbackRate, function(deadTime:FlxTimer):Void {
									FlxG.camera.fade(FlxColor.WHITE, 1.6 / playbackRate, false);
								});
							}
						});
					}
					else {
						add(dialogueBox);
					}
				}
				else startCountdown();

				remove(black);
			}
		});
	}

	var cutsceneHandler:CutsceneHandler;
	var tankmanCutscene:FlxAnimate;
	var picoCutscene:FlxAnimate;
	var boyfriendCutscene:FlxSprite;

	function prepareTankCutscene():Void
	{
		cutsceneHandler = new CutsceneHandler();

		dadGroup.alpha = 0.00001;
		camHUD.visible = false;

		tankmanCutscene = new FlxAnimate(dad.x + 419, dad.y + 225);
		tankmanCutscene.showPivot = false;
		Paths.loadAnimateAtlas(tankmanCutscene, 'cutscenes/tankman');
		tankmanCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		addBehindDad(tankmanCutscene);

		cutsceneHandler.push(tankmanCutscene);

		cutsceneHandler.finishCallback = function():Void
		{
			var timeForStuff:Float = (Conductor.crochet / 1000 * 4.5) / playbackRate;

			FlxG.sound.music.fadeOut(timeForStuff);

			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			startCountdown();

			cameraMovementSection();

			dadGroup.alpha = 1;
			camHUD.visible = true;

			boyfriend.animation.finishCallback = null;

			gf.animation.finishCallback = null;
			gf.dance();
		}

		camFollow.setPosition(dad.x + 280, dad.y + 170);
	}

	function ughIntro():Void
	{
		prepareTankCutscene();

		cutsceneHandler.endTime = 12;
		cutsceneHandler.music = 'DISTORTO';

		Paths.getSound('wellWellWell');
		Paths.getSound('killYou');
		Paths.getSound('bfBeep');

		var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.getSound('wellWellWell'));
		FlxG.sound.list.add(wellWellWell);

		tankmanCutscene.anim.addBySymbol('wellWell', 'TANK TALK 1 P1', 24, false);
		tankmanCutscene.anim.addBySymbol('killYou', 'TANK TALK 1 P2', 24, false);
		tankmanCutscene.anim.play('wellWell', true);
		FlxG.camera.zoom *= 1.2;

		cutsceneHandler.timer(0.1, function():Void
		{
			wellWellWell.play(true);
		});

		cutsceneHandler.timer(3, function():Void
		{
			camFollow.x += 750;
			camFollow.y += 100;
		});

		cutsceneHandler.timer(4.5, function():Void
		{
			boyfriend.playAnim('singUP', true);
			boyfriend.specialAnim = true;

			FlxG.sound.play(Paths.getSound('bfBeep'));
		});

		cutsceneHandler.timer(6, function():Void
		{
			camFollow.x -= 750;
			camFollow.y -= 100;

			tankmanCutscene.anim.play('killYou', true);
			FlxG.sound.play(Paths.getSound('killYou'));
		});
	}

	function gunsIntro():Void
	{
		prepareTankCutscene();

		cutsceneHandler.endTime = 11.5;
		cutsceneHandler.music = 'DISTORTO';

		Paths.getSound('tankSong2');

		var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.getSound('tankSong2'));
		FlxG.sound.list.add(tightBars);

		tankmanCutscene.anim.addBySymbol('tightBars', 'TANK TALK 2', 24, false);
		tankmanCutscene.anim.play('tightBars', true);
		boyfriend.animation.curAnim.finish();

		cutsceneHandler.onStart = function():Void
		{
			tightBars.play(true);

			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
		};

		cutsceneHandler.timer(4, function():Void
		{
			gf.playAnim('sad', true);
			gf.animation.finishCallback = function(name:String):Void
			{
				gf.playAnim('sad', true);
			}
		});
	}

	var dualWieldAnimPlayed:Int = 0;

	function stressIntro():Void
	{
		prepareTankCutscene();
		
		cutsceneHandler.endTime = 35.5;

		gfGroup.alpha = 0.00001;
		boyfriendGroup.alpha = 0.00001;
		camFollow.setPosition(dad.x + 400, dad.y + 170);

		FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});

		foregroundSprites.forEach(function(spr:BGSprite):Void
		{
			spr.y += 100;
		});

		Paths.getSound('stressCutscene');

		picoCutscene = new FlxAnimate(gf.x + 150, gf.y + 450);
		picoCutscene.showPivot = false;
		Paths.loadAnimateAtlas(picoCutscene, 'cutscenes/picoAppears');
		picoCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		picoCutscene.anim.addBySymbol('dance', 'GF Dancing at Gunpoint', 24, true);
		picoCutscene.anim.addBySymbol('dieBitch', 'GF Time to Die sequence', 24, false);
		picoCutscene.anim.addBySymbol('picoAppears', 'Pico Saves them sequence', 24, false);
		picoCutscene.anim.addBySymbol('picoEnd', 'Pico Dual Wield on Speaker idle', 24, false);
		picoCutscene.anim.play('dance', true);
		addBehindGF(picoCutscene);

		cutsceneHandler.push(picoCutscene);

		boyfriendCutscene = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
		boyfriendCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
		boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
		boyfriendCutscene.animation.play('idle', true);
		boyfriendCutscene.animation.curAnim.finish();
		addBehindBF(boyfriendCutscene);
		cutsceneHandler.push(boyfriendCutscene);

		var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.getSound('stressCutscene'));
		FlxG.sound.list.add(cutsceneSnd);

		tankmanCutscene.anim.addBySymbol('godEffingDamnIt', 'TANK TALK 3 P1 UNCUT', 24, false);
		tankmanCutscene.anim.addBySymbol('lookWhoItIs', 'TANK TALK 3 P2 UNCUT', 24, false);
		tankmanCutscene.anim.play('godEffingDamnIt', true);

		cutsceneHandler.onStart = function():Void
		{
			cutsceneSnd.play(true);
		};

		cutsceneHandler.timer(15.2, function():Void
		{
			FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
			FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});

			picoCutscene.anim.play('dieBitch', true);
			picoCutscene.anim.onComplete = function():Void
			{
				picoCutscene.anim.play('picoAppears', true);
				picoCutscene.anim.onComplete = function():Void
				{
					picoCutscene.anim.play('picoEnd', true);
					picoCutscene.anim.onComplete = function():Void
					{
						gfGroup.alpha = 1;
						picoCutscene.visible = false;
						picoCutscene.anim.onComplete = null;
					}
				};

				boyfriendGroup.alpha = 1;
				boyfriendCutscene.visible = false;
				boyfriend.playAnim('bfCatch', true);

				boyfriend.animation.finishCallback = function(name:String):Void
				{
					if (name != 'idle')
					{
						boyfriend.playAnim('idle', true);
						boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
					}
				};
			};
		});

		var zoomBack:Void->Void = function():Void
		{
			var calledTimes:Int = 0;

			snapCamFollowToPos(630, 425);

			FlxG.camera.zoom = 0.8;
			cameraSpeed = 1;
	
			calledTimes++;
	
			if (calledTimes > 1)
			{
				foregroundSprites.forEach(function(spr:BGSprite):Void {
					spr.y -= 100;
				});
			}
		}

		cutsceneHandler.timer(17.5, function():Void
		{
			zoomBack();
		});

		cutsceneHandler.timer(19.5, function():Void
		{
			tankmanCutscene.anim.play('lookWhoItIs', true);
		});

		cutsceneHandler.timer(20, function():Void
		{
			camFollow.setPosition(dad.x + 500, dad.y + 170);
		});

		cutsceneHandler.timer(31.2, function():Void
		{
			boyfriend.playAnim('singUPmiss', true);
			boyfriend.animation.finishCallback = function(name:String)
			{
				if (name == 'singUPmiss')
				{
					boyfriend.playAnim('idle', true);
					boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
				}
			};

			camFollow.setPosition(boyfriend.x + 280, boyfriend.y + 200);

			FlxG.camera.snapToTarget();
			cameraSpeed = 12;

			FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
		});

		cutsceneHandler.timer(32.2, function():Void
		{
			zoomBack();
		});
	}

	var startTimer:FlxTimer = new FlxTimer();
	var finishTimer:FlxTimer = null;

	public static var startOnTime:Float = 0;

	public var introImagesSuffix:String = '';
	public var introSoundsSuffix:String = '';

	public var countdownReady:Sprite; // For being able to mess with the sprites on Lua
	public var countdownSet:Sprite;
	public var countdownGo:Sprite;

	public var tickArray:Array<Countdown> = [THREE, TWO, ONE, GO, START];
	public var introAssets:Array<String> = ['Ready', 'Set', 'Go'];

	private function cacheCountdown():Void
	{
		if (isPixelStage)
		{
			if (introImagesSuffix.length < 1) introImagesSuffix = '-pixel';
			if (introSoundsSuffix.length < 1) introSoundsSuffix = '-pixel';
		}

		for (asset in introAssets)
		{
			var doubleAsset:String = Paths.formatToSongPath(asset) + introImagesSuffix;

			if (Paths.fileExists('images/pixelUI/' + doubleAsset + '.png', IMAGE) && isPixelStage) {
				Paths.getImage('pixelUI/' + doubleAsset);
			}
			else if (Paths.fileExists('images/' + doubleAsset + '.png', IMAGE)) {
				Paths.getImage(doubleAsset);
			}
			else if (Paths.fileExists('images/countdown/' + doubleAsset + '.png', IMAGE)) {
				Paths.getImage('countdown/' + doubleAsset);
			}
		}

		for (i in 1...4) {
			Paths.getSound('intro' + i + introSoundsSuffix);
		}

		Paths.getSound('introGo' + introSoundsSuffix);
	}

	public function startCountdown():Bool
	{
		if (startedCountdown)
		{
			callOnScripts('onStartCountdown');
			return false;
		}

		seenCutscene = true;
		inCutscene = false;

		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);

		if (ret != Function_Stop)
		{
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);

			for (i in 0...playerStrums.length)
			{
				setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}

			for (i in 0...opponentStrums.length)
			{
				setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;

			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted', null);

			var swagCounter:Int = 0;

			if (startOnTime > 0)
			{
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - noteKillOffset);
				return true;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return true;
			}

			startTimer.start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer):Void
			{
				characterBopper(tmr.loopsLeft);

				switch (SONG.stage)
				{
					case 'philly':
					{
						if (tmr.loopsLeft % 4 == 0)
						{
							curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
		
							phillyWindow.color = phillyLightsColors[curLight];
							phillyWindow.alpha = 1;
						}
					}
					case 'limo':
					{
						if (!ClientPrefs.lowQuality && grpLimoDancers != null)
						{
							grpLimoDancers.forEach(function(dancer:BackgroundDancer):Void {
								dancer.dance();
							});
						}
		
						if (FlxG.random.bool(10) && fastCarCanDrive) fastCarDrive();
					}
					case 'mall': everyoneDanceOnMall();
					case 'school': if (bgGirls != null) bgGirls.dance();
					case 'tank': everyoneDanceOnTank();
				}

				var introSprPaths:Array<String> = [for (i in introAssets) Paths.formatToSongPath(i)];
				var curSprPath:String = introSprPaths[swagCounter - 1];

				if (curSprPath != null) {
					readySetGo(curSprPath);
				}

				var introSndPaths:Array<String> = ['intro3', 'intro2', 'intro1', 'introGo'];
				var introSndPath:String = introSndPaths[swagCounter] + introSoundsSuffix;

				if (Paths.fileExists('sounds/' + introSndPath + '.${Paths.SOUND_EXT}', SOUND)) {
					FlxG.sound.play(Paths.getSound(introSndPath), 0.6) #if FLX_PITCH .pitch = playbackRate #end;
				}

				notes.forEachAlive(function(note:Note):Void
				{
					if (ClientPrefs.opponentStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;

						if (ClientPrefs.middleScroll && !note.mustPress) note.alpha *= 0.35;
					}
				});

				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHScript('onCountdownTick', [tickArray[swagCounter], swagCounter]);

				swagCounter++;
			}, 5);
		}

		return true;
	}

	function readySetGo(path:String):Void
	{
		var antialias:Bool = ClientPrefs.globalAntialiasing && !isPixelStage;
		var name:String = Paths.formatToSongPath(path) + introImagesSuffix;

		var countdownSpr:Sprite = new Sprite();

		if (Paths.fileExists('images/pixelUI/' + name + '.png', IMAGE) && isPixelStage) {
			countdownSpr.loadGraphic(Paths.getImage('pixelUI/' + name));
		}
		else if (Paths.fileExists('images/' + name + '.png', IMAGE)) {
			countdownSpr.loadGraphic(Paths.getImage(name));
		}
		else if (Paths.fileExists('images/countdown/' + name + '.png', IMAGE)) {
			countdownSpr.loadGraphic(Paths.getImage('countdown/' + name));
		}

		if (!isPixelStage) {
			countdownSpr.setGraphicSize(Std.int(countdownSpr.width * 0.8));
		}

		countdownSpr.scrollFactor.set();

		if (isPixelStage) {
			countdownSpr.setGraphicSize(Std.int(countdownSpr.width * daPixelZoom));
		}

		countdownSpr.updateHitbox();
		countdownSpr.screenCenter();
		countdownSpr.antialiasing = antialias;
		countdownSpr.cameras = [camHUD];
		insert(members.indexOf(noteGroup), countdownSpr);

		Reflect.setProperty(instance, 'countdown' + CoolUtil.capitalize(path), countdownSpr);

		FlxTween.tween(countdownSpr, {alpha: 0}, Conductor.crochet / 1000 / playbackRate,
		{
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween):Void
			{
				countdownSpr.kill();
				remove(countdownSpr, true);
				countdownSpr.destroy();
			}
		});
	}

	public function addBehindGF(obj:FlxBasic):FlxBasic
	{
		return insert(members.indexOf(gfGroup), obj);
	}

	public function addBehindBF(obj:FlxBasic):FlxBasic
	{
		return insert(members.indexOf(boyfriendGroup), obj);
	}

	public function addBehindDad(obj:FlxBasic):FlxBasic
	{
		return insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float):Void
	{
		var i:Int = unspawnNotes.length - 1;

		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];

			if (daNote.strumTime - noteKillOffset < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}

			--i;
		}

		i = notes.length - 1;

		while (i >= 0)
		{
			var daNote:Note = notes.members[i];

			if (daNote.strumTime - noteKillOffset < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}

			--i;
		}
	}

	public var scoreSeparator:String = ' | ';
	public var scoreDisplays = {
		deaths: true,
		ratingPercent: true,
		ratingName: true,
		ratingFC: true,
		health: true,
		misses: true
	};

	public function updateScore(miss:Bool = false):Void
	{
		var ret:Dynamic = callOnScripts('preUpdateScore', [miss], true);
		if (ret == Function_Stop) return;

		var ultimateScoreArray:Array<String> = ['Score: ' + songScore];

		if (scoreDisplays.misses) {
			ultimateScoreArray.insert(0, 'Combo Breaks: ' + songMisses);
		}

		if (scoreDisplays.health) {
			ultimateScoreArray.insert(0, 'Health: ' + Math.round(healthLerp * 50) + '%');
		}

		if (scoreDisplays.ratingName) {
			ultimateScoreArray.insert(0, 'Rating: ' + ratingName + (ratingName != 'N/A' && scoreDisplays.ratingFC ? ' (' + ratingFC + ')' : ''));
		}

		if (scoreDisplays.ratingPercent)
		{
			var ratingSplit:Array<String> = ('' + CoolUtil.floorDecimal(songAccuracy * 100, 2)).split('.');

			if (ratingSplit.length < 2) { // No decimals, add an empty space
				ratingSplit.push('');
			}
	
			while (ratingSplit[1].length < 2) { // Less than 2 decimals in it, add decimals then
				ratingSplit[1] += '0';
			}

			ultimateScoreArray.insert(0, 'Accuracy: ' + ratingSplit.join('.') + '%');
		}

		if (scoreDisplays.deaths) {
			ultimateScoreArray.insert(0, 'Deaths: ' + deathCounter);
		}

		if (scoreTxt != null) scoreTxt.text = ultimateScoreArray.join(scoreSeparator);

		callOnScripts('onUpdateScore', [miss]);
	}

	public dynamic function fullComboFunction():Void
	{
		final sicks:Int = ratingsData[0].hits;
		final goods:Int = ratingsData[1].hits;
		final bads:Int = ratingsData[2].hits;
		final shits:Int = ratingsData[3].hits;

		ratingFC = 'Clear';

		if (songMisses < 1)
		{
			if (bads > 0 || shits > 0) ratingFC = 'FC';
			else if (goods > 0) ratingFC = 'GFC';
			else if (sicks > 0) ratingFC = 'SFC';
		}
		else if (songMisses < 10) ratingFC = 'SDCB';
	}

	public function setSongTime(time:Float):Void
	{
		if (time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		#if FLX_PITCH
		FlxG.sound.music.pitch = playbackRate;
		#end
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			#if FLX_PITCH
			vocals.pitch = playbackRate;
			#end
		}

		vocals.play();
		Conductor.songPosition = time;
	}

	public function startNextDialogue():Void
	{
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue():Void
	{
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;
		cameraMovementSection();

		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		#if FLX_PITCH
		FlxG.sound.music.pitch = playbackRate;
		#end
		FlxG.sound.music.onComplete = finishSong.bind();

		vocals.play();

		if (startOnTime > 0) {
			setSongTime(startOnTime - 500);
		}

		startOnTime = 0;

		if (paused)
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}

		songLength = FlxG.sound.music.length; // Song duration in a float, useful for the time left feature

		FlxTween.tween(timeBar, {alpha: 1}, 0.5 / playbackRate, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5 / playbackRate, {ease: FlxEase.circOut});

		#if DISCORD_ALLOWED
		if (autoUpdateRPC) DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyText, iconP2.character, true, songLength); // Updating Discord Rich Presence (with Time Left)
		#end

		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
	}

	public var noteTypes:Array<String> = [];
	public var eventsPushed:Array<String> = [];

	private function generateSong(songData:SwagSong):Void
	{
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');

		switch (songSpeedType)
		{
			case 'multiplicative':
				songSpeed = songData.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case 'constant':
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
			default:
				songSpeed = songData.speed;
		}

		Conductor.bpm = songData.bpm;

		var diffSuffix:String = CoolUtil.difficultyStuff[lastDifficulty][2];

		inst = new FlxSound();

		if (Paths.fileExists(Paths.getInst(songData.songID, diffSuffix, true), SOUND))
		{
			try {
				inst.loadEmbedded(Paths.getInst(songData.songID, diffSuffix));
			}
			catch (e:Error) {
				Debug.logError('Error in loading inst of song "' + songData.songName + '": ' + e.toString());
			}
		}
		else {
			Debug.logError('File with inst of song "' + songData.songName + '" not found!');
		}
		
		FlxG.sound.list.add(inst);

		vocals = new FlxSound();

		if (songData.needsVoices && Paths.fileExists(Paths.getVoices(songData.songID, diffSuffix, true), SOUND)) {
			vocals.loadEmbedded(Paths.getVoices(songData.songID, diffSuffix));
		}

		vocals.onComplete = function():Void {
			vocalsFinished = true;
		}

		#if FLX_PITCH
		vocals.pitch = playbackRate;
		#end

		FlxG.sound.list.add(vocals);

		if (Paths.fileExists(Paths.getJson('data/' + songData.songID + '/events'), TEXT))
		{
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songData.songID).events;

			for (event in eventsData) // Event Notes
			{
				for (i in 0...event[1].length) {
					makeEvent(event, i);
				}
			}
		}

		unspawnNotes = ChartParser.parseSongChart(songData, playbackRate);

		for (event in songData.events) // Event Notes
		{
			for (i in 0...event[1].length) {
				makeEvent(event, i);
			}
		}

		if (unspawnNotes.length > 0) unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	function eventPushed(event:EventNote):Void
	{
		eventPushedUnique(event);

		if (eventsPushed.contains(event.event)) {
			return;
		}

		eventsPushed.push(event.event);
	}

	public function eventIsCalled(name:String):Bool
	{
		for (i in eventNotes) if (i.event == name) return true;
		return false;
	}

	function eventPushedUnique(event:EventNote):Void
	{
		switch (event.event)
		{
			case 'Dad Battle Spotlight' | 'Dadbattle Spotlight':
			{
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				add(dadbattleBlack);

				dadbattleLight = new BGSprite('spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;
				add(dadbattleLight);

				dadbattleFog = new DadBattleFog();
				dadbattleFog.visible = false;
				add(dadbattleFog);
			}
			case 'Philly Glow':
			{
				blammedLightsBlack = new Sprite(FlxG.width * -0.5, FlxG.height * -0.5);
				blammedLightsBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				insert(members.indexOf(phillyStreet), blammedLightsBlack);

				phillyWindowEvent = new BGSprite('philly/window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
				phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
				phillyWindowEvent.updateHitbox();
				phillyWindowEvent.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);

				phillyGlowGradient = new PhillyGlowGradient(-400, 225); // This shit was refusing to properly load FlxGradient so fuck it
				phillyGlowGradient.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);

				if (!ClientPrefs.flashingLights) phillyGlowGradient.intendedAlpha = 0.7;

				Paths.getImage('philly/particle'); // precache philly glow particle image

				phillyGlowParticles = new FlxTypedGroup<PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
			}
			case 'Trigger BG Ghouls':
			{
				if (!ClientPrefs.lowQuality)
				{
					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					bgGhouls.animation.finishCallback = function(name:String):Void
					{
						if (name == 'BG freaks glitch instance') {
							bgGhouls.visible = false;
						}
					}

					addBehindGF(bgGhouls);
				}
			}
			case 'Pico Speaker Shoot':
			{
				if (gf != null && gf.curCharacter == 'pico-speaker' && SONG.stage == 'tank')
				{
					gf.playAnim('shoot1', true);
					gf.animation.finishCallback = function(name:String):Void
					{
						if (gf.hasAnimation(name)) {
							gf.playAnim(name, false, false, gf.animation.curAnim.frames.length - 3);
						}
					}

					if (!ClientPrefs.lowQuality && tankmanRun != null && FlxG.random.bool(16))
					{
						var val1:Int = Std.parseInt(event.value1);
						if (Math.isNaN(val1)) val1 = 1;

						var tankman:TankmenBG = tankmanRun.recycle(TankmenBG, true);
						tankman.strumTime = event.strumTime;
						tankman.resetShit(500, 200 + FlxG.random.int(50, 100), val1 < 2);
						tankmanRun.add(tankman);
					}
				}
			}
			case 'Change Character':
			{
				var charType:Int = 0;

				switch (event.value1.toLowerCase())
				{
					case 'gf' | 'girlfriend' | '1': charType = 2;
					case 'dad' | 'opponent' | '0': charType = 1;
					default:
					{
						var val1:Int = Std.parseInt(event.value1);
						if (Math.isNaN(val1)) val1 = 0;
						charType = val1;
					}
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
			}
			case 'Play Sound': Paths.getSound(event.value1);
		}
	}

	function eventEarlyTrigger(event:EventNote):Float
	{
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true, [], [0]);

		if (returnedValue != null && returnedValue != 0 && returnedValue != Function_Continue) {
			return returnedValue;
		}

		switch (event.event)
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}

		return 0;
	}

	public static function sortByTime(obj1:Dynamic, obj2:Dynamic):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, obj1.strumTime, obj2.strumTime);
	}

	function makeEvent(event:Array<Dynamic>, i:Int):Void
	{
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};

		eventNotes.push(subEvent);
		eventPushed(subEvent);

		callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
	}

	public var skipArrowStartTween:Bool = false; // for lua

	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.downScroll ? (FlxG.height - 150) : 50;

		for (i in 0...Note.pointers.length)
		{
			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.downScroll;
			babyArrow.visible = false;

			var targetAlpha:Float = 1;

			switch (player)
			{
				case 1: playerStrums.add(babyArrow);
				case 0:
				{
					if (!ClientPrefs.opponentStrums) targetAlpha = FlxMath.EPSILON;
					else if (ClientPrefs.middleScroll) targetAlpha = 0.35;

					if (ClientPrefs.middleScroll)
					{
						babyArrow.x += 310;

						if (i > 1) { // Up and Right
							babyArrow.x += FlxG.width / 2 + 25;
						}
					}

					opponentStrums.add(babyArrow);
				}
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();

			if (!skipArrowStartTween)
			{
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: targetAlpha}, 1 / playbackRate, {ease: FlxEase.circOut, startDelay: (0.5 + (0.2 * i)) / playbackRate});
			}
			else {
				babyArrow.alpha = targetAlpha;
			}

			babyArrow.visible = true;
		}
	}

	override public function openSubState(subState:FlxSubState):Void
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			makeOperationsActive(false);
		}

		super.openSubState(subState);
	}

	override public function closeSubState():Void
	{
		super.closeSubState();

		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong) {
				resyncVocals();
			}

			makeOperationsActive();

			paused = false;
			callOnScripts('onResume');

			if (autoUpdateRPC) resetRPC(startTimer != null && startTimer.finished);
		}
	}

	override public function onFocus():Void
	{
		if (health > 0 && !paused) resetRPC(Conductor.songPosition > 0.0);
		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if DISCORD_ALLOWED
		if (health > 0 && !paused && autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.songName + " - " + storyDifficultyText, iconP2.character);
		#end

		super.onFocusLost();
	}

	public var autoUpdateRPC:Bool = true; // performance setting for custom RPC things

	function resetRPC(?showTime:Bool = false):Void
	{
		#if DISCORD_ALLOWED
		if (!autoUpdateRPC) return;

		if (showTime)
			DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyText, iconP2.character, true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
		else
			DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyText, iconP2.character);
		#end
	}

	function resyncVocals():Void
	{
		if (finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		#if FLX_PITCH
		FlxG.sound.music.pitch = playbackRate;
		#end

		Conductor.songPosition = FlxG.sound.music.time;

		if (vocalsFinished) return;

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			#if FLX_PITCH
			vocals.pitch = playbackRate;
			#end
		}

		vocals.play();
	}

	public var canReset:Bool = true;

	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var freezeCamera:Bool = false;
	var allowDebugKeys:Bool = true;

	var limoSpeed:Float = 0;

	override public function update(elapsed:Float):Void
	{
		if (!inCutscene && !paused && !freezeCamera)
		{
			FlxG.camera.followLerp = 2.4 * cameraSpeed * playbackRate;

			if (!startingSong && !endingSong && !boyfriend.isAnimationNull() && boyfriend.getAnimationName().startsWith('idle'))
			{
				boyfriendIdleTime += elapsed;

				if (boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			}
			else {
				boyfriendIdleTime = 0;
			}
		}
		else FlxG.camera.followLerp = 0;

		callOnScripts('onUpdate', [elapsed]);

		switch (SONG.stage)
		{
			case 'philly':
			{
				phillyWindow.alpha -= (Conductor.crochet / 1000) * elapsed * 1.5 * playbackRate;

				if (phillyGlowParticles != null)
				{
					var i:Int = phillyGlowParticles.members.length - 1;
	
					while (i > 0)
					{
						var particle:PhillyGlowParticle = phillyGlowParticles.members[i];

						if (particle.alpha <= 0)
						{
							particle.kill();
							phillyGlowParticles.remove(particle, true);
							particle.destroy();
						}

						--i;
					}
				}
			}
			case 'limo':
			{
				if (!ClientPrefs.lowQuality)
				{
					grpLimoParticles.forEach(function(spr:BGSprite):Void
					{
						if (spr.animation.curAnim.finished)
						{
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch (limoKillingState)
					{
						case 'KILLING':
						{
							limoMetalPole.x += 5000 * elapsed * playbackRate;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;
		
							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;

							for (i in 0...dancers.length)
							{
								if (dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 170) 
								{
									switch (i) // Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									{
										case 0 | 3:
										{
											if (i == 0) FlxG.sound.play(Paths.getSound('dancerdeath'), 0.5) #if FLX_PITCH .pitch = playbackRate #end;
		
											var diffStr:String = i == 3 ? ' 2 ' : ' ';

											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
		
											var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										}
										case 1: limoCorpse.visible = true;
										case 2: limoCorpseTwo.visible = true;
									}

									dancers[i].x += FlxG.width * 2; 
								}
							}
		
							if (limoMetalPole.x > FlxG.width * 2)
							{
								resetLimoKill();

								limoSpeed = 800;
								limoKillingState = 'SPEEDING_OFFSCREEN';
							}
						}
						case 'SPEEDING_OFFSCREEN':
						{
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed * playbackRate;

							if (bgLimo.x > FlxG.width * 1.5)
							{
								limoSpeed = 3000;
								limoKillingState = 'SPEEDING';
							}
						}
						case 'SPEEDING':
						{
							limoSpeed -= 2000 * elapsed;
							if (limoSpeed < 1000) limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed * playbackRate;

							if (bgLimo.x < -275)
							{
								limoKillingState = 'STOPPING';
								limoSpeed = 800;
							}

							limoDancersParenting();
						}
						case 'STOPPING':
						{
							bgLimo.x = FlxMath.lerp(-150, bgLimo.x, Math.exp(-elapsed * 9 * playbackRate));

							if (Math.round(bgLimo.x) == -150)
							{
								bgLimo.x = -150;
								limoKillingState = 'WAIT';
							}

							limoDancersParenting();
						}
					}
				}
			}
			case 'schoolEvil':
			{
				if (ClientPrefs.shadersEnabled && !ClientPrefs.lowQuality)
				{
					if (wiggle != null) {
						wiggle.update(elapsed);
					}
				}
			}
		}

		super.update(elapsed);

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if (botplayTxt.visible)
		{
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE_P && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnScripts('onPause', null, true);

			if (ret != Function_Stop) {
				openPauseMenu();
			}
		}

		if (allowDebugKeys && !endingSong && !inCutscene)
		{
			if (controls.DEBUG_1_P) openChartEditor();
			if (controls.DEBUG_2_P) openCharacterEditor();
		}

		healthLerp = FlxMath.lerp(health, healthLerp, Math.exp(-elapsed * 9 * playbackRate));

		updateIconsScale(elapsed);
		updateIconsPosition();

		iconP1.animation.curAnim.curFrame = (healthBar.percent < 20) ? 1 : ((healthBar.percent > 80 && iconP1.animation.curAnim.numFrames == 3) ? 2 : 0);
		iconP2.animation.curAnim.curFrame = (healthBar.percent > 80) ? 1 : ((healthBar.percent < 20 && iconP2.animation.curAnim.numFrames == 3) ? 2 : 0);

		if (startedCountdown && !paused && !endingSong) {
			Conductor.songPosition += elapsed * 1000 * playbackRate;
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0) {
				startSong();
			}
			else if (!startedCountdown) {
				Conductor.songPosition = -Conductor.crochet * 5;
			}
		}
		else if (!paused && updateTime)
		{
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.noteOffset);
			songPercent = curTime / songLength;

			var songCalc:Float = songLength - curTime;

			var secondsTotalLeft:Int = Math.floor(songCalc / 1000);
			if (secondsTotalLeft < 0) secondsTotalLeft = 0;

			var secondsTotalElapsed:Int = Math.floor(curTime / 1000);
			if (secondsTotalElapsed < 0) secondsTotalElapsed = 0;

			timeTxt.text = SONG.songName + ' - ' + CoolUtil.difficultyStuff[lastDifficulty][1];

			switch (ClientPrefs.timeBarType)
			{
				case 'Time Elapsed/Left': timeTxt.text += ' (${FlxStringUtil.formatTime(secondsTotalElapsed)} / ${FlxStringUtil.formatTime(secondsTotalLeft)})';
				case 'Time Elapsed': timeTxt.text += ' (${FlxStringUtil.formatTime(secondsTotalElapsed)})';
				case 'Time Left': timeTxt.text += ' (${FlxStringUtil.formatTime(secondsTotalLeft)})';
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
		}

		camNoteCombo.zoom = camHUD.zoom - 0.25;

		if (!ClientPrefs.noReset && controls.RESET_P && canReset && !inCutscene && startedCountdown && !endingSong) // RESET = Quick Game Over Screen
		{
			health = 0;
			Debug.logInfo("RESET = True");
		}

		doDeathCheck();

		FlxG.watch.addQuick('secShit', curSection);
		FlxG.watch.addQuick('beatShit', curBeat);
		FlxG.watch.addQuick('stepShit', curStep);

		updateScore();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;

			if (songSpeed < 1) time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
				callOnHScript('onSpawnNote', [dunceNote]);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if (!inCutscene)
			{
				if (!cpuControlled) {
					keysCheck();
				}
				else {
					playerDance();
				}

				if (notes.length > 0)
				{
					if (startedCountdown)
					{
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;

						notes.forEachAlive(function(daNote:Note):Void
						{
							var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
							if (!daNote.mustPress) strumGroup = opponentStrums;

							var strum:StrumNote = strumGroup.members[daNote.noteData];
							daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

							if (daNote.mustPress)
							{
								if (cpuControlled && !daNote.blockHit && daNote.canBeHit && (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition)) {
									goodNoteHit(daNote);
								}
							}
							else if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote) {
								opponentNoteHit(daNote);
							}

							if (daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

							if (Conductor.songPosition - daNote.strumTime > noteKillOffset) // Kill extremely late notes and cause misses
							{
								if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
									noteMiss(daNote);
								}

								daNote.active = daNote.visible = false;
								invalidateNote(daNote);
							}
						});
					}
					else
					{
						notes.forEachAlive(function(daNote:Note)
						{
							daNote.canBeHit = false;
							daNote.wasGoodHit = false;
						});
					}
				}
			}

			checkEventNote();
		}

		#if debug
		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.justPressed.ONE)
			{
				killNotes();
				FlxG.sound.music.onComplete();
			}

			if (FlxG.keys.justPressed.TWO) // Go 10 seconds into the future :O
			{
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnScripts('cameraX', camFollow.x);
		setOnScripts('cameraY', camFollow.y);
		setOnScripts('botPlay', cpuControlled);

		callOnScripts('onUpdatePost', [elapsed]);
	}

	public dynamic function updateIconsScale(elapsed:Float):Void // Health icon updaters
	{
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();
	}

	public dynamic function updateIconsPosition():Void
	{
		var iconOffset:Float = 26;

		iconP1.x = healthBar.barCenter - iconOffset;
		iconP2.x = healthBar.barCenter - (iconP2.width - iconOffset);
	}

	var iconsAnimations:Bool = true;

	function set_health(value:Float):Float
	{
		if (!iconsAnimations || healthBar == null || !healthBar.enabled || healthBar.valueFunction == null)
		{
			health = value;
			setOnScripts('health', health);
			return health;
		}

		health = CoolUtil.boundTo(value, healthBar.bounds.min, healthBar.bounds.max);

		var newPercent:Null<Float> = FlxMath.remapToRange(CoolUtil.boundTo(healthBar.valueFunction(), healthBar.bounds.min, healthBar.bounds.max), healthBar.bounds.min, healthBar.bounds.max, 0, 100);
		healthBar.percent = (newPercent != null ? newPercent : 0);

		setOnScripts('health', health);

		return health;
	}

	private function makeOperationsActive(value:Bool = true):Void
	{
		camGame.active = value;
		camCustom.active = value;
		camHUD.active = value;
		camOther.active = value;

		FlxTimer.globalManager.forEach(function(tmr:FlxTimer):Void
		{
			if (!tmr.finished) tmr.active = value;
		});

		FlxG.sound.list.forEachAlive(function(sud:FlxSound):Void
		{
			if (sud != vocals)
			{
				@:privateAccess
				{
					if (value) {
						if (sud._paused) sud.resume();
					}
					else {
						if (!sud._paused) sud.pause();
					}
				}	
			}
		});

		FlxTween.globalManager.forEach(function(twn:FlxTween):Void
		{
			if (!twn.finished) twn.active = value;
		});
	}

	function openPauseMenu():Void
	{
		FlxG.camera.followLerp = 0;

		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}

		if (!cpuControlled)
		{
			for (note in playerStrums)
			{
				if (note.animation.curAnim != null && note.animation.curAnim.name != 'static')
				{
					note.playAnim('static');
					note.resetAnim = 0;
				}
			}
		}

		openSubState(new PauseSubState());

		#if DISCORD_ALLOWED
		if (autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.songName + " - " + storyDifficultyText, iconP2.character);
		#end
	}

	function openChartEditor():Void
	{
		FlxG.camera.followLerp = 0;

		persistentUpdate = false;
		paused = true;

		cancelMusicFadeTween();
		stopMusic();

		chartingMode = true;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		DiscordClient.resetClientID();
		#end
		
		FlxG.switchState(new editors.ChartingState());
	}

	function openCharacterEditor():Void
	{
		FlxG.camera.followLerp = 0;

		persistentUpdate = false;
		paused = true;

		cancelMusicFadeTween();
		stopMusic();

		#if DISCORD_ALLOWED
		DiscordClient.resetClientID();
		#end
	
		FlxG.switchState(new editors.CharacterEditorState(SONG.player2));
	}

	public var isDead:Bool = false; // Don't mess with this on Lua!!!

	function doDeathCheck(?skipHealthCheck:Bool = false):Bool
	{
		final hpBound:Float = (healthBar.bounds != null ? healthBar.bounds.min : 0);

		if (((skipHealthCheck && instakillOnMiss) || health <= hpBound) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnScripts('onGameOver', null, true);

			if (ret != Function_Stop)
			{
				FlxG.animationTimeScale = 1;
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;
				stopMusic();

				persistentUpdate = false;
				persistentDraw = false;

				FlxTimer.globalManager.clear();
				FlxTween.globalManager.clear();

				#if LUA_ALLOWED
				modchartTimers.clear();
				modchartTweens.clear();
				#end

				openSubState(new GameOverSubState());
				makeOperationsActive();

				#if DISCORD_ALLOWED
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.songName + " - " + storyDifficultyText, iconP2.character); // Game Over doesn't get his own variable because it's only used here
				#end

				return isDead = true;
			}
		}

		return false;
	}

	public function checkEventNote():Void
	{
		while (eventNotes.length > 0)
		{
			var leStrumTime:Float = eventNotes[0].strumTime;

			if (Conductor.songPosition < leStrumTime) {
				return;
			}

			var value1:String = '';

			if (eventNotes[0].value1 != null) {
				value1 = eventNotes[0].value1;
			}

			var value2:String = '';

			if (eventNotes[0].value2 != null) {
				value2 = eventNotes[0].value2;
			}

			try {
				triggerEvent(eventNotes[0].event, value1, value2, leStrumTime);
			}
			catch (e:Error) {
				Debug.logError('Error on event "' + eventNotes[0].event + '": ' + e.toString());
			}

			eventNotes.shift();
		}
	}

	public function triggerEvent(eventName:String, value1:String, value2:String, ?strumTime:Float):Void
	{
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);

		if (Math.isNaN(flValue1)) flValue1 = null;
		if (Math.isNaN(flValue2)) flValue2 = null;

		if (strumTime == null) strumTime = Conductor.songPosition;

		switch (eventName)
		{
			case 'Dad Battle Spotlight' | 'Dadbattle Spotlight':
			{
				if (flValue1 == null) flValue1 = 0;
				var val:Int = Math.round(flValue1);

				switch (val)
				{
					case 1, 2, 3: // enable and target dad
					{
						if (val == 1) //enable
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleFog.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if (val > 2) who = boyfriend; // 2 only targets dad

						dadbattleLight.alpha = 0;

						new FlxTimer().start(0.12, function(tmr:FlxTimer):Void {
							dadbattleLight.alpha = 0.375;
						});

						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);
						FlxTween.tween(dadbattleFog, {alpha: 0.7}, 1.5, {ease: FlxEase.quadInOut});
					}
					default:
					{
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= 0.12;

						FlxTween.tween(dadbattleFog, {alpha: 0}, 0.7, {onComplete: function(twn:FlxTween):Void dadbattleFog.visible = false});
					}
				}
			}
			case 'Hey!':
			{
				var value:Int = 2;

				switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '0': value = 0;
					case 'gf' | 'girlfriend' | '1': value = 1;
				}

				if (flValue2 == null || flValue2 <= 0) flValue2 = 0.6;

				if (value != 0)
				{
					if (dad.curCharacter.startsWith('gf')) // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
					{
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					}
					else if (gf != null && (phillyTrain == null || !phillyTrain.moving))
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					}
				}

				if (value != 1)
				{
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = flValue2;
				}
			}
			case 'Set GF Speed':
			{
				if (flValue1 == null || flValue1 < 1) flValue1 = 1;
				gfSpeed = Math.round(flValue1);
			}
			case 'Philly Glow':
			{
				if (flValue1 == null || flValue1 <= 0) flValue1 = 0;
				var lightId:Int = Math.round(flValue1);

				var chars:Array<Character> = [boyfriend, gf, dad];

				switch (lightId)
				{
					case 0:
					{
						if (phillyGlowGradient.visible)
						{
							doPhillyGlowFlash();

							if (ClientPrefs.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = false;

							phillyWindowEvent.visible = false;
							phillyGlowGradient.visible = false;
							phillyGlowParticles.visible = false;

							curLightEvent = -1;

							for (who in chars) {
								who.color = FlxColor.WHITE;
							}

							phillyStreet.color = FlxColor.WHITE;
						}
					}
					case 1: // turn on
					{
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length - 1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];

						if (!phillyGlowGradient.visible)
						{
							doPhillyGlowFlash();

							if (ClientPrefs.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = true;
							blammedLightsBlack.alpha = 1;
							phillyWindowEvent.visible = true;
							phillyGlowGradient.visible = true;
							phillyGlowParticles.visible = true;
						}
						else if (ClientPrefs.flashingLights)
						{
							var colorButLower:FlxColor = color;
							colorButLower.alphaFloat = 0.25;
							FlxG.camera.flash(colorButLower, 0.5, null, true);
						}

						var charColor:FlxColor = color;

						if (!ClientPrefs.flashingLights) {
							charColor.saturation *= 0.5;
						}
						else charColor.saturation *= 0.75;

						for (who in chars) {
							who.color = charColor;
						}

						phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle):Void {
							particle.color = color;
						});

						phillyGlowGradient.color = color;
						phillyWindowEvent.color = color;

						color.brightness *= 0.5;
						phillyStreet.color = color;
					}
					case 2: // spawn particles
					{
						if (!ClientPrefs.lowQuality)
						{
							var particlesNum:Int = FlxG.random.int(8, 12);
							var width:Float = (2000 / particlesNum);
							var color:FlxColor = phillyLightsColors[curLightEvent];

							for (j in 0...3)
							{
								for (i in 0...particlesNum)
								{
									var particle:PhillyGlowParticle = new PhillyGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5), phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40), color);
									phillyGlowParticles.add(particle);
								}
							}
						}

						phillyGlowGradient.bop();
					}
				}
			}
			case 'Kill Henchmen': killHenchmen();
			case 'Add Camera Zoom':
			{
				camZooming = true;

				if (ClientPrefs.camZooms && FlxG.camera.zoom < 1.35)
				{
					if (flValue1 == null) flValue1 = 0.015;
					if (flValue2 == null) flValue2 = 0.03;

					FlxG.camera.zoom += flValue1;
					camHUD.zoom += flValue2;
				}
			}
			case 'BG Freaks Expression': if (bgGirls != null) bgGirls.swapDanceType();
			case 'Trigger BG Ghouls':
			{
				if (!ClientPrefs.lowQuality)
				{
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}
			}
			case 'Pico Speaker Shoot':
			{
				if (gf != null && gf.curCharacter == 'pico-speaker')
				{
					var val1:Int = Std.parseInt(value1);
					if (Math.isNaN(val1)) val1 = 1;

					if (val1 > 2) {
						val1 = 3;
					}

					val1 += FlxG.random.int(0, 1);

					var animName:String = 'shoot' + val1;

					if (gf.hasAnimation(animName))
					{
						gf.playAnim(animName, true);
						gf.animation.finishCallback = function(name:String):Void
						{
							if (gf.hasAnimation(name)) {
								gf.playAnim(name, false, false, gf.animation.curAnim.frames.length - 3);
							}
						}
					}
				}
			}
			case 'Play Animation':
			{
				var char:Character = dad;

				switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend': char = boyfriend;
					case 'gf' | 'girlfriend': char = gf;
					default:
					{
						if (flValue2 == null) flValue2 = 0;

						switch (Math.round(flValue2))
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
					}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}
			}
			case 'Camera Follow Pos':
			{
				if (camFollow != null)
				{
					isCameraOnForcedPos = false;

					if (flValue1 != null || flValue2 != null)
					{
						isCameraOnForcedPos = true;

						if (flValue1 == null) flValue1 = 0;
						if (flValue2 == null) flValue2 = 0;

						camFollow.x = flValue1;
						camFollow.y = flValue2;
					}
				}
			}
			case 'Alt Idle Animation':
			{
				var char:Character = dad;

				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend': char = gf;
					case 'boyfriend' | 'bf': char = boyfriend;
					default:
					{
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val)) val = 0;

						switch (val)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
					}
				}

				if (char != null) char.idleSuffix = value2;
			}
			case 'Screen Shake':
			{
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];

				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');

					var duration:Float = 0;
					var intensity:Float = 0;

					if (split[0] != null) duration = Std.parseFloat(split[0].trim());
					if (split[1] != null) intensity = Std.parseFloat(split[1].trim());

					if (Math.isNaN(duration)) duration = 0;
					if (Math.isNaN(intensity)) intensity = 0;

					if (duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}
			}
			case 'Change Character':
			{
				var charType:Int = 0;

				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend': charType = 2;
					case 'dad' | 'opponent': charType = 1;
					default:
					{
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
					}
				}

				switch (charType)
				{
					case 0:
					{
						if (boyfriend.curCharacter != value2)
						{
							if (!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = FlxMath.EPSILON;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}

						setOnScripts('boyfriendName', boyfriend.curCharacter);
					}
					case 1:
					{
						if (dad.curCharacter != value2)
						{
							if (!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf-') || dad.curCharacter == 'gf';
							var lastAlpha:Float = dad.alpha;

							dad.alpha = FlxMath.EPSILON;
							dad = dadMap.get(value2);

							if (!dad.curCharacter.startsWith('gf-') && dad.curCharacter != 'gf')
							{
								if (wasGf && gf != null) {
									gf.visible = true;
								}
							}
							else if (gf != null) {
								gf.visible = false;
							}

							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}

						setOnScripts('dadName', dad.curCharacter);
					}
					case 2:
					{
						if (gf != null)
						{
							if (gf.curCharacter != value2)
							{
								if (!gfMap.exists(value2)) {
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = FlxMath.EPSILON;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
						}

						setOnScripts('gfName', gf.curCharacter);
					}
				}

				reloadHealthBarColors();
			}
			case 'Change Scroll Speed':
			{
				if (songSpeedType != 'constant')
				{
					if (flValue1 == null) flValue1 = 1;
					if (flValue2 == null) flValue2 = 0;

					final newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;

					if (flValue2 <= 0) {
						songSpeed = newValue;
					}
					else
					{
						songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, flValue2 / playbackRate,
						{
							ease: FlxEase.linear,
							onComplete: function(twn:FlxTween):Void {
								songSpeedTween = null;
							}
						});
					}
				}
			}
			case 'Play Sound':
			{
				if (flValue2 == null) flValue2 = 1;
				FlxG.sound.play(Paths.getSound(value1), flValue2) #if FLX_PITCH .pitch = playbackRate #end;
			}
			case 'Set Camera Zoom':
			{
				if (flValue1 == null) flValue1 = stageData.defaultZoom;
				defaultCamZoom = flValue1;
			}
			case 'Set Camera Speed':
			{
				if (flValue1 == null) flValue1 = stageData.camera_speed;
				cameraSpeed = flValue1;
			}
			case 'Move Camera':
			{
				var charType:String = null;

				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend' | '2': charType = 'gf';
					case 'dad' | 'opponent' | '1' | 'true': charType = 'dad';
					case 'bf' | 'boyfriend' | '0' | 'false': charType = 'boyfriend';
				}

				if (value1 != null && value1.length > 0) {
					cameraMovement(charType);
				}
				else {
					cameraMovementSection();
				}
			}
			case 'Camera Flash':
			{
				var array:Array<String> = [for (i in value1.trim().split(',')) i.trim()];

				var color:FlxColor = CoolUtil.colorFromString(value2);
				var duration:Float = (array[1] != null && array[1].length > 0) ? Std.parseInt(array[1]) : -1;

				if (Math.isNaN(duration)) duration = -1;

				var camera:FlxCamera = cameraFromString((value2 != null && value2.length > 0) ? value2 : 'game');

				if (duration > 0) {
					camera.flash(color, duration);
				}
			}
			case 'Camera Fade':
			{
				var array:Array<String> = [for (i in value1.trim().split(',')) i.trim()];

				var color:FlxColor = CoolUtil.colorFromString(value2);
				var duration:Float = (array[1] != null && array[1].length > 0) ? Std.parseInt(array[1]) : -1;
				var fadeIn:Bool = (array[2] != null && array[2].length > 0) ? array[1] == 'true' : false;

				if (Math.isNaN(duration)) duration = -1;

				var camera:FlxCamera = cameraFromString((value2 != null && value2.length > 0) ? value2 : 'game');

				if (duration > 0) {
					camera.fade(color, duration, fadeIn);
				}
			}
		}

		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
	}

	public function cameraMovementSection(?sec:Null<Int>, ?callOnScripts:Null<Bool> = true):Void
	{
		if (sec == null) sec = curSection;
		if (sec < 0) sec = 0;

		if (SONG.notes[sec] != null)
		{
			if (gf != null && SONG.notes[sec].gfSection) {
				cameraMovement('gf', callOnScripts);
			}
			else
			{
				if (!SONG.notes[curSection].mustHitSection) {
					cameraMovement('dad', callOnScripts);
				}
				else {
					cameraMovement('boyfriend', callOnScripts);
				}
			}
		}
	}

	var cameraTwn:FlxTween;

	public function cameraMovement(target:Dynamic, callOnScripts:Bool = false):Void
	{
		if (target == 'dad' || target == 'opponent' || target == true)
		{
			final mid:FlxPoint = dad.getMidpoint();

			camFollow.setPosition(mid.x + 150, mid.y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];

			mid.put();

			tweenCamIn();

			if (callOnScripts) {
				instance.callOnScripts('onMoveCamera', ['dad']);
			}
		}
		else if (target == 'boyfriend' || target == 'bf' || target == false)
		{
			final mid:FlxPoint = boyfriend.getMidpoint();

			camFollow.setPosition(mid.x - 100, mid.y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			mid.put();

			if (SONG.songID == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000) / playbackRate,
				{
					ease: FlxEase.elasticInOut,
					onComplete: function(twn:FlxTween):Void {
						cameraTwn = null;
					}
				});
			}

			if (callOnScripts) {
				instance.callOnScripts('onMoveCamera', ['boyfriend']);
			}
		}
		else
		{
			final mid:FlxPoint = gf.getMidpoint();

			camFollow.setPosition(mid.x, mid.y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];

			mid.put();

			tweenCamIn();

			if (callOnScripts) {
				instance.callOnScripts('onMoveCamera', ['gf']);
			}
		}
	}

	public function tweenCamIn():Void
	{
		if (SONG.songID == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3)
		{
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000) / playbackRate,
			{
				ease: FlxEase.elasticInOut,
				onComplete: function(twn:FlxTween):Void {
					cameraTwn = null;
				}
			});
		}
	}

	public function snapCamFollowToPos(x:Float, y:Float):Void
	{
		camFollow.setPosition(x, y);
		FlxG.camera.focusOn(FlxPoint.get(x, y));
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = function():Void endSong(); // In case you want to change it in a specific song.

		var mode:String = Paths.formatToSongPath(ClientPrefs.cutscenesOnMode);
		allowPlayCutscene = mode.contains(gameMode) || ClientPrefs.cutscenesOnMode == 'Everywhere';

		if (allowPlayCutscene)
		{
			switch (SONG.songID)
			{
				case 'eggnog':
				{
					finishCallback = function():Void
					{
						var blackShit:Sprite = new Sprite(-FlxG.width * FlxG.camera.zoom, -FlxG.height * FlxG.camera.zoom);
						blackShit.makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);

						camHUD.visible = false;
						inCutscene = true;
	
						FlxG.sound.play(Paths.getSound('Lights_Shut_off'), 1, false, null, true, function():Void endSong()) #if FLX_PITCH .pitch = playbackRate #end;
					}
				}
				case 'earworm':
				{
					finishCallback = function():Void
					{
						cameraMovement('dad');

						FlxG.sound.play(Paths.getSound('rewind'));

						camHUD.visible = false;

						defaultCamZoom = 1;
						dad.alpha = FlxMath.EPSILON;
	
						var cg:Sprite = new Sprite(dadGroup.x, dadGroup.y);
						cg.frames = Paths.getSparrowAtlas('characters/cassettegirl-chill');
						cg.animation.addByPrefix('idle', 'cassettegirl-chill', 22, false);
	
						cg.animation.finishCallback = function(anim:String):Void {
							endSong();
						}
	
						cg.playAnim('idle', true);
						add(cg);
					}
				}
			}
		}

		updateTime = false;

		stopMusic();

		if (ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		}
		else
		{
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer):Void {
				finishCallback();
			});
		}
	}

	public function stopMusic():Void
	{
		FlxG.sound.music.pause();
		FlxG.sound.music.stop();
		FlxG.sound.music.volume = 0;

		vocals.pause();
		vocals.stop();
		vocals.volume = 0;
	}

	public var transitioning:Bool = false;

	public function endSong():Bool
	{
		if (!startingSong)
		{
			notes.forEach(function(daNote:Note):Void
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});

			for (daNote in unspawnNotes)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if (doDeathCheck()) {
				return false;
			}
		}

		timeBar.alpha = 0;
		timeTxt.alpha = 0;

		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;
		deathCounter = 0;
		seenCutscene = false;

		var mode:String = Paths.formatToSongPath(ClientPrefs.cutscenesOnMode);
		allowPlayCutscene = mode.contains(gameMode) || ClientPrefs.cutscenesOnMode == 'Everywhere';

		#if ACHIEVEMENTS_ALLOWED
		checkForAchievement([], ['friday_night_play']);
		#end

		var ret:Dynamic = callOnScripts('onEndSong', null, true);

		if (ret != Function_Stop && !transitioning)
		{
			Debug.logInfo('Finished song "' + SONG.songName + '".');

			#if !switch
			if (addScoreOnPractice || !usedPractice)
			{
				var percent:Float = songAccuracy;
				if (Math.isNaN(percent)) percent = 0;

				Highscore.saveScore(SONG.songID, storyDifficulty, songScore, percent);
			}
			#end

			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return false;
			}

			switch (gameMode)
			{
				case 'story':
				{
					campaignScore += songScore;
					campaignMisses += songMisses;

					storyPlaylist.shift();

					if (storyPlaylist.length < 1)
					{
						Paths.loadTopMod(); #if DISCORD_ALLOWED
						DiscordClient.resetClientID();
						#end

						cancelMusicFadeTween();

						if (addScoreOnPractice || !usedPractice)
						{
							var filename:String = WeekData.getWeekFileName();

							WeekData.weekCompleted.set(filename, true);

							#if !switch
							Highscore.saveWeekScore(filename, storyDifficulty, campaignScore);
							#end

							FlxG.save.data.weekCompleted = WeekData.weekCompleted;
							FlxG.save.flush();
						}

						usedPractice = false;
						changedDifficulty = false;

						firstSong = null;

						var week:WeekData = WeekData.getCurrentWeek();

						Debug.logInfo('Finished week "' + week.weekName + '".');
						FlxG.switchState(new StoryMenuState());
					}
					else
					{
						FlxTransitionableState.skipNextTransIn = true;
						FlxTransitionableState.skipNextTransOut = true;

						prevCamFollow = camFollow;

						if (changedDifficulty) lastDifficulty = storyDifficulty;

						SONG = Song.loadFromJson(CoolUtil.formatSong(storyPlaylist[0], storyDifficulty), storyPlaylist[0]);
						cancelMusicFadeTween();

						var diffName:String = CoolUtil.difficultyStuff[PlayState.lastDifficulty][1];
						var weekName:String = WeekData.getCurrentWeek().weekName;

						Debug.logInfo('Loading song "' + SONG.songName + '" on difficulty "' + diffName + '" into week "' + weekName + '".');

						LoadingState.loadAndSwitchState(new PlayState(), true);
					}
				}
				case 'freeplay':
				{
					Paths.loadTopMod(); #if DISCORD_ALLOWED
					DiscordClient.resetClientID();
					#end

					cancelMusicFadeTween();

					firstSong = null;

					FlxG.switchState(new FreeplayMenuState());
				}
				default:
				{
					Paths.loadTopMod(); #if DISCORD_ALLOWED
					DiscordClient.resetClientID();
					#end

					cancelMusicFadeTween();

					firstSong = null;

					FlxG.switchState(new MainMenuState());
				}
			}

			transitioning = true;
		}

		return true;
	}

	public function killNotes():Void
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];

			if (daNote != null)
			{
				daNote.active = false;
				daNote.visible = false;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
		}

		unspawnNotes = [];
		eventNotes = [];
	}

	public var ratingSuffix:String = '';
	public var comboSuffix:String = '';

	private function cachePopUpScore():Void
	{
		var uiPrefix:String = 'ui/';

		if (isPixelStage && ratingSuffix == '') {
			ratingSuffix = '-pixel';
		}

		for (rating in ratingsData)
		{
			if (isPixelStage && Paths.fileExists('images/pixelUI/' + rating.image + ratingSuffix + '.png', IMAGE)) {
				uiPrefix = 'pixelUI/';
			}
			else if (Paths.fileExists('images/' + rating.image + ratingSuffix + '.png', IMAGE)) {
				uiPrefix = '';
			}

			Paths.getImage(uiPrefix + rating.image + ratingSuffix);
		}

		if (isPixelStage && comboSuffix == '') comboSuffix = '-pixel';

		if (isPixelStage && Paths.fileExists('images/pixelUI/combo' + comboSuffix + '.png', IMAGE)) {
			uiPrefix = 'pixelUI/';
		}
		else if (Paths.fileExists('images/combo' + comboSuffix + '.png', IMAGE)) {
			uiPrefix = '';
		}

		Paths.getImage(uiPrefix + 'combo' + comboSuffix);

		uiPrefix = 'ui/';

		for (i in 0...10)
		{
			if (isPixelStage && Paths.fileExists('images/pixelUI/num' + i + comboSuffix + '.png', IMAGE)) {
				uiPrefix = 'pixelUI/';
			}
			else if (Paths.fileExists('images/num' + i + comboSuffix + '.png', IMAGE)) {
				uiPrefix = '';
			}

			Paths.getImage(uiPrefix + 'num' + i + comboSuffix);
		}
	}

	public var showRating:Bool = true;

	private function popUpScore(daNote:Note):Void
	{
		if (daNote != null && !daNote.ratingDisabled)
		{
			if (daNote.isSustainNote)
			{
				if (daNote.parent.rating != 'unknown')
				{
					daNote.rating = daNote.parent.rating;

					var daRating:Rating = Rating.fromListByName(ratingsData, daNote.rating);

					if (daRating != null) {
						health += daRating.health * healthGain;
					}
				}
			}
			else
			{
				final noteDiff:Float = Math.abs(daNote.strumTime - Conductor.songPosition);
				final daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

				if (daRating != null)
				{
					daNote.rating = daRating.name;

					if (daRating.noteSplash && !daNote.noteSplashData.disabled && !daNote.noteSplashData.quick) {
						spawnNoteSplashOnNote(daNote);
					}

					if (!daNote.ratingDisabled) daRating.hits++;

					if ((!practiceMode && !cpuControlled) || ((practiceMode || cpuControlled) && addScoreOnPractice))
					{
						totalPlayed++;

						songScore += daRating.score;
						totalNotesHit += daRating.ratingMod;

						RecalculateRating();
					}

					daNote.ratingMod = daRating.ratingMod;

					if (!daRating.healthDisabled) {
						health += daRating.health * healthGain;
					}

					if (!ClientPrefs.comboStacking && grpRatings.members.length > 0)
					{
						for (rating in grpRatings) {
							grpRatings.remove(rating);
						}
					}

					var rating:RatingSprite = grpRatings.recycle(RatingSprite, true);
					rating.resetSprite(580, 224, daRating.image, ratingSuffix);
					rating.reoffset();
					rating.visible = (ClientPrefs.showCombo && showRating);
					grpRatings.add(rating);

					rating.disappear();

					displayCombo();
				}
			}
		}
	}

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;

	var lastComboTen:Int = 3;
	var _lastComboTenDiffs:Int = 0;

	private function displayCombo():Void
	{
		if (!ClientPrefs.comboStacking && grpComboNumbers.members.length > 0)
		{
			for (i in grpComboNumbers) {
				grpComboNumbers.remove(i);
			}
		}

		var stringCombo:String = Std.string(combo);

		if (stringCombo.length > lastComboTen)
		{
			var prevCombo:Int = lastComboTen;

			lastComboTen += (stringCombo.length - prevCombo);
			_lastComboTenDiffs += (lastComboTen - prevCombo);
		}

		final seperatedScore:Array<Int> = [for (i in 0...lastComboTen) Math.floor(combo / Math.pow(10, i)) % 10];
		seperatedScore.reverse();

		for (i in 0...seperatedScore.length)
		{
			var int:Int = i - _lastComboTenDiffs;

			var numScore:ComboNumberSprite = grpComboNumbers.recycle(ComboNumberSprite, true);
			numScore.resetSprite(705 + (43 * (int)) - 175, 380, seperatedScore[i], comboSuffix);
			numScore.reoffset();
			numScore.visible = (ClientPrefs.showCombo && showComboNum);
			grpComboNumbers.add(numScore);

			numScore.disappear();
		}

		if (!ClientPrefs.comboStacking && grpCombo.members.length > 0)
		{
			for (combo in grpCombo) {
				grpCombo.remove(combo);
			}
		}

		var comboSpr:ComboSprite = grpCombo.recycle(ComboSprite, true);
		comboSpr.resetSprite(705, 350, comboSuffix);
		comboSpr.reoffset();
		comboSpr.visible = (ClientPrefs.showCombo && showCombo);
		grpCombo.add(comboSpr);

		comboSpr.disappear();
	}

	public var strumsBlocked:Array<Bool> = [];

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);

		if (!controls.controllerMode)
		{
			#if debug
			@:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey)) return; // Prevents crash specifically on debug without needing to try catch shit
			#end

			if (FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
		}
	}

	private function keyPressed(key:Int):Void
	{
		if (startingSong || cpuControlled || paused || inCutscene || key < 0 || key >= playerStrums.length || !generatedMusic || endingSong || boyfriend.stunned) return;

		var ret:Dynamic = callOnScripts('onKeyPressPre', [key]);
		if (ret == Function_Stop) return;

		var lastTime:Float = Conductor.songPosition; // more accurate hit time for the ratings?
		if (Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time;

		var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool // obtain notes that the player can hit
		{
			var canHit:Bool = !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
			return n != null && canHit && !n.isSustainNote && n.noteData == key;
		});

		plrInputNotes.sort(sortHitNotes);

		var shouldMiss:Bool = !ClientPrefs.ghostTapping;

		if (plrInputNotes.length != 0) // slightly faster than doing `> 0` lol
		{
			var funnyNote:Note = plrInputNotes[0]; // front note

			if (plrInputNotes.length > 1)
			{
				var doubleNote:Note = plrInputNotes[1];

				if (doubleNote.noteData == funnyNote.noteData)
				{
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0) { // if the note has a 0ms distance (is on top of the current note), kill it
						invalidateNote(doubleNote);
					}
					else if (doubleNote.strumTime < funnyNote.strumTime) {
						funnyNote = doubleNote; // replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
					}
				}
			}

			goodNoteHit(funnyNote);
		}
		else if (shouldMiss)
		{
			callOnScripts('onGhostTap', [key]);
			noteMissPress(key);
		}

		if (!keysPressed.contains(key)) keysPressed.push(key);

		Conductor.songPosition = lastTime; // more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)

		var spr:StrumNote = playerStrums.members[key];

		if (strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
		{
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}

		callOnScripts('onKeyPress', [key]);
	}

	public static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority) {
			return 1;
		}
		else if (!a.lowPriority && b.lowPriority) {
			return -1;
		}

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);

		if (!controls.controllerMode && key > -1) keyReleased(key);
	}

	private function keyReleased(key:Int):Void
	{
		if (!cpuControlled && startedCountdown && !startingSong && !paused && key < playerStrums.length)
		{
			var ret:Dynamic = callOnScripts('onKeyReleasePre', [key]);
			if (ret == Function_Stop) return;

			var spr:StrumNote = playerStrums.members[key];

			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}

			callOnScripts('onKeyRelease', [key]);
		}
	}

	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...arr.length)
			{
				var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];

				for (noteKey in note) {
					if (key == noteKey) return i;
				}
			}
		}

		return -1;
	}

	private function keysCheck():Void // Hold notes
	{
		var holdArray:Array<Bool> = [for (key in keysArray) controls.pressed(key)]; // HOLDING
		var pressArray:Array<Bool> = [for (key in keysArray) controls.justPressed(key)];
		var releaseArray:Array<Bool> = [for (key in keysArray) controls.justReleased(key)];

		if (controls.controllerMode && pressArray.contains(true)) // TO DO: Find a better way to handle controller inputs, this should work for now
		{
			for (i in 0...pressArray.length) {
				if (pressArray[i] && strumsBlocked[i] != true) keyPressed(i);
			}
		}

		if (startedCountdown && !inCutscene && !boyfriend.stunned && generatedMusic && !startingSong)
		{
			if (notes.length > 0)
			{
				for (n in notes) // I can't do a filter here, that's kinda awesome
				{
					var canHit:Bool = (n != null && !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit);

					if (canHit && n.isSustainNote)
					{
						var released:Bool = !holdArray[n.noteData];
						if (!released) goodNoteHit(n);
					}
				}
			}

			if (!holdArray.contains(true) || endingSong) {
				playerDance();
			}
			#if ACHIEVEMENTS_ALLOWED
			else checkForAchievement(['oversinging']);
			#end
		}

		if ((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true)) // TO DO: Find a better way to handle controller inputs, this should work for now
		{
			for (i in 0...releaseArray.length) {
				if (releaseArray[i] || strumsBlocked[i] == true) keyReleased(i);
			}
		}
	}

	function noteMiss(daNote:Note):Void // You didn't hit the key and let it go offscreen, also used by Hurt Notes
	{
		var result:Dynamic = callOnLuas('noteMissPre', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);

		if (result != Function_Stop && result != Function_StopAll)
		{
			if (result != Function_StopHScript) {
				callOnHScript('noteMissPre', [daNote]);
			}
		}

		notes.forEachAlive(function(note:Note):Void //Dupe note remove
		{
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				invalidateNote(note);
			}
		});
		
		noteMissCommon(daNote.noteData, daNote);

		var result:Dynamic = callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);

		if (result != Function_Stop && result != Function_StopAll)
		{
			if (result != Function_StopHScript) {
				callOnHScript('noteMiss', [daNote]);
			}
		}
	}

	function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
	{
		if (ClientPrefs.ghostTapping) return; // fuck it
		noteMissCommon(direction);

		callOnScripts('noteMissPress', [direction]);
	}

	function noteMissCommon(direction:Int, note:Note = null):Void
	{
		FlxG.sound.play(Paths.getSoundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2)) #if FLX_PITCH .pitch = playbackRate #end;

		callOnScripts('noteMissCommon');

		if (instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		var lastCombo:Int = combo;

		if (!endingSong)
		{
			var subtract:Float = (note != null ? note.missHealth : 0.05);
			health -= subtract * healthLoss;

			if (((!practiceMode && !cpuControlled) || ((practiceMode || cpuControlled) && addScoreOnPractice)) && (note == null || !note.isSustainNote))
			{
				songMisses++;
				songHits++;
				totalPlayed++;
				combo = 0;
			}
		}

		RecalculateRating(true);

		var charType:String = 'bf';
		var char:Character = boyfriend; // play character anims

		if ((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection))
		{
			char = gf;
			charType = 'gf';
		}

		if (char != null && (note == null || !note.noMissAnimation) && char.hasMissAnimations)
		{
			var suffix:String = '';
			if (note != null) suffix = note.animSuffix;

			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, direction)))] + 'miss' + suffix;
			var ret:Dynamic = callOnLuas('onCharMissPress', [charType, char.curCharacter, animToPlay, direction]);

			if (note != null) {
				ret = callOnLuas('onCharMissNote', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote, charType, char.curCharacter, animToPlay]);
			}

			if (ret != Function_Stop)
			{
				if (ret != Function_Stop && ret != Function_StopAll)
				{
					if (ret != Function_StopHScript)
					{
						if (note != null) {
							callOnHScript('onCharMissNote', [note, charType, char.curCharacter, animToPlay]);
						}
						else {
							callOnHScript('onCharMissPress', [charType, char.curCharacter, animToPlay, direction]);
						}
					}
				}

				char.playAnim(animToPlay, true);

				if (char != gf && lastCombo > 5 && (note == null || !note.isSustainNote) && gf != null && gf.hasAnimation('sad'))
				{
					gf.playAnim('sad');
					gf.specialAnim = true;
				}
			}
		}

		vocals.volume = 0;
	}

	function opponentNoteHit(note:Note):Void
	{
		var result:Dynamic = callOnLuas('opponentNoteHitPre', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (result != Function_Stop && result != Function_StopAll)
		{
			if (result != Function_StopHScript) {
				callOnHScript('opponentNoteHitPre', [note]);
			}
		}

		if (SONG.songID != 'tutorial') camZooming = true;

		if (note.noteType == 'Hey!' && dad.hasAnimation('hey'))
		{
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		}
		else if (!note.noAnimation)
		{
			var altAnim:String = note.animSuffix;

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection) {
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, note.noteData)))] + altAnim;

			if (note.gfNote) {
				char = gf;
			}

			if (char != null)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		if (SONG.needsVoices) {
			vocals.volume = 1;
		}

		strumPlayAnim(true, note.noteData, Conductor.stepCrochet * 1.25 / 1000 / playbackRate);

		note.hitByOpponent = true;

		var result:Dynamic = callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (result != Function_Stop && result != Function_StopAll)
		{
			if (result != Function_StopHScript) {
				callOnHScript('opponentNoteHit', [note]);
			}
		}

		if (!note.isSustainNote) invalidateNote(note);
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (cpuControlled && note.ignoreNote) return;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;

			var result:Dynamic = callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), leData, leType, isSus]);

			if (result != Function_Stop && result != Function_StopAll)
			{
				if (result != Function_StopHScript) {
					callOnHScript('goodNoteHitPre', [note]);
				}
			}

			note.wasGoodHit = true;

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled) {
				FlxG.sound.play(Paths.getSound(note.hitsound), ClientPrefs.hitsoundVolume) #if FLX_PITCH .pitch = playbackRate #end;
			}

			if (note.hitCausesMiss)
			{
				var result:Dynamic = callOnLuas('onHitCausesMissNotePre', [notes.members.indexOf(note), leData, leType, isSus]);

				if (result != Function_Stop && result != Function_StopAll)
				{
					if (result != Function_StopHScript) {
						callOnHScript('onHitCausesMissNotePre', [note]);
					}
				}

				noteMiss(note);

				if (!note.noMissAnimation)
				{
					switch (note.noteType)
					{
						case 'Hurt Note': // Hurt note
						{
							if (boyfriend.animation.getByName('hurt') != null)
							{
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
						}
					}
				}

				switch (note.noteType)
				{
					default:
					{
						if (!note.noteSplashData.disabled && note.noteSplashData.quick) {
							spawnNoteSplashOnNote(note);
						}
					}
				}

				if (!note.isSustainNote) invalidateNote(note);

				var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
				var leData:Int = note.noteData;
				var leType:String = note.noteType;

				var result:Dynamic = callOnLuas('onHitCausesMissNote', [notes.members.indexOf(note), leData, leType, isSus]);

				if (result != Function_Stop && result != Function_StopAll)
				{
					if (result != Function_StopHScript) {
						callOnHScript('onHitCausesMissNote', [note]);
					}
				}

				return;
			}

			if (!note.isSustainNote && !note.comboDisabled)
			{
				combo++;
				songHits++;
			}

			popUpScore(note);

			switch (note.noteType)
			{
				default:
				{
					if (!note.noteSplashData.disabled && note.noteSplashData.quick) {
						spawnNoteSplashOnNote(note);
					}
				}
			}

			if (!note.healthDisabled) {
				health += note.hitHealth * healthGain;
			}

			if (!note.noAnimation)
			{
				var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, note.noteData)))];

				var char:Character = boyfriend;
				var animCheck:String = 'hey';

				if (note.gfNote)
				{
					char = gf;
					animCheck = 'cheer';
				}
				
				if (char != null)
				{
					char.playAnim(animToPlay + note.animSuffix, true);
					char.holdTimer = 0;
					
					if (note.noteType == 'Hey!')
					{
						if (char.hasAnimation(animCheck))
						{
							char.playAnim(animCheck, true);
							char.specialAnim = true;
							char.heyTimer = 0.6;
						}
					}
				}
			}

			if (!cpuControlled)
			{
				var spr:StrumNote = playerStrums.members[note.noteData];
				if (spr != null) spr.playAnim('confirm', true);
			}
			else {
				strumPlayAnim(false, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
			}

			vocals.volume = 1;

			var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (result != Function_Stop && result != Function_StopAll)
			{
				if (result != Function_StopHScript) {
					callOnHScript('goodNoteHit', [note]);
				}
			}

			if (!note.isSustainNote) invalidateNote(note);
		}
	}

	public function invalidateNote(note:Note):Void
	{
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	public function spawnNoteSplashOnNote(note:Note):Void
	{
		if (note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];

			if (strum != null) {
				spawnNoteSplash(note, strum);
			}
		}
	}

	public function spawnNoteSplash(note:Note, strum:StrumNote):Void
	{
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(strum.x, strum.y, note.noteData, note);
		grpNoteSplashes.add(splash);
	}

	override public function destroy():Void
	{
		#if LUA_ALLOWED
		var luaScript:FunkinLua = null;

		while (luaArray.length > 0)
		{
			luaScript = luaArray.pop();
			if (luaScript == null) continue;

			luaScript.call('onDestroy', []);
			luaScript.stop();
		}
		#end

		#if HSCRIPT_ALLOWED
		var hscript:HScript = null;

		while (hscriptArray.length > 0)
		{
			hscript = hscriptArray.pop();
			if (hscript == null) continue;

			hscript.executeFunction('onDestroy');
			hscript.destroy();
		}
		#end

		customFunctions.clear();

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		FlxG.animationTimeScale = 1;

		#if FLX_PITCH
		FlxG.sound.music.pitch = 1;
		#end

		Note.globalRgbShaders = [];

		NoteTypesConfig.clearNoteTypesData();
		NoteSplash.configs.clear();

		instance = null;

		super.destroy();
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.getSoundRandom('thunder_', 1, 2)) #if FLX_PITCH .pitch = playbackRate #end;
		if (!ClientPrefs.lowQuality) halloweenBG.playAnim('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if (boyfriend.hasAnimation('scared')) {
			boyfriend.playAnim('scared', true);
		}

		if (dad.hasAnimation('scared')) {
			dad.playAnim('scared', true);
		}

		if (gf != null && gf.hasAnimation('scared')) {
			gf.playAnim('scared', true);
		}

		if (ClientPrefs.camZooms)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if (!camZooming) // Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
			{
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5 / playbackRate);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5 / playbackRate);
			}
		}

		if (ClientPrefs.flashingLights)
		{
			halloweenWhite.alpha = 0.4;

			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075 / playbackRate);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25 / playbackRate, {startDelay: 0.15 / playbackRate});
		}
	}

	function doPhillyGlowFlash():Void
	{
		var color:FlxColor = FlxColor.WHITE;
		if (!ClientPrefs.flashingLights) color.alphaFloat = 0.5;

		FlxG.camera.flash(color, 0.15, null, true);
	}

	function resetLimoKill():Void
	{
		limoMetalPole.x = -500;
		limoMetalPole.visible = false;
		limoLight.x = -500;
		limoLight.visible = false;
		limoCorpse.x = -500;
		limoCorpse.visible = false;
		limoCorpseTwo.x = -500;
		limoCorpseTwo.visible = false;
	}

	function limoDancersParenting():Void
	{
		var dancers:Array<BackgroundDancer> = grpLimoDancers.members;

		for (i in 0...dancers.length) {
			dancers[i].x = (370 * i) + dancersDiff + bgLimo.x;
		}
	}

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer = null;

	function fastCarDrive():Void
	{
		FlxG.sound.play(Paths.getSoundRandom('carPass', 0, 1), 0.7) #if FLX_PITCH .pitch = playbackRate #end;

		fastCar.velocity.x = ((FlxG.random.int(170, 220) / FlxG.elapsed) * 3) * playbackRate;
		fastCarCanDrive = false;

		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer):Void
		{
			resetFastCar();
			carTimer = null;
		});
	}

	function killHenchmen():Void
	{
		if (!ClientPrefs.lowQuality)
		{
			if (limoKillingState == 'WAIT')
			{
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 'KILLING';

				#if ACHIEVEMENTS_ALLOWED
				var kills:Float = Achievements.addScore("roadkill_enthusiast");
				Debug.logInfo('Henchmen kills: $kills');
				#end
			}
		}
	}

	function everyoneDanceOnMall():Void
	{
		if (!ClientPrefs.lowQuality && upperBoppers != null) {
			upperBoppers.dance(true);
		}

		bottomBoppers.dance(true);
		santa.dance(true);
	}

	function everyoneDanceOnTank():Void
	{
		if (!ClientPrefs.lowQuality && tankWatchtower != null) tankWatchtower.dance();

		if (foregroundSprites != null)
		{
			foregroundSprites.forEach(function(spr:BGSprite):Void {
				spr.dance();
			});
		}
	}

	public static function cancelMusicFadeTween():Void
	{
		if (FlxG.sound.music != null)
		{
			if (FlxG.sound.music.fadeTween != null) {
				FlxG.sound.music.fadeTween.cancel();
			}

			FlxG.sound.music.fadeTween = null;
		}
	}

	var lastStepHit:Int = -1;

	var climb:Bool = false;
	var climbDelay:Int = -1;

	override function stepHit():Void
	{
		if (FlxG.sound.music.time >= -ClientPrefs.noteOffset)
		{
			final timeWithOffset:Float = Conductor.songPosition - Conductor.offset;
			final maxDelay:Float = 20 * playbackRate;

			if (Math.abs(FlxG.sound.music.time - timeWithOffset) > maxDelay || (SONG.needsVoices && Math.abs(vocals.time - timeWithOffset) > maxDelay)) {
				resyncVocals();
			}
		}

		super.stepHit();

		if (curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;

		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	var lastBeatHit:Int = -1;
	var hotdogGFDanceDir:Bool = false;

	override function beatHit():Void
	{
		if (lastBeatHit >= curBeat) {
			return;
		}

		lastBeatHit = curBeat;

		super.beatHit();

		if (generatedMusic) {
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		characterBopper(curBeat);

		switch (SONG.stage)
		{
			case 'spooky':
			{
				if (FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset) {
					lightningStrikeShit();
				}
			}
			case 'philly':
			{
				phillyTrain.beatHit(curBeat);

				if (curBeat % 4 == 0)
				{
					curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);

					phillyWindow.color = phillyLightsColors[curLight];
					phillyWindow.alpha = 1;
				}
			}
			case 'limo':
			{
				if (!ClientPrefs.lowQuality && grpLimoDancers != null)
				{
					grpLimoDancers.forEach(function(dancer:BackgroundDancer):Void {
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive) fastCarDrive();
			}
			case 'mall': everyoneDanceOnMall();
			case 'school': if (bgGirls != null) bgGirls.dance();
			case 'tank': everyoneDanceOnTank();
		}

		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}

	public function characterBopper(beat:Int, force:Bool = false):Void
	{
		if (gf != null && beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.isAnimationNull() && !gf.getAnimationName().startsWith('sing') && !gf.stunned) {
			gf.dance(force);
		}

		if (boyfriend != null && beat % boyfriend.danceEveryNumBeats == 0 && !boyfriend.isAnimationNull() && !boyfriend.getAnimationName().startsWith('sing') && !boyfriend.stunned) {
			boyfriend.dance(force);
		}

		if (dad != null && beat % dad.danceEveryNumBeats == 0 && !dad.isAnimationNull() && !dad.getAnimationName().startsWith('sing') && !dad.stunned) {
			dad.dance(force);
		}
	}

	public function playerDance(force:Bool = false):Void
	{
		if (!boyfriend.isAnimationNull())
		{
			var anim:String = boyfriend.getAnimationName();

			if (boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 #if FLX_PITCH / FlxG.sound.music.pitch #end) * boyfriend.singDuration && anim.startsWith('sing') && !anim.endsWith('miss')) {
				boyfriend.dance(force);
			}
		}
	}

	override function sectionHit():Void
	{
		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos) {
				cameraMovementSection();
			}

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM == true)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;

				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}

			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}

		super.sectionHit();

		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String):Bool
	{
		var luaToLoad:String = Paths.getLua(luaFile);

		if (Paths.fileExists(luaToLoad, TEXT))
		{
			#if sys
			luaToLoad.substr(luaToLoad.indexOf(':') + 1);
			#end

			for (script in luaArray) {
				if (script.scriptName == luaToLoad) return false;
			}

			var lua:FunkinLua = new FunkinLua(luaToLoad);
			return !lua.closed;
		}

		return false;
	}
	#end

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String):Bool
	{
		var scriptToLoad:String = Paths.getHX(scriptFile);

		if (Paths.fileExists(scriptToLoad, TEXT))
		{
			for (hx in hscriptArray)
			{
				if (hx.origin == scriptToLoad) {
					return false;
				}
			}
	
			initHScript(scriptToLoad);
			return true;
		}

		return false;
	}

	public function initHScript(file:String):HScript
	{
		try
		{
			var newScript:HScript = new HScript(file);
			hscriptArray.push(newScript);

			if (newScript.exception != null)
			{
				debugTrace('ERROR ON LOADING - ${newScript.exception.message}', false, 'error', FlxColor.RED);

				newScript.destroy();
				hscriptArray.remove(newScript);
				newScript = null;

				return null;
			}

			if (newScript.variables.exists('onCreate'))
			{
				newScript.executeFunction('onCreate');

				if (newScript.exception != null)
				{
					debugTrace('ERROR (onCreate) - ${newScript.exception.message}', false, 'error', FlxColor.RED);

					newScript.destroy();
					hscriptArray.remove(newScript);
					newScript = null;

					return null;
				}
			}

			Debug.logInfo('initialized hscript interp successfully: $file');
			return newScript;
		}
		catch (e:Error)
		{
			debugTrace('ERROR - ${e.toString()}', false, 'error', FlxColor.RED);

			if (hscriptArray.length > 0)
			{
				var script:HScript = hscriptArray[hscriptArray.length - 1];

				script.destroy();
				hscriptArray.remove(script);
				script = null;
			}
		}

		return null;
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic
	{
		if (args == null) args = new Array();
		if (exclusions == null) exclusions = new Array();
		if (excludeValues == null) excludeValues = [Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if (result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);

		return result;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = Function_Continue;

		#if LUA_ALLOWED
		if (args == null) args = [];
		if (exclusions == null) exclusions = [];
		if (excludeValues == null) excludeValues = [Function_Continue];

		var arr:Array<FunkinLua> = [];

		for (script in luaArray)
		{
			if (script.closed)
			{
				arr.push(script);
				continue;
			}

			if (exclusions.contains(script.scriptName)) continue;

			var myValue:Dynamic = script.call(funcToCall, args);

			if ((myValue == Function_StopLua || myValue == Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
			{
				returnVal = myValue;
				break;
			}

			if (myValue != null && !excludeValues.contains(myValue)) {
				returnVal = myValue;
			}

			if (script.closed) arr.push(script);
		}

		if (arr.length > 0) {
			for (script in arr) luaArray.remove(script);
		}
		#end

		return returnVal;
	}
	
	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, ?exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = Function_Continue;

		#if HSCRIPT_ALLOWED
		if (exclusions == null) exclusions = new Array();
		if (excludeValues == null) excludeValues = new Array();

		excludeValues.push(Function_Continue);

		var len:Int = hscriptArray.length;

		if (len < 1) {
			return returnVal;
		}

		for (i in 0...len)
		{
			var script:HScript = hscriptArray[i];

			if (script == null || !script.active || !script.variables.exists(funcToCall) || exclusions.contains(script.origin)) {
				continue;
			}

			var myValue:Dynamic = null;

			try
			{
				returnVal = script.executeFunction(funcToCall, args);

				if (script.exception != null)
				{
					script.active = false;
					debugTrace('ERROR ($funcToCall) - ${script.exception}', true, 'error', FlxColor.RED);
				}
				else {
					if ((returnVal == Function_StopHScript || returnVal == Function_StopAll) && !excludeValues.contains(returnVal) && !ignoreStops) break;
				}
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void
	{
		if (exclusions == null) exclusions = new Array();

		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void
	{
		#if LUA_ALLOWED
		if (exclusions == null) exclusions = new Array();

		for (script in luaArray)
		{
			if (exclusions.contains(script.scriptName)) continue;
			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void
	{
		#if HSCRIPT_ALLOWED
		if (exclusions == null) exclusions = new Array();

		for (script in hscriptArray)
		{
			if (exclusions.contains(script.origin)) continue;
			script.setVar(variable, arg);
		}
		#end
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float):Void
	{
		var spr:StrumNote = null;

		if (isDad) {
			spr = opponentStrums.members[id];
		}
		else {
			spr = playerStrums.members[id];
		}

		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public function RecalculateRating(badHit:Bool = false):Void
	{
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);
		setOnScripts('combo', combo);

		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);

		if (ret != Function_Stop)
		{
			ratingName = 'N/A';

			if (totalPlayed > 0) // Prevent divide by 0
			{
				songAccuracy = CoolUtil.boundTo(totalNotesHit / totalPlayed, 0, 1);

				if (songAccuracy < 1)
				{
					for (i in 0...ratingStuff.length - 1)
					{
						final daRating:Array<Dynamic> = ratingStuff[i];
						final leAccuracy:Float = cast daRating[1];

						if (songAccuracy < leAccuracy)
						{
							ratingName = daRating[0]; // Rating Name
							break;
						}
					}
				}
				else ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
			}

			fullComboFunction();
		}

		updateScore(badHit);

		setOnScripts('accuracy', songAccuracy);
		setOnScripts('rating', songAccuracy);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	public function checkForAchievement(?include:Array<String>, ?exclude:Array<String>):Void
	{
		if (chartingMode) return;

		if (include == null || include.length < 1) include = Achievements.achievementList.copy();
		if (exclude == null) exclude = [];

		if (exclude.length > 0) {
			for (i in exclude) include.remove(i);
		}

		var achievesToCheck:Array<Achievement> = [for (i in include) Achievements.get(i)];

		for (award in achievesToCheck)
		{
			if (award != null)
			{
				var name:String = award.save_tag;

				if (!Achievements.isUnlocked(name) && (addScoreOnPractice || !cpuControlled) && Achievements.exists(name))
				{
					var unlock:Bool = false;

					if ((!usedPractice || addScoreOnPractice) && (isStoryMode && award.week_nomiss == WeekData.getWeekFileName()) || (award.song == SONG.songID))
					{
						var diff:String = CoolUtil.difficultyStuff[storyDifficulty][0];

						if (award.diff == diff || award.diff == null || award.diff.length < 1)
						{
							var isNoMisses:Bool = true;

							if (award.misses > -1)
								isNoMisses = campaignMisses + songMisses < award.misses + 1;

							if (!changedDifficulty && isNoMisses)
								unlock = (storyPlaylist.length < 2 || !isStoryMode);
						}
					}

					switch (name)
					{
						case 'ur_bad': if (songAccuracy < 0.2 && (addScoreOnPractice || !practiceMode)) unlock = true;
						case 'ur_good': if (songAccuracy >= 1 && (addScoreOnPractice || !usedPractice)) unlock = true;
						case 'oversinging': unlock = boyfriend.holdTimer >= 10 && (addScoreOnPractice || !usedPractice);
						case 'hype': unlock = !boyfriendIdled && (addScoreOnPractice || !usedPractice);
						case 'two_keys': unlock = (addScoreOnPractice || !usedPractice) && keysPressed.length <= 2;
						case 'toastie': unlock = !ClientPrefs.cacheOnGPU && ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing && !ClientPrefs.shadersEnabled;
						case 'debugger': unlock = SONG.songID == 'test' && (addScoreOnPractice || !usedPractice);
					}

					if (unlock) Achievements.unlock(name);
				}
			}
		}
	}
	#end

	#if (LUA_ALLOWED && desktop && RUNTIME_SHADERS_ALLOWED)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();

	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if (ClientPrefs.shadersEnabled)
		{
			if (!runtimeShaders.exists(name) && !initLuaShader(name))
			{
				Debug.logWarn('Shader $name is missing!');
				return new FlxRuntimeShader();
			}

			var arr:Array<String> = runtimeShaders.get(name);
			return new FlxRuntimeShader(arr[0], arr[1]);
		}

		return new FlxRuntimeShader();
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120):Bool
	{
		if (ClientPrefs.shadersEnabled)
		{
			if (runtimeShaders.exists(name))
			{
				Debug.logWarn('Shader $name was already initialized!');
				return true;
			}
	
			var foldersToCheck:Array<String> = [Paths.getPreloadPath('shaders/')];

			var libraryPath:String = Paths.getLibraryPath('shaders/', 'shared');
			foldersToCheck.insert(0, libraryPath.substring(libraryPath.indexOf(':') + 1, libraryPath.length));

			if (Paths.currentLevel != null && Paths.currentLevel.length > 0 && Paths.currentLevel != 'shared')
			{
				var libraryPath:String = Paths.getLibraryPath('shaders/', Paths.currentLevel);
				foldersToCheck.insert(0, libraryPath.substring(libraryPath.indexOf(':') + 1, libraryPath.length));
			}

			#if MODS_ALLOWED
			foldersToCheck.insert(0, Paths.mods('shaders/'));

			if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) {
				foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));
			}

			for (mod in Paths.globalMods) {
				foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
			}
			#end
			
			for (folder in foldersToCheck)
			{
				if (FileSystem.exists(folder))
				{
					var frag:String = folder + name + '.frag';
					var vert:String = folder + name + '.vert';
	
					var found:Bool = false;
	
					if (FileSystem.exists(frag))
					{
						frag = File.getContent(frag);
						found = true;
					}
					else frag = null;
	
					if (FileSystem.exists(vert))
					{
						vert = File.getContent(vert);
						found = true;
					}
					else vert = null;
	
					if (found)
					{
						runtimeShaders.set(name, [frag, vert]);
						return true;
					}
				}
			}

			Debug.logWarn('Missing shader $name .frag AND .vert files!');
		}

		return false;
	}
	#end

	public static function debugTrace(text:String, ignoreCheck:Bool = false, type:String = 'normal', color:FlxColor = FlxColor.WHITE):Void
	{
		#if MODS_ALLOWED
		if (PlayState.instance != null && (ignoreCheck || PlayState.instance.debugMode)) {
			PlayState.instance.addTextToDebug(text, color);
		}
		#end

		switch (type)
		{
			case 'error': Debug.logError(text);
			case 'warn' | 'deprecated': Debug.logWarn(text);
			default: Debug.logInfo(text);
		}
	}

	public static function getTween(options:Dynamic):LuaTweenOptions
	{
		return {
			type: getTweenTypeByString(options.type),
			startDelay: options.startDelay,
			onUpdate: options.onUpdate,
			onStart: options.onStart,
			onComplete: options.onComplete,
			loopDelay: options.loopDelay,
			ease: getTweenEaseByString(options.ease)
		};
	}

	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic, allowMaps:Bool = false):Any
	{
		if (value == 'true') value = true;

		final splitProps:Array<String> = variable.split('[');

		if (splitProps.length > 1)
		{
			var target:Dynamic = null;

			if (PlayState.instance.variables.exists(splitProps[0]))
			{
				final retVal:Dynamic = PlayState.instance.variables.get(splitProps[0]);
				if (retVal != null) target = retVal;
			}
			else target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length)
			{
				final j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);

				if (i >= splitProps.length - 1) target[j] = value; // Last array
				else target = target[j]; // Anything else
			}

			return target;
		}

		if (allowMaps && isMap(instance))
		{
			instance.set(variable, value);
			return value;
		}

		if (PlayState.instance.variables.exists(variable))
		{
			PlayState.instance.variables.set(variable, value);
			return value;
		}

		Reflect.setProperty(instance, variable, value);
		return value;
	}

	public static function getVarInArray(instance:Dynamic, variable:String, allowMaps:Bool = false):Any
	{
		final splitProps:Array<String> = variable.split('[');

		if (splitProps.length > 1)
		{
			var target:Dynamic = null;

			if (PlayState.instance.variables.exists(splitProps[0]))
			{
				final retVal:Dynamic = PlayState.instance.variables.get(splitProps[0]);
				if (retVal != null) target = retVal;
			}
			else target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length)
			{
				final j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				target = target[j];
			}

			return target;
		}

		if (allowMaps && isMap(instance)) {
			return instance.get(variable);
		}

		if (PlayState.instance.variables.exists(variable))
		{
			var retVal:Dynamic = PlayState.instance.variables.get(variable);
			if (retVal != null) return retVal;
		}

		return Reflect.getProperty(instance, variable);
	}

	public static function isMap(variable:Dynamic):Bool
	{
		return variable.exists != null && variable.keyValueIterator != null;
	}

	public static function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic, ?allowMaps:Bool = false):Dynamic
	{
		final split:Array<String> = variable.split('.');

		if (split.length > 1)
		{
			var obj:Dynamic = Reflect.getProperty(leArray, split[0]);

			for (i in 1...split.length - 1) {
				obj = Reflect.getProperty(obj, split[i]);
			}

			leArray = obj;
			variable = split[split.length - 1];
		}

		if (allowMaps && isMap(leArray)) leArray.set(variable, value);
		else Reflect.setProperty(leArray, variable, value);

		return value;
	}

	public static function getGroupStuff(leArray:Dynamic, variable:String, ?allowMaps:Bool = false):Dynamic
	{
		final split:Array<String> = variable.split('.');

		if (split.length > 1)
		{
			var obj:Dynamic = Reflect.getProperty(leArray, split[0]);

			for (i in 1...split.length - 1) {
				obj = Reflect.getProperty(obj, split[i]);
			}

			leArray = obj;
			variable = split[split.length - 1];
		}

		if (allowMaps && isMap(leArray)) return leArray.get(variable);
		return Reflect.getProperty(leArray, variable);
	}

	public static function getPropertyLoop(split:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool = true, ?allowMaps:Bool = false):Dynamic
	{
		var obj:Dynamic = getObjectDirectly(split[0], checkForTextsToo);
		final end:Int = (getProperty ? split.length - 1 : split.length);

		for (i in 1...end) {
			obj = getVarInArray(obj, split[i], allowMaps);
		}

		return obj;
	}

	public static function callMethodFromObject(classObj:Dynamic, funcStr:String, args:Array<Dynamic> = null):Dynamic
	{
		if (args == null) args = [];

		var split:Array<String> = funcStr.split('.');
		var funcToRun:Function = null;

		var obj:Dynamic = classObj;

		if (obj == null) {
			return null;
		}

		for (i in 0...split.length) {
			obj = getVarInArray(obj, split[i].trim());
		}

		funcToRun = cast obj;

		if (funcToRun != null) {
			return Reflect.callMethod(obj, funcToRun, args);
		}

		return null;
	}

	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true, ?allowMaps:Bool = false):Dynamic
	{
		switch (objectName)
		{
			case 'this' | 'instance' | 'game': return instance;
			default:
			{
				var obj:Dynamic = instance.getLuaObject(objectName, checkForTextsToo);
				if (obj == null) obj = getVarInArray(getTargetInstance(), convertVariableToNew(getTargetInstanceName(), objectName), allowMaps);

				return obj;
			}
		}
	}

	public static function convertObjectToNew(obj:String):String
	{
		switch (obj.trim())
		{
			case 'backend.ClientPrefs':
				return 'ClientPrefs';
			case 'backend.CoolUtil':
				return 'CoolUtil';
			case 'backend.Achievements':
				return 'Achievements';
			case 'backend.Conductor':
				return 'Conductor';
			case 'backend.CustomFadeTransition':
				return 'CustomFadeTransition';
			case 'backend.Difficulty':
				return 'CoolUtil';
			case 'backend.Discord':
				return 'Discord';
			case 'backend.Discord.DiscordClient':
				return 'Discord.DiscordClient';
			case 'backend.Highscore':
				return 'Highscore';
			case 'backend.Mods':
				return 'Paths';
			case 'backend.MusicBeatState':
				return 'MusicBeatState';
			case 'backend.MusicBeatSubState' | 'backend.MusicBeatSubstate' | 'MusicBeatSubstate':
				return 'MusicBeatSubState';
			case 'backend.NoteTypesConfig':
				return 'NoteTypesConfig';
			case 'backend.Paths':
				return 'Paths';
			case 'backend.Rating':
				return 'Rating';
			case 'backend.Section':
				return 'Section';
			case 'backend.Section.SwagSection':
				return 'Section.SwagSection';
			case 'backend.Song':
				return 'Song';
			case 'backend.Song.SwagSong':
				return 'Song.SwagSong';
			case 'backend.StageData':
				return 'StageData';
			case 'backend.WeekData':
				return 'WeekData';
			case 'cutscenes.CutsceneHandler':
				return 'CutsceneHandler';
			case 'cutscenes.DialogueBox':
				return 'DialogueBox';
			case 'cutscenes.DialogueBoxPsych':
				return 'DialogueBoxPsych';
			case 'cutscenes.DialogueCharacter':
				return 'DialogueCharacter';
			case 'cutscenes.FlxVideo':
				return 'FlxVideo';
			case 'objects.AchievementPopup':
				return 'AchievementPopup';
			case 'objects.Alphabet':
				return 'Alphabet';
			case 'objects.AttachedAchievement':
				return 'AttachedAchievement';
			case 'objects.AttachedSprite':
				return 'AttachedSprite';
			case 'objects.AttachedText':
				return 'AttachedText';
			case 'objects.BGSprite':
				return 'BGSprite';
			case 'objects.Character':
				return 'Character';
			case 'objects.CheckboxThingie':
				return 'CheckboxThingie';
			case 'objects.Bar' | 'objects.HealthBar' | 'HealthBar':
				return 'Bar';
			case 'objects.HealthIcon':
				return 'HealthIcon';
			case 'objects.MenuCharacter':
				return 'MenuCharacter';
			case 'objects.MenuItem':
				return 'MenuItem';
			case 'objects.Note':
				return 'Note';
			case 'objects.NoteSplash':
				return 'NoteSplash';
			case 'objects.Sprite':
				return 'Sprite';
			case 'objects.StrumNote':
				return 'StrumNote';
			case 'shaders.ColorSwap':
				return 'shaderslmfao.ColorSwap';
			case 'shaders.RGBPalette':
				return 'shaderslmfao.RGBPalette';
			case 'shaders.WiggleEffect':
				return 'shaderslmfao.WiggleEffect';
			case 'states.AchievementsMenuState':
				return 'AchievementsMenuState';
			case 'states.CreditsState' | 'states.CreditsMenuState' | 'CreditsState':
				return 'AchievementsMenuState';
			case 'states.FreeplayState' | 'states.FreeplayMenuState' | 'FreeplayState':
				return 'FreeplayMenuState';
			case 'states.LoadingState':
				return 'LoadingState';
			case 'states.MainMenuState':
				return 'MainMenuState';
			case 'states.ModsMenuState':
				return 'ModsMenuState';
			case 'states.OutdatedState':
				return 'OutdatedState';
			case 'states.PlayState':
				return 'PlayState';
			case 'states.StoryMenuState':
				return 'StoryMenuState';
			case 'states.TitleState':
				return 'TitleState';
			case 'states.stages.objects.BackgroundDancer':
				return 'BackgroundDancer';
			case 'states.stages.objects.BackgroundGirls':
				return 'BackgroundGirls';
			case 'states.stages.objects.BackgroundTank':
				return 'BackgroundTank';
			case 'states.stages.objects.DadBattleFog':
				return 'DadBattleFog';
			case 'states.stages.objects.MallCrowd':
				return 'MallCrowd';
			case 'states.stages.objects.PhillyGlowGradient':
				return 'PhillyGlowGradient';
			case 'states.stages.objects.PhillyGlowParticle':
				return 'PhillyGlowParticle';
			case 'states.stages.objects.PhillyTrain':
				return 'PhillyTrain';
			case 'substates.GameOverSubState' | 'substates.GameOverSubstate' | 'GameOverSubstate':
				return 'GameOverSubState';
			case 'substates.GameplayChangersSubstate' | 'substates.GameplayChangersSubState' | 'GameplayChangersSubstate':
				return 'GameplayChangersSubState';
			case 'substates.PauseSubState':
				return 'PauseSubState';
			case 'substates.Prompt':
				return 'Prompt';
			case 'substates.ResetScoreSubState':
				return 'ResetScoreSubState';
			default:
				return obj;
		}
	}

	public static function convertVariableToNew(obj:String, variable:String):String
	{
		switch (obj)
		{
			case 'ClientPrefs':
			{
				if (variable.startsWith('data.')) {
					variable = variable.substr(variable.indexOf('.') + 1);
				}

				switch (variable.trim())
				{
					case 'antialiasing':
						return 'globalAntialiasing';
					case 'showFPS':
						return 'fpsCounter';
					case 'showMEM' | 'showMemory':
						return 'memoryCounter';
					case 'shaders':
						return 'shadersEnabled';
					case 'saveSettings':
						return 'savePrefs';
					case 'flashing':
						return 'flashingLights';
				}
			}
			case 'PlayState.instance':
			{
				switch (variable.trim())
				{
					case 'moveCameraSection':
						return 'cameraMovementSection';
					case 'moveCamera':
						return 'cameraMovement';
					case 'ratingPercent':
						return 'songAccuracy';
				}
			}
		}

		return variable;
	}

	public static function getTextObject(name:String):FlxText
	{
		return instance.modchartTexts.exists(name) ? instance.modchartTexts.get(name) : Reflect.getProperty(PlayState.getTargetInstance(), PlayState.convertVariableToNew('PlayState.instance', name));
	}

	public static function isOfTypes(value:Any, types:Array<Dynamic>):Bool
	{
		for (type in types) {
			if (Std.isOfType(value, type)) return true;
		}

		return false;
	}

	public static inline function getTargetInstanceName():String
	{
		return instance.isDead ? 'GameOverSubState.instance' : 'PlayState.instance';
	}
	
	public static inline function getTargetInstance()
	{
		return instance.isDead ? GameOverSubState.instance : instance;
	}

	public static inline function getLowestCharacterGroup():FlxTypedSpriteGroup<Character>
	{
		var group:FlxTypedSpriteGroup<Character> = instance.gfGroup;
		var pos:Int = instance.members.indexOf(group);

		var newPos:Int = instance.members.indexOf(instance.boyfriendGroup);

		if (newPos < pos)
		{
			group = instance.boyfriendGroup;
			pos = newPos;
		}

		newPos = instance.members.indexOf(instance.dadGroup);

		if (newPos < pos)
		{
			group = instance.dadGroup;
			pos = newPos;
		}

		return group;
	}

	public static function addAnimByIndices(obj:String, name:String, prefix:String, indices:Any = null, framerate:Int = 24, loop:Bool = false):Bool
	{
		final  obj:Dynamic = getObjectDirectly(obj, false);

		if (obj != null && obj.animation != null)
		{
			if (indices == null) indices = [];

			if (Std.isOfType(indices, String)) {
				indices = FlxStringUtil.toIntArray(cast indices);
			}

			obj.animation.addByIndices(name, prefix, indices, '', framerate, loop);

			if (obj.animation.curAnim == null)
			{
				if (obj.playAnim != null) obj.playAnim(name, true);
				else obj.playAnim(name, true);
			}

			return true;
		}

		return false;
	}
	
	public static function loadSpriteFrames(spr:FlxSprite, image:String, spriteType:String):Void
	{
		switch (spriteType.toLowerCase().trim())
		{
			case 'packer' | 'packeratlas' | 'pac': spr.frames = Paths.getPackerAtlas(image);
			default: spr.frames = Paths.getSparrowAtlas(image);
		}
	}

	public static function resetTextTag(tag:String):Void
	{
		if (!instance.modchartTexts.exists(tag)) {
			return;
		}

		final target:FlxText = instance.modchartTexts.get(tag);
		target.kill();

		instance.remove(target, true);
		target.destroy();

		instance.modchartTexts.remove(tag);
	}

	public static function resetSpriteTag(tag:String):Void
	{
		if (!instance.modchartSprites.exists(tag)) {
			return;
		}

		final target:Sprite = instance.modchartSprites.get(tag);
		target.kill();

		instance.remove(target, true);
		target.destroy();

		instance.modchartSprites.remove(tag);
	}

	public static function tweenPrepare(tag:String, vars:String):Dynamic
	{
		cancelTween(tag);

		final variables:Array<String> = vars.split('.');
		return (variables.length > 1) ? getVarInArray(getPropertyLoop(variables), variables[variables.length - 1]) : getObjectDirectly(variables[0]);
	}

	public static function cancelTimer(tag:String):Void
	{
		if (instance.modchartTimers.exists(tag))
		{
			var theTimer:FlxTimer = instance.modchartTimers.get(tag);
			theTimer.cancel();
			theTimer.destroy();

			instance.modchartTimers.remove(tag);
		}
	}

	public static function cancelTween(tag:String):Void
	{
		if (instance.modchartTweens.exists(tag))
		{
			instance.modchartTweens.get(tag).cancel();
			instance.modchartTweens.get(tag).destroy();
			instance.modchartTweens.remove(tag);
		}
	}

	public static function getTweenTypeByString(?type:String = ''):FlxTweenType // buncho string stuffs
	{
		switch (type.toLowerCase().trim())
		{
			case 'backward': return FlxTweenType.BACKWARD;
			case 'looping' | 'loop': return FlxTweenType.LOOPING;
			case 'persist': return FlxTweenType.PERSIST;
			case 'pingpong': return FlxTweenType.PINGPONG;
		}

		return FlxTweenType.ONESHOT;
	}

	public static function getTweenEaseByString(?ease:String = ''):EaseFunction
	{
		switch (ease.toLowerCase().trim())
		{
			case 'backin': return FlxEase.backIn;
			case 'backinout': return FlxEase.backInOut;
			case 'backout': return FlxEase.backOut;
			case 'bouncein': return FlxEase.bounceIn;
			case 'bounceinout': return FlxEase.bounceInOut;
			case 'bounceout': return FlxEase.bounceOut;
			case 'circin': return FlxEase.circIn;
			case 'circinout': return FlxEase.circInOut;
			case 'circout': return FlxEase.circOut;
			case 'cubein': return FlxEase.cubeIn;
			case 'cubeinout': return FlxEase.cubeInOut;
			case 'cubeout': return FlxEase.cubeOut;
			case 'elasticin': return FlxEase.elasticIn;
			case 'elasticinout': return FlxEase.elasticInOut;
			case 'elasticout': return FlxEase.elasticOut;
			case 'expoin': return FlxEase.expoIn;
			case 'expoinout': return FlxEase.expoInOut;
			case 'expoout': return FlxEase.expoOut;
			case 'quadin': return FlxEase.quadIn;
			case 'quadinout': return FlxEase.quadInOut;
			case 'quadout': return FlxEase.quadOut;
			case 'quartin': return FlxEase.quartIn;
			case 'quartinout': return FlxEase.quartInOut;
			case 'quartout': return FlxEase.quartOut;
			case 'quintin': return FlxEase.quintIn;
			case 'quintinout': return FlxEase.quintInOut;
			case 'quintout': return FlxEase.quintOut;
			case 'sinein': return FlxEase.sineIn;
			case 'sineinout': return FlxEase.sineInOut;
			case 'sineout': return FlxEase.sineOut;
			case 'smoothstepin': return FlxEase.smoothStepIn;
			case 'smoothstepinout': return FlxEase.smoothStepInOut;
			case 'smoothstepout': return FlxEase.smoothStepInOut;
			case 'smootherstepin': return FlxEase.smootherStepIn;
			case 'smootherstepinout': return FlxEase.smootherStepInOut;
			case 'smootherstepout': return FlxEase.smootherStepOut;
		}

		return FlxEase.linear;
	}

	public static function blendModeFromString(blend:String):BlendMode
	{
		switch (blend.toLowerCase().trim())
		{
			case 'add': return ADD;
			case 'alpha': return ALPHA;
			case 'darken': return DARKEN;
			case 'difference': return DIFFERENCE;
			case 'erase': return ERASE;
			case 'hardlight': return HARDLIGHT;
			case 'invert': return INVERT;
			case 'layer': return LAYER;
			case 'lighten': return LIGHTEN;
			case 'multiply': return MULTIPLY;
			case 'overlay': return OVERLAY;
			case 'screen': return SCREEN;
			case 'shader': return SHADER;
			case 'subtract': return SUBTRACT;
		}

		return NORMAL;
	}

	public static function cameraFromString(cam:String):FlxCamera
	{
		switch (cam.toLowerCase())
		{
			case 'camhud' | 'hud': return instance.camHUD;
			case 'camother' | 'other': return instance.camOther;
			case 'camcustom' | 'custom': return instance.camCustom;
			case 'camnotecombo' | 'notecombo' | 'camcombo' | 'combo': return instance.camNoteCombo;
		}

		if (instance.isDead) {
			return GameOverSubState.instance.camDeath;
		}

		return instance.camGame;
	}

	public static function noteTweenFunction(tag:String, note:Int, tweenValue:Any, duration:Float, ease:String):Void
	{
		cancelTween(tag);

		if (note < 0) note = 0;

		final testicle:StrumNote = instance.strumLineNotes.members[note % instance.strumLineNotes.length];

		if (testicle != null)
		{
			instance.modchartTweens.set(tag, FlxTween.tween(testicle, tweenValue, duration,
			{
				ease: getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween):Void
				{
					instance.callOnLuas('onTweenCompleted', [tag]);
					instance.modchartTweens.remove(tag);
				}
			}));
		}
	}

	static final _lePoint:FlxPoint = FlxPoint.get();

	public static function getMousePoint(camera:String, axis:String):Float
	{
		FlxG.mouse.getScreenPosition(cameraFromString(camera), _lePoint);
		return (axis == 'y' ? _lePoint.y : _lePoint.x);
	}

	public static function getPoint(leVar:String, type:String, axis:String, ?camera:String):Float
	{
		final split:Array<String> = leVar.split('.');

		var obj:FlxSprite = (split.length > 1) ? getVarInArray(getPropertyLoop(split), split[split.length - 1]) : getObjectDirectly(split[0]);

		if (obj != null)
		{
			switch (type)
			{
				case 'graphic': obj.getGraphicMidpoint(_lePoint);
				case 'screen': obj.getScreenPosition(_lePoint, cameraFromString(camera));
				default: obj.getMidpoint(_lePoint);
			}
	
			return (axis == 'y' ? _lePoint.y : _lePoint.x);
		}

		return 0;
	}

	public static function setBarColors(bar:Bar, color1:String, color2:String):Void
	{
		final left_color:Null<FlxColor> = (color1 != null && color1 != '' ? CoolUtil.colorFromString(color1) : null);
		final right_color:Null<FlxColor> = (color2 != null && color2 != '' ? CoolUtil.colorFromString(color2) : null);

		bar.setColors(left_color, right_color);
	}

	public static function getVar(name:String):Dynamic
	{
		var result:Dynamic = null;
		if (instance != null && instance.variables.exists(name)) result = instance.variables.get(name);

		return result;
	}

	public static function setVar(name:String, value:Dynamic):Void
	{
		if (instance != null) instance.variables.set(name, value);
	}

	public static function removeVar(name:String):Void
	{
		if (instance != null) instance.variables.remove(name);
	}
}