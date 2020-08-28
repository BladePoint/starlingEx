package starlingEx.display {

	import starling.animation.Juggler;
	import starling.animation.Transitions;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.errors.AbstractClassError;
	import starling.core.Starling;
	import starling.utils.Color;
	import starlingEx.animation.TweenEx;
	import starlingEx.animation.TweenObject;
	import starlingEx.display.IAperture;
	import starlingEx.display.IApertureMesh;
	import starlingEx.display.IApertureDisplayObjectContainer;
	import starlingEx.utils.PoolEx;

	public class ApertureUtils {
		static public function multiplyChildren(iApertureDOC:IApertureDisplayObjectContainer):void {
			var iAperture:IAperture = iApertureDOC as IAperture;
			var parentMultA:Array;
			if (!iAperture.apertureLock) parentMultA = getParentMult(iApertureDOC as DisplayObject);
			iAperture.calcMult(parentMultA);
			PoolEx.putArray(parentMultA);
			var displayObjectContainer:DisplayObjectContainer = iApertureDOC as DisplayObjectContainer;
			var l:uint = displayObjectContainer.numChildren;
			for (var i:uint=0; i<l; i++) {
				multiplyChild(displayObjectContainer.getChildAt(i));
			}
		}
		static public function multiplyChild(displayObject:DisplayObject):void {
			if (displayObject is IAperture) {
				var iAperture:IAperture = displayObject as IAperture;
				if (!iAperture.apertureLock) iAperture.multiplyColor();
			}
		}
		static public function multiplyVertices(iApertureMesh:IApertureMesh,vertices:uint):void {
			var iAperture:IAperture = iApertureMesh as IAperture;
			var parentMultA:Array;
			if (!iAperture.apertureLock) parentMultA = getParentMult(iApertureMesh as DisplayObject);
			for (var i:uint=0; i<vertices; i++) {
				iAperture.calcMult(parentMultA,i);
				iApertureMesh.applyVertexMult(i);
			}
			PoolEx.putArray(parentMultA);
		}
		static public function getParentMult(displayObject:DisplayObject):Array {
			var parentDOC:DisplayObjectContainer = displayObject.parent;
			var parentMultA:Array;
			if (parentDOC is IApertureDisplayObjectContainer) {
				var parentApertureDOC:IApertureDisplayObjectContainer = parentDOC as IApertureDisplayObjectContainer;
				parentMultA = parentApertureDOC.getMultRGB();
			}
			return parentMultA;
		}
		static public function tweenApertureHex(iAperture:IAperture,colorHex:uint,duration:Number,transition:String=null,onComplete:Function=null,onCompleteDelay:Number=0,juggler:Juggler=null):void {
			var r:uint = Color.getRed(colorHex),
				g:uint = Color.getGreen(colorHex),
				b:uint = Color.getBlue(colorHex);
			tweenApertureRGB(iAperture,r,g,b,duration,transition,onComplete,onCompleteDelay,juggler);
		}
		static public function tweenApertureRGB(iAperture:IAperture,finalR:uint,finalG:uint,finalB:uint,duration:Number,transition:String=null,onComplete:Function=null,onCompleteDelay:Number=0,juggler:Juggler=null):void {
			if (transition == null) transition = Transitions.LINEAR;
			if (juggler == null) juggler = Starling.juggler;
			var initHex:uint = iAperture.getHex();
			var initR:uint = Color.getRed(initHex),
				initG:uint = Color.getGreen(initHex),
				initB:uint = Color.getBlue(initHex);
			var tween:TweenEx = TweenEx.getTween(0,duration,transition);
			tween.animateEx(1);
			var updateA:Array = PoolEx.getArray(),
				completeA:Array = PoolEx.getArray();
			tween.onUpdate = updateTween;
			updateA.push(iAperture,tween.tweenObject,initR,initG,initB,finalR,finalG,finalB);
			tween.onUpdateArgs = updateA;
			tween.onComplete = completeTween;
			completeA.push(tween,updateA,completeA,onComplete,onCompleteDelay,juggler);
			tween.onCompleteArgs = completeA;
			juggler.add(tween);
		}
		static private function updateTween(iAperture:IAperture,tweenObject:TweenObject,initR:uint,initG:uint,initB:uint,finalR:uint,finalG:uint,finalB:uint):void {
			var complement:Number = 1 - tweenObject.t;
			var r:uint = Math.round(initR*complement+finalR*tweenObject.t),
				g:uint = Math.round(initG*complement+finalG*tweenObject.t),
				b:uint = Math.round(initB*complement+finalB*tweenObject.t);
			iAperture.setRGB(r,g,b);
		}
		static private function completeTween(tween:TweenEx,updateA:Array,completeA:Array,onComplete:Function,delay:Number,juggler:Juggler):void {
			TweenEx.putTween(tween);
			PoolEx.putArray(updateA);
			PoolEx.putArray(completeA);
			if (onComplete != null) juggler.delayCall(onComplete,delay);
		}
		static public function fadeToBlack(iAperture:IAperture,duration:Number=1,onComplete:Function=null,onCompleteDelay:Number=0):void {
			tweenApertureRGB(iAperture,0,0,0,duration,null,onComplete,onCompleteDelay);
		}
		static public function fadeFromBlack(iAperture:IAperture,duration:Number=1,onComplete:Function=null,onCompleteDelay:Number=0):void {
			tweenApertureRGB(iAperture,255,255,255,duration,null,onComplete,onCompleteDelay);
		}

		public function ApertureUtils() {throw new AbstractClassError();}

	}
	
}
