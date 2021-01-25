// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.display {

	import starling.display.DisplayObject;
	import starlingEx.display.ApertureObject;

	public interface IApertureDisplayObjectContainer {
		function getMultHex():uint;
		function getMultRGB():Array;
		function getMultAO():ApertureObject;
		function addChild(child:DisplayObject):DisplayObject;
	}

}
