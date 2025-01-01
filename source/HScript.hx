package;

import flixel.FlxG;
import openfl.errors.Error;
import flixel.util.FlxColor;
import flixel.input.gamepad.FlxGamepad;

#if HSCRIPT_ALLOWED
import hscript.Parser;
import hscript.Interp;
#end

using StringTools;

#if HSCRIPT_ALLOWED
class HScript extends Interp
{
	public var active:Bool = true;
	public var parser:Parser;

	#if LUA_ALLOWED
	public var parentLua(default, set):FunkinLua = null;
	#end

	#if MODS_ALLOWED
	public var modFolder:String;
	#end
	
	public var exception:Error;

	#if LUA_ALLOWED
	public static function initHaxeModuleForLua(parent:FunkinLua):Void
	{
		#if HSCRIPT_ALLOWED
		if (parent.hscript == null)
		{
			Debug.logInfo('initializing haxe interp for: ${parent.scriptName}');

			parent.hscript = new HScript();
			parent.hscript.parentLua = parent;
		}
		#end
	}

	public static function initHaxeModuleCodeForLua(parent:FunkinLua, code:String):Void
	{
		initHaxeModuleForLua(parent);

		if (parent.hscript != null) {
			parent.hscript.executeCode(code);
		}
	}
	#end

	public var origin:String;

	public function new(?file:String):Void
	{
		super();

		var content:String = null;

		if (file != null && file.trim().length > 0)
		{
			content = Paths.getTextFromFile(file);

			#if MODS_ALLOWED
			var myFolder:Array<String> = file.split('/');

			if (myFolder[0] + '/' == Paths.mods() && (Paths.currentModDirectory == myFolder[1] || Paths.globalMods.contains(myFolder[1]))) { // is inside mods folder
				this.modFolder = myFolder[1];
			}
			#end
		}

		if (content != null && content.trim().length > 0) {
			origin = file;
		}

		preset();
		executeCode(content);
	}

	function preset():Void
	{
		parser = new Parser();
		parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;

		scriptObject = PlayState.instance; // allow use vars from playstate without "game" thing

		setVar('Date', Date);
		setVar('DateTools', DateTools);
		setVar('Math', Math);
		setVar('Reflect', Reflect);
		setVar('Std', Std);
		setVar('HScript', HScript);
		setVar('StringTools', StringTools);
		setVar('Type', Type);

		#if sys
		setVar('File', sys.io.File);
		setVar('FileSystem', sys.FileSystem);
		setVar('Sys', Sys);
		#end

		setVar('Assets', openfl.Assets);

		// Some very commonly used classes
		setVar('FlxG', flixel.FlxG);
		setVar('SwagCamera', SwagCamera);
		setVar('PsychCamera', SwagCamera);
		setVar('FlxSprite', flixel.FlxSprite);
		setVar('FlxCamera', flixel.FlxCamera);
		setVar('FlxTimer', flixel.util.FlxTimer);
		setVar('FlxTween', flixel.tweens.FlxTween);
		setVar('FlxEase', flixel.tweens.FlxEase);
		setVar('FlxColor', CustomFlxColor);
		setVar('PlayState', PlayState);
		setVar('Sprite', Sprite);
		setVar('Paths', Paths);
		setVar('Conductor', Conductor);
		setVar('ClientPrefs', ClientPrefs);
		#if ACHIEVEMENTS_ALLOWED
		setVar('Achievements', Achievements);
		#end
		setVar('Character', Character);
		setVar('Alphabet', Alphabet);
		setVar('Note', Note);
		setVar('CustomSubState', CustomSubState);
		setVar('CustomSubstate', CustomSubState);
		#if RUNTIME_SHADERS_ALLOWED
		setVar('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		#end
		setVar('ShaderFilter', openfl.filters.ShaderFilter);

		// Functions & Variables
		setVar('setVar', PlayState.setVar);
		setVar('getVar', PlayState.getVar);
		setVar('removeVar', PlayState.removeVar);

		setVar('debugPrint', function(text:String, ?color:FlxColor = null):Void
		{
			if (color == null) color = FlxColor.WHITE;
			PlayState.instance.addTextToDebug(text, color);
		});

		setVar('keyboardJustPressed', function(name:String):Bool return Reflect.getProperty(FlxG.keys.justPressed, name));
		setVar('keyboardPressed', function(name:String):Bool return Reflect.getProperty(FlxG.keys.pressed, name));
		setVar('keyboardReleased', function(name:String):Bool return Reflect.getProperty(FlxG.keys.justReleased, name));

		setVar('anyGamepadJustPressed', function(name:String):Bool return FlxG.gamepads.anyJustPressed(name));
		setVar('anyGamepadPressed', function(name:String):Bool return FlxG.gamepads.anyPressed(name));
		setVar('anyGamepadReleased', function(name:String):Bool return FlxG.gamepads.anyJustReleased(name));

		setVar('gamepadAnalogX', function(id:Int, ?leftStick:Bool = true):Float
		{
			var controller:FlxGamepad = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});

		setVar('gamepadAnalogY', function(id:Int, ?leftStick:Bool = true):Float
		{
			var controller:FlxGamepad = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});

		setVar('gamepadJustPressed', function(id:Int, name:String):Bool
		{
			var controller:FlxGamepad = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justPressed, name) == true;
		});

		setVar('gamepadPressed', function(id:Int, name:String):Bool
		{
			var controller:FlxGamepad = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.pressed, name) == true;
		});

