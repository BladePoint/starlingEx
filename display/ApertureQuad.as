package starlingEx.display {

	import starling.display.DisplayObjectContainer;
	import starling.display.Quad;
	import starling.utils.Color;
	import starling.utils.Pool;
	import starlingEx.display.ApertureObject;
	import starlingEx.display.ApertureSprite;
	import starlingEx.display.ApertureUtils;
	import starlingEx.display.IAperture;
	import starlingEx.display.IApertureMesh;

	public class ApertureQuad extends Quad implements IAperture, IApertureMesh {
		static private const vertices:uint = 4;

		public var quadW:Number, quadH:Number;
		private var trueV:Vector.<ApertureObject>, multV:Vector.<ApertureObject>;
		private var _apertureLock:Boolean;
		public function ApertureQuad(w:Number=1,h:Number=1,colorHex:uint=0xffffff) {
			quadW = w;
			quadH = h;
			trueV = new <ApertureObject>[];
			multV = new <ApertureObject>[];
			for (var i:uint=0; i<vertices; i++) {
				trueV[i] = ApertureObject.getApertureObject(colorHex);
				multV[i] = ApertureObject.getApertureObject(colorHex);
			}
			super(w,h,colorHex);
		}
		public function setHex(colorHex:uint=0xffffff,apply:Boolean=true):void {
			for (var i:uint=0; i<vertices; i++) {
				trueV[i].hex = colorHex;
			}
			if (apply) multiplyColor();
		}
		public function getHex(index:uint=0):uint {
			return trueV[index].hex;
		}
		public function setRGB(r:uint=255,g:uint=255,b:uint=255,apply:Boolean=true):void {
			for (var i:uint=0; i<vertices; i++) {
				trueV[i].rgb(r,g,b);
			}
			if (apply) multiplyColor();
		}
		public function getRGB(index:uint=0):Array {
			var returnA:Array = Pool.getArray();
			returnA[0] = trueV[index].r;
			returnA[1] = trueV[index].g;
			returnA[2] = trueV[index].b;
			return returnA;
		}
		public function setVertexHex(vertexID:uint,colorHex:uint,apply:Boolean=true):void {
			trueV[vertexID].hex = colorHex;
			if (apply) multiplyColor();
		}
		public function setVertexRGB(vertexID:uint,r:uint,g:uint,b:uint,apply:Boolean=true):void {
			trueV[vertexID].rgb(r,g,b);
			if (apply) multiplyColor();
		}
		public function setEachHex(topLeftColor:uint,topRightColor:uint,bottomLeftColor:uint,bottomRightColor:uint,apply:Boolean=true):void {
			trueV[0].hex = topLeftColor;
			trueV[1].hex = topRightColor;
			trueV[2].hex = bottomLeftColor;
			trueV[3].hex = bottomRightColor;
			if (apply) multiplyColor();
		}
		public function setEachRGB(topLeftR:uint,topLeftG:uint,topLeftB:uint,topRightR:uint,topRightG:uint,topRightB:uint,bottomLeftR:uint,bottomLeftG:uint,bottomLeftB:uint,bottomRightR:uint,bottomRightG:uint,bottomRightB:uint,apply:Boolean=true):void {
			setEachHex(
				Color.rgb(topLeftR,topLeftG,topLeftB),
				Color.rgb(topRightR,topRightG,topRightB),
				Color.rgb(bottomLeftR,bottomLeftG,bottomLeftB),
				Color.rgb(bottomRightR,bottomRightG,bottomRightB),
				apply
			);
		}
		public function setTopHex(colorHex:uint,apply:Boolean=true):void {
			trueV[0].hex = trueV[1].hex = colorHex;
			if (apply) multiplyColor();
		}
		public function setTopRGB(r:uint,g:uint,b:uint,apply:Boolean=true):void {
			trueV[0].rgb(r,g,b);
			trueV[1].rgb(r,g,b);
			if (apply) multiplyColor();
		}
		public function setBottomHex(colorHex:uint,apply:Boolean=true):void {
			trueV[2].hex = trueV[3].hex = colorHex;
			if (apply) multiplyColor();
		}
		public function setBottomRGB(r:uint,g:uint,b:uint,apply:Boolean=true):void {
			trueV[2].rgb(r,g,b);
			trueV[3].rgb(r,g,b);
			if (apply) multiplyColor();
		}
		public function setLeftHex(colorHex:uint,apply:Boolean=true):void {
			trueV[0].hex = trueV[2].hex = colorHex;
			if (apply) multiplyColor();
		}
		public function setLeftRGB(r:uint,g:uint,b:uint,apply:Boolean=true):void {
			trueV[0].rgb(r,g,b);
			trueV[2].rgb(r,g,b);
			if (apply) multiplyColor();
		}
		public function setRightHex(colorHex:uint,apply:Boolean=true):void {
			trueV[1].hex = trueV[4].hex = colorHex;
			if (apply) multiplyColor();
		}
		public function setRightRGB(r:uint,g:uint,b:uint,apply:Boolean=true):void {
			trueV[1].rgb(r,g,b);
			trueV[4].rgb(r,g,b);
			if (apply) multiplyColor();
		}
		public function setAperture(decimal:Number,apply:Boolean=true):void {
			if (decimal < 0 || decimal > 1) return;
			var roundInt:uint = Math.round(decimal*255);
			setRGB(roundInt,roundInt,roundInt,apply);
		}
		public function set apertureLock(boolean:Boolean):void {_apertureLock = boolean;}
		public function get apertureLock():Boolean {return _apertureLock;}
		public function multiplyColor():void {
			ApertureUtils.multiplyVertices(this,vertices)
		}
		public function calcMult(parentMultA:Array,index:uint=0):void {
			if (parentMultA) multV[index].hex = ApertureObject.multiplyRGB(trueV[index],parentMultA);
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
			trueV[vertexID].hex = colorHex;
			var parentMultA:Array = ApertureUtils.getParentMult(this);
			calcMult(parentMultA,vertexID);
			applyVertexMult(vertexID);
			if (parentMultA) Pool.putArray(parentMultA);
		}
		override public function readjustSize(width:Number=-1,height:Number=-1):void {
			quadW = width;
			quadH = height;
			super.readjustSize(width,height);
		}
		override public function dispose():void {
			for (var i:uint=0; i<vertices; i++) {
				ApertureObject.putApertureObject(trueV[i]);
				ApertureObject.putApertureObject(multV[i]);
			}
			trueV.length = multV.length = 0;
			trueV = multV = null;
			texture = null;
			super.dispose();
		}
	}
	
}
