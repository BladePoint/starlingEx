package starlingEx.animation {

	public class TweenObject {
		static var tweenObjectV:Vector.<TweenObject> = new <TweenObject>[];
		static public function getTweenObject(initialT:Number=0):TweenObject {
			if (tweenObjectV.length == 0) return new TweenObject(initialT);
			else {
				var tweenObject:TweenObject = tweenObjectV.pop();
				tweenObject.t = initialT;
				return tweenObject;
			}
		}
		static public function putTweenObject(tweenObject:TweenObject):void {
			if (tweenObject) tweenObjectV[tweenObjectV.length] = tweenObject;
		}

		public var t:Number;
		public function TweenObject(initialT:Number=0) {
			t = initialT;
		}

	}

}
