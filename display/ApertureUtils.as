// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

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
	import starlingEx.styles.ApertureDistanceFieldStyle;
	import starlingEx.utils.PoolEx;

	public class ApertureUtils {
		static public function multiplyChildren(iApertureDOC:IApertureDisplayObjectContainer):void {
			const iAperture:IAperture = iApertureDOC as IAperture;
			var parentMult_AO:ApertureObject;
			if (!iAperture.apertureLock) parentMult_AO = getParentMult(iApertureDOC as DisplayObject);
			iAperture.calcMult(parentMult_AO);
			const displayObjectContainer:DisplayObjectContainer = iApertureDOC as DisplayObjectContainer;
			const l:uint = displayObjectContainer.numChildren;
			for (var i:uint=0; i<l; i++) {
				multiplyChild(displayObjectContainer.getChildAt(i));
			}
		}
		static public function multiplyChild(displayObject:DisplayObject):void {
			if (displayObject is IAperture) {
				const iAperture:IAperture = displayObject as IAperture;
				if (!iAperture.apertureLock) iAperture.multiplyColor();
			}
		}
		static public function multiplyVertex(iApertureMesh:IApertureMesh,vertexV:Vector.<uint>):void {
			const iAperture:IAperture = iApertureMesh as IAperture;
			var parentMult_AO:ApertureObject;
			if (!iAperture.apertureLock) parentMult_AO = getParentMult(iApertureMesh as DisplayObject);
			const l:uint = vertexV.length;
			for (var i:uint=0; i<l; i++) {
				iAperture.calcMult(parentMult_AO,vertexV[i]);
				iApertureMesh.applyVertexMult(vertexV[i]);
			}
		}
		static public function multiplyStyle(style:ApertureDistanceFieldStyle):void {
			const iAperture:IAperture = style as IAperture;
			if (!iAperture.apertureLock) {
				const parentMult_AO:ApertureObject = getParentMult(style.target);
				iAperture.calcMult(parentMult_AO);
			}
		}
		static private function getParentMult(displayObject:DisplayObject):ApertureObject {
			var parentDOC:DisplayObjectContainer;
			if (displayObject) parentDOC = displayObject.parent;
			var parentMult_AO:ApertureObject;
			if (parentDOC is IApertureDisplayObjectContainer) {
				const parentApertureDOC:IApertureDisplayObjectContainer = parentDOC as IApertureDisplayObjectContainer;
				parentMult_AO = parentApertureDOC.getMultAO();
			}
			return parentMult_AO;
		}
		static public function tweenApertureHex(iAperture:IAperture,colorHex:uint,duration:Number,transition:String=null,onComplete:Function=null,onCompleteDelay:Number=0,juggler:Juggler=null):void {
			const r:uint = Color.getRed(colorHex),
				g:uint = Color.getGreen(colorHex),
				b:uint = Color.getBlue(colorHex);
			tweenApertureRGB(iAperture,r,g,b,duration,transition,onComplete,onCompleteDelay,juggler);
		}
		static public function tweenApertureRGB(iAperture:IAperture,finalR:uint,finalG:uint,finalB:uint,duration:Number,transition:String=null,onComplete:Function=null,onCompleteDelay:Number=0,juggler:Juggler=null):void {
			if (transition == null) transition = Transitions.LINEAR;
			if (juggler == null) juggler = Starling.juggler;
			const initHex:uint = iAperture.getHex();
			const initR:uint = Color.getRed(initHex),
				initG:uint = Color.getGreen(initHex),
				initB:uint = Color.getBlue(initHex);
			const tween:TweenEx = TweenEx.getInstance(0,duration,transition);
			tween.animateEx(1);
			const updateA:Array = PoolEx.getArray(),
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
			const complement:Number = 1 - tweenObject.t;
			const r:uint = Math.round(initR*complement+finalR*tweenObject.t),
				g:uint = Math.round(initG*complement+finalG*tweenObject.t),
				b:uint = Math.round(initB*complement+finalB*tweenObject.t);
			iAperture.setRGB(r,g,b);
		}
		static private function completeTween(tween:TweenEx,updateA:Array,completeA:Array,onComplete:Function,delay:Number,juggler:Juggler):void {
			TweenEx.putInstance(tween);
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
