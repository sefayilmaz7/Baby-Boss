//#define GGI_ENABLED
//#define IRONSOURCE_ENABLED
//#define LIONKIT_ENABLED

// Only one ad SDK can be active at a time
#if GGI_ENABLED
#undef IRONSOURCE_ENABLED
#undef LIONKIT_ENABLED
#elif IRONSOURCE_ENABLED
#undef LIONKIT_ENABLED
#endif

#if GGI_ENABLED
using GGI.Ads;
using GGI.Core;
#endif
#if LIONKIT_ENABLED
using LionStudios.Ads;
#endif
using UnityEngine;

namespace FTemplateNamespace
{
	public class AdsModule : MonoBehaviour
	{
#if IRONSOURCE_ENABLED
		private enum BannerAdLoadState { NotLoaded = 0, Loading = 1, Loaded = 2 };
#endif

		public delegate void BannerAdVisibilityChangeCallback( bool isVisible );
		public delegate void RewardedAdCallback( RewardedAdReward reward );

#pragma warning disable IDE0044
#pragma warning disable 0414
#pragma warning disable 0649
		private AdsConfiguration configuration;
		public AdsConfiguration Configuration { get { return configuration; } }

		private float nextInterstitialAdShowTime;
		private bool skipNextInterstitialAd;

		private float calculatedBannerAdHeight;

#if GGI_ENABLED || LIONKIT_ENABLED
		private bool? pendingBannerVisibilityCallback;
#endif

#if IRONSOURCE_ENABLED
		private float nextBannerAdLoadTime = float.PositiveInfinity;
		private float nextInterstitialAdLoadTime = float.PositiveInfinity;
		private float nextRewardedAdLoadTime = float.PositiveInfinity;

		private BannerAdLoadState bannerAdLoadState;
		private bool isBannerAdVisible;
#endif

#if LIONKIT_ENABLED
		private LionStudios.Ads.ShowAdRequest bannerAdRequest;
		private LionStudios.Ads.ShowAdRequest interstitialAdRequest;
		private LionStudios.Ads.ShowAdRequest rewardedAdRequest;
#endif

		[SerializeField]
		private BannerBackground bannerAdBackground;

		public bool BannerAdVisible { get; private set; }
		public bool BannerAdAtBottom { get; private set; }
		public float BannerAdHeightInPixels { get; private set; }

		public event BannerAdVisibilityChangeCallback OnBannerAdVisibilityChanged;

		private RewardedAdCallback rewardedAdCallback;
		private RewardedAdReward? pendingRewardedAdReward;
#pragma warning restore 0649
#pragma warning restore 0414
#pragma warning restore IDE0044

		#region Helper Classes
#pragma warning disable 0414
		public struct RewardedAdReward
		{
			public readonly string currency;
			public readonly int amount;

			public RewardedAdReward( string currency, int amount )
			{
				this.currency = currency;
				this.amount = amount;
			}
		}
#pragma warning restore 0414
		#endregion

		#region SDK Integration Queries
		public bool AdsEnabled
		{
			get
			{
#if UNITY_EDITOR || GGI_ENABLED || IRONSOURCE_ENABLED || LIONKIT_ENABLED
				return true;
#else
				return false;
#endif
			}
		}
		#endregion

