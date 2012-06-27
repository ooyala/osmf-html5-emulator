package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.errors.StackOverflowError;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.system.Security;

	import flashx.textLayout.factory.StringTextLineFactory;

	import org.osmf.containers.MediaContainer;
	import org.osmf.elements.VideoElement;
	import org.osmf.events.PlayEvent;
	import org.osmf.events.TimeEvent;
	import org.osmf.media.DefaultMediaFactory;
	import org.osmf.media.MediaElement;
	import org.osmf.media.MediaFactory;
	import org.osmf.media.MediaPlayer;
	import org.osmf.media.MediaPlayerSprite;
	import org.osmf.media.URLResource;

	[SWF(width="640", height="352")]
	public class Main extends Sprite
	{
		private var sprite:MediaPlayerSprite;
		private var adsSprite:MediaPlayerSprite;
		private var currentStream:String = '';
		private var currentAdsStream:String = '';
		private var isAdPlaying:Boolean = false;

		public function Main()
		{
			Security.allowDomain('*');
			Security.allowInsecureDomain('*');

			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;

			// style the player
			stage.color = 0x000000;

			// Create the container class that displays the media.
			sprite = new MediaPlayerSprite();
			adsSprite = new MediaPlayerSprite();

			this.showMainPlayer(true);

            this.syncPlayerToStage(sprite);
			this.syncPlayerToStage(adsSprite);
			addChild(sprite);
			addChild(adsSprite);

			stage.addEventListener(Event.RESIZE, onResize);

			// Register external api
			ExternalInterface.addCallback('load',load);
			ExternalInterface.addCallback('play',play);
			ExternalInterface.addCallback('loadAds',loadAds);
			ExternalInterface.addCallback('playAds',playAds);
			ExternalInterface.addCallback('pause',pause);
			ExternalInterface.addCallback('seek',seek);
			ExternalInterface.addCallback('setVolume',setVolume);
			ExternalInterface.addCallback('getStreamUrl',getStreamUrl);
			ExternalInterface.addCallback('getVolume',getVolume);
			ExternalInterface.addCallback('getCurrentTime',getCurrentTime);
			ExternalInterface.addCallback('getDuration',getDuration);
			ExternalInterface.addCallback('getBuffer',getBuffer);
			ExternalInterface.addCallback('getSeekableRange',getSeekableRange);

			// hook up events
			sprite.mediaPlayer.addEventListener(PlayEvent.PLAY_STATE_CHANGE, onPlayEvent);
			sprite.mediaPlayer.addEventListener(TimeEvent.CURRENT_TIME_CHANGE, onTimeChange);
			sprite.mediaPlayer.addEventListener(TimeEvent.DURATION_CHANGE, onTimeChange);

			// Notify loading complete
			reportEvent("osmf-ready");
		}

		private function onResize(event:Event):void
		{
			this.syncPlayerToStage(sprite);
			this.syncPlayerToStage(adsSprite);
		}

		private function showMainPlayer(shown:Boolean):void
		{
			sprite.visible = shown;
			adsSprite.visible = !shown;
		}

		private function syncPlayerToStage(s:MediaPlayerSprite):void
		{
			s.width = stage.stageWidth;
			s.height = stage.stageHeight;
			s.mediaPlayer.autoPlay = false;
		}

		public function reportEvent(event:String):void
		{
			ExternalInterface.call(root.loaderInfo.parameters.callback+'("' + event + '")');
		}

		public function onPlayEvent(event: PlayEvent):void
		{
			if(sprite.mediaPlayer.playing) {
				reportEvent('playing');
			} else {
				reportEvent('paused');
			}
		}

		public function onTimeChange(event:TimeEvent):void
		{
			reportEvent('playheadUpdate:'+sprite.mediaPlayer.currentTime+':'+sprite.mediaPlayer.duration);
		}

		private function loadForSprite(s:MediaPlayerSprite, url:String, curStream:String):String
		{
			try
			{
				if(url!=curStream)
				{
					s.resource = new URLResource(url);
					curStream = url;
				}
			}
			catch(e:*)
			{
				ExternalInterface.call('alert("error ' + e.toString()+ '")');
			}
			return curStream;
		}

		public function seek(playhead:Number):void
		{
			if (this.isAdPlaying)
			{
				adsSprite.mediaPlayer.seek(playhead);
			} else {
				sprite.mediaPlayer.seek(playhead);
			}
		}

		public function setVolume(volume:Number):void
		{
			if (this.isAdPlaying)
			{
				adsSprite.mediaPlayer.volume = volume;
			} else {
				sprite.mediaPlayer.volume = volume;
			}
		}

		public function load(url:String):void
		{
			currentStream = this.loadForSprite(sprite, url, currentStream);
		}

		public function play():void
		{
			reportEvent('will-play');
			this.isAdPlaying = false;
			this.showMainPlayer(true);
			sprite.mediaPlayer.play();
			this.pauseWithTry(adsSprite);
		}

		public function loadAds(url:String):void
		{
			currentAdsStream = this.loadForSprite(adsSprite, url, currentAdsStream);
		}

		public function playAds():void
		{
			reportEvent('will-play');
			this.isAdPlaying = true;
			this.showMainPlayer(false);
			this.pauseWithTry(sprite);
			adsSprite.mediaPlayer.play();
		}

		private function pauseWithTry(s:MediaPlayerSprite):void
		{
			try
			{
				s.mediaPlayer.pause();
			}
			catch(e:*)
			{

			}
		}

		public function pause():void
		{
			this.pauseWithTry(sprite);
			this.pauseWithTry(adsSprite);
		}

		public function getStreamUrl():String
		{
			return (this.isAdPlaying) ? currentAdsStream : currentStream;
		}

		public function getVolume():Number
		{
			return (this.isAdPlaying) ? adsSprite.mediaPlayer.volume : sprite.mediaPlayer.volume;
		}

		public function getCurrentTime():Number
		{
			return (this.isAdPlaying) ? adsSprite.mediaPlayer.currentTime : sprite.mediaPlayer.currentTime;
		}

		public function getDuration():Number
		{
			return (this.isAdPlaying) ? adsSprite.mediaPlayer.duration : sprite.mediaPlayer.duration;
		}

		public function getBuffer():Number
		{
			return (this.isAdPlaying) ? adsSprite.mediaPlayer.bufferLength : sprite.mediaPlayer.bufferLength;
		}

		public function getSeekableRange():Object
		{
			return null;
		}

	}
}