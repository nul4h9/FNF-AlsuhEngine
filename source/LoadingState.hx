package;

import haxe.io.Path;

import Character.CharacterFile;

import flixel.FlxG;
import flixel.FlxState;
import lime.app.Future;
import lime.app.Promise;
import openfl.media.Sound;
import flixel.math.FlxMath;
import openfl.utils.Assets;
import openfl.errors.Error;
import flixel.util.FlxTimer;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.Assets as LimeAssets;

using StringTools;

class LoadingState extends MusicBeatState
{
	inline static var MIN_TIME = 1.0;

	var target:FlxState;
	var stopMusic:Bool = false;
	var directory:String;
	var callbacks:MultiCallback;

	var loadBar:Sprite;

	function new(target:FlxState, stopMusic:Bool, directory:String):Void
	{
		super();

		this.target = target;
		this.stopMusic = stopMusic;
		this.directory = directory;
	}

	override function create():Void
	{
		var bg:Sprite = new Sprite();
		bg.makeGraphic(FlxG.width, FlxG.height, 0xFFcaff4d);
		add(bg);

		var funkay:Sprite = new Sprite();
		funkay.loadGraphic(Paths.getImage('bg/funkay'));
		funkay.setGraphicSize(0, FlxG.height);
		funkay.updateHitbox();
		funkay.scrollFactor.set();
		funkay.screenCenter();
		add(funkay);

		loadBar = new Sprite(0, FlxG.height - 20);
		loadBar.makeGraphic(FlxG.width, 10, 0xFFff16d2);
		loadBar.screenCenter(X);
		loadBar.scale.x = FlxMath.EPSILON;
		add(loadBar);

		var fadeTime:Float = 0.5;

		FlxG.camera.fade(FlxG.camera.bgColor, fadeTime, true, function():Void
		{
			loadEmptyLibrary('songs').onComplete(function(lib:AssetLibrary):Void
			{
				callbacks = new MultiCallback(onLoad);

				var introComplete:Void->Void = callbacks.add('introComplete');

				if (PlayState.SONG != null)
				{
					checkLoadSong(getSongPath());

					if (PlayState.SONG.needsVoices)
					{
						checkLoadSong(getVocalsPath());

						var opponentVocalsPath:String = getOpponentVocalsPath();

						if (Paths.fileExists(opponentVocalsPath, SOUND)) {
							checkLoadSong(opponentVocalsPath);
						}
					}
				}

				checkLibrary('shared');

				if (directory != null && directory.length > 0 && directory != 'shared') {
					checkLibrary(directory);
				}

				new FlxTimer().start(MIN_TIME, function(_:FlxTimer):Void introComplete());
			});
		});
	}

	function checkLoadSong(path:String):Void
	{
		if (!isSoundLoaded(path))
		{
			var callback:Void->Void = callbacks.add("song:" + path);

			Paths.loadSound(path).onComplete(function(_:Sound):Void
			{
				var cutPath:String = path.substr(path.indexOf(':') + 1);
				Debug.logInfo('loaded path: ' + cutPath);
				callback();
			})
			.onError(function(error:Error):Void
			{
				Debug.logError('error: ' + error.toString());
				callback();
			});
		}
	}

	function checkLibrary(library:String):Void
	{
		if (!isLibraryLoaded(library))
		{
			@:privateAccess
			if (LimeAssets.libraryPaths.exists(library))
			{
				var callback:Void->Void = callbacks.add("library:" + library);

				Assets.loadLibrary(library).onComplete(function(_:AssetLibrary):Void
				{
					Debug.logInfo('loaded library: ' + library);
					callback();
				})
				.onError(function(error:Error):Void
				{
					Debug.logError('error: ' + error);
					callback();
				});
			}
			else {
				Debug.logError("Missing library: " + library);
			}
		}
	}