		#region Initialization & Unity Messages
		public void SetConfiguration( AdsConfiguration configuration )
		{
			if( !configuration || this.configuration == configuration )
				return;

			this.configuration = configuration;

#if GGI_ENABLED
			try
			{
				// GGI SDK always shows bottom banner ads
				BannerAdAtBottom = true;

				BannerAd.OnBannerShowing += GGIBannerShown;
				BannerAd.OnBannerHiding += GGIBannerHidden;
			}
			catch( System.Exception e )
			{
				Debug.LogException( e );
			}
#endif

#if IRONSOURCE_ENABLED
			try
			{
				IronSource.Agent.init( configuration.IronSourceAppID );
				IronSource.Agent.loadInterstitial();

				IronSourceEvents.onBannerAdLoadFailedEvent += IronSourceBannerLoadFailed;
				IronSourceEvents.onBannerAdLoadedEvent += IronSourceBannerLoaded;
				IronSourceEvents.onInterstitialAdLoadFailedEvent += IronSourceInterstitialLoadFailed;
				IronSourceEvents.onInterstitialAdClosedEvent += IronSourceInterstitialClosed;
				IronSourceEvents.onRewardedVideoAdRewardedEvent += IronSourceRewardedAdRewarded;

				// To validate the IronSource integration (shown in logcat/Xcode console)
				//IronSource.Agent.validateIntegration();

				// To receive detailed logs from mediation networks
				//IronSource.Agent.setAdaptersDebug( true );

				// To log the device ID
				//Debug.Log( IronSource.Agent.getAdvertiserId() );
			}
			catch( System.Exception e )
			{
				Debug.LogException( e );
			}
#endif

#if LIONKIT_ENABLED
			try
			{
				// Default position is bottom center
				BannerAdAtBottom = true;

				bannerAdRequest = new LionStudios.Ads.ShowAdRequest();
				interstitialAdRequest = new LionStudios.Ads.ShowAdRequest();
				rewardedAdRequest = new LionStudios.Ads.ShowAdRequest();

				bannerAdRequest.OnDisplayed += LionKitBannerShown;
				bannerAdRequest.OnHidden += LionKitBannerHidden;
				rewardedAdRequest.OnReceivedReward += LionKitRewardedAdRewarded;
			}
			catch( System.Exception e )
			{
				Debug.LogException( e );
			}
#endif
		}

		private void Start()
		{
#if GGI_ENABLED || LIONKIT_ENABLED
			float dpi = Screen.dpi;
			float dp = dpi / 160f;

			bool isTablet = false;
			if( Screen.width >= 800f && Screen.height >= 800f )
			{
				float screenWidth = Screen.width / dpi;
				float screenHeight = Screen.height / dpi;
				isTablet = Mathf.Sqrt( screenWidth * screenWidth + screenHeight * screenHeight ) >= 6.5f;
			}

			if( isTablet )
				calculatedBannerAdHeight = 60f * dp;
			else if( Screen.height <= 400f * dp )
				calculatedBannerAdHeight = 32f * dp;
			else
				calculatedBannerAdHeight = 54f * dp;
#elif IRONSOURCE_ENABLED
			float dp = Screen.dpi / 160f;
			if( Screen.height <= 720f * dp )
				calculatedBannerAdHeight = 50f * dp;
			else
				calculatedBannerAdHeight = 90f * dp;
#else
			calculatedBannerAdHeight = 0f;
#endif
		}

		private void Update()
		{
			float time = Time.unscaledTime;

			// Callbacks must be invoked from main thread
			if( pendingRewardedAdReward.HasValue )
			{
				RewardedAdReward reward = pendingRewardedAdReward.Value;
				pendingRewardedAdReward = null;

				if( rewardedAdCallback != null )
				{
					rewardedAdCallback( reward );
					rewardedAdCallback = null;
				}
			}

#if GGI_ENABLED || LIONKIT_ENABLED
			if( pendingBannerVisibilityCallback.HasValue )
			{
				bool bannerVisible = pendingBannerVisibilityCallback.Value;
				pendingBannerVisibilityCallback = null;

				BannerAdVisibilityChanged( bannerVisible );
			}
#endif

#if IRONSOURCE_ENABLED
			// Retry failed load ad requests
			if( time >= nextBannerAdLoadTime )
			{
				IronSource.Agent.loadBanner( IronSourceBannerSize.BANNER, BannerAdAtBottom ? IronSourceBannerPosition.BOTTOM : IronSourceBannerPosition.TOP );
				nextBannerAdLoadTime = float.PositiveInfinity;
			}

			if( time >= nextInterstitialAdLoadTime )
			{
				IronSource.Agent.loadInterstitial();
				nextInterstitialAdLoadTime = float.PositiveInfinity;
			}
#endif
		}

#if IRONSOURCE_ENABLED
		private void OnApplicationPause( bool isPaused )
		{
			IronSource.Agent.onApplicationPause( isPaused );
		}
#endif
		#endregion

		#region Advertisement Functions
		public bool IsInterstitialAdAvailable()
		{
			if( !configuration )
			{
				Debug.LogError( "Call SetConfiguration before showing ads!" );
				return false;
			}

#if GGI_ENABLED
			return GGIAds.Instance.IsInterstitialAvailable();
#elif IRONSOURCE_ENABLED
			return IronSource.Agent.isInterstitialReady();
#elif LIONKIT_ENABLED
			return LionStudios.Ads.Interstitial.IsAdReady;
#elif UNITY_EDITOR
			return true;
#else
			return false;
#endif
		}

