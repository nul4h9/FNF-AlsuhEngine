package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

using StringTools;

class ClientPrefs
{
	public static var defaultData(default, null):Dynamic = {};
	public static var prefBlackList(default, never):Array<String> = [
		'defaultData',
		'prefBlackList',
		'keyBinds',
		'gamepadBinds',
		'defaultKeys',
		'defaultButtons',
		'arrowRGB',
		'arrowRGBPixel',
		'gameplaySettings',
	];

	public static var fullScreen:Bool = false;
	public static var lowQuality:Bool = false;
	public static var globalAntialiasing:Bool = true;
	public static var shadersEnabled:Bool = true;
	public static var cacheOnGPU:Bool = #if !switch false #else true #end; // From Stilic
	public static var framerate:Int = 140;

	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var opponentStrums:Bool = true;
	public static var ghostTapping:Bool = true;
	public static var autoPause:Bool = false;
	public static var noReset:Bool = false;
	public static var hitsoundVolume:Float = 0;
	public static var sickWindow:Int = 45;
	public static var goodWindow:Int = 90;
	public static var badWindow:Int = 135;
	public static var safeFrames:Float = 10;

	public static var noteSkin:String = 'Default';
	public static var splashSkin:String = 'Default';
	public static var splashAlpha:Float = 0.6;
	public static var timeBarType:String = 'Time Elapsed/Left';
	public static var scoreText:Bool = true;
	public static var flashingLights:Bool = true;
	public static var camZooms:Bool = true;
	public static var healthBarAlpha:Float = 1;
	public static var fpsCounter:Bool = true;
	public static var memoryCounter:Bool = true;
	#if ALSUH_WATERMARKS
	public static var watermarks:Bool = true;
	#end
	#if CHECK_FOR_UPDATES
	public static var checkForUpdates:Bool = true;
	#end
	public static var cutscenesOnMode:String = 'Story';
	public static var pauseMusic:String = 'Tea Time';
	public static var discordRPC:Bool = true;
	public static var showCombo:Bool = true;
	public static var comboStacking:Bool = true;

	public static var noteOffset:Int = 0;
	public static var comboOffset:Array<Int> = [0, 0, 0, 0];
	public static var ratingOffset:Int = 0;
	public static var danceOffset:Int = 2;

	public static function savePrefs():Void
	{
		for (field in Type.getClassFields(ClientPrefs))
		{
			var value:Dynamic = Reflect.getProperty(ClientPrefs, field);

			if (Type.typeof(value) != TFunction && !prefBlackList.contains(field)) {
				Reflect.setProperty(FlxG.save.data, field, value);
			}
		}

		FlxG.save.flush();

		Debug.logInfo("Settings saved!");
	}

	public static function loadPrefs():Void
	{
		for (field in Type.getClassFields(ClientPrefs))
		{
			if (Type.typeof(Reflect.getProperty(ClientPrefs, field)) != TFunction && !prefBlackList.contains(field))
			{
				if (Reflect.hasField(FlxG.save.data, field)) {
					Reflect.setProperty(ClientPrefs, field, Reflect.getProperty(FlxG.save.data, field));
				}

				switch (field)
				{
					case 'fullScreen': FlxG.fullscreen = fullScreen;
					case 'framerate':
					{
						#if (!html5 && !switch)
						if (FlxG.save.data.framerate == null)
						{
							final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
							framerate = Std.int(CoolUtil.boundTo(refreshRate, 60, 240));
						}
						#end

						if (framerate > FlxG.drawFramerate)
						{
							FlxG.updateFramerate = framerate;
							FlxG.drawFramerate = framerate;
						}
						else
						{
							FlxG.drawFramerate = framerate;
							FlxG.updateFramerate = framerate;
						}
					}
					case 'autoPause': FlxG.autoPause = autoPause;
					case 'safeFrames': Conductor.safeZoneOffset = (safeFrames / 60) * 1000;
					case 'discordRPC':
					{
						#if DISCORD_ALLOWED
						DiscordClient.check();
						#end
					}
				}
			}
		}

		if (FlxG.save.data.volume != null) {
			FlxG.sound.volume = FlxG.save.data.volume;
		}

		if (FlxG.save.data.mute != null) {
			FlxG.sound.muted = FlxG.save.data.mute;
		}
	}

	#if LUA_ALLOWED
	public static function implementForLua(lua:FunkinLua):Void // Some settings for lua, no jokes
	{
		lua.set('downscroll', downScroll);
		lua.set('middlescroll', middleScroll);
		lua.set('framerate', framerate);
		lua.set('ghostTapping', ghostTapping);
		lua.set('timeBarType', timeBarType);
		lua.set('cameraZoomOnBeat', camZooms);
		lua.set('flashingLights', flashingLights);
		lua.set('noteOffset', noteOffset);
		lua.set('healthBarAlpha', healthBarAlpha);
		lua.set('noResetButton', noReset);
		lua.set('lowQuality', lowQuality);
		lua.set('shadersEnabled', shadersEnabled);
		#if ALSUH_WATERMARKS
		lua.set('watermarks', watermarks);
		#end

		lua.set('noteSkin', noteSkin);
		lua.set('splashSkin', splashSkin);
		lua.set('splashAlpha', splashAlpha);
	}
	#end

	public static var keyBinds:Map<String, Array<FlxKey>> = // Key Bind, Name for ControlsSubState
	[
		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_up'		=> [W, UP],
		'note_right'	=> [D, RIGHT],

		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_up'			=> [W, UP],
		'ui_right'		=> [D, RIGHT],

		'reset'			=> [R],
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],