	var targetShit:Float = 0;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (callbacks != null)
		{
			targetShit = FlxMath.remapToRange(callbacks.numRemaining / callbacks.length, 1, 0, 0, 1);
			loadBar.scale.x = FlxMath.lerp(targetShit, loadBar.scale.x, Math.exp(-elapsed * 30));
		}
	}

	function onLoad():Void
	{
		if (stopMusic)
		{
			if (FlxG.sound.music != null) {
				FlxG.sound.music.stop();
			}

			FreeplayMenuState.destroyFreeplayVocals();
		}

		FlxG.switchState(target);
	}

	static function getSongPath():String
	{
		var diff:String = CoolUtil.difficultyStuff[PlayState.lastDifficulty] != null && CoolUtil.difficultyStuff[PlayState.lastDifficulty].length == 2 ? CoolUtil.difficultyStuff[PlayState.lastDifficulty][2] : null;
		return Paths.getInst(PlayState.SONG.songID, diff, true);
	}

	static function getVocalsPath():String
	{
		var diff:String = CoolUtil.difficultyStuff[PlayState.lastDifficulty] != null && CoolUtil.difficultyStuff[PlayState.lastDifficulty].length == 2 ? CoolUtil.difficultyStuff[PlayState.lastDifficulty][2] : null;

		var characterFile:CharacterFile = Character.getCharacterFile(PlayState.SONG.player1);
		var postfix:String = ((characterFile != null && characterFile.vocals_file != null && characterFile.vocals_file.length > 0) ? characterFile.vocals_file : 'Player');
		var playerVocalPath:String = Paths.getVoices(PlayState.SONG.songID, diff, postfix, true);

		if (Paths.fileExists(playerVocalPath, SOUND)) {
			return playerVocalPath;
		}

		return Paths.getVoices(PlayState.SONG.songID, diff, null, true);
	}

	static function getOpponentVocalsPath():String
	{
		var diff:String = CoolUtil.difficultyStuff[PlayState.lastDifficulty] != null && CoolUtil.difficultyStuff[PlayState.lastDifficulty].length == 2 ? CoolUtil.difficultyStuff[PlayState.lastDifficulty][2] : null;
		var characterFile:CharacterFile = Character.getCharacterFile(PlayState.SONG.player2);
		var postfix:String = ((characterFile != null && characterFile.vocals_file != null && characterFile.vocals_file.length > 0) ? characterFile.vocals_file : 'Opponent');

		return Paths.getVoices(PlayState.SONG.songID, diff, postfix, true);
	}

	public static function loadAndSwitchState(target:FlxState, stopMusic:Bool = false):Void
	{
		FlxG.switchState(getNextState(target, stopMusic));
	}

	static function getNextState(target:FlxState, stopMusic:Bool = false):FlxState
	{
		var directory:String = 'shared';

		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if (weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;
		Paths.currentLevel = directory;

		Debug.logInfo('Setting asset folder to ' + directory);

		var loaded:Bool = isLibraryLoaded('shared');

		if (PlayState.SONG != null)
		{
			loaded = isSoundLoaded(getSongPath())
				&& (!PlayState.SONG.needsVoices
				|| (isSoundLoaded(getVocalsPath())
				&& (!Paths.fileExists(getOpponentVocalsPath(), SOUND)
				|| isSoundLoaded(getOpponentVocalsPath()))))
				&& isLibraryLoaded('shared')
				&& isLibraryLoaded(directory);
		}

		if (!loaded) return new LoadingState(target, stopMusic, directory);

		if (stopMusic)
		{
			if (FlxG.sound.music != null) {
				FlxG.sound.music.stop();
			}

			FreeplayMenuState.destroyFreeplayVocals();
		}

		return target;
	}

	static function isSoundLoaded(path:String):Bool
	{
		return #if html5 Assets.cache.hasSound(path) && #end Paths.currentTrackedSounds.exists(path.substr(path.indexOf(':') + 1));
	}

	static function isLibraryLoaded(library:String):Bool
	{
		return Assets.getLibrary(library) != null;
	}

	public static function loadEmptyLibrary(id:String):Future<AssetLibrary>
	{
		var promise:Promise<AssetLibrary> = new Promise<AssetLibrary>();
		var library:AssetLibrary = LimeAssets.getLibrary(id);

		if (library != null) {
			return Future.withValue(library);
		}

		var path:String = id;
		var rootPath:String = null;

		@:privateAccess
		var libraryPaths:Map<String, String> = LimeAssets.libraryPaths;

		if (libraryPaths.exists(id))
		{
			path = libraryPaths[id];
			rootPath = Path.directory(path);
		}
		else
		{
			if (StringTools.endsWith(path, ".bundle"))
			{
				rootPath = path;
				path += "/library.json";
			}
			else {
				rootPath = Path.directory(path);
			}
			@:privateAccess
			path = LimeAssets.__cacheBreak(path);
		}

		AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest:AssetManifest):Void
		{
			if (manifest == null)
			{
				promise.error("Cannot parse asset manifest for library \"" + id + "\"");
				return;
			}

			var library:AssetLibrary = AssetLibrary.fromManifest(manifest);

			if (library == null) {
				promise.error("Cannot open library \"" + id + "\"");
			}
			else
			{
				@:privateAccess
				LimeAssets.libraries.set(id, library);
				library.onChange.add(LimeAssets.onChange.dispatch);
				promise.completeWith(Future.withValue(library));
			}
		})
		.onError(function(_:Dynamic):Void {
			promise.error("There is no asset library with an ID of \"" + id + "\"");
		});

		return promise.future;
	}
}

class MultiCallback
{
	public var callback:Void->Void;
	public var logId:String = null;
	public var length(default, null) = 0;
	public var numRemaining(default, null) = 0;

	var unfired:Map<String, Void->Void> = [];
	var fired:Array<String> = [];

	public function new(callback:Void->Void, logId:String = null):Void
	{
		this.callback = callback;
		this.logId = logId;
	}

	public function add(id:String = 'untitled'):Void->Void
	{
		id = '$length:$id';

		length++;
		numRemaining++;

		var func:Void->Void = function():Void
		{
			if (unfired.exists(id))
			{
				unfired.remove(id);
				fired.push(id);

				numRemaining--;

				if (logId != null) {
					log('fired $id, $numRemaining remaining');
				}

				if (numRemaining == 0)
				{
					if (logId != null) {
						log('all callbacks fired');
					}
	
					callback();
				}
			}
			else {
				log('already fired $id');
			}
		}

		unfired.set(id, func);
		return func;
	}

	inline function log(msg):Void
	{
		if (logId != null) {
			Debug.logInfo('$logId: $msg');
		}
	}

	public function getFired():Array<String>
	{
		return fired.copy();
	}

	public function getUnfired():Array<String>
	{
		return [for (id in unfired.keys()) id];
	}
}