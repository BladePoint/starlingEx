package starlingEx.display {

	import flash.geom.Rectangle;
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.utils.Pool;
	import starlingEx.display.ApertureSprite;

	public class Button extends ApertureSprite {

		public var clickFunction:Function;
		public var enableOnAdd:Boolean = true,
			disableOnClick:Boolean = true;
		protected var displayObject:DisplayObject;
		protected var triggerBounds:Rectangle;
		protected var hover:Boolean;
		public function Button(displayObjectP:DisplayObject,clickFunctionP:Function) {
			displayObject = displayObjectP;
			clickFunction = clickFunctionP;
			addChild(displayObject);
			addEventListener(Event.ADDED_TO_STAGE,addedToStage);
		}
		protected function addedToStage(evt:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE,addedToStage);
			triggerBounds = Pool.getRectangle();
			setBounds();
			touchGroup = useHandCursor = true;
			initTouch();
		}
		protected function initTouch():void {
			if (enableOnAdd) enableTouch();
			else disableTouch();
		}
		public function setBounds():void {
			displayObject.getBounds(displayObject.stage,triggerBounds);
		}
		public function enableTouch():void {
			addEventListener(TouchEvent.TOUCH,onTouch);
			touchable = true;
		}
		public function disableTouch():void {
			removeEventListener(TouchEvent.TOUCH,onTouch);
			touchable = false;
			mouseOut();
		}
		private function onTouch(evt:TouchEvent):void {
			var touch:Touch = evt.getTouch(this,null);
			if (touch == null) mouseOut();
			else {
				if (touch.phase == TouchPhase.HOVER) mouseOver();
				else if (touch.phase == TouchPhase.MOVED) mouseMove(touch);
				else if (touch.phase == TouchPhase.BEGAN && hover) mouseDown(touch);
				else if (touch.phase == TouchPhase.ENDED && hover) mouseUp(touch);
			}
		}
		protected function mouseOut():void {
			hover = false;
		}
		protected function mouseOver():void {
			if (hover) return;
			else hover = true;
		}
		protected function mouseMove(touch:Touch):void {
			var withinBounds:Boolean = triggerBounds.contains(touch.globalX,touch.globalY);
			if (!withinBounds) mouseOut();
			else if (!hover) mouseOver();
		}
		protected function mouseDown(touch:Touch):void {
			displayObject.getBounds(stage,triggerBounds);
		}
		protected function mouseUp(touch:Touch):void {
			if (touch.cancelled) return;
			else {
				if (clickFunction != null) clickFunction();
				if (disableOnClick) disableTouch();
			}
		}
		override public function dispose():void {
			clickFunction = null;
			removeChild(displayObject);
			displayObject = null;
			removeEventListener(TouchEvent.TOUCH,onTouch);
			Pool.putRectangle(triggerBounds);
			triggerBounds = null;
			super.dispose();
		}
	}

}