		'volume_mute'	=> [ZERO],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		'volume_up'		=> [NUMPADPLUS, PLUS],

		'debug_1'		=> [SEVEN],
		'debug_2'		=> [EIGHT]
	];

	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> =
	[
		'note_up'		=> [DPAD_UP, Y],
		'note_left'		=> [DPAD_LEFT, X],
		'note_down'		=> [DPAD_DOWN, A],
		'note_right'	=> [DPAD_RIGHT, B],

		'ui_left'		=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down'		=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_up'			=> [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_right'		=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],

		'reset'			=> [BACK],
		'accept'		=> [A, START],
		'back'			=> [B],
		'pause'			=> [START]
	];

	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;

	public static function resetKeys(?controller:String = null):Void //Null = all, Key = Keyboard, Gamepad = Controller
	{
		if (controller == null || controller.toLowerCase().trim() == 'key')
		{
			for (key in keyBinds.keys()) {
				if (defaultKeys.exists(key)) keyBinds.set(key, defaultKeys.get(key).copy());
			}
		}

		if (controller == null || controller.toLowerCase().trim() == 'gamepad')
		{
			for (button in gamepadBinds.keys()) {
				if (defaultButtons.exists(button)) gamepadBinds.set(button, defaultButtons.get(button).copy());
			}
		}
	}

	public static function clearInvalidKeys(key:String):Void
	{
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		var gamepadBind:Array<FlxGamepadInputID> = gamepadBinds.get(key);

		while (keyBind != null && keyBind.contains(NONE)) keyBind.remove(NONE);
		while (gamepadBind != null && gamepadBind.contains(NONE)) gamepadBind.remove(NONE);
	}

	public static function saveBinds():Void
	{
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', CoolUtil.getSavePath());
		save.data.keyboard = keyBinds;
		save.data.gamepad = gamepadBinds;
		save.flush();
	}

	public static function loadBinds():Void
	{
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', CoolUtil.getSavePath());

		if (save != null)
		{
			if (save.data.keyboard != null)
			{
				var loadedControls:Map<String, Array<FlxKey>> = save.data.keyboard;

				for (control => keys in loadedControls) {
					if (keyBinds.exists(control)) keyBinds.set(control, keys);
				}
			}

			if (save.data.gamepad != null)
			{
				var loadedControls:Map<String, Array<FlxGamepadInputID>> = save.data.gamepad;

				for (control => keys in loadedControls) {
					if (gamepadBinds.exists(control)) gamepadBinds.set(control, keys);
				}
			}

			reloadVolumeKeys();
		}
	}

	public static function reloadVolumeKeys():Void
	{
		TitleState.muteKeys = keyBinds.get('volume_mute').copy();
		TitleState.volumeDownKeys = keyBinds.get('volume_down').copy();
		TitleState.volumeUpKeys = keyBinds.get('volume_up').copy();

		toggleVolumeKeys(true);
	}

	public static function toggleVolumeKeys(turnOn:Bool):Void
	{
		if (turnOn)
		{
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
		}
		else
		{
			FlxG.sound.muteKeys = [];
			FlxG.sound.volumeDownKeys = [];
			FlxG.sound.volumeUpKeys = [];
		}
	}

	public static var arrowRGB:Array<Array<FlxColor>> =
	[
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
	];

	public static var arrowRGBPixel:Array<Array<FlxColor>> =
	[
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]
	];

	public static function saveNoteColors():Void
	{
		var save:FlxSave = new FlxSave();
		save.bind('note_colors', CoolUtil.getSavePath());
		save.data.arrowRGB = arrowRGB;
		save.data.arrowRGBPixel = arrowRGBPixel;
		save.flush();
	}

	public static function loadNoteColors():Void
	{
		var save:FlxSave = new FlxSave();
		save.bind('note_colors', CoolUtil.getSavePath());

		if (save != null)
		{
			if (save.data.arrowRGB != null) {
				arrowRGB = save.data.arrowRGB;
			}

			if (save.data.arrowRGBPixel != null) {
				arrowRGBPixel = save.data.arrowRGBPixel;
			}
		}
	}

	public static var gameplaySettings:Map<String, Dynamic> =
	[
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];

	public static function saveGameplaySettings():Void
	{
		var save:FlxSave = new FlxSave();
		save.bind('gameplay_settings', CoolUtil.getSavePath());
		save.data.gameplaySettings = gameplaySettings;
		save.flush();
	}

	public static function loadGameplaySettings():Void
	{
		var save:FlxSave = new FlxSave();
		save.bind('gameplay_settings', CoolUtil.getSavePath());
		
		if (save != null)
		{
			var savedMap:Map<String, Dynamic> = save.data.gameplaySettings;

			if (savedMap != null)
			{
				for (name => value in savedMap) {
					gameplaySettings.set(name, value);
				}
			}
		}
	}

	public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
	{
		if (!customDefaultValue) defaultValue = defaultData.gameplaySettings.get(name);
		return gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue;
	}

	public static function loadDefaultSettings():Void
	{
		defaultData.arrowRGB = arrowRGB.copy();
		defaultData.arrowRGBPixel = arrowRGBPixel.copy();

		defaultData.gameplaySettings = gameplaySettings.copy();

		defaultKeys = keyBinds.copy();
		defaultButtons = gamepadBinds.copy();

		for (field in Type.getClassFields(ClientPrefs))
		{
			var defaultValue:Dynamic = Reflect.getProperty(ClientPrefs, field);

			if (Type.typeof(defaultValue) != TFunction && !prefBlackList.contains(field)) {
				Reflect.setProperty(defaultData, field, defaultValue);
			}
		}
	}
}