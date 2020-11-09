// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.text {

	import starlingEx.display.ApertureQuad;
	import starlingEx.display.ApertureSprite;
	import starlingEx.text.ApertureTextFormat;
	import starlingEx.text.ApertureTextField;
	import starlingEx.text.CharLocation;

	/* An IDistanceCompositor arranges letters for an ApertureTextField. */
	public interface IDistanceCompositor {

		function fillContainer(textField:ApertureTextField,width:Number,height:Number):Vector.<CharLocation>;
		function fillShadow(textField:ApertureTextField):void;
		function getDefaultSoftness(format:ApertureTextFormat):Number;
		function setupOutline(charLocation:CharLocation,outlineColor:uint,outlineWidth:Number):void;
		function updateOutlineWidth(charLocation:CharLocation,outlineWidth:Number):void;
		function clearSprites(charLocationV:Vector.<CharLocation>):void;
		function dispose():void;

	}

}
