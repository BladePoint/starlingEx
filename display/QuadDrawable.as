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
		public function QuadDrawable(textureDrawable:TextureDrawable=null) {
			super(textureDrawable);
			addEventListener(Event.ADDED_TO_STAGE,onAddedToStage);
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
		private function onAddedToStage(evt:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE,onAddedToStage);
			demandTexture();
		}
		public function demandTexture(evt:Event=null):void {
			texture = _textureDrawable.texture;
		}
		public function get textureDrawable():TextureDrawable {
			return _textureDrawable;
		}
		override public function dispose():void {
			assignTextureEx(null);
			super.dispose();
		}
	}

}
