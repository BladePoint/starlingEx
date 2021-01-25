// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.textures {

	import starling.textures.Texture;

	public interface ITextureEx {
		function get textureWidth():uint;
		function get textureHeight():uint;
		function get texture():Texture;
		function get textureMultiplier():Number;
		function get quadW():Number;
		function get quadH():Number;
	}

}
