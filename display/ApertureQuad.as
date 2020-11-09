// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.display {

	import starling.display.DisplayObjectContainer;
	import starling.display.Quad;
	import starling.utils.Color;
	import starlingEx.display.ApertureObject;
	import starlingEx.display.ApertureSprite;
	import starlingEx.display.ApertureUtils;
	import starlingEx.display.IAperture;
	import starlingEx.display.IApertureMesh;
	import starlingEx.utils.PoolEx;

	/* An ApertureQuad will have its colors modified when the parent ApertureSprite's color is modified. */
	public class ApertureQuad extends Quad implements IAperture, IApertureMesh {
		static private const vertexV:Vector.<uint> = PoolEx.getUintV(0,3);
		static private const vertices:uint = vertexV.length;

		public var quadW:Number, quadH:Number;
		private var trueV:Vector.<ApertureObject>, multV:Vector.<ApertureObject>;
		private var _apertureLock:Boolean;
		public function ApertureQuad(w:Number=1,h:Number=1,colorHex:uint=0xffffff) {
			quadW = w;
			quadH = h;
			trueV = ApertureObject.getVector();
			multV = ApertureObject.getVector();
			for (var i:uint=0; i<vertices; i++) {
				trueV[i] = ApertureObject.getInstance(colorHex);
				multV[i] = ApertureObject.getInstance(colorHex);
			}
			super(w,h,colorHex);
		}
		public function setHex(colorHex:uint=0xffffff,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			for (var i:uint=0; i<vertices; i++) {
				testTrueHex(i,colorHex,vertexV);
			}
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		private function testTrueHex(i:uint,newHex:uint,vertexV:Vector.<uint>):void {
			var true_AO:ApertureObject = trueV[i];
			if (true_AO.hex != newHex) {
				true_AO.hex = newHex;
				if (vertexV) vertexV[vertexV.length] = i;
			}
		}
		public function getHex(index:uint=0):uint {
			return trueV[index].hex;
		}
		public function setRGB(r:uint=255,g:uint=255,b:uint=255,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			for (var i:uint=0; i<vertices; i++) {
				testTrueRGB(i,r,g,b,vertexV);
			}
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		private function testTrueRGB(i:uint,newR:uint,newG:uint,newB:uint,vertexV:Vector.<uint>):void {
			var true_AO:ApertureObject = trueV[i];
			if (true_AO.r != newR && true_AO.g != newG && true_AO.b != newB) {
				true_AO.rgb(newR,newG,newB);
				if (vertexV) vertexV[vertexV.length] = i;
			}
		}
		public function getRGB(index:uint=0):Array {
			var returnA:Array = PoolEx.getArray();
			returnA[0] = trueV[index].r;
			returnA[1] = trueV[index].g;
			returnA[2] = trueV[index].b;
			return returnA;
		}
		public function setVertexHex(vertexID:uint,colorHex:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueHex(vertexID,colorHex,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setVertexRGB(vertexID:uint,r:uint,g:uint,b:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueRGB(vertexID,r,g,b,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setEachHex(topLeftColor:uint,topRightColor:uint,bottomLeftColor:uint,bottomRightColor:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueHex(0,topLeftColor,vertexV);
			testTrueHex(1,topRightColor,vertexV);
			testTrueHex(2,bottomLeftColor,vertexV);
			testTrueHex(3,bottomRightColor,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setEachRGB(topLeftR:uint,topLeftG:uint,topLeftB:uint,topRightR:uint,topRightG:uint,topRightB:uint,bottomLeftR:uint,bottomLeftG:uint,bottomLeftB:uint,bottomRightR:uint,bottomRightG:uint,bottomRightB:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueRGB(0,topLeftR,topLeftG,topLeftB,vertexV);
			testTrueRGB(1,topRightR,topRightG,topRightB,vertexV);
			testTrueRGB(2,bottomLeftR,bottomLeftG,bottomLeftB,vertexV);
			testTrueRGB(3,bottomRightR,bottomRightG,bottomRightB,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setTopHex(colorHex:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueHex(0,colorHex,vertexV);
			testTrueHex(1,colorHex,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setTopRGB(r:uint,g:uint,b:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueRGB(0,r,g,b,vertexV);
			testTrueRGB(1,r,g,b,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setBottomHex(colorHex:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueHex(2,colorHex,vertexV);
			testTrueHex(3,colorHex,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setBottomRGB(r:uint,g:uint,b:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueRGB(2,r,g,b,vertexV);
			testTrueRGB(3,r,g,b,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setLeftHex(colorHex:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueHex(0,colorHex,vertexV);
			testTrueHex(2,colorHex,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setLeftRGB(r:uint,g:uint,b:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueRGB(0,r,g,b,vertexV);
			testTrueRGB(2,r,g,b,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setRightHex(colorHex:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueHex(1,colorHex,vertexV);
			testTrueHex(4,colorHex,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setRightRGB(r:uint,g:uint,b:uint,apply:Boolean=true):void {
			var vertexV:Vector.<uint>;
			if (apply) vertexV = PoolEx.getUintV();
			testTrueRGB(1,r,g,b,vertexV);
			testTrueRGB(4,r,g,b,vertexV);
			multiplyVertex(vertexV);
			PoolEx.putUintV(vertexV);
		}
		public function setAperture(decimal:Number,apply:Boolean=true):void {
			if (decimal < 0 || decimal > 1) return;
			var roundInt:uint = Math.round(decimal*255);
			setRGB(roundInt,roundInt,roundInt,apply);
		}
		public function set apertureLock(boolean:Boolean):void {_apertureLock = boolean;}
		public function get apertureLock():Boolean {return _apertureLock;}
		public function multiplyColor():void {
			ApertureUtils.multiplyVertex(this,vertexV);
			if (style is IAperture) {
				var iAperture:IAperture = style as IAperture;
				iAperture.multiplyColor();
			}
		}
		private function multiplyVertex(vertexV:Vector.<uint>):void {
			if (vertexV) ApertureUtils.multiplyVertex(this,vertexV);
		}
		public function calcMult(parentMult_AO:ApertureObject,index:uint=0):void {
			if (parentMult_AO) multV[index].hex = ApertureObject.multiply(trueV[index],parentMult_AO);
			else multV[index].hex = trueV[index].hex;
		}
		public function applyVertexMult(vertexID:uint):void {
			super.setVertexColor(vertexID,multV[vertexID].hex);
		}
		override public function set color(value:uint):void {
			setHex(value);
		}
		override public function get color():uint {
			return getHex(0);
		}
		override public function setVertexColor(vertexID:int,colorHex:uint):void {
			setVertexHex(vertexID,colorHex,true);
		}
		override public function readjustSize(width:Number=-1,height:Number=-1):void {
			quadW = width;
			quadH = height;
			super.readjustSize(width,height);
		}
		override public function dispose():void {
			for (var i:uint=0; i<vertices; i++) {
				ApertureObject.putInstance(trueV[i]);
				ApertureObject.putInstance(multV[i]);
			}
			ApertureObject.putVector(trueV);
			ApertureObject.putVector(multV);
			trueV = multV = null;
			texture = null;
			super.dispose();
		}
	}
	
}
