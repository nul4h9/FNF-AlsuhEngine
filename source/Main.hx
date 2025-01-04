package;

#if (!windows && !macos && !linux && !html5 && !hl)
#error "Only Windows, HTML5, Linux, MacOS and Hashlink supported for this game."
#end

import haxe.io.Path;
import haxe.Exception;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

#if !mobile
import debug.FPSCounter;
#end

#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end

#if (sys && CRASH_HANDLER)
#if hl
import haxe.EnumFlags;
import haxe.Exception;
#end
import sys.io.File;
import sys.FileSystem;
import haxe.CallStack;
import openfl.events.UncaughtErrorEvent;
#end

#if linux
import lime.graphics.Image;
#end

import openfl.Lib;
import flixel.FlxG;
import flixel.FlxGame;
import openfl.events.Event;
import openfl.errors.Error;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;

using StringTools;

#if linux
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end
class Main extends Sprite
{
	public static var game:FlxGame;

	var gameVars = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	#if !mobile
	public static var fpsCounter:FPSCounter;
	#end

	public static function main():Void
	{
		#if DARK_MODE_WINDOW
		debug.DarkMode.setDarkMode(Lib.current.stage.application.window.title, true);
		#end

		Lib.current.addChild(new Main());
	}

	public function new():Void
	{
		super();

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?e:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (gameVars.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / gameVars.width;
			var ratioY:Float = stageHeight / gameVars.height;
			gameVars.zoom = Math.min(ratioX, ratioY);
			gameVars.width = Math.ceil(stageWidth / gameVars.zoom);
			gameVars.height = Math.ceil(stageHeight / gameVars.zoom);
		}

		ClientPrefs.loadDefaultSettings();
		Controls.instance = new Controls();

		Debug.onInitProgram();

		#if LUA_ALLOWED
		Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(callLuaFunction));
		#end

		game = new FlxGame(gameVars.width,
			gameVars.height,
			gameVars.initialState,
			gameVars.framerate,
			gameVars.framerate,
			gameVars.skipSplash,
			gameVars.startFullscreen);
		addChild(game);

		#if !mobile
		fpsCounter = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsCounter);

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		#end

		#if linux
		var icon:Image = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if (sys && CRASH_HANDLER)
		#if hl
		hl.Api.setErrorHandler(onCrash);
		#else
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		FlxG.signals.gameResized.add(function(w:Int, h:Int):Void
		{
			if (FlxG.cameras != null)
			{
				for (cam in FlxG.cameras.list)
				{
					if (cam != null && cam.filters != null)
						resetSpriteCache(cam.flashSprite);
				}
			}

			if (FlxG.game != null) resetSpriteCache(FlxG.game);
		});
	}

	#if LUA_ALLOWED
	private static function callLuaFunction(l:State, fname:String):Int
	{
		try
		{
			var cbf:Dynamic = Lua_helper.callbacks.get(fname);

			// Local functions have the lowest priority
			// This is to prevent a "for" loop being called in every single operation,
			// so that it only loops on reserved/special functions

			if (cbf == null)
			{
				var last:FunkinLua = FunkinLua.lastCalledScript;

				if (last == null || last.lua != l)
				{
					for (script in PlayState.instance.luaArray)
					{
						if (script != FunkinLua.lastCalledScript && script != null && script.lua == l)
						{
							cbf = script.callbacks.get(fname);
							break;
						}
					}
				}
				else {
					cbf = last.callbacks.get(fname);
				}
			}

			if (cbf == null) return 0;

			var nparams:Int = Lua.gettop(l);
			var args:Array<Dynamic> = [];

			for (i in 0...nparams) {
				args[i] = Convert.fromLua(l, i + 1);
			}

			var ret:Dynamic = null; /* return the number of results */

			ret = Reflect.callMethod(null, cbf, args);

			if (ret != null)
			{
				Convert.toLua(l, ret);
				return 1;
			}
		}
		catch (e:Dynamic)
		{
			if (Lua_helper.sendErrorsToLua)
			{
				LuaL.error(l, 'CALLBACK ERROR! ' + e.message != null ? e.message : e);
				return 0;
			}

			throw new Error(e);
		}

		return 0;
	}
	#end

	static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess
		{
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	#if (sys && CRASH_HANDLER)
	/**
	 * Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	 * very cool person for real they don't get enough credit for their work
	 */
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var message:String = '';

		if ((e is UncaughtErrorEvent))
			message = e.error;
		else
			message = try Std.string(e) catch (_:Exception) "Unknown";

		var errMsg:String = '';
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(' ', '_');
		dateNow = dateNow.replace(':', "'");

		path = './crash/' + 'AlsuhEngine_' + dateNow + '.txt';

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column): errMsg += file + ' (line ' + line + ')\n';
				default: #if sys Sys.println(stackItem); #end
			}
		}

		errMsg += '\nUncaught Error: ' + message + '\nPlease report this error to the GitHub page: https://github.com/nul4h9/FNF-AlsuhEngine\n\n> Crash Handler written by: sqirra-rng';

		if (!FileSystem.exists('./crash/')) {
			FileSystem.createDirectory('./crash/');
		}

		File.saveContent(path, errMsg + '\n');

		Sys.println(errMsg);
		Sys.println('Crash dump saved in ' + Path.normalize(path));

		#if hl
		var flags:EnumFlags<hl.UI.DialogFlags> = new EnumFlags<hl.UI.DialogFlags>();
		flags.set(IsError);
		hl.UI.dialog("Error!", errMsg, flags);
		#else
		Debug.displayAlert('Error!', errMsg);
		#end

		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end

		Sys.exit(1);
	}
	#end
}