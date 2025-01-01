package;

import haxe.Log;
import haxe.PosInfos;

#if (sys && desktop)
import sys.io.File;
import sys.FileSystem;
import sys.io.FileOutput;
#end

import flixel.FlxG;
import flixel.util.FlxStringUtil;
import flixel.system.debug.log.LogStyle;

using StringTools;

class Debug // stolen from kade engine
{
	static final LOG_STYLE_ERROR:LogStyle = new LogStyle('[ERROR] ', 'FF8888', 12, true, false, false, 'flixel/sounds/beep', true);
	static final LOG_STYLE_WARN:LogStyle = new LogStyle('[WARN] ', 'D9F85C', 12, true, false, false, 'flixel/sounds/beep', true);
	static final LOG_STYLE_INFO:LogStyle = new LogStyle('[INFO] ', '5CF878', 12, false);
	static final LOG_STYLE_TRACE:LogStyle = new LogStyle('[TRACE] ', '5CF878', 12, false);

	static var logFileWriter:DebugLogWriter = null;

	/**
	 * Log an error message to the game's console.
	 * Plays a beep to the user and forces the console open if this is a debug build.
	 * @param input The message to display.
	 * @param pos This magic type is auto-populated, and includes the line number and class it was called from.
	 */
	public static inline function logError(input:Dynamic, ?pos:PosInfos):Void
	{
		if (input == null) return;

		var output:Array<Dynamic> = formatOutput(input, pos);

		writeToFlxGLog(output, LOG_STYLE_ERROR);
		writeToLogFile(output, 'ERROR');
	}

	/**
	 * Log an warning message to the game's console.
	 * Plays a beep to the user and forces the console open if this is a debug build.
	 * @param input The message to display.
	 * @param pos This magic type is auto-populated, and includes the line number and class it was called from.
	 */
	public static inline function logWarn(input:Dynamic, ?pos:PosInfos):Void
	{
		if (input == null) return;

		var output:Array<Dynamic> = formatOutput(input, pos);

		writeToFlxGLog(output, LOG_STYLE_WARN);
		writeToLogFile(output, 'WARN');
	}

	/**
	 * Log an info message to the game's console. Only visible in debug builds.
	 * @param input The message to display.
	 * @param pos This magic type is auto-populated, and includes the line number and class it was called from.
	 */
	public static inline function logInfo(input:Dynamic, ?pos:PosInfos):Void
	{
		if (input == null) return;

		var output:Array<Dynamic> = formatOutput(input, pos);

		writeToFlxGLog(output, LOG_STYLE_INFO);
		writeToLogFile(output, 'INFO');
	}

	/**
	 * Log a debug message to the game's console. Only visible in debug builds.
	 * NOTE: We redirect all Haxe `trace()` calls to this function.
	 * @param input The message to display.
	 * @param pos This magic type is auto-populated, and includes the line number and class it was called from.
	 */
	public static function logTrace(input:Dynamic, ?pos:PosInfos):Void
	{
		if (input == null) return;

		var output = formatOutput(input, pos);

		writeToFlxGLog(output, LOG_STYLE_TRACE);
		writeToLogFile(output, 'TRACE');
	}

	/**
	 * Displays a popup with the provided text.
	 * This interrupts the game, so make sure it's REALLY important.
	 * @param title The title of the popup.
	 * @param description The description of the popup.
	 */
	public static function displayAlert(title:String, description:String):Void
	{
		FlxG.stage.application.window.alert(description, title);
	}

	/**
	 * Display the value of a particular field of a given object
	 * in the Debug watch window, labelled with the specified name.
	 		* Updates continuously.
	 * @param object The object to watch.
	 * @param field The string name of a field of the above object.
	 * @param name
	 */
	public static inline function watchVariable(object:Dynamic, field:String, name:String):Void
	{
		#if debug
		if (object == null)
		{
			logError("Tried to watch a variable on a null object!");
			return;
		}

		FlxG.watch.add(object, field, name == null ? field : name);
		#end // Else, do nothing outside of debug mode.
	}

	/**
	 * Adds the specified value to the Debug Watch window under the current name.
	 * A lightweight alternative to watchVariable, since it doesn't update until you call it again.
	 * 
	 * @param value 
	 * @param name 
	 */
	public static inline function quickWatch(value:Dynamic, name:String):Void
	{
		#if debug
		FlxG.watch.addQuick(name == null ? 'QuickWatch' : name, value);
		#end // Else, do nothing outside of debug mode.
	}

	/**
	 * The Console window already supports most hScript, meaning you can do most things you could already do in Haxe.
	 		* However, you can also add custom commands using this function.
	 */
	public static inline function addConsoleCommand(name:String, callbackFn:Dynamic):Void
	{
		FlxG.console.registerFunction(name, callbackFn);
	}

	/**
	 * Add an object with a custom alias so that it can be accessed via the console.
	 */
	public static inline function addObject(name:String, object:Dynamic):Void
	{
		FlxG.console.registerObject(name, object);
	}

	/**
	 * Create a tracker window for an object.
	 * This will display the properties of that object in
	 * a fancy little Debug window you can minimize and drag around.
	 * 
	 * @param obj The object to display.
	 */
	public static inline function trackObject(obj:Dynamic):Void
	{
		if (obj == null)
		{
			logError("Tried to track a null object!");
			return;
		}

		FlxG.debugger.track(obj);
	}

