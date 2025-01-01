package;

import haxe.Json;
import haxe.io.Path;
import haxe.Exception;
import haxe.Constraints;

import Type.ValueType;

#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import openfl.errors.Error;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import PlayState;
import DialogueBoxPsych;

#if RUNTIME_SHADERS_ALLOWED
import flixel.addons.display.FlxRuntimeShader;
#end

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxSave;
import flixel.util.FlxSort;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.sound.FlxSound;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.animation.FlxAnimationController;
import flixel.addons.transition.FlxTransitionableState;

using StringTools;

typedef LuaTweenOptions =
{
	type:FlxTweenType,
	startDelay:Float,
	?onUpdate:String,
	?onStart:String,
	?onComplete:String,
	loopDelay:Float,
	ease:EaseFunction
}

class FunkinLua
{
	public static var lastCalledScript:FunkinLua = null;

	#if LUA_ALLOWED
	public var lua:State = null;
	#end

	public var camTarget:FlxCamera;
	public var scriptName:String = '';
	public var modFolder:String = null;
	public var closed:Bool = false;

	#if HSCRIPT_ALLOWED
	public var hscript:HScript = null;
	#end

	public var callbacks:Map<String, Dynamic> = new Map<String, Dynamic>();

	public function new(scriptName:String):Void
	{
		#if LUA_ALLOWED
		lua = LuaL.newstate();
		LuaL.openlibs(lua);

		this.scriptName = scriptName;

		final game:PlayState = PlayState.instance;
		game.luaArray.push(this);

		#if MODS_ALLOWED
		final myFolder:Array<String> = this.scriptName.split('/');

		if (myFolder[0] + '/' == Paths.mods() && (Paths.currentModDirectory == myFolder[1] || Paths.globalMods.contains(myFolder[1]))) { // is inside mods folder
			this.modFolder = myFolder[1];
		}
		#end

		set('Function_StopLua', PlayState.Function_StopLua);

		#if HSCRIPT_ALLOWED
		set('Function_StopHScript', PlayState.Function_StopHScript);
		#end

		set('Function_StopAll', PlayState.Function_StopAll);
		set('Function_Stop', PlayState.Function_Stop);
		set('Function_Continue', PlayState.Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', false);

		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music.length);
		set('songName', PlayState.SONG.songName);
		set('songPath', Paths.formatToSongPath(PlayState.SONG.songID));
		set('startedCountdown', false);
		set('curStage', PlayState.SONG.stage);

		set('gameMode', PlayState.gameMode);
		set('isStoryMode', PlayState.isStoryMode);

		set('difficulty', PlayState.lastDifficulty);
		set('difficultyName', CoolUtil.difficultyStuff[PlayState.lastDifficulty][1]);
		set('difficultyPath', CoolUtil.difficultyStuff[PlayState.lastDifficulty][0]);
		set('storyDifficulty', PlayState.storyDifficulty);
		set('storyDifficultyName', CoolUtil.difficultyStuff[PlayState.storyDifficulty][1]);
		set('storyDifficultyPath', CoolUtil.difficultyStuff[PlayState.storyDifficulty][0]);

		set('weekRaw', PlayState.storyWeek);
		set('week', WeekData.getWeekFileName());
		set('seenCutscene', PlayState.seenCutscene);
		set('hasVocals', PlayState.SONG.needsVoices);

		var mode:String = Paths.formatToSongPath(ClientPrefs.cutscenesOnMode);
		set('allowPlayCutscene', mode.contains(PlayState.gameMode) || ClientPrefs.cutscenesOnMode == 'Everywhere');

		// Camera poo
		set('cameraX', 0);
		set('cameraY', 0);

		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		// PlayState cringe ass nae nae bullcrap
		set('curSection', 0);
		set('curBeat', 0);
		set('curStep', 0);
		set('curDecBeat', 0);
		set('curDecStep', 0);

		set('score', 0);
		set('misses', 0);
		set('hits', 0);
		set('combo', 0);
		set('health', 0);

		set('rating', 0);
		set('ratingName', '');
		set('ratingFC', '');
		set('version', MainMenuState.alsuhEngineVersion.trim());

		set('inGameOver', false);
		set('mustHitSection', false);
		set('altAnim', false);
		set('gfSection', false);

		// Gameplay settings
		set('healthGainMult', game.healthGain);
		set('healthLossMult', game.healthLoss);
		#if FLX_PITCH set('playbackRate', game.playbackRate); #end
		set('instakillOnMiss', game.instakillOnMiss);
		set('botPlay', game.cpuControlled);
		set('practice', game.practiceMode);

		for (i in 0...4)
		{
			set('defaultPlayerStrumX' + i, 0);
			set('defaultPlayerStrumY' + i, 0);
			set('defaultOpponentStrumX' + i, 0);
			set('defaultOpponentStrumY' + i, 0);
		}

		// Default character positions woooo
		set('defaultBoyfriendX', game.BF_X);
		set('defaultBoyfriendY', game.BF_Y);
		set('defaultOpponentX', game.DAD_X);
		set('defaultOpponentY', game.DAD_Y);
		set('defaultGirlfriendX', game.GF_X);
		set('defaultGirlfriendY', game.GF_Y);

		// Character shit
		set('boyfriendName', PlayState.SONG.player1);
		set('dadName', PlayState.SONG.player2);
		set('gfName', PlayState.SONG.gfVersion);

		ClientPrefs.implementForLua(this); // Some settings, no jokes

		set('scriptName', scriptName);
		set('currentModDirectory', Paths.currentModDirectory);

		// Noteskin/Splash
		set('noteSkinPostfix', Note.getNoteSkinPostfix());
		set('splashSkinPostfix', NoteSplash.getSplashSkinPostfix());

		set('buildTarget', CoolUtil.getBuildTarget());

		for (name => func in PlayState.customFunctions) {
			if (func != null) set(name, func);
		}

		set("getRunningScripts", function():Array<String>
		{
			return [for (script in game.luaArray) script.scriptName];
		});

		addLocalCallback("setOnScripts", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null):Void
		{
			if (exclusions == null) exclusions = [];
			if (ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);

			game.setOnScripts(varName, arg, exclusions);
		});

