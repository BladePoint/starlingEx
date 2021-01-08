// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.display {

	import flash.geom.Rectangle;
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.utils.Pool;
	import starlingEx.display.ApertureSprite;

	public class ButtonEx extends ApertureSprite {

		public var clickFunction:Function;
		public var enableOnAdd:Boolean = true,
			disableOnClick:Boolean = true;
		protected var displayObject:DisplayObject;
		protected var triggerBounds:Rectangle;
		protected var hover:Boolean;
		public function ButtonEx(displayObject:DisplayObject,clickFunction:Function) {
			this.displayObject = displayObject;
			this.clickFunction = clickFunction;
			addChild(displayObject);
			useHandCursor = true;
			initTriggerBounds();
			removedFromStage();
		}
		protected function initTriggerBounds():void {
			triggerBounds = Pool.getRectangle();
		}
		protected function removedFromStage(evt:Event=null):void {
			removeEventListener(Event.REMOVED_FROM_STAGE,removedFromStage);
			addEventListener(Event.ADDED_TO_STAGE,addedToStage);
		}
		protected function addedToStage(evt:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE,addedToStage);
			initTouch();
			addEventListener(Event.REMOVED_FROM_STAGE,removedFromStage);
		}
		protected function initTouch():void {
			if (enableOnAdd) enableTouch();
			else disableTouch();
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
			const touch:Touch = evt.getTouch(this,null);
			if (touch == null) mouseOut();
			else {
				if (touch.phase == TouchPhase.HOVER) mouseOver();
				else if (touch.phase == TouchPhase.BEGAN && hover) mouseDown(evt,touch);
				else if (touch.phase == TouchPhase.MOVED) mouseMove(touch);
				else if (touch.phase == TouchPhase.ENDED && hover) mouseUp(touch);
			}
		}
		private function mouseOut():void {
			hover = false;
			mouseOutMethod();
		}
		protected function mouseOutMethod():void {}
		private function mouseOver():void {
			if (hover) return;
			else {
				hover = true;
				mouseOverMethod();
			}
		}
		protected function mouseOverMethod():void {}
		protected function mouseMove(touch:Touch):void {
			var withinBounds:Boolean = triggerBounds.contains(touch.globalX,touch.globalY);
			if (hover && !withinBounds) mouseOut();
			else if (!hover && withinBounds) mouseOver();
		}
		protected function mouseDown(touchEvent:TouchEvent,touch:Touch):void {
			const displayObject:DisplayObject = touchEvent.target as DisplayObject;
			displayObject.getBounds(stage,triggerBounds);
		}
		private function mouseUp(touch:Touch):void {
			if (touch.cancelled) return;
			else {
				mouseUpMethod();
				if (clickFunction != null) clickFunction();
				if (disableOnClick) disableTouch();
			}
		}
		protected function mouseUpMethod():void {}
		override public function dispose():void {
			removeEventListener(Event.REMOVED_FROM_STAGE,removedFromStage);
			removeEventListener(Event.ADDED_TO_STAGE,addedToStage);
			removeEventListener(TouchEvent.TOUCH,onTouch);
			clickFunction = null;
			removeChild(displayObject);
			displayObject = null;
			Pool.putRectangle(triggerBounds);
			triggerBounds = null;
			super.dispose();
		}
	}

}