		public bool IsRewardedAdAvailable()
		{
			if( !configuration )
			{
				Debug.LogError( "Call SetConfiguration before showing ads!" );
				return false;
			}

#if GGI_ENABLED
			return GGIAds.Instance.IsRewardedLoaded();
#elif IRONSOURCE_ENABLED
			return IronSource.Agent.isRewardedVideoAvailable();
#elif LIONKIT_ENABLED
			return LionStudios.Ads.RewardedAd.IsAdReady;
#elif UNITY_EDITOR
			return true;
#else
			return false;
#endif
		}

		public void ShowBannerAd( bool bottomBanner )
		{
			if( !configuration )
			{
				Debug.LogError( "Call SetConfiguration before showing ads!" );
				return;
			}

#if GGI_ENABLED
			GGIAds.Instance.ShowBanner( ( size ) => { } );
#elif IRONSOURCE_ENABLED
			if( bannerAdLoadState != BannerAdLoadState.NotLoaded )
			{
				if( BannerAdAtBottom == bottomBanner )
				{
					if( bannerAdLoadState == BannerAdLoadState.Loaded && !isBannerAdVisible )
					{
						IronSource.Agent.displayBanner();
						BannerAdVisibilityChanged( true );
					}

					isBannerAdVisible = true;
					return;
				}
				else
				{
					IronSource.Agent.destroyBanner();
					bannerAdLoadState = BannerAdLoadState.NotLoaded;
					BannerAdVisibilityChanged( false );
				}
			}

			IronSource.Agent.loadBanner( IronSourceBannerSize.BANNER, bottomBanner ? IronSourceBannerPosition.BOTTOM : IronSourceBannerPosition.TOP );

			bannerAdLoadState = BannerAdLoadState.Loading;
			BannerAdAtBottom = bottomBanner;
			isBannerAdVisible = true;
#elif LIONKIT_ENABLED
			if( BannerAdAtBottom != bottomBanner )
			{
				if( BannerAdVisible && LionStudios.Ads.Banner.Created )
				{
					LionStudios.Ads.Banner.Destroy();
					BannerAdVisibilityChanged( false );
				}

				LionStudios.Ads.Banner.Create( bottomBanner ? MaxSdkBase.BannerPosition.BottomCenter : MaxSdkBase.BannerPosition.TopCenter );
				BannerAdAtBottom = bottomBanner;
			}

			if( FTemplate.Gallery )
				bannerAdRequest.SetLevel( FTemplate.Gallery.CompletedLevelCount );

			LionStudios.Ads.Banner.Show( bannerAdRequest );
#endif
		}

		public void HideBannerAd()
		{
			if( !configuration )
			{
				Debug.LogError( "Call SetConfiguration before showing ads!" );
				return;
			}

#if GGI_ENABLED
			GGIAds.Instance.HideBanner();
#elif IRONSOURCE_ENABLED
			if( bannerAdLoadState == BannerAdLoadState.Loaded && isBannerAdVisible )
			{
				IronSource.Agent.hideBanner();
				BannerAdVisibilityChanged( false );
			}

			isBannerAdVisible = false;
#elif LIONKIT_ENABLED
			LionStudios.Ads.Banner.Hide();
#endif
		}

		public void ShowInterstitialAd(string identifier = "")
		{
			if( !configuration )
			{
				Debug.LogError( "Call SetConfiguration before showing ads!" );
				return;
			}

			if( skipNextInterstitialAd )
			{
				skipNextInterstitialAd = false;
				return;
			}

			if( Time.realtimeSinceStartup < nextInterstitialAdShowTime )
				return;

			if( !IsInterstitialAdAvailable() )
				return;

			nextInterstitialAdShowTime = Time.realtimeSinceStartup + configuration.InterstitialAdCooldown;

#if GGI_ENABLED
			return GGIAds.Instance.ShowInterstitial( () => { } );
#elif IRONSOURCE_ENABLED
			IronSource.Agent.showInterstitial();
#elif LIONKIT_ENABLED
			if( FTemplate.Gallery )
				interstitialAdRequest.SetLevel( FTemplate.Gallery.CompletedLevelCount );

			LionStudios.Ads.Interstitial.Show( interstitialAdRequest );
#endif
		}