		setVar('gamepadReleased', function(id:Int, name:String):Bool
		{
			var controller:FlxGamepad = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justReleased, name) == true;
		});

		setVar('keyJustPressed', function(name:String = ''):Bool
		{
			name = name.toLowerCase();

			switch (name)
			{
				case 'left': return Controls.instance.NOTE_LEFT_P;
				case 'down': return Controls.instance.NOTE_DOWN_P;
				case 'up': return Controls.instance.NOTE_UP_P;
				case 'right': return Controls.instance.NOTE_RIGHT_P;
				default: return Controls.instance.justPressed(name);
			}

			return false;
		});

		setVar('keyPressed', function(name:String = ''):Bool
		{
			name = name.toLowerCase();

			switch (name)
			{
				case 'left': return Controls.instance.NOTE_LEFT;
				case 'down': return Controls.instance.NOTE_DOWN;
				case 'up': return Controls.instance.NOTE_UP;
				case 'right': return Controls.instance.NOTE_RIGHT;
				default: return Controls.instance.pressed(name);
			}

			return false;
		});

		setVar('keyReleased', function(name:String = ''):Bool
		{
			name = name.toLowerCase();

			switch (name)
			{
				case 'left': return Controls.instance.NOTE_LEFT_R;
				case 'down': return Controls.instance.NOTE_DOWN_R;
				case 'up': return Controls.instance.NOTE_UP_R;
				case 'right': return Controls.instance.NOTE_RIGHT_R;
				default: return Controls.instance.justReleased(name);
			}

			return false;
		});

		// For adding your own callbacks

		setVar('createGlobalCallback', function(name:String, func:Dynamic):Void // not very tested but should work
		{
			#if LUA_ALLOWED
			for (script in PlayState.instance.luaArray)
			{
				if (script != null && script.lua != null && !script.closed) {
					script.set(name, func);
				}
			}
			#end

			PlayState.customFunctions.set(name, func);
		});

		// tested
		#if LUA_ALLOWED
		setVar('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null):Void
		{
			if (funk == null) funk = parentLua;
			
			if (funk != null) {
				funk.addLocalCallback(name, func);
			}
			else PlayState.debugTrace('createCallback ($name): 3rd argument is null', false, 'error', FlxColor.RED);
		});
		#end

		setVar('addHaxeLibrary', function(libName:String, ?libPackage:String = ''):Void
		{
			try
			{
				var str:String = '';

				if (libPackage.length > 0) {
					str = libPackage + '.';
				}

				setVar(libName, Type.resolveClass(str + libName));
			}
			catch (e:Error)
			{
				var msg:String = e.message.substr(0, e.message.indexOf('\n'));

				#if LUA_ALLOWED if (parentLua != null)
				{
					FunkinLua.lastCalledScript = parentLua;
					msg = origin + ":" + parentLua.lastCalledFunction + " - " + msg;
				}
				else #end msg = '$origin - $msg';

				PlayState.debugTrace(msg, #if LUA_ALLOWED parentLua == null #else true #end, 'error', FlxColor.RED);
			}
		});

		#if LUA_ALLOWED
		setVar('parentLua', parentLua);
		#else
		setVar('parentLua', null);
		#end

		setVar('this', this);
		setVar('game', PlayState.instance);
		setVar('buildTarget', CoolUtil.getBuildTarget());
		setVar('customSubstate', CustomSubState.instance);
		setVar('customSubstateName', CustomSubState.name);

		setVar('Function_Stop', PlayState.Function_Stop);
		setVar('Function_Continue', PlayState.Function_Continue);

		#if LUA_ALLOWED
		setVar('Function_StopLua', PlayState.Function_StopLua);
		#end

		setVar('Function_StopHScript', PlayState.Function_StopHScript);
		setVar('Function_StopAll', PlayState.Function_StopAll);

		setVar('add', FlxG.state.add);
		setVar('insert', FlxG.state.insert);
		setVar('remove', FlxG.state.remove);

		if (PlayState.instance == FlxG.state)
		{
			setVar('addBehindGF', PlayState.instance.addBehindGF);
			setVar('addBehindDad', PlayState.instance.addBehindDad);
			setVar('addBehindBF', PlayState.instance.addBehindBF);
		}
	}

	public function executeCode(?codeToRun:String):Dynamic
	{
		if (codeToRun != null && active)
		{
			try {
				return execute(parser.parseString(codeToRun, origin));
			}
			catch (e:Error) {
				exception = e;
			}
		}

		return null;
	}

	public function executeFunction(funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic
	{
		if (funcToRun != null && active)
		{
			if (variables.exists(funcToRun))
			{
				if (funcArgs == null) funcArgs = [];

				try {
					return Reflect.callMethod(null, variables.get(funcToRun), funcArgs);
				}
				catch (e:Error) {
					exception = e;
				}
			}
		}

		return null;
	}

	#if LUA_ALLOWED
	public static function implementForLua(funk:FunkinLua):Void
	{
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic
		{
			initHaxeModuleForLua(funk);

			if (funk.hscript.active)
			{
				if (varsToBring != null)
				{
					for (key in Reflect.fields(varsToBring)) {
						funk.hscript.setVar(key, Reflect.field(varsToBring, key));
					}
				}

				var retVal:Dynamic = funk.hscript.executeCode(codeToRun);

				if (funcToRun != null)
				{
					var retFunc:Dynamic = funk.hscript.executeFunction(funcToRun, funcArgs);

					if (retFunc != null) {
						retVal = retFunc;
					}
				}

				if (funk.hscript.exception != null)
				{
					funk.hscript.active = false;
					PlayState.debugTrace('ERROR (${funk.lastCalledFunction}) - ${funk.hscript.exception}', false, 'error', FlxColor.RED);
				}

				return retVal;
			}

			return null;
		});
		
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null):Null<Dynamic>
		{
			if (funk.hscript.active)
			{
				var retVal:Dynamic = funk.hscript.executeFunction(funcToRun, funcArgs);

				if (funk.hscript.exception != null)
				{
					funk.hscript.active = false;
					PlayState.debugTrace('ERROR (${funk.lastCalledFunction}) - ${funk.hscript.exception}', false, 'error', FlxColor.RED);
				}
	
				return retVal;
			}

			return null;
		});

		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = ''):Void // This function is unnecessary because import already exists in HScript as a native feature
		{
			initHaxeModuleForLua(funk);

			if (funk.hscript.active)
			{
				var str:String = '';

				if (libPackage.length > 0) {
					str = libPackage + '.';
				}
				else if (libName == null) {
					libName = '';
				}
	
				var c:Dynamic = funk.hscript.resolveClassOrEnum(str + libName);
	
				try {
					funk.hscript.setVar(libName, c);
				}
				catch (e:Error)
				{
					funk.hscript.active = false;
					PlayState.debugTrace('ERROR (${funk.lastCalledFunction}) - $e', false, 'error', FlxColor.RED);
				}
			}
		});
	}
	#end

	function resolveClassOrEnum(name:String):Dynamic
	{
		var c:Dynamic = Type.resolveClass(name);

		if (c == null) {
			c = Type.resolveEnum(name);
		}

		return c;
	}

	public function destroy():Void
	{
		active = false;
		parser = null;
		origin = null;

		#if LUA_ALLOWED
		parentLua = null;
		#end

		__instanceFields = [];
		binops.clear();
		customClasses.clear();
		declared = [];
		importBlocklist = [];
		locals.clear();

		resetVariables();
	}

	#if LUA_ALLOWED
	private function set_parentLua(newLua:FunkinLua):FunkinLua
	{
		if (newLua != null)
		{
			if (newLua != null)
			{
				origin = newLua.scriptName;
				#if MODS_ALLOWED
				modFolder = newLua.modFolder;
				#end
			}

			parentLua = newLua;
			setVar('parentLua', parentLua);
		}

		return null;
	}
	#end
}
#end