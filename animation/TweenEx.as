package starlingEx.animation {

	import starling.animation.Tween;
	import starlingEx.animation.TweenObject;

	public class TweenEx extends Tween {
		static var tweenV:Vector.<TweenEx> = new <TweenEx>[];
		static public function getTween(target:Object,time:Number,transition:Object="linear"):TweenEx {
			if (tweenV.length == 0) return new TweenEx(target,time,transition);
			else {
				var tween:TweenEx = tweenV.pop();
				tween.reset(target,time,transition);
				return tween;
			}
		}
		static public function putTween(tween:TweenEx):void {
			if (tween) {
				tween.dispose();
				tweenV[tweenV.length] = tween;
			}
		}
		
		public var tweenObject:TweenObject;
		public function TweenEx(target:Object,time:Number,transition:Object="linear") {
			var superTarget:Object;
			if (target is Number) superTarget = tweenObject = TweenObject.getTweenObject(target as Number);
			else superTarget = target;
			super(superTarget,time,transition);
		}
		public function animateEx(endValue:Number):void {
			if (tweenObject) animate("t",endValue);
			else throw new Error("TweenObject does not exist.");
		}
		override public function reset(target:Object,time:Number,transition:Object="linear"):Tween {
			if (target is Number) {
				if (tweenObject) tweenObject.t = target as Number;
				else tweenObject = TweenObject.getTweenObject(target as Number);
				super.reset(tweenObject,time,transition);
			} else if (target is TweenObject) {
				if (tweenObject != target) disposeTweenObject();
				super.reset(target,time,transition);
			} else {
				disposeTweenObject();
				super.reset(target,time,transition);
			}
			return this;
		}
		private function disposeTweenObject():void {
			if (tweenObject) {
				TweenObject.putTweenObject(tweenObject);
				tweenObject = null;
			}
		}
		public function dispose():void {
			disposeTweenObject();
			reset(null,0);
			removeEventListeners();
		}

	}

}
