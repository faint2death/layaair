package laya.webgl.resource {
	import laya.maths.Arith;
	import laya.renders.Render;
	import laya.resource.Bitmap;
	import laya.resource.Context;
	import laya.utils.Browser;
	import laya.webgl.WebGL;
	import laya.webgl.WebGLContext;
	
	/**
	 * ...
	 * @author
	 */
	public class WebGLSubImage extends Bitmap {
		/*[DISABLE-ADD-VARIABLE-DEFAULT-VALUE]*/
		/**HTML Context*/
		private var _ctx:Context;
		/**HTML Canvas，绘制子图载体,非私有数据载体*/
		public var canvas:*;
		/**是否使用重复模式纹理寻址*/
		public var repeat:Boolean;
		/**是否使用mipLevel*/
		public var mipmap:Boolean;
		/**缩小过滤器*/
		public var minFifter:int;//动态默认值，判断是否可生成miplevel
		/**放大过滤器*/
		public var magFifter:int;//动态默认值，判断是否可生成miplevel
		
		/***是否创建WebGLTexture,值为false时不根据src创建私有WebGLTexture,同时销毁时也只清空source=null,不调用WebGL.mainContext.deleteTexture，目前只有大图合集用到,将HTML Image subImage到公共纹理上*/
		public var createOwnSource:Boolean;
		
		public var atlasImage:*;
		public var offsetX:int = 0;
		public var offsetY:int = 0;
		public var src:String;
		
		///**像素，私有数据*/
		//public var imageData:*
		//public var createFromPixel:Boolean = true;
		
		public function WebGLSubImage(canvas:*, offsetX:int, offsetY:int, width:int, height:int, atlasImage:*, src:String, createOwnSource:Boolean = false) {
			super();
			repeat = true;
			mipmap = false;
			minFifter = -1;
			magFifter = -1;
			
			this.atlasImage = atlasImage;
			
			this.canvas = canvas;
			_ctx = canvas.getContext('2d', undefined);
			this.createOwnSource = createOwnSource;
			_w = width;
			_h = height;
			this.offsetX = offsetX;
			this.offsetY = offsetY;
			this.src = src;
			
			activeResource();
		}
		
		override public function copyTo(dec:Bitmap):void {
			var d:WebGLSubImage = dec as WebGLSubImage;
			super.copyTo(dec);
			d._ctx = _ctx;
		}
		
		private function size(w:Number, h:Number):void {
			_w = w;
			_h = h;
			_ctx && _ctx.size(w, h);
			canvas && (canvas.height = h, canvas.width = w);
		}
		
		override protected function recreateResource():void {
			size(_w, _h);
			_ctx.drawImage(atlasImage, offsetX, offsetY, _w, _h, 0, 0, _w, _h);
			//imageData = _ctx.getImageData(0, 0, _w, _h);
			(createOwnSource) && (createWebGlTexture());
			super.recreateResource();
		}
		
		private function createWebGlTexture():void {
			var gl:WebGLContext = WebGL.mainContext;
			
			if (!canvas) {
				debugger;
				throw "create GLTextur err:no data:" + canvas;
			}
			var glTex:* = _source = gl.createTexture();
			gl.bindTexture(WebGLContext.TEXTURE_2D, glTex);
			gl.texImage2D(WebGLContext.TEXTURE_2D, 0, WebGLContext.RGBA, WebGLContext.RGBA, WebGLContext.UNSIGNED_BYTE, canvas);
			
			var minFifter:int = this.minFifter;
			var magFifter:int = this.magFifter;
			var repeat:int = this.repeat ? WebGLContext.REPEAT : WebGLContext.CLAMP_TO_EDGE
			
			var isPOT:Boolean = Arith.isPOT(width, height);//提前修改内存尺寸，忽悠异步影响
			if (isPOT) {
				if (this.mipmap)
					(minFifter !== -1) || (minFifter = WebGLContext.LINEAR_MIPMAP_LINEAR);
				else
					(minFifter !== -1) || (minFifter = WebGLContext.LINEAR);
				
				(magFifter !== -1) || (magFifter = WebGLContext.LINEAR);
				
				gl.texParameteri(WebGLContext.TEXTURE_2D, WebGLContext.TEXTURE_MAG_FILTER, magFifter);
				gl.texParameteri(WebGLContext.TEXTURE_2D, WebGLContext.TEXTURE_MIN_FILTER, minFifter);
				gl.texParameteri(WebGLContext.TEXTURE_2D, WebGLContext.TEXTURE_WRAP_S, repeat);
				gl.texParameteri(WebGLContext.TEXTURE_2D, WebGLContext.TEXTURE_WRAP_T, repeat);
				this.mipmap && gl.generateMipmap(WebGLContext.TEXTURE_2D);
			} else {
				(minFifter !== -1) || (minFifter = WebGLContext.LINEAR);
				(magFifter !== -1) || (magFifter = WebGLContext.LINEAR);
				gl.texParameteri(WebGLContext.TEXTURE_2D, WebGLContext.TEXTURE_MIN_FILTER, minFifter);
				gl.texParameteri(WebGLContext.TEXTURE_2D, WebGLContext.TEXTURE_MAG_FILTER, magFifter);
				gl.texParameteri(WebGLContext.TEXTURE_2D, WebGLContext.TEXTURE_WRAP_S, WebGLContext.CLAMP_TO_EDGE);
				gl.texParameteri(WebGLContext.TEXTURE_2D, WebGLContext.TEXTURE_WRAP_T, WebGLContext.CLAMP_TO_EDGE);
			}
			gl.bindTexture(WebGLContext.TEXTURE_2D, null);
			canvas = null;
			memorySize = _w * _h * 4;
		}
		
		override protected function detoryResource():void {
			if (createOwnSource && _source) {
				WebGL.mainContext.deleteTexture(_source);
				_source = null;
				memorySize = 0;
			}
		}
	
	}

}