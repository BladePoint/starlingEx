# StarlingEx
This repository contains several extensions that expand the functionality of their base Starling classes, and some new original classes as well that I hope you will find useful. The highlights are as follows.

## ApertureSprite
An ApertureSprite is a container, much like its base Sprite class, with the additional functionality of allowing you to assign a color to it. The container itself does not display a color, but every child that implements IAperture will automatically have its color multiplied by the parent color, unless its apertureLock property is set to true. This is useful if you wish to tint a number of IAperture DisplayObjects at the same time to the same color, such as if you are doing a fade-to-black effect. You could also apertureLock one of the children to prevent it from darkening to produce a spotlight effect.

## ApertureQuad
In order to utilize ApertureSprite's color feature, children must implement IAperture. ApertureQuad extends Quad and implements IAperture, and thus can have its color changed by its parent ApertureSprite. Changing colors in this manner is very fast and efficient and does not require additional draw calls, although it is limited in that it can only reduce the color in a channel, much like how reducing the aperture size in a camera can only reduce the amount of light coming in. If you wanted to increase the color in a channel, that would require the use of a color offset filter, which would need additional draw calls. The Starling Manual has an excellent [explanation of this.](https://manual.starling-framework.org/en/#_the_goal)

## TextFormatEx
TextFormatEx sets the default formatting for a TextFieldEx. It has 3 additional features over the standard TextFormat.
* Set the color for each corner which will be applied to all the letters.
* Set the thickness and color of an outline that goes around all the letters. This only works with distance field bitmap fonts.
* Set the position, color, and alpha of a dropshadow that appears behind all the letters.

