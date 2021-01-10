package starlingEx.textures {

	import starling.textures.Texture;

	public interface ITextureOnDemand {

		function calcQuadDimensions():void;
		function get quadW():uint;
		function get quadH():uint;
		function get texture():Texture;

	}
	
}
