// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.display {

	import starlingEx.display.ApertureQuad;
	import starlingEx.textures.ITextureEx;

	public class QuadEx extends ApertureQuad {

		private var iTextureEx:ITextureEx;
		public function QuadEx(iTextureEx:ITextureEx) {
			super(1,1);
			assignTextureEx(iTextureEx);
		}
		public function assignTextureEx(iTextureEx:ITextureEx):void {
			this.iTextureEx = iTextureEx;
			if (iTextureEx) {
				texture = iTextureEx.texture;
				readjustSize(iTextureEx.quadW,iTextureEx.quadH);
			} else texture = null;
		}
		override public function dispose():void {
			iTextureEx = null;
			super.dispose();
		}
	}

}