		/// <summary>
		/// Displays a rewarded ad
		/// </summary>
		/// <param name="rewardedAdCallback">Callback function that will be invoked on the main thread after user watches the rewarded video. If the ads SDK doesn't support specifying reward values remotely, returned Reward parameter will have default values</param>
		/// <param name="identifier">Source of this rewarded ad, e.g. "free_xp_offer"</param>
		public void ShowRewardedAd( RewardedAdCallback rewardedAdCallback, string identifier )
		{
			if( !configuration )
			{
				Debug.LogError( "Call SetConfiguration before showing ads!" );
				return;
			}

			this.rewardedAdCallback = rewardedAdCallback;

#if GGI_ENABLED
			return GGIAds.Instance.ShowRewardedVideo( GGIRewardedAdRewarded, identifier );
#elif IRONSOURCE_ENABLED
			IronSource.Agent.showRewardedVideo();
#elif LIONKIT_ENABLED
			rewardedAdRequest.SetPlacement( identifier );
			if( FTemplate.Gallery )
				rewardedAdRequest.SetLevel( FTemplate.Gallery.CompletedLevelCount );

			LionStudios.Ads.RewardedAd.Show( rewardedAdRequest );
#elif UNITY_EDITOR
			pendingRewardedAdReward = new RewardedAdReward();
#endif
		}

		public void SkipNextInterstitialAd()
		{
			skipNextInterstitialAd = true;
		}

		public void ShowBannerAdBackground( Color backgroundColor )
		{
			bannerAdBackground.SetActive( true );
			bannerAdBackground.SetColor( backgroundColor );
		}

		public void HideBannerAdBackground()
		{
			bannerAdBackground.SetActive( false );
		}

		private void BannerAdVisibilityChanged( bool isVisible )
		{
			try
			{
				BannerAdVisible = isVisible;
				BannerAdHeightInPixels = isVisible ? calculatedBannerAdHeight : 0f;

				if( OnBannerAdVisibilityChanged != null )
					OnBannerAdVisibilityChanged( isVisible );
			}
			catch( System.Exception e )
			{
				Debug.LogException( e );
			}
		}

#if GGI_ENABLED
		private void GGIBannerShown()
		{
			pendingBannerVisibilityCallback = true;
		}

		private void GGIBannerHidden()
		{
			pendingBannerVisibilityCallback = false;
		}

		private void GGIRewardedAdRewarded( bool watched )
		{
			if( watched )
				pendingRewardedAdReward = new RewardedAdReward();
		}
#endif

#if IRONSOURCE_ENABLED
		private void IronSourceBannerLoadFailed( IronSourceError error )
		{
			nextBannerAdLoadTime = Time.unscaledTime + configuration.FailedAdRetryInterval;
		}

		private void IronSourceInterstitialLoadFailed( IronSourceError error )
		{
			nextInterstitialAdLoadTime = Time.unscaledTime + configuration.FailedAdRetryInterval;
		}

		private void IronSourceBannerLoaded()
		{
			bannerAdLoadState = BannerAdLoadState.Loaded;

			if( !isBannerAdVisible )
				IronSource.Agent.hideBanner();
			else
				BannerAdVisibilityChanged( true );
		}

		private void IronSourceInterstitialClosed()
		{
			IronSource.Agent.loadInterstitial();
		}

		private void IronSourceRewardedAdRewarded( IronSourcePlacement ssp )
		{
			pendingRewardedAdReward = new RewardedAdReward( ssp.getRewardName(), ssp.getRewardAmount() );
		}
#endif

#if LIONKIT_ENABLED
		private void LionKitBannerShown( string adUnitId )
		{
			pendingBannerVisibilityCallback = true;
		}

		private void LionKitBannerHidden( string adUnitId )
		{
			pendingBannerVisibilityCallback = false;
		}

		private void LionKitRewardedAdRewarded( string adUnitId, MaxSdk.Reward reward )
		{
			pendingRewardedAdReward = new RewardedAdReward( reward.Label, reward.Amount );
		}
#endif
		#endregion
	}
}