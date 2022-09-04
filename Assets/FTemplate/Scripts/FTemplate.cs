using DG.Tweening;
using FTemplateNamespace;
using MoreMountains.NiceVibrations;
using UnityEngine;

[assembly: System.Runtime.CompilerServices.InternalsVisibleTo( "FTemplateEditor" )]
public class FTemplate : SingletonBehaviour<FTemplate>
{
	private const string PREFS_GAME_VERSION = "F_GameVersion";

	public struct SessionVersion
	{
		public readonly string previousVersion;
		public readonly string currentVersion;

		public SessionVersion( string prev, string curr )
		{
			previousVersion = prev;
			currentVersion = curr;
		}
	}

#pragma warning disable 0649
	[SerializeField]
	private AdsModule adsModule;
	public static AdsModule Ads { get; private set; }

	[SerializeField]
	private AnalyticsModule analyticsModule;
	public static AnalyticsModule Analytics { get; private set; }

	[SerializeField]
	private AnimationModule animationModule;
	internal static AnimationModule Animation { get; private set; }

	[SerializeField]
	private AudioModule audioModule;
	public static AudioModule Audio { get; private set; }

	[SerializeField]
	private GalleryModule galleryModule;
	public static GalleryModule Gallery { get; private set; }

	[SerializeField]
	private ShopModule shopModule;
	public static ShopModule Shop { get; private set; }

	[SerializeField]
	private UIModule uiModule;
	public static UIModule UI { get; private set; }

	public static SessionVersion Session { get; private set; }
#pragma warning restore 0649

	[RuntimeInitializeOnLoadMethod( RuntimeInitializeLoadType.BeforeSceneLoad )]
	private static void Initialize()
	{
		FTemplate initializer = Instantiate( Resources.Load<FTemplate>( "FTemplate" ) );
		DontDestroyOnLoad( initializer.gameObject );
	}

	protected override void Awake()
	{
		base.Awake();

		// FTemplate internally uses Analytics and Animation modules
		if( !analyticsModule )
		{
			analyticsModule = new GameObject( "Analytics" ).AddComponent<AnalyticsModule>();
			analyticsModule.transform.SetParent( uiModule.transform.parent );
		}

		if( !animationModule )
		{
			animationModule = new GameObject( "Animation" ).AddComponent<AnimationModule>();
			animationModule.transform.SetParent( uiModule.transform.parent );
		}

		if( !audioModule )
		{
			audioModule = new GameObject( "Audio" ).AddComponent<AudioModule>();
			audioModule.transform.SetParent( uiModule.transform.parent );
		}

		Ads = adsModule;
		Analytics = analyticsModule;
		Animation = animationModule;
		Audio = audioModule;
		Gallery = galleryModule;
		Shop = shopModule;
		UI = uiModule;

#if UNITY_ANDROID || UNITY_IOS
		Screen.sleepTimeout = SleepTimeout.NeverSleep;
		MMNViOS.iOSInitializeHaptics();

		// To force Unity to add VIBRATE permission to AndroidManifest
		bool vibrator = false;
		bool vibrationEnabled = MMVibrationManager.VibrationEnabled;
		if( vibrationEnabled && vibrator )
			Handheld.Vibrate();
#endif

		string previousApplicationVersion = PlayerPrefs.GetString( PREFS_GAME_VERSION, "0.0" );
		string currentApplicationVersion = Application.version;
		if( previousApplicationVersion != currentApplicationVersion )
		{
			PlayerPrefs.SetString( PREFS_GAME_VERSION, currentApplicationVersion );
			PlayerPrefs.Save();
		}

		Session = new SessionVersion( previousApplicationVersion, currentApplicationVersion );

		for( int i = transform.childCount - 1; i >= 0; i-- )
		{
			Transform child = transform.GetChild( i );
			child.SetParent( null, false );
			DontDestroyOnLoad( child.gameObject );
		}

		if( analyticsModule )
			analyticsModule.Initialize();
	}

	private void Start()
	{
		// Try to initialize the Ads, Shop and Gallery modules automatically via Resources folder
		if( adsModule )
		{
			AdsConfiguration adsConfiguration = Resources.Load<AdsConfiguration>( "AdsConfiguration" );
			if( adsConfiguration )
				adsModule.SetConfiguration( adsConfiguration );
		}

		if( galleryModule )
		{
			GalleryConfiguration galleryConfiguration = Resources.Load<GalleryConfiguration>( "GalleryConfiguration" );
			if( galleryConfiguration )
				galleryModule.SetConfiguration( galleryConfiguration );
		}

		if( shopModule )
		{
			ShopConfiguration shopConfiguration = Resources.Load<ShopConfiguration>( "ShopConfiguration" );
			if( shopConfiguration )
				shopModule.SetConfiguration( shopConfiguration );
		}
	}

	protected override void OnLevelClosed()
	{
		uiModule.ClearCelebrationParticles();

		if( animationModule )
			animationModule.Clear();

		DOTween.KillAll();
	}
}