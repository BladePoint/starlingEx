package starlingEx.display {

	import starling.display.DisplayObjectContainer;

	public interface IAperture {

		function setHex(colorHex:uint=0xffffff,apply:Boolean=true):void;
		function getHex(index:uint=0):uint;
		function setRGB(r:uint=255,g:uint=255,b:uint=255,apply:Boolean=true):void;
		function getRGB(index:uint=0):Array;
		function setAperture(decimal:Number,apply:Boolean=true):void;
		function set apertureLock(boolean:Boolean):void;
		function get apertureLock():Boolean;
		function multiplyColor():void;
		function calcMult(parentMultA:Array,index:uint=0):void;

	}
	
}