	/**
	 * The game runs this function immediately when it starts.
	 		* Use onGameStart() if it can wait until a little later.
	 */
	public static function onInitProgram():Void
	{
		trace('Initializing Debug tools...'); // Initialize logging tools.

		Log.trace = function(data:Dynamic, ?info:PosInfos):Void // Override Haxe's vanilla trace() calls to use the Flixel console.
		{
			var paramArray:Array<Dynamic> = [data];

			if (info != null)
			{
				if (info.customParams != null)
				{
					for (i in info.customParams) {
						paramArray.push(i);
					}
				}
			}

			logTrace(paramArray, info);
		}

		// Start the log file writer.
		// We have to set it to TRACE for now.
		logFileWriter = new DebugLogWriter("TRACE");

		logInfo("Debug logging initialized.");

		#if debug
		logInfo("This is a DEBUG build.");
		#else
		logInfo("This is a RELEASE build.");
		#end

		logInfo('HaxeFlixel version: ${Std.string(FlxG.VERSION)}');
		logInfo('Friday Night Funkin\' version: ${FlxG.stage.application.meta.get('version')}');
		logInfo('Alsuh Engine version: ${MainMenuState.alsuhEngineVersion}');
	}

	/**
	 * The game runs this function when it starts, but after Flixel is initialized.
	 */
	public static function onGameStart():Void
	{
		FlxG.watch.addMouse(); // Add the mouse position to the debug Watch window.

		var debugLogLevel:String = try FlxG.save.data.debugLogLevel catch (_:Dynamic) 'TRACE';

		if (debugLogLevel == null || debugLogLevel.length < 1) { // Now we can remember the log level.
			debugLogLevel = "TRACE";
		}

		logFileWriter.setLogLevel(debugLogLevel);
	}

	static function writeToFlxGLog(data:Array<Dynamic>, logStyle:LogStyle):Void
	{
		if (FlxG != null && FlxG.game != null && FlxG.log != null) {
			FlxG.log.advanced(data, logStyle);
		}
	}

	static function writeToLogFile(data:Array<Dynamic>, logLevel:String = "TRACE"):Void
	{
		if (logFileWriter != null && logFileWriter.isActive()) {
			logFileWriter.write(data, logLevel);
		}
	}

	static function formatOutput(input:Dynamic, pos:PosInfos):Array<Dynamic>
	{
		var inArray:Array<Dynamic> = null; // This code is junk but I kept getting Null Function References.

		if (input == null) {
			inArray = ['<NULL>'];
		}
		else if (!Std.isOfType(input, Array)) {
			inArray = [input];
		}
		else {
			inArray = input;
		}

		if (pos == null) return inArray;

		var output:Array<Dynamic> = ['(${pos.className}/${pos.methodName}#${pos.lineNumber}): ']; // Format the position ourselves.
		return output.concat(inArray);
	}
}

class DebugLogWriter
{
	static final LOG_FOLDER:String = "logs";
	public static final LOG_LEVELS:Array<String> = ['ERROR', 'WARN', 'INFO', 'TRACE'];

	/**
	 * Set this to the current timestamp that the game started.
	 */
	var startTime:Float = 0;
	var logLevel:Int;
	var active:Bool = false;

	#if (sys && desktop)
	var file:FileOutput;
	#end

	public function new(logLevelParam:String):Void
	{
		logLevel = LOG_LEVELS.indexOf(logLevelParam);

		#if (sys && desktop)
		printDebug("Initializing log file...");

		var logFilePath:String = '$LOG_FOLDER/${Sys.time()}.log';

		if (logFilePath.indexOf("/") != -1) // Make sure that the path exists
		{
			var lastIndex:Int = logFilePath.lastIndexOf("/");
			var logFolderPath:String = logFilePath.substr(0, lastIndex);

			printDebug('Creating log folder $logFolderPath');
			FileSystem.createDirectory(logFolderPath);
		}
		
		printDebug('Creating log file $logFilePath'); // Open the file

		file = File.write(logFilePath, false);
		active = true;
		#else
		printDebug("Won't create log file; no file system access.");
		active = false;
		#end

		startTime = getTime(true); // Get the absolute time in seconds. This lets us show relative time in log, which is more readable.
	}

	public function isActive():Bool
	{
		return active;
	}

	/**
	 * Get the time in seconds.
	 * @param abs Whether the timestamp is absolute or relative to the start time.
	 */
	public inline function getTime(abs:Bool = false):Float
	{
		#if sys
		return abs ? Sys.time() : (Sys.time() - startTime); // Use this one on CPP and Neko since it's more accurate.
		#else
		return abs ? Date.now().getTime() : (Date.now().getTime() - startTime); // This one is more accurate on non-CPP platforms.
		#end
	}

	function shouldLog(input:String):Bool
	{
		var levelIndex:Int = LOG_LEVELS.indexOf(input);

		if (levelIndex == -1) return false; // Could not find this log level.
		return levelIndex <= logLevel;
	}

	public function setLogLevel(input:String):Void
	{
		var levelIndex:Int = LOG_LEVELS.indexOf(input);

		if (levelIndex == -1) return; // Could not find this log level.
		logLevel = levelIndex;

		FlxG.save.data.debugLogLevel = logLevel;
	}

	/**
	 * Output text to the log file.
	 */
	public function write(input:Array<Dynamic>, logLevel:String = 'TRACE'):Void
	{
		var ts:String = FlxStringUtil.formatTime(getTime(), true);
		var msg:String = '$ts [$logLevel] ${input.join('')}';

		#if (sys && desktop)
		if (active && file != null)
		{
			if (shouldLog(logLevel))
			{
				file.writeString('$msg\n');

				file.flush();
				file.flush();
			}
		}
		#end

		if (shouldLog(logLevel)) { // Output text to the debug console directly.
			printDebug(msg);
		}
	}

	function printDebug(msg:String):Void
	{
		#if sys
		Sys.println(msg);
		#else
		Log.trace(msg, null); // Pass null to exclude the position.
		#end
	}
}