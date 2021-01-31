// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.display {

	import starling.events.Event;
	import starlingEx.display.QuadEx;
	import starlingEx.textures.ITextureEx;
	import starlingEx.textures.TextureDrawable;

	public class QuadDrawable extends QuadEx {

		private var _textureDrawable:TextureDrawable;
		private var _fixedW:Number, _fixedH:Number;
		public function QuadDrawable(textureDrawable:TextureDrawable=null) {
			super(textureDrawable);
			onRemovedFromStage();
		}
		override public function assignTextureEx(iTextureEx:ITextureEx):void {
			this.iTextureEx = iTextureEx;
			if (_textureDrawable) {
				_textureDrawable.removeEventListener(Event.CHANGE,demandTexture);
				_textureDrawable = null;
			}
			if (iTextureEx) {
				_textureDrawable = iTextureEx as TextureDrawable;
				_textureDrawable.addEventListener(Event.CHANGE,demandTexture);
			}
		}
		private function onRemovedFromStage(evt:Event=null):void {
			removeEventListener(Event.REMOVED_FROM_STAGE,onRemovedFromStage);
			addEventListener(Event.ADDED_TO_STAGE,onAddedToStage);
		}
		private function onAddedToStage(evt:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE,onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE,onRemovedFromStage);
			demandTexture();
		}
		public function demandTexture(evt:Event=null):void {
			texture = _textureDrawable.texture;
			var w:Number, h:Number;
			if (!isNaN(_fixedW)) w = _fixedW;
			else w = _textureDrawable.quadW;
			if (!isNaN(_fixedH)) h = _fixedH;
			else h = _textureDrawable.quadH;
			readjustSize(w,h);
		}
		public function get textureDrawable():TextureDrawable {
			return _textureDrawable;
		}
		override public function readjustSize(width:Number=-1,height:Number=-1):void {
			if (width != -1) _fixedW = width;
			if (height != -1) _fixedH = height;
			super.readjustSize(width,height);
		}
		public function get fixedW():Number {return _fixedW;}
		public function get fixedH():Number {return _fixedH;}
		public function reset():void {
			_fixedW = _fixedH = NaN;
			assignTextureEx(null);
		}
		override public function dispose():void {
			assignTextureEx(null);
			super.dispose();
		}
	}

}