		#if HSCRIPT_ALLOWED
		addLocalCallback("setOnHScript", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null):Void
		{
			if (exclusions == null) exclusions = [];
			if (ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);

			game.setOnHScript(varName, arg, exclusions);
		});
		#end

		addLocalCallback("setOnLuas", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null):Void
		{
			if (exclusions == null) exclusions = [];
			if (ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);

			game.setOnLuas(varName, arg, exclusions);
		});

		addLocalCallback("callOnScripts", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null):Bool
		{
			if (excludeScripts == null) excludeScripts = [];
			if (ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);

			game.callOnScripts(funcName, args, ignoreStops, excludeScripts, excludeValues);
			return true;
		});

		addLocalCallback("callOnLuas", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null):Bool
		{
			if (excludeScripts == null) excludeScripts = [];
			if (ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);

			game.callOnLuas(funcName, args, ignoreStops, excludeScripts, excludeValues);
			return true;
		});

		#if HSCRIPT_ALLOWED
		addLocalCallback("callOnHScript", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null):Bool
		{
			if (excludeScripts == null) excludeScripts = [];
			if (ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);

			game.callOnHScript(funcName, args, ignoreStops, excludeScripts, excludeValues);
			return true;
		});
		#end

		set("callScript", function(luaFile:String, funcName:String, ?args:Array<Dynamic> = null):Void
		{
			if (args == null) {
				args = [];
			}

			final foundScript:String = findScript(luaFile);

			if (foundScript != null)
			{
				for (luaInstance in game.luaArray)
				{
					if (luaInstance.scriptName == foundScript)
					{
						luaInstance.call(funcName, args);
						return;
					}
				}
			}
		});

		set("getGlobalFromScript", function(luaFile:String, global:String):Void // returns the global from a script
		{
			final foundScript:String = findScript(luaFile);

			if (foundScript != null)
			{
				for (luaInstance in game.luaArray)
				{
					if (luaInstance.scriptName == foundScript)
					{
						Lua.getglobal(luaInstance.lua, global);

						if (Lua.isnumber(luaInstance.lua, -1)) {
							Lua.pushnumber(lua, Lua.tonumber(luaInstance.lua, -1));
						}
						else if (Lua.isstring(luaInstance.lua, -1)) {
							Lua.pushstring(lua, Lua.tostring(luaInstance.lua, -1));
						}
						else if (Lua.isboolean(luaInstance.lua, -1)) {
							Lua.pushboolean(lua, Lua.toboolean(luaInstance.lua, -1));
						}
						else Lua.pushnil(lua);

						Lua.pop(luaInstance.lua, 1); // remove the global
					}
				}
			}
		});

		set("setGlobalFromScript", function(luaFile:String, global:String, val:Dynamic):Void // returns the global from a script
		{
			final foundScript:String = findScript(luaFile);

			if (foundScript != null)
			{
				for (luaInstance in game.luaArray)
				{
					if (luaInstance.scriptName == foundScript) {
						luaInstance.set(global, val);
					}
				}
			}
		});

		set("isRunning", function(luaFile:String):Bool
		{
			final foundScript:String = findScript(luaFile);

			if (foundScript != null)
			{
				for (luaInstance in game.luaArray)
				{
					if (luaInstance.scriptName == foundScript) {
						return true;
					}
				}
			}
	
			return false;
		});

		set("setVar", PlayState.setVar);
		set("getVar", PlayState.getVar);

		set("addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false):Void // would be dope asf.
		{
			final foundScript:String = findScript(luaFile);

			if (foundScript != null)
			{
				if (!ignoreAlreadyRunning)
				{
					for (luaInstance in game.luaArray)
					{
						if (luaInstance.scriptName == foundScript)
						{
							PlayState.debugTrace('addLuaScript: The script "' + foundScript + '" is already running!');
							return;
						}
					}
				}

				new FunkinLua(foundScript);
			}
			else {
				PlayState.debugTrace("addLuaScript: Script doesn't exist!", false, 'error', FlxColor.RED);
			}
		});

		set("addHScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false):Void
		{
			#if HSCRIPT_ALLOWED
			final foundScript:String = findScript(luaFile, '.hx');

			if (foundScript != null)
			{
				if (!ignoreAlreadyRunning)
				{
					for (script in game.hscriptArray)
					{
						if (script.origin == foundScript)
						{
							PlayState.debugTrace('addHScript: The script "' + foundScript + '" is already running!');
							return;
						}
					}
				}

				PlayState.instance.initHScript(foundScript);
			}
			else {
				PlayState.debugTrace("addHScript: Script doesn't exist!", false, 'error', FlxColor.RED);
			}
			#else
			PlayState.debugTrace("addHScript: HScript is not supported on this platform!", false, 'error', FlxColor.RED);
			#end
		});

		set("removeLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false):Bool
		{
			final foundScript:String = findScript(luaFile);

			if (foundScript != null)
			{
				if (!ignoreAlreadyRunning)
				{
					for (luaInstance in game.luaArray)
					{
						if (luaInstance.scriptName == foundScript)
						{
							luaInstance.stop();

							Debug.logInfo('Closing script ' + luaInstance.scriptName);
							return true;
						}
					}
				}
			}
			else {
				PlayState.debugTrace('removeLuaScript: Script $luaFile isn\'t running!', false, 'error', FlxColor.RED);
			}

			return false;
		});

		Lua_helper.add_callback(lua, "removeHScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false):Bool
		{
			#if HSCRIPT_ALLOWED
			var foundScript:String = findScript(luaFile, '.hx');

			if (foundScript != null)
			{
				if (!ignoreAlreadyRunning)
				{
					for (script in game.hscriptArray)
					{
						if (script.origin == foundScript)
						{
							Debug.logInfo('Closing script ' + (script.origin != null ? script.origin : luaFile));
							script.destroy();
							return true;
						}
					}
				}
			}
			else {
				PlayState.debugTrace('removeHScript: Script $luaFile isn\'t running!', false, 'error', FlxColor.RED);
			}
			#else
			PlayState.debugTrace("removeHScript: HScript is not supported on this platform!", false, 'error', FlxColor.RED);
			#end

			return false;
		});

		set("getProperty", function(variable:String, ?allowMaps:Bool = false):Dynamic
		{
			var split:Array<String> = variable.split('.');

			if (split.length > 1) {
				return PlayState.getVarInArray(PlayState.getPropertyLoop(split, true, true, allowMaps), split[split.length - 1], allowMaps);
			}

			return PlayState.getVarInArray(PlayState.getTargetInstance(), variable, allowMaps);
		});

		set("setProperty", function(variable:String, value:Dynamic, allowMaps:Bool = false):Bool
		{
			var split:Array<String> = variable.split('.');

			try
			{
				if (split.length > 1)
				{
					PlayState.setVarInArray(PlayState.getPropertyLoop(split, true, true, allowMaps), split[split.length - 1], value, allowMaps);
					return true;
				}
	
				PlayState.setVarInArray(PlayState.getTargetInstance(), variable, value, allowMaps);
				return true;
			}
			catch (e) {
				trace(e);
			}

			return false;
		});

		set("getPropertyFromClass", function(classVar:String, variable:String, ?allowMaps:Bool = false):Dynamic
		{
			var myClass:Dynamic = Type.resolveClass(PlayState.convertObjectToNew(classVar));

			if (myClass == null)
			{
				PlayState.debugTrace('getPropertyFromClass: Class $classVar not found', false, 'error', FlxColor.RED);
				return null;
			}

			var split:Array<String> = variable.split('.');

			if (split.length > 1)
			{
				var obj:Dynamic = PlayState.getVarInArray(myClass, split[0], allowMaps);

				for (i in 1...split.length - 1) {
					obj = PlayState.getVarInArray(obj, split[i], allowMaps);
				}

				return PlayState.getVarInArray(obj, split[split.length - 1], allowMaps);
			}

			return PlayState.getVarInArray(myClass, variable, allowMaps);
		});

		set("setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic, ?allowMaps:Bool = false):Dynamic
		{
			var myClass:Dynamic = Type.resolveClass(PlayState.convertObjectToNew(classVar));

			if (myClass == null)
			{
				PlayState.debugTrace('getPropertyFromClass: Class $classVar not found', false, 'error', FlxColor.RED);
				return null;
			}

			var split:Array<String> = variable.split('.');

			if (split.length > 1)
			{
				var obj:Dynamic = PlayState.getVarInArray(myClass, split[0], allowMaps);

				for (i in 1...split.length - 1) {
					obj = PlayState.getVarInArray(obj, split[i], allowMaps);
				}

				PlayState.setVarInArray(obj, split[split.length - 1], value, allowMaps);
				return value;
			}
	
			PlayState.setVarInArray(myClass, variable, value, allowMaps);
			return value;
		});

		set("getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, ?allowMaps:Bool = false):Dynamic
		{
			var split:Array<String> = obj.split('.');
			var realObject:Dynamic = null;

			if (split.length > 1)
				realObject = PlayState.getPropertyLoop(split, true, false, allowMaps);
			else
				realObject = Reflect.getProperty(PlayState.getTargetInstance(), obj);

			if (Std.isOfType(realObject, FlxTypedGroup))
			{
				var result:Dynamic = PlayState.getGroupStuff(realObject.members[index], variable, allowMaps);
				return result;
			}

			var leArray:Dynamic = realObject[index];

			if (leArray != null)
			{
				var result:Dynamic = null;

				if (Type.typeof(variable) == ValueType.TInt)
					result = leArray[variable];
				else
					result = PlayState.getGroupStuff(leArray, variable, allowMaps);

				return result;
			}

			PlayState.debugTrace("getPropertyFromGroup: Object #" + index + " from group: " + obj + " doesn't exist!", false, 'error', FlxColor.RED);
			return null;
		});

		set("setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic, ?allowMaps:Bool = false):Dynamic
		{
			var split:Array<String> = obj.split('.');
			var realObject:Dynamic = null;

			if (split.length > 1)
				realObject = PlayState.getPropertyLoop(split, true, false, allowMaps);
			else
				realObject = Reflect.getProperty(PlayState.getTargetInstance(), obj);

			if (Std.isOfType(realObject, FlxTypedGroup))
			{
				PlayState.setGroupStuff(realObject.members[index], variable, value, allowMaps);
				return value;
			}

			var leArray:Dynamic = realObject[index];

			if (leArray != null)
			{
				if (Type.typeof(variable) == ValueType.TInt)
				{
					leArray[variable] = value;
					return value;
				}

				PlayState.setGroupStuff(leArray, variable, value, allowMaps);
			}

			return value;
		});

		set("removeFromGroup", function(obj:String, index:Int, dontDestroy:Bool = false):Void
		{
			var groupOrArray:Dynamic = Reflect.getProperty(PlayState.getTargetInstance(), obj);
	
			if (Std.isOfType(groupOrArray, FlxTypedGroup))
			{
				var sex:FlxBasic = groupOrArray.members[index];
				if (!dontDestroy) sex.kill();

				groupOrArray.remove(sex, true);
				if (!dontDestroy) sex.destroy();

				return;
			}

			groupOrArray.remove(groupOrArray[index]);
		});
		
		set("callMethod", function(funcToRun:String, ?args:Array<Dynamic> = null):Dynamic
		{
			return PlayState.callMethodFromObject(PlayState.instance, funcToRun, args);
		});

		set("callMethodFromClass", function(className:String, funcToRun:String, ?args:Array<Dynamic> = null):Dynamic
		{
			return PlayState.callMethodFromObject(Type.resolveClass(PlayState.convertObjectToNew(className)), funcToRun, args);
		});

		set("createInstance", function(variableToSave:String, className:String, ?args:Array<Dynamic> = null):Bool
		{
			variableToSave = variableToSave.trim().replace('.', '');

			if (!PlayState.instance.variables.exists(variableToSave))
			{
				if (args == null) args = [];
				var myType:Dynamic = Type.resolveClass(className);
		
				if (myType == null)
				{
					PlayState.debugTrace('createInstance: Variable $variableToSave is already being used and cannot be replaced!', false, 'error', FlxColor.RED);
					return false;
				}

				var obj:Dynamic = Type.createInstance(myType, args);

				if (obj != null)
					PlayState.instance.variables.set(variableToSave, obj);
				else
					PlayState.debugTrace('createInstance: Failed to create $variableToSave, arguments are possibly wrong.', false, 'error', FlxColor.RED);

				return (obj != null);
			}
			else PlayState.debugTrace('createInstance: Variable $variableToSave is already being used and cannot be replaced!', false, 'error', FlxColor.RED);

			return false;
		});

		set("addInstance", function(objectName:String, ?inFront:Bool = false):Void
		{
			if (PlayState.instance.variables.exists(objectName))
			{
				var obj:Dynamic = PlayState.instance.variables.get(objectName);

				if (inFront) {
					PlayState.getTargetInstance().add(obj);
				}
				else
				{
					if (!PlayState.instance.isDead)
						PlayState.instance.insert(PlayState.instance.members.indexOf(PlayState.getLowestCharacterGroup()), obj);
					else
						GameOverSubState.instance.insert(GameOverSubState.instance.members.indexOf(GameOverSubState.instance.boyfriend), obj);
				}
			}
			else {
				PlayState.debugTrace('addInstance: Can\'t add what doesn\'t exist~ ($objectName)', false, 'error', FlxColor.RED);
			}
		});

		set("loadSong", function(?name:String = null, ?difficultyNum:Int = -1):Void
		{
			if (name == null || name.length < 1) name = PlayState.SONG.songID;

			if (difficultyNum == -1) {
				difficultyNum = PlayState.storyDifficulty;
			}

			final poop:String = CoolUtil.formatSong(name, difficultyNum);

			PlayState.SONG = Song.loadFromJson(poop, name);
			PlayState.storyDifficulty = difficultyNum;

			game.persistentUpdate = false;
			LoadingState.loadAndSwitchState(new PlayState(), true);

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;

			if (game.vocals != null)
			{
				game.vocals.pause();
				game.vocals.volume = 0;
			}

			FlxG.camera.followLerp = 0;
		});

		set("loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0):Void
		{
			final split:Array<String> = variable.split('.');
			final animated = gridX != 0 || gridY != 0;

			final spr:FlxSprite = (split.length > 1) ? PlayState.getVarInArray(PlayState.getPropertyLoop(split), split[split.length - 1]) : PlayState.getObjectDirectly(split[0]);

			if (spr != null && image != null && image.length > 0) {
				spr.loadGraphic(Paths.getImage(image), animated, gridX, gridY);
			}
		});

		set("loadFrames", function(variable:String, image:String, spriteType:String = "sparrow"):Void
		{
			final split:Array<String> = variable.split('.');
			final spr:FlxSprite = (split.length > 1) ? PlayState.getVarInArray(PlayState.getPropertyLoop(split), split[split.length - 1]) : PlayState.getObjectDirectly(split[0]);

			if (spr != null && image != null && image.length > 0) {
				PlayState.loadSpriteFrames(spr, image, spriteType);
			}
		});

		set("getObjectOrder", function(obj:String):Int // shitass stuff for epic coders like me B)  *image of obama giving himself a medal*
		{
			final split:Array<String> = obj.split('.');
			final leObj:FlxBasic = (split.length > 1) ? PlayState.getVarInArray(PlayState.getPropertyLoop(split), split[split.length - 1]) : PlayState.getObjectDirectly(split[0]);

			if (leObj != null) {
				return PlayState.getTargetInstance().members.indexOf(leObj);
			}

			PlayState.debugTrace("getObjectOrder: Object " + obj + " doesn't exist!", false, 'error', FlxColor.RED);
			return -1;
		});

		set("setObjectOrder", function(obj:String, position:Int):Void
		{
			final split:Array<String> = obj.split('.');
			final leObj:FlxBasic = (split.length > 1) ? PlayState.getVarInArray(PlayState.getPropertyLoop(split), split[split.length - 1]) : PlayState.getObjectDirectly(split[0]);

			if (leObj != null)
			{
				PlayState.getTargetInstance().remove(leObj, true);
				PlayState.getTargetInstance().insert(position, leObj);

				return;
			}

			PlayState.debugTrace("setObjectOrder: Object " + obj + " doesn't exist!", false, 'error', FlxColor.RED);
		});

		set("startTween", function(tag:String, vars:String, values:Any = null, duration:Float, options:Any = null):Void
		{
			final tween:Dynamic = PlayState.tweenPrepare(tag, vars);

			if (tween != null)
			{
				if (values != null)
				{
					var myOptions:LuaTweenOptions = PlayState.getTween(options);
					game.modchartTweens.set(tag, FlxTween.tween(tween, values, duration,
					{
						type: myOptions.type,
						ease: myOptions.ease,
						startDelay: myOptions.startDelay,
						loopDelay: myOptions.loopDelay,
						onUpdate: function(twn:FlxTween):Void {
							if (myOptions.onUpdate != null) game.callOnLuas(myOptions.onUpdate, [tag, vars]);
						},
						onStart: function(twn:FlxTween):Void {
							if (myOptions.onStart != null) game.callOnLuas(myOptions.onStart, [tag, vars]);
						},
						onComplete: function(twn:FlxTween)
						{
							if (myOptions.onComplete != null) game.callOnLuas(myOptions.onComplete, [tag, vars]);
							if (twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD) game.modchartTweens.remove(tag);
						}
					}));
				}
				else {
					PlayState.debugTrace('startTween: No values on 2nd argument!', false, 'error', FlxColor.RED);
				}
			}
			else {
				PlayState.debugTrace('startTween: Couldnt find object: ' + vars, false, 'error', FlxColor.RED);
			}
		});

		set("doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String):Void
		{
			oldTweenFunction(tag, vars, {x: value}, duration, ease, 'doTweenX');
		});

		set("doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String):Void
		{
			oldTweenFunction(tag, vars, {y: value}, duration, ease, 'doTweenY');
		});

		set("doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String):Void
		{
			oldTweenFunction(tag, vars, {angle: value}, duration, ease, 'doTweenAngle');
		});

		set("doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String):Void
		{
			oldTweenFunction(tag, vars, {alpha: value}, duration, ease, 'doTweenAlpha');
		});

		set("doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String):Void
		{
			oldTweenFunction(tag, vars, {zoom: value}, duration, ease, 'doTweenZoom');
		});

		set("doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String):Void
		{
			final tween:Dynamic = PlayState.tweenPrepare(tag, vars);

			if (tween != null)
			{
				var curColor:FlxColor = tween.color;
				curColor.alphaFloat = tween.alpha;
				game.modchartTweens.set(tag, FlxTween.color(tween, duration, curColor, CoolUtil.colorFromString(targetColor),
				{
					ease: PlayState.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween):Void
					{
						game.modchartTweens.remove(tag);
						game.callOnLuas('onTweenCompleted', [tag, vars]);
					}
				}));
			}
			else {
				PlayState.debugTrace('doTweenColor: Couldnt find object: ' + vars, false, 'error', FlxColor.RED);
			}
		});

		set("noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String):Void
		{
			PlayState.noteTweenFunction(tag, note, {x: value}, duration, ease);
		});

		set("noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String):Void
		{
			PlayState.noteTweenFunction(tag, note, {y: value}, duration, ease);
		});

		set("noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String):Void
		{
			PlayState.noteTweenFunction(tag, note, {angle: value}, duration, ease);
		});

		set("noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String):Void
		{
			PlayState.noteTweenFunction(tag, note, {alpha: value}, duration, ease);
		});

		set("noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String):Void
		{
			PlayState.noteTweenFunction(tag, note, {alpha: value}, duration, ease);
		});

		set("mouseClicked", function(button:String):Bool
		{
			switch (button)
			{
				case 'middle': return FlxG.mouse.justPressedMiddle;
				case 'right': return FlxG.mouse.justPressedRight;
			}

			return FlxG.mouse.justPressed;
		});

		set("mousePressed", function(button:String):Bool
		{
			switch (button)
			{
				case 'middle': return FlxG.mouse.pressedMiddle;
				case 'right': return FlxG.mouse.pressedRight;
			}

			return FlxG.mouse.pressed;
		});

		set("mouseReleased", function(button:String):Bool
		{
			switch (button)
			{
				case 'middle': return FlxG.mouse.justReleasedMiddle;
				case 'right': return FlxG.mouse.justReleasedRight;
			}

			return FlxG.mouse.justReleased;
		});

		set("cancelTween", PlayState.cancelTween);

		set("runTimer", function(tag:String, time:Float = 1, loops:Int = 1):Void
		{
			PlayState.cancelTimer(tag);

			game.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer):Void
			{
				if (tmr.finished) {
					game.modchartTimers.remove(tag);
				}

				game.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
			}, loops));
		});

		set("cancelTimer", function(tag:String):Void
		{
			PlayState.cancelTimer(tag);
		});

		addLocalCallback("initLuaShader", function(name:String, ?glslVersion:Int = 120):Bool
		{
			if (!ClientPrefs.shadersEnabled) return false;

			#if RUNTIME_SHADERS_ALLOWED
			return initLuaShader(name, glslVersion);
			#else
			PlayState.debugTrace("initLuaShader: Platform unsupported for Runtime Shaders!", false, 'error', FlxColor.RED);
			#end

			return false;
		});
		
		addLocalCallback("setSpriteShader", function(obj:String, shader:String):Bool
		{
			if (!ClientPrefs.shadersEnabled) return false;

			#if RUNTIME_SHADERS_ALLOWED
			if (!runtimeShaders.exists(shader) && !initLuaShader(shader))
			{
				PlayState.debugTrace('setSpriteShader: Shader $shader is missing!', false, 'error', FlxColor.RED);
				return false;
			}

			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = PlayState.getObjectDirectly(split[0]);

			if (split.length > 1) {
				leObj = PlayState.getVarInArray(PlayState.getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null)
			{
				var arr:Array<String> = runtimeShaders.get(shader);
				leObj.shader = new FlxRuntimeShader(arr[0], arr[1]);

				return true;
			}
			#else
			PlayState.debugTrace("setSpriteShader: Platform unsupported for Runtime Shaders!", false, 'error', FlxColor.RED);
			#end

			return false;
		});

		set("removeSpriteShader", function(obj:String):Bool
		{
			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = PlayState.getObjectDirectly(split[0]);

			if (split.length > 1) {
				leObj = PlayState.getVarInArray(PlayState.getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null)
			{
				leObj.shader = null;
				return true;
			}
	
			return false;
		});

		set("getShaderBool", function(obj:String, prop:String):Null<Bool>
		{
			#if RUNTIME_SHADERS_ALLOWED
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null)
			{
				PlayState.debugTrace("getShaderBool: Shader is not FlxRuntimeShader!", false, 'error', FlxColor.RED);
				return null;
			}

			return shader.getBool(prop);
			#else
			PlayState.debugTrace("getShaderBool: Platform unsupported for Runtime Shaders!", false, 'error', FlxColor.RED);
			return null;
			#end
		});

		set("getShaderBoolArray", function(obj:String, prop:String):Null<Array<Bool>>
		{
			#if RUNTIME_SHADERS_ALLOWED
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null)
			{
				PlayState.debugTrace("getShaderBoolArray: Shader is not FlxRuntimeShader!", false, 'error', FlxColor.RED);
				return null;
			}

			return shader.getBoolArray(prop);
			#else
			PlayState.debugTrace("getShaderBoolArray: Platform unsupported for Runtime Shaders!", false, 'error', FlxColor.RED);
			return null;
			#end
		});

		set("getShaderInt", function(obj:String, prop:String):Null<Int>
		{
			#if RUNTIME_SHADERS_ALLOWED
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null)
			{
				PlayState.debugTrace("getShaderInt: Shader is not FlxRuntimeShader!", false, 'error', FlxColor.RED);
				return null;
			}

			return shader.getInt(prop);
			#else
			PlayState.debugTrace("getShaderInt: Platform unsupported for Runtime Shaders!", false, 'error', FlxColor.RED);
			return null;
			#end
		});

		set("getShaderIntArray", function(obj:String, prop:String):Null<Array<Int>>
		{
			#if RUNTIME_SHADERS_ALLOWED
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null)
			{
				PlayState.debugTrace("getShaderIntArray: Shader is not FlxRuntimeShader!", false, 'error', FlxColor.RED);
				return null;
			}

			return shader.getIntArray(prop);
			#else
			PlayState.debugTrace("getShaderIntArray: Platform unsupported for Runtime Shaders!", false, 'error', FlxColor.RED);
			return null;
			#end
		});

		set("getShaderFloat", function(obj:String, prop:String):Null<Float>
		{
			#if RUNTIME_SHADERS_ALLOWED
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null)
			{
				PlayState.debugTrace("getShaderFloat: Shader is not FlxRuntimeShader!", false, 'error', FlxColor.RED);
				return null;
			}

			return shader.getFloat(prop);
			#else
			PlayState.debugTrace("getShaderFloat: Platform unsupported for Runtime Shaders!", false, 'error', FlxColor.RED);
			return null;
			#end
		});

		set("getShaderFloatArray", function(obj:String, prop:String):Null<Array<Float>>
		{
			#if RUNTIME_SHADERS_ALLOWED
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null)
			{
				PlayState.debugTrace("getShaderFloatArray: Shader is not FlxRuntimeShader!", false, 'error', FlxColor.RED);
				return null;
			}

			return shader.getFloatArray(prop);
			#else
			PlayState.debugTrace("getShaderFloatArray: Platform unsupported for Runtime Shaders!", false, 'error', FlxColor.RED);
			return null;
			#end
		});

		set("setShaderBool", function(obj:String, prop:String, value:Bool):Bool
		{
			#if RUNTIME_SHADERS_ALLOWED
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null)
			{
				PlayState.debugTrace("setShaderBool: Shader is not FlxRuntimeShader!", false, 'error', FlxColor.RED);
				return false;
			}

			shader.setBool(prop, value);
			return true;
			#else
			PlayState.debugTrace("setShaderBool: Platform unsupported for Runtime Shaders!", false, 'error', FlxColor.RED);
			return false;
			#end
		});

		set("setShaderBoolArray", function(obj:String, prop:String, values:Dynamic):Bool
		{
			#if RUNTIME_SHADERS_ALLOWED
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null)
			{
				PlayState.debugTrace("setShaderBoolArray: Shader is not FlxRuntimeShader!", false, 'error', FlxColor.RED);
				return false;
			}

			shader.setBoolArray(prop, values);
			return true;
			#else
			PlayState.debugTrace("setShaderBoolArray: Platform unsupported for Runtime Shaders!", false, 'error', FlxColor.RED);
			return false;
			#end
		});

		set("setShaderInt", function(obj:String, prop:String, value:Int):Bool
		{
			#if RUNTIME_SHADERS_ALLOWED
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null)
			{
				PlayState.debugTrace("setShaderInt: Shader is not FlxRuntimeShader!", false, 'error', FlxColor.RED);
				return false;
			}

			shader.setInt(prop, value);
			return true;
			#else
			PlayState.debugTrace("setShaderInt: Platform unsupported for Runtime Shaders!", false, 'error', FlxColor.RED);
			return false;
			#end
		});

		set("setShaderIntArray", function(obj:String, prop:String, values:Dynamic):Bool
		{
			#if RUNTIME_SHADERS_ALLOWED
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null)
			{
				PlayState.debugTrace("setShaderIntArray: Shader is not FlxRuntimeShader!", false, 'error', FlxColor.RED);
				return false;
			}

			shader.setIntArray(prop, values);
			return true;
			#else
			PlayState.debugTrace("setShaderIntArray: Platform unsupported for Runtime Shaders!", false, 'error', FlxColor.RED);
			return false;
			#end
		});

		set("setShaderFloat", function(obj:String, prop:String, value:Float):Bool
		{
			#if RUNTIME_SHADERS_ALLOWED
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null)
			{
				PlayState.debugTrace("setShaderFloat: Shader is not FlxRuntimeShader!", false, 'error', FlxColor.RED);
				return false;
			}

			shader.setFloat(prop, value);
			return true;
			#else
			PlayState.debugTrace("setShaderFloat: Platform unsupported for Runtime Shaders!", false, 'error', FlxColor.RED);
			return false;
			#end
		});

		set("setShaderFloatArray", function(obj:String, prop:String, values:Dynamic):Bool
		{
			#if RUNTIME_SHADERS_ALLOWED
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null)
			{
				PlayState.debugTrace("setShaderFloatArray: Shader is not FlxRuntimeShader!", false, 'error', FlxColor.RED);
				return false;
			}

			shader.setFloatArray(prop, values);
			return true;
			#else
			PlayState.debugTrace("setShaderFloatArray: Platform unsupported for Runtime Shaders!", false, 'error', FlxColor.RED);
			return true;
			#end
		});

		set("setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String):Bool
		{
			#if RUNTIME_SHADERS_ALLOWED
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null)
			{
				PlayState.debugTrace("setShaderSampler2D: Shader is not FlxRuntimeShader!", false, 'error', FlxColor.RED);
				return false;
			}

			var value:FlxGraphic = Paths.getImage(bitmapdataPath);

			if (value != null && value.bitmap != null)
			{
				shader.setSampler2D(prop, value.bitmap);
				return true;
			}

			return false;
			#else
			PlayState.debugTrace("setShaderSampler2D: Platform unsupported for Runtime Shaders!", false, 'error', FlxColor.RED);
			return false;
			#end
		});

		set("addScore", function(value:Int = 0):Void
		{
			game.songScore += value;
			game.RecalculateRating();
		});

		set("addMisses", function(value:Int = 0):Void
		{
			game.songMisses += value;
			game.RecalculateRating();
		});

		set("addHits", function(value:Int = 0):Void
		{
			game.songHits += value;
			game.RecalculateRating();
		});

		set("setScore", function(value:Int = 0):Void
		{
			game.songScore = value;
			game.RecalculateRating();
		});

		set("setMisses", function(value:Int = 0):Void
		{
			game.songMisses = value;
			game.RecalculateRating();
		});

		set("setHits", function(value:Int = 0):Void
		{
			game.songHits = value;
			game.RecalculateRating();
		});

		set("getScore", function():Int return game.songScore);
		set("getMisses", function():Int return game.songMisses);
		set("getHits", function():Int  return game.songHits);

		set("setHealth", function(value:Float = 0):Void game.health = value);
		set("addHealth", function(value:Float = 0):Void game.health += value);
		set("getHealth", function():Float return game.health);

		set("FlxColor", FlxColor.fromString);

		set("getColorFromName", FlxColor.fromString);
		set("colorFromString", FlxColor.fromString);
		set("getColorFromHex", function(color:String):FlxColor return FlxColor.fromString('#$color'));

		set("addCharacterToList", function(name:String, type:String):Void
		{
			game.addCharacterToList(name, switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':  1;
				case 'gf' | 'girlfriend': 2;
				default: 0;
			});
		});

		set("precacheImage", Paths.getImage);
		set("precacheSound", Paths.getSound);
		set("precacheMusic", Paths.getMusic);

		set("triggerEvent", function(name:String, arg1:Any, arg2:Any):Void game.triggerEvent(name, arg1, arg2, Conductor.songPosition));

		set("startCountdown", game.startCountdown);

		set("endSong", function():Bool
		{
			game.killNotes();
			return game.endSong();
		});

		set("restartSong", function(?skipTransition:Bool = false):Bool
		{
			game.persistentUpdate = false;
			FlxG.camera.followLerp = 0;

			PauseSubState.restartSong(skipTransition);
			return true;
		});

		set("exitSong", function(?skipTransition:Bool = false):Bool
		{
			if (skipTransition)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}

			PlayState.cancelMusicFadeTween();
			PlayState.instance.stopMusic();

			#if DISCORD_ALLOWED
			DiscordClient.resetClientID();
			#end

			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.usedPractice = false;
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;

			PlayState.firstSong = null;

			game.transitioning = true;

			FlxG.camera.followLerp = 0;

			Paths.loadTopMod();

			switch (PlayState.gameMode)
			{
				case 'story':
					FlxG.switchState(new StoryMenuState());
				case 'freeplay':
					FlxG.switchState(new FreeplayMenuState());
				default:
					FlxG.switchState(new MainMenuState());
			}

			return true;
		});

		set("getSongPosition", function():Float return Conductor.songPosition);

		set("getCharacterX", function(type:String):Float
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent': return game.dadGroup.x;
				case 'gf' | 'girlfriend': return game.gfGroup.x;
				default: return game.boyfriendGroup.x;
			}
		});

		set("setCharacterX", function(type:String, value:Float):Void
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent': game.dadGroup.x = value;
				case 'gf' | 'girlfriend': game.gfGroup.x = value;
				default: game.boyfriendGroup.x = value;
			}
		});

		set("getCharacterY", function(type:String):Float
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent': return game.dadGroup.y;
				case 'gf' | 'girlfriend': return game.gfGroup.y;
				default: return game.boyfriendGroup.y;
			}
		});

		set("setCharacterY", function(type:String, value:Float):Void
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent': game.dadGroup.y = value;
				case 'gf' | 'girlfriend': game.gfGroup.y = value;
				default: game.boyfriendGroup.y = value;
			}
		});

		set("cameraSetTarget", function(target:Dynamic, callOnScripts:Null<Bool> = false):Void
		{
			game.cameraMovement(target, callOnScripts);
		});

		set("cameraShake", function(camera:String, intensity:Float, duration:Float):Void
		{
			PlayState.cameraFromString(camera).shake(intensity, duration);
		});

		set("cameraFlash", function(camera:String, color:String, duration:Float, forced:Bool):Void
		{
			PlayState.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration, null, forced);
		});

		set("cameraFade", function(camera:String, color:String, duration:Float, forced:Bool):Void
		{
			PlayState.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration, false, null, forced);
		});

		set("setAccuracy", function(value:Float):Float
		{
			return game.songAccuracy = value;
		});

		set("setRatingPercent", function(value:Float):Float
		{
			return game.songAccuracy = value;
		});

		set("setRatingName", function(value:String):String
		{
			return game.ratingName = value;
		});

		set("setRatingFC", function(value:String):String
		{
			return game.ratingFC = value;
		});

		set("getMouseX", function(camera:String):Float
		{
			return PlayState.getMousePoint(camera, 'x');
		});

		set("getMouseY", function(camera:String):Float
		{
			return PlayState.getMousePoint(camera, 'y');
		});

		set("getMidpointX", function(variable:String):Float
		{
			return PlayState.getPoint(variable, 'midpoint', 'x');
		});

		set("getMidpointY", function(variable:String):Float
		{
			return PlayState.getPoint(variable, 'midpoint', 'y');
		});

		set("getGraphicMidpointX", function(variable:String):Float
		{
			return PlayState.getPoint(variable, 'graphic', 'x');
		});

		set("getGraphicMidpointY", function(variable:String):Float
		{
			return PlayState.getPoint(variable, 'graphic', 'y');
		});

		set("getScreenPositionX", function(variable:String, ?camera:String):Float
		{
			return PlayState.getPoint(variable, 'screen', 'x', camera);
		});

		set("getScreenPositionY", function(variable:String, ?camera:String):Float
		{
			return PlayState.getPoint(variable, 'screen', 'y', camera);
		});

		set("characterDance", function(character:String, force:Bool = false):Void
		{
			switch (character.toLowerCase())
			{
				case 'dad': game.dad.dance(force);
				case 'gf' | 'girlfriend': if (game.gf != null) game.gf.dance(force);
				default: game.boyfriend.dance(force);
			}
		});

		set("makeLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0):Void
		{
			tag = tag.replace('.', '');
			PlayState.resetSpriteTag(tag);

			final leSprite:Sprite = new Sprite(x, y);

			if (image != null && image.length > 0) {
				leSprite.loadGraphic(Paths.getImage(image));
			}

			game.modchartSprites.set(tag, leSprite);

			if (game.isDead) {
				leSprite.cameras = [GameOverSubState.instance.camDeath];
			}

			leSprite.active = true;
		});

		set("makeAnimatedLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?spriteType:String = "sparrow"):Void
		{
			tag = tag.replace('.', '');
			PlayState.resetSpriteTag(tag);

			final leSprite:Sprite = new Sprite(x, y);

			PlayState.loadSpriteFrames(leSprite, image, spriteType);

			if (game.isDead) {
				leSprite.cameras = [GameOverSubState.instance.camDeath];
			}

			game.modchartSprites.set(tag, leSprite);
		});

		set("makeGraphic", function(obj:String, width:Int = 256, height:Int = 256, color:String = 'FFFFFF'):Void
		{
			final spr:FlxSprite = PlayState.getObjectDirectly(obj, false);
			if (spr != null) spr.makeGraphic(width, height, CoolUtil.colorFromString(color));
		});

		set("addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true):Bool
		{
			final obj:Dynamic = PlayState.getObjectDirectly(obj, false);

			if (obj != null && obj.animation != null)
			{
				obj.animation.addByPrefix(name, prefix, framerate, loop);
	
				if (obj.animation.curAnim == null)
				{
					if (obj.playAnim != null) {
						obj.playAnim(name, true);
					}
					else obj.animation.play(name, true);
				}

				return true;
			}

			return false;
		});

		set("addAnimation", function(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true):Bool
		{
			final obj:Dynamic = PlayState.getObjectDirectly(obj, false);
	
			if (obj != null && obj.animation != null)
			{
				obj.animation.add(name, frames, framerate, loop);

				if (obj.animation.curAnim == null) {
					obj.animation.play(name, true);
				}

				return true;
			}

			return false;
		});

		set("addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false):Bool
		{
			return PlayState.addAnimByIndices(obj, name, prefix, indices, framerate, loop);
		});

		set("playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0):Bool
		{
			final obj:Dynamic = PlayState.getObjectDirectly(obj, false);

			if (obj != null)
			{
				if (obj.playAnim != null)
				{
					obj.playAnim(name, forced, reverse, startFrame);
					return true;
				}
				else
				{
					obj.animation.play(name, forced, reverse, startFrame);
					return true;
				}
			}

			return false;
		});

		set("addOffset", function(obj:String, anim:String, x:Float, y:Float):Bool
		{
			final obj:Dynamic = PlayState.getObjectDirectly(obj, false);

			if (obj != null && obj.addOffset != null)
			{
				obj.addOffset(anim, x, y);
				return true;
			}

			return false;
		});

		set("setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float):Void
		{
			if (game.getLuaObject(obj, false) != null)
			{
				game.getLuaObject(obj, false).scrollFactor.set(scrollX, scrollY);
				return;
			}

			final object:FlxObject = Reflect.getProperty(PlayState.getTargetInstance(), PlayState.convertVariableToNew(PlayState.getTargetInstanceName(), obj));

			if (object != null) {
				object.scrollFactor.set(scrollX, scrollY);
			}
		});

		set("addLuaSprite", function(tag:String, front:Bool = false):Bool
		{
			final mySprite:FlxSprite = if (game.modchartSprites.exists(tag))
				game.modchartSprites.get(tag);
			else if (game.variables.exists(tag)) 
				game.variables.get(tag);
			else
				null;
			
			if (mySprite == null) return false;

			if (front) PlayState.getTargetInstance().add(mySprite);
			else
			{
				if (!game.isDead)
					game.insert(game.members.indexOf(PlayState.getLowestCharacterGroup()), mySprite);
				else
					GameOverSubState.instance.insert(GameOverSubState.instance.members.indexOf(GameOverSubState.instance.boyfriend), mySprite);
			}

			return true;
		});

		set("setGraphicSize", function(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true):Void
		{
			if (game.getLuaObject(obj) != null)
			{
				final shit:FlxSprite = game.getLuaObject(obj);
				shit.setGraphicSize(x, y);

				if (updateHitbox) shit.updateHitbox();
				return;
			}

			final split:Array<String> = obj.split('.');
			final poop:FlxSprite = (split.length > 1) ? PlayState.getVarInArray(PlayState.getPropertyLoop(split), split[split.length - 1]) : PlayState.getObjectDirectly(split[0]);

			if (poop != null)
			{
				poop.setGraphicSize(x, y);
				if (updateHitbox) poop.updateHitbox();

				return;
			}

			PlayState.debugTrace('setGraphicSize: Couldnt find object: ' + obj, false, 'error', FlxColor.RED);
		});

		set("scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true):Void
		{
			if (game.getLuaObject(obj) != null)
			{
				final shit:FlxSprite = game.getLuaObject(obj);
				shit.scale.set(x, y);

				if (updateHitbox) shit.updateHitbox();
				return;
			}

			final split:Array<String> = obj.split('.');
			final poop:FlxSprite = (split.length > 1) ? PlayState.getVarInArray(PlayState.getPropertyLoop(split), split[split.length - 1]) : PlayState.getObjectDirectly(split[0]);

			if (poop != null)
			{
				poop.scale.set(x, y);
				if (updateHitbox) poop.updateHitbox();

				return;
			}

			PlayState.debugTrace('scaleObject: Couldnt find object: ' + obj, false, 'error', FlxColor.RED);
		});

		set("updateHitbox", function(obj:String):Void
		{
			if (game.getLuaObject(obj) != null)
			{
				final shit:FlxSprite = game.getLuaObject(obj);
				shit.updateHitbox();
				return;
			}

			final poop:FlxSprite = Reflect.getProperty(PlayState.getTargetInstance(), PlayState.convertVariableToNew(PlayState.getTargetInstanceName(), obj));

			if (poop != null)
			{
				poop.updateHitbox();
				return;
			}

			PlayState.debugTrace('updateHitbox: Couldnt find object: ' + obj, false, 'error', FlxColor.RED);
		});

		set("updateHitboxFromGroup", function(group:String, index:Int):Void
		{
			final daInstance:FlxState = PlayState.getTargetInstance();

			if (Std.isOfType(Reflect.getProperty(daInstance, group), FlxTypedGroup))
			{
				Reflect.getProperty(daInstance, group).members[index].updateHitbox();
				return;
			}

			Reflect.getProperty(daInstance, group)[index].updateHitbox();
		});

		set("removeLuaSprite", function(tag:String, destroy:Bool = true):Void
		{
			if (!game.modchartSprites.exists(tag)) {
				return;
			}

			final pee:Sprite = game.modchartSprites.get(tag);

			if (destroy) {
				pee.kill();
			}

			PlayState.getTargetInstance().remove(pee, true);

			if (destroy)
			{
				pee.destroy();
				game.modchartSprites.remove(tag);
			}
		});

		set("luaSpriteExists", game.modchartSprites.exists);

		set("makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float):Void
		{
			tag = tag.replace('.', '');
			PlayState.resetTextTag(tag);

			var leText:FlxText = new FlxText(x, y, width, text, 16);
			leText.setFormat(Paths.getFont("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			leText.cameras = [game.camHUD];
			leText.scrollFactor.set();
			leText.borderSize = 2;
			game.modchartTexts.set(tag, leText);
		});

		set("setTextString", function(tag:String, text:String):Bool
		{
			var obj:FlxText = PlayState.getTextObject(tag);

			if (obj != null)
			{
				obj.text = text;
				return true;
			}

			PlayState.debugTrace("setTextString: Object " + tag + " doesn't exist!", false, 'error', FlxColor.RED);
			return false;
		});

		set("setTextSize", function(tag:String, size:Int):Bool
		{
			var obj:FlxText = PlayState.getTextObject(tag);

			if (obj != null)
			{
				obj.size = size;
				return true;
			}

			PlayState.debugTrace("setTextSize: Object " + tag + " doesn't exist!", false, 'error', FlxColor.RED);
			return false;
		});

		set("setTextWidth", function(tag:String, width:Float):Bool
		{
			var obj:FlxText = PlayState.getTextObject(tag);

			if (obj != null)
			{
				obj.fieldWidth = width;
				return true;
			}

			PlayState.debugTrace("setTextWidth: Object " + tag + " doesn't exist!", false, 'error', FlxColor.RED);
			return false;
		});

		set("setTextBorder", function(tag:String, size:Int, color:String):Bool
		{
			var obj:FlxText = PlayState.getTextObject(tag);

			if (obj != null)
			{
				if (size > 0)
				{
					obj.borderStyle = OUTLINE;
					obj.borderSize = size;
				}
				else obj.borderStyle = NONE;

				obj.borderColor = CoolUtil.colorFromString(color);
				return true;
			}

			PlayState.debugTrace("setTextBorder: Object " + tag + " doesn't exist!", false, 'error', FlxColor.RED);
			return false;
		});

		set("setTextColor", function(tag:String, color:String):Bool
		{
			var obj:FlxText = PlayState.getTextObject(tag);

			if (obj != null)
			{
				obj.color = CoolUtil.colorFromString(color);
				return true;
			}

			PlayState.debugTrace("setTextColor: Object " + tag + " doesn't exist!", false, 'error', FlxColor.RED);
			return false;
		});

		set("setTextFont", function(tag:String, newFont:String):Bool
		{
			var obj:FlxText = PlayState.getTextObject(tag);

			if (obj != null)
			{
				obj.font = Paths.getFont(newFont);
				return true;
			}

			PlayState.debugTrace("setTextFont: Object " + tag + " doesn't exist!", false, 'error', FlxColor.RED);
			return false;
		});

		set("setTextItalic", function(tag:String, italic:Bool):Bool
		{
			var obj:FlxText = PlayState.getTextObject(tag);

			if (obj != null)
			{
				obj.italic = italic;
				return true;
			}

			PlayState.debugTrace("setTextItalic: Object " + tag + " doesn't exist!", false, 'error', FlxColor.RED);
			return false;
		});

		set("setTextAlignment", function(tag:String, alignment:String = 'left'):Bool
		{
			var obj:FlxText = PlayState.getTextObject(tag);
	
			if (obj != null)
			{
				obj.alignment = alignment.trim().toLowerCase();
				return true;
			}

			PlayState.debugTrace("setTextAlignment: Object " + tag + " doesn't exist!", false, 'error', FlxColor.RED);
			return false;
		});

		set("getTextString", function(tag:String):String
		{
			var obj:FlxText = PlayState.getTextObject(tag);

			if (obj != null && obj.text != null) {
				return obj.text;
			}

			PlayState.debugTrace("getTextString: Object " + tag + " doesn't exist!", false, 'error', FlxColor.RED);
			return null;
		});

		set("getTextSize", function(tag:String):Int
		{
			var obj:FlxText = PlayState.getTextObject(tag);

			if (obj != null) {
				return obj.size;
			}

			PlayState.debugTrace("getTextSize: Object " + tag + " doesn't exist!", false, 'error', FlxColor.RED);
			return -1;
		});

		set("getTextFont", function(tag:String):String
		{
			var obj:FlxText = PlayState.getTextObject(tag);

			if (obj != null) {
				return obj.font;
			}

			PlayState.debugTrace("getTextFont: Object " + tag + " doesn't exist!", false, 'error', FlxColor.RED);
			return null;
		});

		set("getTextWidth", function(tag:String):Float
		{
			var obj:FlxText = PlayState.getTextObject(tag);

			if (obj != null) {
				return obj.fieldWidth;
			}

			PlayState.debugTrace("getTextWidth: Object " + tag + " doesn't exist!", false, 'error', FlxColor.RED);
			return 0;
		});

		set("addLuaText", function(tag:String):Void
		{
			if (game.modchartTexts.exists(tag))
			{
				var shit:FlxText = game.modchartTexts.get(tag);
				PlayState.getTargetInstance().add(shit);
			}
		});

		set("removeLuaText", function(tag:String, destroy:Bool = true):Void
		{
			if (!game.modchartTexts.exists(tag)) {
				return;
			}

			var pee:FlxText = game.modchartTexts.get(tag);

			if (destroy) {
				pee.kill();
			}

			PlayState.getTargetInstance().remove(pee, true);

			if (destroy)
			{
				pee.destroy();
				game.modchartTexts.remove(tag);
			}
		});

		set("luaTextExists", game.modchartTexts.exists);

		set("playMusic", function(sound:String, volume:Float = 1, loop:Bool = false):Void
		{
			FlxG.sound.playMusic(Paths.getMusic(sound), volume, loop);
		});

		set("playSound", function(sound:String, volume:Float = 1, ?tag:String = null):Void
		{
			if (!Paths.fileExists('sounds/' + sound + '.' + Paths.SOUND_EXT, SOUND)) return;

			if (tag != null && tag.length > 0)
			{
				tag = tag.replace('.', '');

				if (game.modchartSounds.exists(tag)) {
					game.modchartSounds.get(tag).stop();
				}

				game.modchartSounds.set(tag, FlxG.sound.play(Paths.getSound(sound), volume, false, function():Void
				{
					game.modchartSounds.remove(tag);
					game.callOnLuas('onSoundFinished', [tag]);
				}));

				return;
			}

			FlxG.sound.play(Paths.getSound(sound), volume);
		});

		set("stopSound", function(tag:String):Void
		{
			if (tag != null && tag.length > 1 && game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).stop();
				game.modchartSounds.remove(tag);
			}
		});

		set("pauseSound", function(tag:String):Void
		{
			if (tag != null && tag.length > 1 && game.modchartSounds.exists(tag)) {
				game.modchartSounds.get(tag).pause();
			}
		});

		set("resumeSound", function(tag:String):Void
		{
			if (tag != null && tag.length > 1 && game.modchartSounds.exists(tag)) {
				game.modchartSounds.get(tag).play();
			}
		});

		set("soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1)
		{
			if (tag == null || tag.length < 1) {
				FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			}
			else if (game.modchartSounds.exists(tag)) {
				game.modchartSounds.get(tag).fadeIn(duration, fromValue, toValue);
			}
		});

		set("soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0):Void
		{
			if (tag == null || tag.length < 1) {
				FlxG.sound.music.fadeOut(duration, toValue);
			}
			else if (game.modchartSounds.exists(tag)) {
				game.modchartSounds.get(tag).fadeOut(duration, toValue);
			}
		});

		set("soundFadeCancel", function(tag:String):Void
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music.fadeTween != null) {
					FlxG.sound.music.fadeTween.cancel();
				}
			}
			else if (game.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = game.modchartSounds.get(tag);

				if (theSound.fadeTween != null)
				{
					theSound.fadeTween.cancel();
					game.modchartSounds.remove(tag);
				}
			}
		});

		set("getSoundVolume", function(tag:String):Float
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null) {
					return FlxG.sound.music.volume;
				}
			}
			else if (game.modchartSounds.exists(tag)) {
				return game.modchartSounds.get(tag).volume;
			}

			return 0;
		});

		set("setSoundVolume", function(tag:String, value:Float):Void
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null) {
					FlxG.sound.music.volume = value;
				}
			}
			else if (game.modchartSounds.exists(tag)) {
				game.modchartSounds.get(tag).volume = value;
			}
		});

		set("getSoundTime", function(tag:String):Float
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag)) {
				return game.modchartSounds.get(tag).time;
			}

			return 0;
		});

		set("setSoundTime", function(tag:String, value:Float):Void
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = game.modchartSounds.get(tag);
	
				if (theSound != null)
				{
					var wasResumed:Bool = theSound.playing;
					theSound.pause();
					theSound.time = value;

					if (wasResumed) theSound.play();
				}
			}
		});

		#if FLX_PITCH
		set("getSoundPitch", function(tag:String):Float
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag)) {
				return game.modchartSounds.get(tag).pitch;
			}

			return 0;
		});

		set("setSoundPitch", function(tag:String, value:Float, doPause:Bool = false):Void
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag)) 
			{
				var theSound:FlxSound = game.modchartSounds.get(tag);

				if (theSound != null)
				{
					var wasResumed:Bool = theSound.playing;
					if (doPause) theSound.pause();

					theSound.pitch = value;
					if (doPause && wasResumed) theSound.play();
				}
			}
		});
		#end

		set("luaSoundExists", game.modchartSounds.exists);

		set("setHealthBarColors", function(left:String, right:String):Void
		{
			PlayState.setBarColors(game.healthBar, left, right);
		});

		set("setTimeBarColors", function(left:String, right:String):Void
		{
			PlayState.setBarColors(game.timeBar, left, right);
		});

		set("setObjectCamera", function(obj:String, camera:String = ''):Bool
		{
			final real:FlxBasic = game.getLuaObject(obj);

			if (real != null)
			{
				real.cameras = [PlayState.cameraFromString(camera)];
				return true;
			}

			final split:Array<String> = obj.split('.');
			final object:FlxSprite = (split.length > 1) ? PlayState.getVarInArray(PlayState.getPropertyLoop(split), split[split.length - 1]) : PlayState.getObjectDirectly(split[0]);

			if (object != null)
			{
				object.cameras = [PlayState.cameraFromString(camera)];
				return true;
			}

			PlayState.debugTrace("setObjectCamera: Object " + obj + " doesn't exist!", false, 'error', FlxColor.RED);
			return false;
		});

		set("setBlendMode", function(obj:String, blend:String = ''):Bool
		{
			final real:Dynamic = game.getLuaObject(obj);

			if (real != null)
			{
				real.blend = PlayState.blendModeFromString(blend);
				return true;
			}

			final split:Array<String> = obj.split('.');
			final spr:FlxSprite = (split.length > 1) ? PlayState.getVarInArray(PlayState.getPropertyLoop(split), split[split.length - 1]) : PlayState.getObjectDirectly(split[0]);

			if (spr != null)
			{
				spr.blend = PlayState.blendModeFromString(blend);
				return true;
			}

			PlayState.debugTrace("setBlendMode: Object " + obj + " doesn't exist!", false, 'error', FlxColor.RED);
			return false;
		});

		set("screenCenter", function(obj:String, pos:String = 'xy'):Void
		{
			var spr:FlxSprite = game.getLuaObject(obj);

			if (spr == null)
			{
				final split:Array<String> = obj.split('.');
				spr = (split.length > 1) ? PlayState.getVarInArray(PlayState.getPropertyLoop(split), split[split.length - 1]) : PlayState.getObjectDirectly(split[0]);
			}

			if (spr != null)
			{
				try {
					spr.screenCenter(FlxAxes.fromString(pos));
				}
				catch (e:Error) PlayState.debugTrace("screenCenter: invalid axes: " + pos + "! - " + e.toString(), false, 'error', FlxColor.RED);

				return;
			}

			PlayState.debugTrace("screenCenter: Object " + obj + " doesn't exist!", false, 'error', FlxColor.RED);
		});

		set("objectsOverlap", function(obj1:String, obj2:String):Bool
		{
			final namesArray:Array<String> = [obj1, obj2];
			final objectsArray:Array<FlxSprite> = [];

			for (i in 0...namesArray.length)
			{
				final real:FlxSprite = game.getLuaObject(namesArray[i]);
	
				if (real != null) {
					objectsArray.push(real);
				}
				else {
					objectsArray.push(Reflect.getProperty(PlayState.getTargetInstance(), Reflect.getProperty(PlayState.getTargetInstance(), PlayState.convertVariableToNew(PlayState.getTargetInstanceName(), namesArray[i]))));
				}
			}

			return !objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]);
		});

		set("getPixelColor", function(obj:String, x:Int, y:Int):FlxColor
		{
			final split:Array<String> = obj.split('.');
			final spr:FlxSprite = (split.length > 1) ? PlayState.getVarInArray(PlayState.getPropertyLoop(split), split[split.length - 1]) : PlayState.getObjectDirectly(split[0]);

			if (spr != null) return spr.pixels.getPixel32(x, y);
			return FlxColor.BLACK;
		});

		set("startDialogue", function(dialogueFile:String, music:String = null):Bool
		{
			final path:String = Paths.getJson('data/' + PlayState.SONG.songID + '/' + dialogueFile);
			PlayState.debugTrace('startDialogue: Trying to load dialogue: ' + path);

			if (Paths.fileExists(path, TEXT))
			{
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);

				if (shit.dialogue.length > 0)
				{
					game.startDialogue(shit, music);
					PlayState.debugTrace('startDialogue: Successfully loaded dialogue', false, 'normal', FlxColor.GREEN);

					return true;
				}
				else {
					PlayState.debugTrace('startDialogue: Your dialogue file is badly formatted!', false, 'error', FlxColor.RED);
				}
			}
			else
			{
				PlayState.debugTrace('startDialogue: Dialogue file not found', false, 'error', FlxColor.RED);
				game.startAndEnd();
			}

			return false;
		});

		set("startVideo", function(videoFile:String):Bool
		{
			#if VIDEOS_ALLOWED
			if (Paths.fileExists(Paths.getVideo(videoFile), BINARY))
			{
				game.startVideo(videoFile);
				return true;
			}
			else
			{
				PlayState.debugTrace('startVideo: Video file not found: ' + videoFile, false, 'error', FlxColor.RED);
				game.startAndEnd();
				return false;
			}
			#end

			PlayState.debugTrace('Platform not supported!', false, 'error', FlxColor.RED);

			game.startAndEnd();
			return true;
		});

		set("keyboardJustPressed", function(name:String):Bool
		{
			return Reflect.getProperty(FlxG.keys.justPressed, name.toUpperCase()) == true;
		});

		set("keyboardPressed", function(name:String):Bool
		{
			return Reflect.getProperty(FlxG.keys.pressed, name.toUpperCase()) == true;
		});

		set("keyboardReleased", function(name:String):Bool
		{
			return Reflect.getProperty(FlxG.keys.justReleased, name.toUpperCase()) == true;
		});

		set("anyGamepadJustPressed", function(name:String):Bool
		{
			return FlxG.gamepads.anyJustPressed(name.toUpperCase());
		});

		set("anyGamepadPressed", function(name:String):Bool
		{
			return FlxG.gamepads.anyPressed(name.toUpperCase());
		});

		set("anyGamepadReleased", function(name:String):Bool
		{
			return FlxG.gamepads.anyJustReleased(name.toUpperCase());
		});

		set("gamepadAnalogX", function(id:Int, ?leftStick:Bool = true):Float
		{
			var controller:FlxGamepad = FlxG.gamepads.getByID(id);

			if (controller == null) {
				return 0.0;
			}

			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});

		set("gamepadAnalogY", function(id:Int, ?leftStick:Bool = true):Float
		{
			var controller:FlxGamepad = FlxG.gamepads.getByID(id);

			if (controller == null) {
				return 0.0;
			}

			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});

		set("gamepadJustPressed", function(id:Int, name:String):Bool
		{
			var controller:FlxGamepad = FlxG.gamepads.getByID(id);

			if (controller == null) {
				return false;
			}

			return Reflect.getProperty(controller.justPressed, name.toUpperCase()) == true;
		});

		set("gamepadPressed", function(id:Int, name:String):Bool
		{
			var controller:FlxGamepad = FlxG.gamepads.getByID(id);

			if (controller == null) {
				return false;
			}

			return Reflect.getProperty(controller.pressed, name.toUpperCase()) == true;
		});

		set("gamepadReleased", function(id:Int, name:String):Bool
		{
			var controller:FlxGamepad = FlxG.gamepads.getByID(id);

			if (controller == null) {
				return false;
			}

			return Reflect.getProperty(controller.justReleased, name.toUpperCase()) == true;
		});

		set("keyJustPressed", function(name:String = ''):Bool
		{
			name = name.toLowerCase();

			switch (name)
			{
				case 'left': return PlayState.instance.controls.NOTE_LEFT_P;
				case 'down': return PlayState.instance.controls.NOTE_DOWN_P;
				case 'up': return PlayState.instance.controls.NOTE_UP_P;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT_P;
				default: return PlayState.instance.controls.justPressed(name);
			}

			return false;
		});

		set("keyPressed", function(name:String = ''):Bool
		{
			name = name.toLowerCase();

			switch (name)
			{
				case 'left': return PlayState.instance.controls.NOTE_LEFT;
				case 'down': return PlayState.instance.controls.NOTE_DOWN;
				case 'up': return PlayState.instance.controls.NOTE_UP;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT;
				default: return PlayState.instance.controls.pressed(name);
			}

			return false;
		});

		set("keyReleased", function(name:String = ''):Bool
		{
			name = name.toLowerCase();

			switch (name)
			{
				case 'left': return PlayState.instance.controls.NOTE_LEFT_R;
				case 'down': return PlayState.instance.controls.NOTE_DOWN_R;
				case 'up': return PlayState.instance.controls.NOTE_UP_R;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT_R;
				default: return PlayState.instance.controls.justReleased(name);
			}

			return false;
		});

		set("initSaveData", function(name:String, ?folder:String = 'psychenginemods'):Void
		{
			if (!PlayState.instance.modchartSaves.exists(name))
			{
				var save:FlxSave = new FlxSave();
				save.bind(name, CoolUtil.getSavePath() + '/' + folder);

				PlayState.instance.modchartSaves.set(name, save);
				return;
			}

			PlayState.debugTrace('initSaveData: Save file already initialized: ' + name);
		});

		set("flushSaveData", function(name:String):Void
		{
			if (PlayState.instance.modchartSaves.exists(name))
			{
				PlayState.instance.modchartSaves.get(name).flush();
				return;
			}

			PlayState.debugTrace('flushSaveData: Save file not initialized: ' + name, false, 'error', FlxColor.RED);
		});

		set("getDataFromSave", function(name:String, field:String, ?defaultValue:Dynamic = null):Dynamic
		{
			if (PlayState.instance.modchartSaves.exists(name))
			{
				var saveData:Dynamic = PlayState.instance.modchartSaves.get(name).data;

				if (Reflect.hasField(saveData, field)) {
					return Reflect.getProperty(saveData, field);
				}
				else {
					return defaultValue;
				}
			}

			PlayState.debugTrace('getDataFromSave: Save file not initialized: ' + name, false, 'error', FlxColor.RED);
			return defaultValue;
		});

		set("setDataFromSave", function(name:String, field:String, value:Dynamic):Void
		{
			if (PlayState.instance.modchartSaves.exists(name))
			{
				Reflect.setProperty(PlayState.instance.modchartSaves.get(name).data, field, value);
				return;
			}

			PlayState.debugTrace('setDataFromSave: Save file not initialized: ' + name, false, 'error', FlxColor.RED);
		});

		set("eraseSaveData", function(name:String):Void
		{
			if (PlayState.instance.modchartSaves.exists(name))
			{
				PlayState.instance.modchartSaves.get(name).erase();
				return;
			}

			PlayState.debugTrace('eraseSaveData: Save file not initialized: ' + name, false, 'error', FlxColor.RED);
		});

		set("checkFileExists", function(filename:String):Bool
		{
			return Paths.fileExists(filename, null);
		});

		set("saveFile", function(path:String, content:String, ?absolute:Bool = false):Bool
		{
			try
			{
				#if MODS_ALLOWED
				if (!absolute) File.saveContent(Paths.mods(path), content);
				else #end File.saveContent(path, content);

				return true;
			}
			catch (e:Error) {
				PlayState.debugTrace("saveFile: Error trying to save " + path + ": " + e, false, 'error', FlxColor.RED);
			}

			return false;
		});

		set("deleteFile", function(path:String, ?ignoreModFolders:Bool = false):Bool
		{
			try
			{
				var lePath:String = Paths.getFile(path, TEXT, ignoreModFolders);

				if (Paths.fileExists(lePath, TEXT))
				{
					FileSystem.deleteFile(lePath);
					return true;
				}
			}
			catch (e:Error) {
				PlayState.debugTrace("deleteFile: Error trying to delete " + path + ": " + e, false, 'error', FlxColor.RED);
			}

			return false;
		});

		set("getTextFromFile", function(path:String, ?ignoreModFolders:Bool = false):String
		{
			return Paths.getTextFromFile(path, ignoreModFolders);
		});

		set("directoryFileList", function(folder:String):Array<String>
		{
			var list:Array<String> = [];

			#if sys
			if (FileSystem.exists(folder))
			{
				for (folder in FileSystem.readDirectory(folder))
				{
					if (!list.contains(folder)) {
						list.push(folder);
					}
				}
			}
			#end

			return list;
		});

		set("getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = ''):Int
		{
			return FlxG.random.int(min, max, [for (i in exclude.split(',')) Std.parseInt(i.trim())]);
		});

		set("getRandomFloat", function(min:Float, max:Float = 1, exclude:String = ''):Float
		{
			return FlxG.random.float(min, max, [for (i in exclude.split(',')) Std.parseFloat(i.trim())]);
		});

		set("getRandomBool", function(chance:Float = 50):Bool
		{
			return FlxG.random.bool(chance);
		});

		set("stringStartsWith", function(str:String, start:String):Bool
		{
			return str.startsWith(start);
		});

		set("stringEndsWith", function(str:String, end:String):Bool
		{
			return str.endsWith(end);
		});

		set("stringSplit", function(str:String, split:String):Array<String>
		{
			return str.split(split);
		});

		set("stringTrim", function(str:String):String
		{
			return str.trim();
		});

		// DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
		set("addAnimationByIndicesLoop", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24):Bool
		{
			PlayState.debugTrace("addAnimationByIndicesLoop is deprecated! Use addAnimationByIndices instead", false, 'deprecated');
			return PlayState.addAnimByIndices(obj, name, prefix, indices, framerate, true);
		});

		set("objectPlayAnimation", function(obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0):Bool
		{
			PlayState.debugTrace("objectPlayAnimation is deprecated! Use playAnim instead", false, 'deprecated');

			if (PlayState.instance.getLuaObject(obj, false) != null)
			{
				PlayState.instance.getLuaObject(obj, false).animation.play(name, forced, false, startFrame);
				return true;
			}

			var spr:FlxSprite = Reflect.getProperty(PlayState.getTargetInstance(), obj);

			if (spr != null)
			{
				spr.animation.play(name, forced, false, startFrame);
				return true;
			}

			return false;
		});

		set("characterPlayAnim", function(character:String, anim:String, ?forced:Bool = false):Void
		{
			PlayState.debugTrace("characterPlayAnim is deprecated! Use playAnim instead", false, 'deprecated');

			switch (character.toLowerCase())
			{
				case 'dad':
				{
					if (PlayState.instance.dad.animOffsets.exists(anim)) {
						PlayState.instance.dad.playAnim(anim, forced);
					}
				}
				case 'gf' | 'girlfriend':
				{
					if (PlayState.instance.gf != null && PlayState.instance.gf.animOffsets.exists(anim)) {
						PlayState.instance.gf.playAnim(anim, forced);
					}
				}
				default:
				{
					if (PlayState.instance.boyfriend.animOffsets.exists(anim)) {
						PlayState.instance.boyfriend.playAnim(anim, forced);
					}
				}
			}
		});

		set("luaSpriteMakeGraphic", function(tag:String, width:Int, height:Int, color:String):Void
		{
			PlayState.debugTrace("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", false, 'deprecated');

			if (PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).makeGraphic(width, height, CoolUtil.colorFromString(color));
			}
		});

		set("luaSpriteAddAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true):Void
		{
			PlayState.debugTrace("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", false, 'deprecated');

			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var cock:Sprite = PlayState.instance.modchartSprites.get(tag);
				cock.animation.addByPrefix(name, prefix, framerate, loop);

				if (cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});

		set("luaSpriteAddAnimationByIndices", function(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24):Void
		{
			PlayState.debugTrace("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", false, 'deprecated');

			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var strIndices:Array<String> = indices.trim().split(',');
				var die:Array<Int> = [];
	
				for (i in 0...strIndices.length) {
					die.push(Std.parseInt(strIndices[i]));
				}
	
				var pussy:Sprite = PlayState.instance.modchartSprites.get(tag);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);

				if (pussy.animation.curAnim == null) {
					pussy.animation.play(name, true);
				}
			}
		});

		set("luaSpritePlayAnimation", function(tag:String, name:String, forced:Bool = false):Void
		{
			PlayState.debugTrace("luaSpritePlayAnimation is deprecated! Use playAnim instead", false, 'deprecated');

			if (PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).animation.play(name, forced);
			}
		});

		set("setLuaSpriteCamera", function(tag:String, camera:String = ''):Bool
		{
			PlayState.debugTrace("setLuaSpriteCamera is deprecated! Use setObjectCamera instead", false, 'deprecated');

			if (PlayState.instance.modchartSprites.exists(tag))
			{
				PlayState.instance.modchartSprites.get(tag).cameras = [PlayState.cameraFromString(camera)];
				return true;
			}

			PlayState.debugTrace("Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});

		set("setLuaSpriteScrollFactor", function(tag:String, scrollX:Float, scrollY:Float):Bool
		{
			PlayState.debugTrace("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead", false, 'deprecated');

			if (PlayState.instance.modchartSprites.exists(tag))
			{
				PlayState.instance.modchartSprites.get(tag).scrollFactor.set(scrollX, scrollY);
				return true;
			}

			return false;
		});

		set("scaleLuaSprite", function(tag:String, x:Float, y:Float):Bool
		{
			PlayState.debugTrace("scaleLuaSprite is deprecated! Use scaleObject instead", false, 'deprecated');

			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var shit:Sprite = PlayState.instance.modchartSprites.get(tag);
				shit.scale.set(x, y);
				shit.updateHitbox();
				return true;
			}

			return false;
		});

		set("getPropertyLuaSprite", function(tag:String, variable:String):Dynamic
		{
			PlayState.debugTrace("getPropertyLuaSprite is deprecated! Use getProperty instead", false, 'deprecated');

			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var killMe:Array<String> = variable.split('.');

				if (killMe.length > 1)
				{
					var coverMeInPiss:Dynamic = Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), killMe[0]);

					for (i in 1...killMe.length - 1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
	
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length - 1]);
				}

				return Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), variable);
			}

			return null;
		});

		set("setPropertyLuaSprite", function(tag:String, variable:String, value:Dynamic):Bool
		{
			PlayState.debugTrace("setPropertyLuaSprite is deprecated! Use setProperty instead", false, 'deprecated');

			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var killMe:Array<String> = variable.split('.');
	
				if (killMe.length > 1)
				{
					var coverMeInPiss:Dynamic = Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), killMe[0]);

					for (i in 1...killMe.length - 1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}

					Reflect.setProperty(coverMeInPiss, killMe[killMe.length - 1], value);
					return true;
				}

				Reflect.setProperty(PlayState.instance.modchartSprites.get(tag), variable, value);
				return true;
			}

			PlayState.debugTrace("setPropertyLuaSprite: Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});

		set("musicFadeIn", function(duration:Float, fromValue:Float = 0, toValue:Float = 1):Void
		{
			FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			PlayState.debugTrace('musicFadeIn is deprecated! Use soundFadeIn instead.', false, 'deprecated');
		});

		set("musicFadeOut", function(duration:Float, toValue:Float = 0):Void
		{
			FlxG.sound.music.fadeOut(duration, toValue);
			PlayState.debugTrace('musicFadeOut is deprecated! Use soundFadeOut instead.', false, 'deprecated');
		});

		set("debugPrint", function(text:Dynamic = '', color:String = 'WHITE'):Void
		{
			PlayState.instance.addTextToDebug(text, CoolUtil.colorFromString(color));
		});

		addLocalCallback("close", function():Bool
		{
			closed = true;

			Debug.logInfo('Closing script $scriptName');
			return closed;
		});

		#if DISCORD_ALLOWED
		DiscordClient.implementForLua(this);
		#end

		#if HSCRIPT_ALLOWED
		HScript.implementForLua(this);
		#end

		#if ACHIEVEMENTS_ALLOWED
		Achievements.implementForLua(this);
		#end

		CustomSubState.implementForLua(this);

		try
		{
			final isString:Bool = !Paths.fileExists(scriptName, TEXT);
			final result:Dynamic = (!isString ? LuaL.dofile(lua, scriptName.substr(scriptName.indexOf(':') + 1)) : LuaL.dostring(lua, scriptName));

			final resultStr:String = Lua.tostring(lua, result);

			if (resultStr != null && result != 0)
			{
				Debug.logError(resultStr);

				#if windows
				Debug.displayAlert('Error on lua script!', resultStr);
				#else
				PlayState.debugTrace('$scriptName\n$resultStr', true, 'error', FlxColor.RED);
				#end

				lua = null;
				return;
			}

			if (isString) scriptName = 'unknown';
		}
		catch (e:Error)
		{
			Debug.logError(e);
			return;
		}

		Debug.logInfo('lua file loaded succesfully: ' + scriptName);

		call('onCreate', []);
		#end
	}

	public var lastCalledFunction:String = ''; // main

	public function call(func:String, args:Array<Dynamic>):Dynamic
	{
		#if LUA_ALLOWED
		if (closed) return PlayState.Function_Continue;

		lastCalledFunction = func;
		lastCalledScript = this;

		try
		{
			if (lua == null) return PlayState.Function_Continue;

			Lua.getglobal(lua, func);
			var type:Int = Lua.type(lua, -1);

			if (type != Lua.LUA_TFUNCTION)
			{
				if (type > Lua.LUA_TNIL) {
					PlayState.debugTrace("ERROR (" + func + "): attempt to call a " + typeToString(type) + " value", false, 'error', FlxColor.RED);
				}

				Lua.pop(lua, 1);
				return PlayState.Function_Continue;
			}

			for (arg in args) Convert.toLua(lua, arg);
			final status:Int = Lua.pcall(lua, args.length, 1, 0);

			if (status != Lua.LUA_OK) // Checks if it's not successful, then show a error.
			{
				final error:String = getErrorMessage(status);
				PlayState.debugTrace("ERROR (" + func + "): " + error, false, 'error', FlxColor.RED);
				return PlayState.Function_Continue;
			}

			var result:Dynamic = cast Convert.fromLua(lua, -1); // If successful, pass and then return the result.
			if (result == null) result = PlayState.Function_Continue;

			Lua.pop(lua, 1);
			if (closed) stop();

			return result;
		}
		catch (e:Error) {
			Debug.logError(e);
		}
		#end

		return PlayState.Function_Continue;
	}
	
	public function set(variable:String, data:Dynamic):Void
	{
		#if LUA_ALLOWED
		if (lua == null) return;

		if (Type.typeof(data) == TFunction)
		{
			Lua_helper.add_callback(lua, variable, data);
			return;
		}

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
		#end
	}

	public function stop():Void
	{
		#if LUA_ALLOWED
		closed = true;

		if (lua == null) {
			return;
		}

		Lua.close(lua);
		lua = null;

		#if HSCRIPT_ALLOWED
		if (hscript != null)
		{
			hscript.active = false;
			hscript.destroy();
			hscript = null;
		}
		#end
		#end
	}

	function oldTweenFunction(tag:String, vars:String, tweenValue:Any, duration:Float, ease:String, funcName:String):Void
	{
		#if LUA_ALLOWED
		final target:Dynamic = PlayState.tweenPrepare(tag, vars);

		if (target != null)
		{
			PlayState.instance.modchartTweens.set(tag, FlxTween.tween(target, tweenValue, duration,
			{
				ease: PlayState.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween):Void
				{
					PlayState.instance.modchartTweens.remove(tag);
					PlayState.instance.callOnLuas('onTweenCompleted', [tag, vars]);
				}
			}));
		}
		else {
			PlayState.debugTrace('$funcName: Couldnt find object: $vars', false, 'error', FlxColor.RED);
		}
		#end
	}

	#if LUA_ALLOWED
	public static function getBool(variable:String):Bool
	{
		if (lastCalledScript == null) return false;

		final lua:State = lastCalledScript.lua;
		if (lua == null) return false;

		Lua.getglobal(lua, variable);

		final result:String = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if (result == null) {
			return false;
		}

		return (result == 'true');
	}
	#end

	function findScript(scriptFile:String, ext:String = '.lua'):String
	{
		if (!scriptFile.endsWith(ext)) scriptFile += ext;

		final path:String = Paths.getFile(scriptFile);

		if (Paths.fileExists(path, TEXT)) {
			return path;
		}

		return null;
	}

	public function getErrorMessage(status:Int):String
	{
		#if LUA_ALLOWED
		var v:String = Lua.tostring(lua, -1);
		Lua.pop(lua, 1);

		if (v != null) v = v.trim();

		if (v == null || v.length < 1)
		{
			switch (status)
			{
				case Lua.LUA_ERRRUN: return "Runtime Error";
				case Lua.LUA_ERRMEM: return "Memory Allocation Error";
				case Lua.LUA_ERRERR: return "Critical Error";
			}

			return "Unknown Error";
		}

		return v;
		#end

		return null;
	}

	public function addLocalCallback(name:String, myFunction:Dynamic):Void
	{
		#if LUA_ALLOWED
		callbacks.set(name, myFunction);
		Lua_helper.add_callback(lua, name, null); // just so that it gets called
		#end
	}

	#if (LUA_ALLOWED && desktop && RUNTIME_SHADERS_ALLOWED)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();

	public function getShader(obj:String):FlxRuntimeShader
	{
		var split:Array<String> = obj.split('.');
		var target:FlxSprite = null;

		if (split.length > 1) {
			target = PlayState.getVarInArray(PlayState.getPropertyLoop(split), split[split.length - 1]);
		}
		else {
			target = PlayState.getObjectDirectly(split[0]);
		}

		if (target != null) {
			return cast (target.shader, FlxRuntimeShader);
		}

		PlayState.debugTrace('Error on getting shader: Object $obj not found', false, 'error', FlxColor.RED);
		return null;
	}
	#end

	public function initLuaShader(name:String, ?glslVersion:Int = 120):Bool
	{
		if (ClientPrefs.shadersEnabled)
		{
			#if (LUA_ALLOWED && desktop && RUNTIME_SHADERS_ALLOWED)
			if (runtimeShaders.exists(name))
			{
				PlayState.debugTrace('Shader $name was already initialized!');
				return true;
			}

			final foldersToCheck:Array<String> = [Paths.getPreloadPath('shaders/')];

			if (Paths.currentLevel != null && Paths.currentLevel.length > 0)
			{
				var libraryPath:String = Paths.getLibraryPath('shaders/', 'shared');
				foldersToCheck.insert(0, libraryPath.substring(libraryPath.indexOf(':') + 1, libraryPath.length));

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

			PlayState.debugTrace('Missing shader $name .frag AND .vert files!', false, 'error', FlxColor.RED);
			#else
			PlayState.debugTrace('This platform doesn\'t support Runtime Shaders!', false, 'error', FlxColor.RED);
			#end
		}

		return false;
	}

	public function typeToString(type:Int):String
	{
		#if LUA_ALLOWED
		switch (type)
		{
			case Lua.LUA_TBOOLEAN: return "boolean";
			case Lua.LUA_TNUMBER: return "number";
			case Lua.LUA_TSTRING: return "string";
			case Lua.LUA_TTABLE: return "table";
			case Lua.LUA_TFUNCTION: return "function";
		}

		if (type <= Lua.LUA_TNIL) return "nil";
		#end

		return "unknown";
	}
}