## TextFieldEx
![TextFieldEx](https://github.com/BladePoint/StarlingEx/blob/master/docs/TextFieldEx.png)
TextFieldEx extends ApertureSprite and uses ApertureQuads for letters. You can override the TextFormatEx formatting through the use of inline tags which use a format similar to BBCode.
* The [font] tag can be used to change fonts anywhere in the textfield. All fonts must be registered in Compositor with the registerFont method: [font=arial]Arial[/font]
* The [size] tag can be used to change the font size anywhere in the textfield: [size=14]smaller text[/size]
* the [offsetY] tag can be used to adjust the vertical alignment of text. You may wish to do this if changing the font and size cause the text to be misaligned: [offsetY=-10]higher text[/offset]
* The [color] tag can have either 1, 2, or 4 comma-separated assignments.
  * Use 1 assignment like the following to color the text between the tags red: [color=0xff0000]red[/color]
  * If you use 2 assignments, the top half of the text will use the first color and the bottom half of the text will use the second color: [color=0xff0000,0x00ff00]red and green[/color]
  * If you use 4 assignments, the top left corner will use the first color, the top right corner will use the second color, the bottom left corner will use the third color, and the bottom right corner will use the fourth color: [color=0xff0000,0x00ff00,0x0000ff,0x000000]red, green, blue, and black[/color]
* The [outlineColor] tag sets the color of the outline to go around the tagged text. [outlineColor=0xff0000]red outline[/outlineColor].
* The [outlineWidth] tag sets the width of the outline to go around the tagged text. You may assign values between 0 (no outline) and .5 (max outline), although using higher values may cause artifacts to appear with the outline. You don't need to create a bold version of your font, if you use [outlineWidth] with an [outlineColor] set to the same color as your text. [outlineWidth=.25]medium thickness outline[/outlineWidth]
* The [italic] tag simulates italics by skewing the letters to the side, so you don't have to create an italic version of your font. [italic]simulated italics[/italic]
* The [underline] tag draws a line underneath the tagged text. [underline]line under this text[/underline]
* The [strikehtrough] tag draw a line through the middle of the tagged text. [strikethrough]line through this text[/strikethrough]
* The [link] tag makes a clickable link in your ApertureTextField, similar to a hyperlink. When setting the text of the ApertureTextField, either through the contructor or through the setText method, use the linkFunctionA paramter to pass an array of functions to be called. The first [link] in the text will call the first function in the array when clicked, and the second [link] in the text will call the second function in the array, etc. [link]clickable link[/link]

Don't forget to close your tags. Try out the [demo here.](https://www.newgrounds.com/projects/games/1546135/preview) If you click the "zoom in" TextLink, you'll notice there is no pixelization as the size increases because a distance field font is being used. The following string was used to produce the text in the demo: `"[link]zoom out[/link] [link]zoom in[/link]\nArial [strikethrough]strikethrough[/strikethrough] [underline]underline[/underline]\n[font=marker]Fine Tip Marker [size=35]smaller[/size] [size=110]larger[/size] [offsetY=-20]offsetY[/offsetY][/font]\n[font='korinna']Korinna [outlineWidth=.2]bold[/outlineWidth] [italic]italic [outlineWidth=.2]bold and italic[/italic][/outlineWidth]\n[outlineColor=0xff0000][outlineWidth=.15][underline]red outline[/underline][/outlineColor][/font][outlineColor=0x00ff00] [color=0x000000,0x00ff00]green outline gradient[/color][/outlineColor]\n[outlineColor=0xffffff][color=0xff0000,0x00ff00,0x0000ff,0x000000]white outline red green blue black[/color][/outlineColor][/outlineWidth]"`

## TextLink
Set the following static properties of the TextLink class to change the default colors of links:
defaultNormalTopLeft, defaultNormalTopRight, defaultNormalBottomLeft, defaultNormalBottomRight, defaultNormalOutlineColor, defaultHoverTopLeft,
defaultHoverTopRight, defaultHoverBottomLeft, defaultHoverBottomRight, defaultHoverOutlineColor, defaultNormalWidth, defaultHoverWidth

## BitmapFontEx
BitmapFontEx implements IFont, which is required to work with TextFieldEx. A BitmapFontEx requires a bitmap font and XML pair generated by a tool like [soimy's msdf-bmfont-xml.](https://github.com/soimy/msdf-bmfont-xml) You can pass a string of characters that you want to use into the constructor, or leave it blank to use all the characters included in the font. After instantiating a BitmapFontEx, you must initialize it in one of three ways:
* Initialize with a BitmapData and XML, and an optional DynamicAtlas: initBitmapData(fontAtlas_BMD:BitmapData,fontXML:XML,dynamicAtlas:DynamicAtlas=null)
* Initialize with a Bitmap class, used when embedding images, and XML, and an optional DynamicAtlas: initBitmapClass(fontAtlasBitmapClass:Class,fontXML:XML,dynamicAtlas:DynamicAtlas=null)
* Initialize with a Texture and XML. You cannot use a DynamicAtlas if you initialize in this manner: initTexture(fontAtlasTexture:Texture,fontXML:XML)

After creating a BitmapFontEx, you must register it with Compositor using the registerFont method.
```
var arial_BFX:BitmapFontEx = new BitmapFontEx("abcdefghijklmnopqrstuvwxyz");
arial_BFX.initBitmapData(arial_BMD,arial_XML);
Compositor.registerFont(arial_BFX,"arial");
```

Use the setWhiteTexture(x:uint,y:uint) method and pass in the coordinates of a 1x1 section of the texture that is purely white. This subtexture will be used when drawing strikethroughs and underlines to prevent an additional draw call. This method is not necessary if you are using a DynamicAtlas.

## DynamicAtlas
A DynamicAtlas takes multiple BitmapDatas and packs them into a small power-of-two-sized Texture. You can save some GPU memory by doing this, and if your Quads which use that texture all have the same style, you can save draw calls as well. BitmapDatas to be packed by a DynamicAtlas first have to go into a TextureBitmapData.

## TextureBitmapData
The constructor of a TextureBitmapData takes the source BitmapData as the sole parameter. If you're only using a portion of the source BitmapData, use setSourceOffset(offsetX:uint,offsetY:uint) to specify the coordinates of the section you want to use, and setSourceDimensions(w:Number,h:Number) to specify its width and height. Use a TextureBitmapData's texture property to return a Texture generated from that section of the source BitmapData. If you pack the TextureBitmapData into a DynamicAtlas before using it's texture property, it will return a SubTexture from the DynamicAtlas.

Heres an example showing how some of all this works:
```
public class StarlingEx_root extends Sprite {
	[Embed(source="/fonts/DG_Arial.png")]
	public var Arial_BMP:Class;
	[Embed(source="/fonts/DG_Arial.fnt", mimeType="application/octet-stream")]
	public var Arial_XML:Class;
	[Embed(source="/fonts/Korinna-Bold.png")]
	public var Korinna_BMP:Class;
	[Embed(source="/fonts/Korinna-Bold.fnt", mimeType="application/octet-stream")]
	public var Korinna_XML:Class;
	public function StarlingEx_root {
    		var dynamicAtlas:DynamicAtlas = new DynamicAtlas();
		var arial_xml:XML = XML(new Arial_XML());
		var arial_BFX:BitmapFontEx = BitmapFontEx.getInstance();
		arial_BFX.initBitmapClass(Arial_BMP,arial_xml,dynamicAtlas);
		var korinna_xml:XML = XML(new Korinna_XML());
		var korinna_BFX:BitmapFontEx = BitmapFontEx.getInstance();
		korinna_BFX.initBitmapClass(Korinna_BMP,korinna_xml,dynamicAtlas);
		dynamicAtlas.pack();
		Compositor.registerFont(arial_BFX,"arial");
		Compositor.registerFont(korinna_BFX,"korinna");
    		var textFormat:TextFormatEx = TextFormatEx.getInstance("arial",32);
    		textFormat.softness = .3;
		textFormat.dropShadowX = textFormat.dropShadowY = 4;
    		var textField:TextFieldEx = new TextFieldEx(-1,-1,
			"This is size 32 Arial. [size=50][font=korinna]This is size 50 Korinna.[/font][/size]",
			textFormat
    		);
		addChild(textField);
	}
}
```
