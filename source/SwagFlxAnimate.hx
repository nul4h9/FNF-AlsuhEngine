package;

import haxe.Json;

import flixel.util.FlxDestroyUtil;
import flxanimate.data.AnimationData;
import flxanimate.frames.FlxAnimateFrames;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flxanimate.FlxAnimate as OriginalFlxAnimate;

using StringTools;

class SwagFlxAnimate extends OriginalFlxAnimate
{
	public function loadAtlasEx(img:FlxGraphicAsset, pathOrStr:String = null, myJson:Dynamic = null):Void
	{
		var animJson:AnimAtlas = null;

		if (myJson is String)
		{
			var trimmed:String = pathOrStr.trim();
			trimmed = trimmed.substr(trimmed.length - 5).toLowerCase();

			if (trimmed == '.json') myJson = Paths.getTextFromFile(myJson); //is a path
			animJson = cast Json.parse(_removeBOM(myJson));
		}
		else animJson = cast myJson;

		var isXml:Null<Bool> = null;
		var myData:Dynamic = pathOrStr;

		var trimmed:String = pathOrStr.trim();
		trimmed = trimmed.substr(trimmed.length - 5).toLowerCase();

		if (trimmed == '.json') //Path is json
		{
			myData = Paths.getTextFromFile(pathOrStr);
			isXml = false;
		}
		else if (trimmed.substr(1) == '.xml') //Path is xml
		{
			myData = Paths.getTextFromFile(pathOrStr);
			isXml = true;
		}

		myData = _removeBOM(myData);

		switch (isXml) // Automatic if everything else fails
		{
			case true: myData = Xml.parse(myData);
			case false: myData = Json.parse(myData);
			case null:
			{
				try
				{
					myData = Json.parse(myData);
					isXml = false;
				}
				catch (_:Dynamic)
				{
					myData = Xml.parse(myData);
					isXml = true;
				}
			}
		}

		anim._loadAtlas(animJson);

		if (!isXml) {
			frames = FlxAnimateFrames.fromSpriteMap(cast myData, img);
		}
		else {
			frames = FlxAnimateFrames.fromSparrow(cast myData, img);
		}

		origin = anim.curInstance.symbol.transformationPoint;
	}

	override function draw():Void
	{
		if (anim.curInstance == null || anim.curSymbol == null) return;
		super.draw();
	}

	override function destroy():Void
	{
		try {
			super.destroy();
		}
		catch (_:Dynamic)
		{
			anim.curInstance = FlxDestroyUtil.destroy(anim.curInstance);
			anim.stageInstance = FlxDestroyUtil.destroy(anim.stageInstance);
			anim.metadata.destroy();
			anim.symbolDictionary = null;
		}
	}

	function _removeBOM(str:String):String //Removes BOM byte order indicator
	{
		if (str.charCodeAt(0) == 0xFEFF) str = str.substr(1); //myData = myData.substr(2);
		return str;
	}

	public function pauseAnimation():Void
	{
		if (anim.curInstance == null || anim.curSymbol == null) return;
		anim.pause();
	}

	public function resumeAnimation():Void
	{
		if (anim.curInstance == null || anim.curSymbol == null) return;
		anim.play();
	}
}