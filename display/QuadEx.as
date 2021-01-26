// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.display {

	import starlingEx.display.ApertureQuad;
	import starlingEx.textures.ITextureEx;

	public class QuadEx extends ApertureQuad {

		protected var iTextureEx:ITextureEx;
		public function QuadEx(iTextureEx:ITextureEx=null) {
			var w:uint, h:uint;
			if (iTextureEx) {
				w = iTextureEx.quadW;
				h = iTextureEx.quadH;
			} else w = h = 1;
			super(w,h);
			assignTextureEx(iTextureEx);
		}
		public function assignTextureEx(iTextureEx:ITextureEx):void {
			this.iTextureEx = iTextureEx;
			if (iTextureEx) {
				texture = iTextureEx.texture;
				readjustSize(iTextureEx.quadW,iTextureEx.quadH);
			}
			else texture = null;
		}
		override public function dispose():void {
			iTextureEx = null;
			super.dispose();
		}
	}

}
