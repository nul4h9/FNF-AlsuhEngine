package;

import flixel.FlxG;

#if DISCORD_ALLOWED
import cpp.Star;
import cpp.Function;
import cpp.RawPointer;
import cpp.ConstPointer;
import sys.thread.Thread;
import cpp.ConstCharStar;
import cpp.RawConstPointer;
import hxdiscord_rpc.Types;
import hxdiscord_rpc.Discord;
#end

using StringTools;

class DiscordClient
{
	#if DISCORD_ALLOWED
	public static var isInitialized:Bool = false;
	private static var _defaultID(default, never):String = '814588678700924999';

	public static var clientID(default, set):String = _defaultID;

	private static var _options:Dynamic = {
		details: 'In the Menus',
		state: null,
		largeImageKey: 'icon',
		largeImageText: "Friday Night Funkin'",
		smallImageKey : null,
		startTimestamp : null,
		endTimestamp : null
	};

	private static var presence:DiscordRichPresence = DiscordRichPresence.create();

	public static function check():Void
	{
		if (ClientPrefs.discordRPC) initialize();
		else if (isInitialized) shutdown();
	}

	public static function prepare():Void
	{
		if (!isInitialized && ClientPrefs.discordRPC) initialize();

		FlxG.stage.application.window.onClose.add(function():Void
		{
			if (isInitialized) {
				shutdown();
			}
		});
	}

	public static dynamic function shutdown():Void
	{
		Discord.Shutdown();
		isInitialized = false;
	}

	private static function onReady(request:RawConstPointer<DiscordUser>):Void
	{
		var requestPtr:Star<DiscordUser> = ConstPointer.fromRaw(request).ptr;

		if (Std.parseInt(cast(requestPtr.discriminator, String)) != 0) { // New Discord IDs/Discriminator system
			Debug.logInfo('(Discord) Connected to User (${cast(requestPtr.username, String)}#${cast(requestPtr.discriminator, String)})');
		}
		else { // Old discriminators
			Debug.logInfo('(Discord) Connected to User (${cast(requestPtr.username, String)})');
		}

		changePresence();
	}

	private static function onError(errorCode:Int, message:ConstCharStar):Void
	{
		Debug.logInfo('Discord: Error ($errorCode: ${cast(message, String)})');
	}

	private static function onDisconnected(errorCode:Int, message:ConstCharStar):Void
	{
		Debug.logInfo('Discord: Disconnected ($errorCode: ${cast(message, String)})');
	}

	public static function initialize():Void
	{
		var discordHandlers:DiscordEventHandlers = DiscordEventHandlers.create();
		discordHandlers.ready = Function.fromStaticFunction(onReady);
		discordHandlers.disconnected = Function.fromStaticFunction(onDisconnected);
		discordHandlers.errored = Function.fromStaticFunction(onError);

		Discord.Initialize(clientID, RawPointer.addressOf(discordHandlers), 1, null);

		if (!isInitialized) Debug.logInfo('Discord Client initialized');

		Thread.create(() ->
		{
			var localID:String = clientID;

			while (localID == clientID)
			{
				#if DISCORD_DISABLE_IO_THREAD
				Discord.UpdateConnection();
				#end
				Discord.RunCallbacks();

				Sys.sleep(0.5); // Wait 0.5 seconds until the next loop...
			}
		});

		isInitialized = true;
	}

	public static function changePresence(?details:String = 'In the Menus', ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float):Void
	{
		var startTimestamp:Float = 0;

		if (hasStartTimestamp) startTimestamp = Date.now().getTime();
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;

		presence.details = details;
		presence.state = state;
		presence.largeImageKey = 'icon';
		presence.largeImageText = "Engine Version: " + MainMenuState.alsuhEngineVersion;
		presence.smallImageKey = smallImageKey;
		presence.startTimestamp = Std.int(startTimestamp / 1000);
		presence.endTimestamp = Std.int(endTimestamp / 1000);

		updatePresence();
	}

	public static function updatePresence():Void
	{
		Discord.UpdatePresence(RawConstPointer.addressOf(presence));
	}

	public dynamic static function changeClientID(newID:String):Void
	{
		if (newID == null) newID = _defaultID;
		clientID = newID;
	}

	public static function resetClientID():Void
	{
		clientID = _defaultID;
	}

	private static function set_clientID(newID:String):String
	{
		var change:Bool = (clientID != newID);
		clientID = newID;

		if (change && isInitialized)
		{
			shutdown();
			initialize();
			updatePresence();
		}

		return newID;
	}

	#if MODS_ALLOWED
	public static function loadModRPC():Void
	{
		var pack:Dynamic = Paths.getModPack();

		if (pack != null && pack.discordRPC != null && pack.discordRPC != clientID) {
			clientID = pack.discordRPC;
		}
	}
	#end

	#if LUA_ALLOWED
	public static function implementForLua(funk:FunkinLua):Void
	{
		funk.set("changeDiscordPresence", changePresence);
		funk.set("changeDiscordClientID", changeClientID);
	}
	#end
	#end
}