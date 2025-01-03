package;

import haxe.Http;
import haxe.Json;

import shaders.ColorSwap;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.graphics.frames.FlxFrame;

using StringTools;

typedef TitleData =
{
	titlex:Float,
	titley:Float,

	startx:Float,
	starty:Float,

	gfx:Float,
	gfy:Float,
	gfscalex:Null<Float>,
	gfscaley:Null<Float>,
	gfantialiasing:Null<Bool>,

	backgroundSprite:String,

	bpm:Float
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;
	public static var closedState:Bool = false;

	var titleJSON:TitleData;

	var blackScreen:Sprite;
	var textGroup:FlxGroup;
	var ngSpr:Sprite;

	var mustUpdate:Bool = false;
	var curWacky:Array<String> = [];

	override public function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end

		Paths.loadTopMod();

		#if (desktop || web)
		FlxG.mouse.useSystemCursor = true;
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];

		var introTextShit:Array<Array<String>> = getIntroTextShit();
		curWacky = FlxG.random.getObject(introTextShit);

		super.create();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());

		Debug.onGameStart();

		ClientPrefs.loadPrefs();
		ClientPrefs.loadBinds();
		ClientPrefs.loadNoteColors();
		ClientPrefs.loadGameplaySettings();

		Highscore.load();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.load();
		#end

		#if CHECK_FOR_UPDATES
		if (ClientPrefs.checkForUpdates && !OutdatedState.leftState && !closedState)
		{
			Debug.logInfo('checking for update');

			var http:Http = new Http('https://raw.githubusercontent.com/nul4h9/FNF-AlsuhEngine/main/version.downloadMe');
			http.onData = function(data:String):Void
			{
				OutdatedState.updateVersion = data.substring(0, data.indexOf(';')).trim();
				OutdatedState.updateChanges = data.substring(data.indexOf('-'), data.length).trim();

				var curVersion:String = MainMenuState.alsuhEngineVersion.trim();
				Debug.logInfo('version online: ' + OutdatedState.updateVersion + ', your version: ' + curVersion);

				if (OutdatedState.updateVersion != curVersion)
				{
					Debug.logInfo('versions arent matching!');
					mustUpdate = true;
				}
			}
			http.onError = function(error:Dynamic):Void {
				Debug.logInfo('error: $error');
			}
			http.request();
		}
		#end

		var path:String = 'title/gfDanceTitle.json';

		if (Paths.fileExists('images/title/gfDanceTitle.json', TEXT)) {
			path = 'images/title/gfDanceTitle.json';
		}
		else if (Paths.fileExists('images/gfDanceTitle.json', TEXT)) {
			path = 'images/gfDanceTitle.json';
		}
		else if (Paths.fileExists('data/gfDanceTitle.json', TEXT)) {
			path = 'data/gfDanceTitle.json';
		}

		titleJSON = Json.parse(Paths.getTextFromFile(path));

		if (!initialized)
		{
			persistentUpdate = true;
			persistentDraw = true;
		}

		startIntro();
	}

	var logoBl:Sprite;
	var gfDance:Sprite;
	var swagShader:ColorSwap = null;
	var danceLeft:Bool = false;
	var titleText:Sprite;
	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];
	var newTitle:Bool = false;

	function startIntro():Void
	{
		if (!initialized)
		{
			if (FlxG.sound.music == null || !FlxG.sound.music.playing) {
				FlxG.sound.playMusic(Paths.getMusic('freakyMenu'), 0);
			}
		}

		if (titleJSON.gfantialiasing == null) titleJSON.gfantialiasing = true;
		if (titleJSON.gfscalex == null) titleJSON.gfscalex = 1;
		if (titleJSON.gfscaley == null) titleJSON.gfscaley = 1;

		Conductor.bpm = titleJSON.bpm;
		persistentUpdate = true;

		var bg:Sprite = new Sprite();

		if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != 'none')
		{
			if (Paths.fileExists('images/' + titleJSON.backgroundSprite + '.png', IMAGE)) {
				bg.loadGraphic(Paths.getImage(titleJSON.backgroundSprite));
			}
			else {
				bg.loadGraphic(Paths.getImage('title/' + titleJSON.backgroundSprite));
			}
		}
		else {
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		}

		add(bg);

		if (ClientPrefs.shadersEnabled) swagShader = new ColorSwap();

		gfDance = new Sprite(titleJSON.gfx, titleJSON.gfy);

		if (Paths.fileExists('images/gfDanceTitle.png', IMAGE)) {
			gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
		}
		else {
			gfDance.frames = Paths.getSparrowAtlas('title/gfDanceTitle');
		}

		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30].concat(CoolUtil.numberArray(15, 0)), '', 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', CoolUtil.numberArray(30, 15), '', 24, false);
		gfDance.scale.set(titleJSON.gfscalex, titleJSON.gfscaley);
		gfDance.antialiasing = ClientPrefs.globalAntialiasing && titleJSON.gfantialiasing;
		add(gfDance);

		logoBl = new Sprite(titleJSON.titlex, titleJSON.titley);

		if (Paths.fileExists('images/logoBumpin.png', IMAGE)) {
			logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		}
		else {
			logoBl.frames = Paths.getSparrowAtlas('title/logoBumpin');
		}

		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		logoBl.updateHitbox();
		add(logoBl);

		if (swagShader != null)
		{
			gfDance.shader = swagShader.shader;
			logoBl.shader = swagShader.shader;
		}

		titleText = new Sprite(titleJSON.startx, titleJSON.starty);

		if (Paths.fileExists('images/titleEnter.png', IMAGE)) {
			titleText.frames = Paths.getSparrowAtlas('titleEnter');
		}
		else {
			titleText.frames = Paths.getSparrowAtlas('title/titleEnter');
		}

		var animFrames:Array<FlxFrame> = [];

		@:privateAccess {
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		
		if (animFrames.length > 0)
		{
			newTitle = true;

			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.flashingLights ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else
		{
			newTitle = false;

			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}

		titleText.playAnim('idle');
		titleText.updateHitbox();
		add(titleText);

		blackScreen = new Sprite();
		blackScreen.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(blackScreen);

		textGroup = new FlxGroup();
		add(textGroup);

		ngSpr = new Sprite(0, FlxG.height * 0.52);

		if (Paths.fileExists('images/newgrounds_logo.png', IMAGE)) {
			ngSpr.loadGraphic(Paths.getImage('newgrounds_logo'));
		}
		else {
			ngSpr.loadGraphic(Paths.getImage('title/newgrounds_logo'));
		}

		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.visible = false;
		add(ngSpr);

		if (initialized) {
			skipIntro();
		}
		else {
			initialized = true;
		}
	}

	function getIntroTextShit():Array<Array<String>>
	{
		return [for (i in Paths.getTextFromFile('data/introText.txt').split('\n')) i.split('--')];
	}

	private static var playJingle:Bool = false;

	var transitioning:Bool = false;
	var titleTimer:Float = 0;

	override function update(elapsed:Float):Void
	{
		if (FlxG.sound.music != null) {
			Conductor.songPosition = FlxG.sound.music.time;
		}

		var mouseShit:Bool = FlxG.mouse.justPressed && FlxG.mouse.overlaps(titleText) && skippedIntro;
		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT_P || mouseShit;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed) {
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START) {
				pressedEnter = true;
			}

			#if switch
			if (gamepad.justPressed.B) {
				pressedEnter = true;
			}
			#end
		}

		if (newTitle)
		{
			titleTimer += CoolUtil.boundTo(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		if (initialized)
		{
			if (!transitioning && skippedIntro)
			{
				if (newTitle && !pressedEnter)
				{
					var timer:Float = titleTimer;

					if (timer >= 1) {
						timer = (-timer) + 2;
					}

					timer = FlxEase.quadInOut(timer);

					titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
					titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
				}

				if (pressedEnter)
				{
					if (titleText != null)
					{
						titleText.playAnim('press');
						titleText.color = FlxColor.WHITE;
						titleText.alpha = 1;
					}

					FlxG.camera.flash(ClientPrefs.flashingLights ? FlxColor.WHITE : 0x4CFFFFFF, 1);
					FlxG.sound.play(Paths.getSound('confirmMenu'), 0.7);

					transitioning = true;

					new FlxTimer().start(1, function(tmr:FlxTimer):Void
					{
						#if CHECK_FOR_UPDATES
						if (mustUpdate) FlxG.switchState(new OutdatedState());
						else #end FlxG.switchState(new MainMenuState());

						closedState = true;
					});
				}
			}

			if (pressedEnter && !skippedIntro) {
				skipIntro();
			}
		}

		if (swagShader != null)
		{
			if (controls.RESET_P) swagShader.hue = 0;

			if (controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
			if (controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0):Void
	{
		if (textGroup != null)
		{
			for (i in 0...textArray.length)
			{
				var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
				money.screenCenter(X);
				money.y += (i * 60) + 200 + offset;
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0):Void
	{
		if (textGroup != null)
		{
			var coolText:Alphabet = new Alphabet(0, 0, text, true);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			textGroup.add(coolText);
		}
	}

	function deleteCoolText():Void
	{
		if (textGroup != null)
		{
			while (textGroup.members.length > 0) {
				textGroup.remove(textGroup.members[0], true);
			}
		}
	}

	private var sickBeats:Int = 0; // Basically curBeat but won't be skipped if you hold the tab or resize the screen

	override function beatHit():Void
	{
		super.beatHit();

		if (logoBl != null) {
			logoBl.playAnim('bump');
		}

		if (gfDance != null)
		{
			danceLeft = !danceLeft;

			if (danceLeft) {
				gfDance.playAnim('danceRight');
			}
			else {
				gfDance.playAnim('danceLeft');
			}
		}

		if (!closedState)
		{
			sickBeats++;

			switch (sickBeats)
			{
				case 1: FlxG.sound.playMusic(Paths.getMusic('freakyMenu'));
				case 2:
				{
					#if ALSUH_WATERMARKS if (ClientPrefs.watermarks) createCoolText(['Alsuh Engine by']); else #end {
						createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er']);
					}
				}
				case 4:
				{
					#if ALSUH_WATERMARKS if (ClientPrefs.watermarks) addMoreText('null the great'); else #end {
						addMoreText('present');
					}
				}
				case 5: deleteCoolText();
				case 6:
				{
					#if ALSUH_WATERMARKS if (ClientPrefs.watermarks) createCoolText(['Not associated', 'with'], -40); else #end {
						createCoolText(['In association', 'with'], -40);
					}
				}
				case 8:
				{
					addMoreText('newgrounds', -40);
					ngSpr.visible = true;
				}
				case 9:
				{
					deleteCoolText();
					ngSpr.visible = false;
				}
				case 10: createCoolText([curWacky[0]]);
				case 12: addMoreText(curWacky[1]);
				case 13: deleteCoolText();
				case 14: addMoreText('Friday');
				case 15: addMoreText('Night');
				case 16: addMoreText('Funkin');
				case 17: skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			Debug.logInfo("Skipping intro...");

			if (ngSpr != null) {
				remove(ngSpr);
			}

			if (blackScreen != null)
			{
				blackScreen.visible = false;
				blackScreen.alpha = 0;
				remove(blackScreen);
			}

			if (textGroup != null) {
				remove(textGroup);
			}

			FlxG.camera.flash(FlxColor.WHITE, (initialized ? 1 : 4));

			skippedIntro = true;
		}
	}
}