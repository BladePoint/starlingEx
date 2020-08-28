package starlingEx.display {

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;
	import starlingEx.display.ApertureObject;
	import starlingEx.display.ApertureUtils;
	import starlingEx.display.IAperture;
	import starlingEx.display.IApertureDisplayObjectContainer;
	import starlingEx.utils.PoolEx;

	public class ApertureSprite extends Sprite implements IAperture, IApertureDisplayObjectContainer {

		private var true_AO:ApertureObject, mult_AO:ApertureObject;
		private var _apertureLock:Boolean;
		public function ApertureSprite(colorHex:uint=0xffffff) {
			true_AO = ApertureObject.getApertureObject(colorHex);
			mult_AO = ApertureObject.getApertureObject(colorHex);
			super();
		}
		public function setHex(colorHex:uint=0xffffff,apply:Boolean=true):void {
			true_AO.hex = colorHex;
			if (apply) multiplyColor();
		}
		public function getHex(index:uint=0):uint {
			return true_AO.hex;
		}
		public function setRGB(r:uint=255,g:uint=255,b:uint=255,apply:Boolean=true):void {
			true_AO.rgb(r,g,b);
			if (apply) multiplyColor();
		}
		public function getRGB(index:uint=0):Array {
			var returnA:Array = PoolEx.getArray();
			returnA[0] = true_AO.r;
			returnA[1] = true_AO.g;
			returnA[2] = true_AO.b;
			return returnA;
		}
		public function setAperture(decimal:Number,apply:Boolean=true):void {
			if (decimal < 0 || decimal > 1) return;
			var roundInt:uint = Math.round(decimal*255);
			setRGB(roundInt,roundInt,roundInt,apply);
		}
		public function set apertureLock(boolean:Boolean):void {_apertureLock = boolean;}
		public function get apertureLock():Boolean {return _apertureLock;}
		public function multiplyColor():void {
			ApertureUtils.multiplyChildren(this);
		}
		public function calcMult(parentMultA:Array,index:uint=0):void {
			if (parentMultA) mult_AO.hex = ApertureObject.multiplyRGB(true_AO,parentMultA);
			else mult_AO.hex = true_AO.hex;
		}
		override public function addChild(child:DisplayObject):DisplayObject {
			super.addChild(child)
			ApertureUtils.multiplyChild(child);
			return child;
		}
		public function getMultRGB(index:uint=0):Array {
			var returnA:Array = PoolEx.getArray();
			returnA[0] = mult_AO.r;
			returnA[1] = mult_AO.g;
			returnA[2] = mult_AO.b;
			return returnA;
		}
		override public function dispose():void {
			ApertureObject.putApertureObject(true_AO);
			ApertureObject.putApertureObject(mult_AO);
			true_AO = mult_AO = null;
			super.dispose();
		}

	}
}
