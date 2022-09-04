//#define USING_URP

using DG.Tweening;
using MoreMountains.NiceVibrations;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.SceneManagement;
using UnityEngine.UI;
#if USING_URP
using UnityEngine.Rendering.Universal;
#endif

namespace FTemplateNamespace
{
	public class UIModule : MonoBehaviour
	{
		public enum LevelCompleteMenu { ShowButtons = 0, ShowTextThenFadeOut = 1, DirectFadeOut = 2 };
		public enum LevelFailedMenu { RestartOnly = 0, AllowSkip = 1 };
		public enum BonusLevelRewardMenu { RotatingStick = 0, PredefinedMultiplier = 1 };

		public const float UI_ELEMENTS_DEFAULT_TOGGLE_DURATION = -0.25f;
		public const float DEFAULT_FADE_DURATION = 0.25f;

		public const string TMP_COIN_SPRITE = "<sprite=\"Coin\" index=0>";

		public delegate bool ButtonClickDelegate();
		public delegate void UIElementDelegate( UIElementType element );

		#region ANIMATIONS
		private class UIElementSetVisibilityJob : IAnimationJob
		{
			private UIElementType type;
			private bool shouldShow;
			private float duration;
			private float autoHideInSeconds;
			private float t;

			public void Initialize( UIElementType type, bool shouldShow, float delay, float duration, float autoHideInSeconds )
			{
				this.type = type;
				this.shouldShow = shouldShow;
				this.duration = duration;
				this.autoHideInSeconds = autoHideInSeconds;
				t = delay;
			}

			public bool Execute( float deltaTime )
			{
				t -= deltaTime;
				if( t > 0f )
					return true;

				if( shouldShow )
					FTemplate.UI.Show( type, duration: duration, autoHideInSeconds: autoHideInSeconds );
				else
					FTemplate.UI.Hide( type, duration: duration );

				return false;
			}

			public bool CheckAnimatedObject( object animatedObject ) { return false; }
			public bool IsValid() { return true; }
			public void Clear() { }
		}

		public class DeactivateOnParticlesStopJob : IAnimationJob
		{
			private GameObject target;
			private ParticlesHolder particles;
#if USING_URP
			private Camera particlesRenderCamera;
			private Camera mainCamera;
#endif

#if USING_URP
			public void Initialize( GameObject target, ParticlesHolder particles, Camera particlesRenderCamera, Camera mainCamera )
#else
			public void Initialize( GameObject target, ParticlesHolder particles )
#endif
			{
				this.target = target;
				this.particles = particles;
#if USING_URP
				this.particlesRenderCamera = particlesRenderCamera;
				this.mainCamera = mainCamera;
#endif
			}

			public bool Execute( float deltaTime )
			{
				if( !particles.IsPlaying )
				{
					target.SetActive( false );

#if USING_URP
					if( particlesRenderCamera && mainCamera )
						mainCamera.GetUniversalAdditionalCameraData().cameraStack.Remove( particlesRenderCamera );
#endif

					return false;
				}

				return true;
			}

			public bool CheckAnimatedObject( object animatedObject )
			{
				return ReferenceEquals( target, animatedObject );
			}

			public bool IsValid()
			{
				return target && particles;
			}

			public void Clear()
			{
				target = null;
				particles = null;
			}
		}
		#endregion

#pragma warning disable 0649
		[Header( "FadeCanvas" )]
		[SerializeField]
		private UIElement fadeOverlay;

		[Header( "GameplayCanvas" )]
		[SerializeField]
		private TextMeshProUGUI currentStageText;

		[SerializeField]
		private TextMeshProUGUI nextStageText;

		[SerializeField]
		private Image[] progressbarSlots;

		[SerializeField]
		private Sprite progressbarInactive;

		[SerializeField]
		private Sprite progressbarInactiveBonus;

		[SerializeField]
		private Sprite progressbarActive;

		[SerializeField]
		private TextMeshProUGUI totalCoinsText;

		[SerializeField]
		private RectTransform totalCoinsTextAnim;

		[SerializeField]
		private AnimationCurve collectedCoinsScaleCurve;

		[SerializeField]
		private TextMeshProUGUI topCurrentLevelText;

		[SerializeField]
		private Button topRestartLevelButton;

		[SerializeField]
		private Button topSkipLevelButton;

		[Header( "MainMenuCanvas" )]
		[SerializeField]
		private RectTransform settingsPanel;
		private bool settingsPanelVisible;

		[SerializeField]
		private Button startLevelButton;

		[SerializeField]
		private Button galleryButton;

		[SerializeField]
		private Button shopButton;

		[SerializeField]
		private Button settingsButton;

		[SerializeField]
		private Button settingsVibrationButton;
		private Image settingsVibrationImage;

		[SerializeField]
		private Button settingsSoundButton;
		private Image settingsSoundImage;

		[SerializeField]
		private TextMeshProUGUI mainMenuCoinsText;

		[Header( "TutorialCanvas" )]
		[SerializeField]
		private TextMeshProUGUI swipeTutorialText;
		[SerializeField]
		private TextMeshProUGUI tapToDoStuffTutorialText;

		[Header( "NextUnlockCanvas" )]
		[SerializeField]
		private Image nextUnlockIcon;

		[SerializeField]
		private SlicedFilledImage nextUnlockProgress;

		[SerializeField]
		private TextMeshProUGUI nextUnlockProgressText;

		[SerializeField]
		private Animator nextUnlockUnlockedAnim;

		[SerializeField]
		private GameObject nextUnlockLockIcon;

		[SerializeField]
		private Button nextUnlockEquipButton;
		private CustomizationItem nextUnlock;
		private Coroutine nextUnlockCoroutine;

		[Header( "LevelFailedCanvas" )]
		[SerializeField]
		private Animator levelFailedRestartOnlyModeAnim;
		[SerializeField]
		private Animator levelFailedAllowSkipModeAnim;

		// Simple Mode
		[SerializeField]
		private Button levelFailedRestartButton;

		// Advanced Mode
		[SerializeField]
		private Button levelFailedRestartButtonRewarded;
		[SerializeField]
		private Button levelFailedContinueButton;

		[SerializeField]
		private Image levelFailedCountdown;
		[SerializeField]
		private Image levelFailedCountdownOutline;

		private Coroutine levelFailedAdvancedCoroutine;

		[Header( "LevelCompletedCanvas" )]
		[SerializeField]
		private Button levelCompletedRestartButton;
		[SerializeField]
		private Button levelCompletedNextLevelButton;
		[SerializeField]
		private TextMeshProUGUI levelCompletedText;

		[Header( "BonusLevelRewardCanvas" )]
		[SerializeField]
		private GameObject bonusLevelRewardV1;
		[SerializeField]
		private GameObject bonusLevelRewardV2;

		[SerializeField]
		private TextMeshProUGUI bonusLevelRewardV1Amount;
		[SerializeField]
		private TextMeshProUGUI bonusLevelRewardV2Amount;
		[SerializeField]
		private TextMeshProUGUI bonusLevelRewardV2ClaimText;

		[SerializeField]
		private PointerEventListener bonusLevelRewardV1AdButton;
		private Button bonusLevelRewardV1AdDummyButton;
		[SerializeField]
		private Button bonusLevelRewardV2AdButton;

		[SerializeField]
		private Button bonusLevelRewardV1ContinueButton;
		[SerializeField]
		private Button bonusLevelRewardV2ContinueButton;

		[SerializeField]
		private Animator bonusLevelRewardBarStick;
		[SerializeField]
		private float[] bonusLevelRewardBarStickAngles;

		private bool bonusLevelRewardGiven;

		[Header( "DialogCanvas" )]
		[SerializeField]
		private TextMeshProUGUI dialogLabel;
		[SerializeField]
		private Button dialogNoButton;
		private UnityAction dialogNoButtonAction;
		[SerializeField]
		private Button dialogYesButton;
		private UnityAction dialogYesButtonAction;

		[Header( "SpawnedCoinsCanvas" )]
		[SerializeField]
		private SpawnedCoin spawnedCoinPrefab;

		[SerializeField]
		private RectTransform spawnedCoinParent;

		private readonly List<SpawnedCoin> activeSpawnedCoins = new List<SpawnedCoin>( 16 );
		private SimplePool<SpawnedCoin> spawnedCoinsPool;

		[Header( "Other" )]
		[SerializeField]
		private UIElement[] uiElements;
		private readonly Dictionary<UIElementType, UIElement> uiElementsDictionary = new Dictionary<UIElementType, UIElement>( 16, new UIElement.Comparer() );

		internal int ShopPrecedingSceneIndex { get; private set; }

		[SerializeField]
		private TextMeshProUGUI calloutText;

		[SerializeField]
		private ParticlesHolder celebrationParticles;

		[SerializeField]
		private GameObject celebrationParticlesRoot;
#pragma warning restore 0649

		public long DisplayedTotalCoins { get; private set; }

		public string SwipeTutorialLabel
		{
			get { return swipeTutorialText.text; }
			set { swipeTutorialText.text = value; }
		}

		public string TapToDoStuffTutorialLabel
		{
			get { return tapToDoStuffTutorialText.text; }
			set { tapToDoStuffTutorialText.text = value; }
		}

		public string TopCurrentLevelLabel
		{
			get { return topCurrentLevelText.text; }
			set { topCurrentLevelText.text = value; }
		}

		public string CalloutLabel
		{
			get { return calloutText.text; }
			set { calloutText.text = value; }
		}

		public float TapToDoStuffTutorialYPosition
		{
			get { return ( (RectTransform) uiElementsDictionary[UIElementType.TapToDoStuffTutorial].NavigationHandler.transform ).anchoredPosition.y; }
			set
			{
				RectTransform tutorialTransform = (RectTransform) uiElementsDictionary[UIElementType.TapToDoStuffTutorial].NavigationHandler.transform;
				tutorialTransform.anchoredPosition = new Vector2( tutorialTransform.anchoredPosition.x, value );
			}
		}

		public float SwipeTutorialYPosition
		{
			get { return ( (RectTransform) uiElementsDictionary[UIElementType.SwipeTutorial].NavigationHandler.transform ).anchoredPosition.y; }
			set
			{
				RectTransform tutorialTransform = (RectTransform) uiElementsDictionary[UIElementType.SwipeTutorial].NavigationHandler.transform;
				tutorialTransform.anchoredPosition = new Vector2( tutorialTransform.anchoredPosition.x, value );
			}
		}

		private int m_bonusLevelRewardAmount = 100;
		public int BonusLevelRewardAmount
		{
			get { return m_bonusLevelRewardAmount; }
			set
			{
				m_bonusLevelRewardAmount = value;

				if( bonusLevelRewardV1Amount )
					bonusLevelRewardV1Amount.SetText( m_bonusLevelRewardAmount );
				if( bonusLevelRewardV2Amount )
					bonusLevelRewardV2Amount.SetText( m_bonusLevelRewardAmount );
			}
		}

		private int m_bonusLevelRewardV2Multiplier = 3;
		public int BonusLevelRewardV2Multiplier
		{
			get { return m_bonusLevelRewardV2Multiplier; }
			set
			{
				m_bonusLevelRewardV2Multiplier = value;
				bonusLevelRewardV2ClaimText.SetText( m_bonusLevelRewardV2Multiplier, "x", " CLAIM" );
			}
		}

		private LevelCompleteMenu m_levelCompleteMenuType = LevelCompleteMenu.DirectFadeOut;
		public LevelCompleteMenu LevelCompleteMenuType
		{
			get { return m_levelCompleteMenuType; }
			set
			{
				m_levelCompleteMenuType = value;

				levelCompletedText.enabled = m_levelCompleteMenuType != LevelCompleteMenu.DirectFadeOut;
				levelCompletedRestartButton.gameObject.SetActive( m_levelCompleteMenuType == LevelCompleteMenu.ShowButtons );
				levelCompletedNextLevelButton.gameObject.SetActive( m_levelCompleteMenuType == LevelCompleteMenu.ShowButtons );
			}
		}

		private LevelFailedMenu m_levelFailedMenuType = LevelFailedMenu.RestartOnly;
		public LevelFailedMenu LevelFailedMenuType
		{
			get { return m_levelFailedMenuType; }
			set
			{
				m_levelFailedMenuType = value;

				levelFailedRestartOnlyModeAnim.gameObject.SetActive( m_levelFailedMenuType == LevelFailedMenu.RestartOnly );
				levelFailedAllowSkipModeAnim.gameObject.SetActive( m_levelFailedMenuType == LevelFailedMenu.AllowSkip );
			}
		}

		private BonusLevelRewardMenu m_bonusLevelRewardMenuType = BonusLevelRewardMenu.RotatingStick;
		public BonusLevelRewardMenu BonusLevelRewardMenuType
		{
			get { return m_bonusLevelRewardMenuType; }
			set
			{
				m_bonusLevelRewardMenuType = value;

				bonusLevelRewardV1.gameObject.SetActive( m_bonusLevelRewardMenuType == BonusLevelRewardMenu.RotatingStick );
				bonusLevelRewardV2.gameObject.SetActive( m_bonusLevelRewardMenuType == BonusLevelRewardMenu.PredefinedMultiplier );
			}
		}

		public ButtonClickDelegate StartLevelButtonClicked;
		public ButtonClickDelegate RestartLevelButtonClicked;
		public ButtonClickDelegate NextLevelButtonClicked;
		public ButtonClickDelegate SkipLevelButtonClicked;

		public UIElementDelegate OnUIElementShown;

		private void Awake()
		{
			int uiElementCount = uiElements.Length;
			Dictionary<Canvas, List<UIElement>> uiElementCanvases = new Dictionary<Canvas, List<UIElement>>( uiElementCount );
			for( int i = 0; i < uiElementCount; i++ )
			{
				Component navigationHandler = uiElements[i].NavigationHandler;
				if( !navigationHandler )
				{
					uiElements[i--] = uiElements[uiElementCount - 1];
					uiElementCount--;

					continue;
				}

				Canvas canvas = FindRootCanvasOf( navigationHandler );
				if( canvas )
				{
					List<UIElement> siblingElements;
					if( !uiElementCanvases.TryGetValue( canvas, out siblingElements ) )
					{
						siblingElements = new List<UIElement>( 2 );
						uiElementCanvases[canvas] = siblingElements;
					}

					siblingElements.Add( uiElements[i] );
				}

				uiElementsDictionary[uiElements[i].Type] = uiElements[i];
			}

			if( uiElements.Length != uiElementCount )
				System.Array.Resize( ref uiElements, uiElementCount );

			foreach( KeyValuePair<Canvas, List<UIElement>> kvPair in uiElementCanvases )
			{
				UIElement[] siblingElements = kvPair.Value.ToArray();
				UIElementCanvas canvas = new UIElementCanvas( kvPair.Key, siblingElements );
				for( int i = 0; i < siblingElements.Length; i++ )
					siblingElements[i].Initialize( canvas );
			}

			SpawnedCoin.AnimationFinishedDelegate onSpawnedCoinAnimationFinished = ( SpawnedCoin coin ) => spawnedCoinsPool.Push( coin );
			spawnedCoinParent.gameObject.SetActive( false );
			spawnedCoinsPool = new SimplePool<SpawnedCoin>( 16, () =>
			{
				SpawnedCoin spawnedCoin = Instantiate( spawnedCoinPrefab, spawnedCoinParent, false );
				spawnedCoin.OnAnimationFinished = onSpawnedCoinAnimationFinished;
				return spawnedCoin;
			},
			( obj ) =>
			{
				obj.gameObject.SetActive( false );

				if( activeSpawnedCoins.Remove( obj ) && activeSpawnedCoins.Count == 0 )
					spawnedCoinParent.gameObject.SetActive( false );
			},
			( obj ) =>
			{
				obj.gameObject.SetActive( true );
				activeSpawnedCoins.Add( obj );
			} );

			if( startLevelButton )
			{
				startLevelButton.onClick.AddListener( () =>
				{
					if( IsVisible( UIElementType.MainMenu ) && startLevelButton.interactable && StartLevelButtonClicked != null && StartLevelButtonClicked() )
					{
						startLevelButton.interactable = false;

						if( galleryButton )
							galleryButton.interactable = false;
						if( shopButton )
							shopButton.interactable = false;

						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Positive );
					}
				} );
			}

			if( levelFailedRestartButton )
			{
				levelFailedRestartButton.onClick.AddListener( () =>
				{
					if( IsVisible( UIElementType.LevelFailedMenu ) && levelFailedRestartButton.interactable && RestartLevelButtonClicked != null && RestartLevelButtonClicked() )
					{
						levelFailedRestartButton.interactable = false;

						if( topRestartLevelButton )
							topRestartLevelButton.interactable = false;
						if( topSkipLevelButton )
							topSkipLevelButton.interactable = false;

						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Neutral );
					}
				} );
			}

			if( levelFailedRestartButtonRewarded )
			{
				levelFailedRestartButtonRewarded.onClick.AddListener( () =>
				{
					if( IsVisible( UIElementType.LevelFailedMenu ) && levelFailedRestartButtonRewarded.interactable && FTemplate.Ads.IsRewardedAdAvailable() && levelFailedRestartButtonRewarded.GetComponent<Image>().color.a > 0.1f )
					{
						if( levelFailedAdvancedCoroutine != null )
						{
							StopCoroutine( levelFailedAdvancedCoroutine );
							levelFailedAdvancedCoroutine = null;
						}

						FTemplate.Ads.ShowRewardedAd( ( reward ) =>
						{
							if( levelFailedContinueButton )
								levelFailedContinueButton.interactable = false;
							if( topRestartLevelButton )
								topRestartLevelButton.interactable = false;
							if( topSkipLevelButton )
								topSkipLevelButton.interactable = false;

							if( RestartLevelButtonClicked != null )
								RestartLevelButtonClicked();

							FTemplate.Ads.SkipNextInterstitialAd(); // Don't show interstitial ad immediately after rewarded ad
						}, "level_fail_v2_retry" );

						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Neutral );
					}
				} );
			}

			if( levelFailedContinueButton )
			{
				levelFailedContinueButton.onClick.AddListener( () =>
				{
					if( IsVisible( UIElementType.LevelFailedMenu ) && levelFailedContinueButton.interactable && levelFailedContinueButton.GetComponent<TextMeshProUGUI>().color.a > 0.1f && NextLevelButtonClicked != null && NextLevelButtonClicked() )
					{
						levelFailedContinueButton.interactable = false;

						if( levelFailedRestartButtonRewarded )
							levelFailedRestartButtonRewarded.interactable = false;
						if( topRestartLevelButton )
							topRestartLevelButton.interactable = false;
						if( topSkipLevelButton )
							topSkipLevelButton.interactable = false;

						if( levelFailedAdvancedCoroutine != null )
						{
							StopCoroutine( levelFailedAdvancedCoroutine );
							levelFailedAdvancedCoroutine = null;
						}

						if( FTemplate.Analytics.GetRemoteBoolValue( "fail_v2_skip_interstitial", false ) )
							FTemplate.Ads.SkipNextInterstitialAd();

						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Neutral );
					}
				} );
			}

			if( topRestartLevelButton )
			{
				topRestartLevelButton.onClick.AddListener( () =>
				{
					if( topRestartLevelButton.interactable && RestartLevelButtonClicked != null && RestartLevelButtonClicked() )
					{
						topRestartLevelButton.interactable = false;

						if( topSkipLevelButton )
							topSkipLevelButton.interactable = false;

						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Neutral );
					}
				} );
			}

			if( topSkipLevelButton )
			{
				topSkipLevelButton.onClick.AddListener( () =>
				{
					if( topSkipLevelButton.interactable && SkipLevelButtonClicked != null && SkipLevelButtonClicked() )
					{
						topSkipLevelButton.interactable = false;

						if( topRestartLevelButton )
							topRestartLevelButton.interactable = false;

						StartCoroutine( ReEnableTopButtonsCoroutine() );

						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Positive );
					}
				} );
			}

			if( levelCompletedRestartButton )
			{
				levelCompletedRestartButton.onClick.AddListener( () =>
				{
					if( IsVisible( UIElementType.LevelCompletedMenu ) && levelCompletedRestartButton.interactable && RestartLevelButtonClicked != null && RestartLevelButtonClicked() )
					{
						levelCompletedRestartButton.interactable = false;

						if( levelCompletedNextLevelButton )
							levelCompletedNextLevelButton.interactable = false;

						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Neutral );
					}
				} );
			}

			if( levelCompletedNextLevelButton )
			{
				levelCompletedNextLevelButton.onClick.AddListener( () =>
				{
					if( IsVisible( UIElementType.LevelCompletedMenu ) && levelCompletedNextLevelButton.interactable && NextLevelButtonClicked != null && NextLevelButtonClicked() )
					{
						levelCompletedNextLevelButton.interactable = false;

						if( levelCompletedRestartButton )
							levelCompletedRestartButton.interactable = false;

						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Positive );
					}
				} );
			}

			if( settingsButton )
			{
				settingsButton.onClick.AddListener( () =>
				{
					settingsPanelVisible = !settingsPanelVisible;

					settingsPanel.DOKill( false );
					settingsPanel.DOScale( settingsPanelVisible ? 1f : 0f, 0.25f ).SetUpdate( true );

					FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Neutral );
				} );
			}

			if( settingsVibrationButton )
			{
				settingsVibrationImage = settingsVibrationButton.GetComponent<Image>();
				settingsVibrationButton.onClick.AddListener( () =>
				{
					MMVibrationManager.VibrationEnabled = !MMVibrationManager.VibrationEnabled;
					if( MMVibrationManager.VibrationEnabled )
					{
						settingsVibrationImage.color = new Color( 1f, 1f, 1f, 1f );
						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Positive );
					}
					else
					{
						settingsVibrationImage.color = new Color( 0.785f, 0.785f, 0.785f, 0.785f );
						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Negative );
					}
				} );

				if( MMVibrationManager.VibrationEnabled )
					settingsVibrationImage.color = new Color( 1f, 1f, 1f, 1f );
				else
					settingsVibrationImage.color = new Color( 0.785f, 0.785f, 0.785f, 0.785f );
			}

			if( settingsSoundButton )
			{
				settingsSoundImage = settingsSoundButton.GetComponent<Image>();
				settingsSoundButton.onClick.AddListener( () =>
				{
					FTemplate.Audio.AudioEnabled = !FTemplate.Audio.AudioEnabled;
					if( FTemplate.Audio.AudioEnabled )
						settingsSoundImage.color = new Color( 1f, 1f, 1f, 1f );
					else
						settingsSoundImage.color = new Color( 0.785f, 0.785f, 0.785f, 0.785f );

					FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Positive );
				} );

				if( FTemplate.Audio.AudioEnabled )
					settingsSoundImage.color = new Color( 1f, 1f, 1f, 1f );
				else
					settingsSoundImage.color = new Color( 0.785f, 0.785f, 0.785f, 0.785f );
			}

			if( galleryButton )
			{
				galleryButton.onClick.AddListener( () =>
				{
					if( IsVisible( UIElementType.MainMenu ) )
					{
						Hide( UIElementType.MainMenu );
						Show( UIElementType.GalleryMenu, delay: Mathf.Abs( UI_ELEMENTS_DEFAULT_TOGGLE_DURATION ) );

						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Neutral );
					}
				} );
			}

			if( shopButton )
			{
				shopButton.onClick.AddListener( () =>
				{
					if( IsVisible( UIElementType.MainMenu ) )
					{
						if( !string.IsNullOrEmpty( FTemplate.Shop.ShopScene ) )
						{
							ShopPrecedingSceneIndex = SceneManager.GetActiveScene().buildIndex;

							Hide( UIElementType.MainMenu, DEFAULT_FADE_DURATION );
							FadeToScene( FTemplate.Shop.ShopScene );
						}
						else
						{
							Hide( UIElementType.MainMenu );
							Show( UIElementType.ShopMenu, delay: Mathf.Abs( UI_ELEMENTS_DEFAULT_TOGGLE_DURATION ) );
						}

						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Neutral );
					}
				} );
			}

			if( nextUnlockEquipButton )
			{
				nextUnlockEquipButton.onClick.AddListener( () =>
				{
					nextUnlockEquipButton.interactable = false;
					FTemplate.Shop.EquipCustomizationItem( nextUnlock, FTemplate.Shop.AutoSaveFreeUnlockProgress );
					FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Positive );
				} );
			}

			if( dialogNoButton )
			{
				dialogNoButton.onClick.AddListener( () =>
				{
					if( IsVisible( UIElementType.Dialog ) )
						OnDialogButtonClicked( false );
				} );
			}

			if( dialogYesButton )
			{
				dialogYesButton.onClick.AddListener( () =>
				{
					if( IsVisible( UIElementType.Dialog ) )
						OnDialogButtonClicked( true );
				} );
			}

			if( bonusLevelRewardV1ContinueButton )
			{
				bonusLevelRewardV1ContinueButton.onClick.AddListener( () =>
				{
					FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Positive );

					if( bonusLevelRewardGiven )
						return;

					bonusLevelRewardV1ContinueButton.interactable = false;
					if( bonusLevelRewardV1AdDummyButton )
						bonusLevelRewardV1AdDummyButton.interactable = false;

					bonusLevelRewardBarStick.enabled = false;

					//FTemplate.Shop.IncrementCoins( BonusLevelRewardAmount );
					//SpawnCollectedCoins( bonusLevelRewardV1Amount.transform.position, 30, BonusLevelRewardAmount, spread: 75f );
					//Hide( UIElementType.BonusLevelRewardMenu, delay: 1.5f );
					//Show( UIElementType.LevelCompletedMenu, delay: 1.5f );

					Hide( UIElementType.BonusLevelRewardMenu );
					Show( UIElementType.LevelCompletedMenu );

					bonusLevelRewardGiven = true;

					if( FTemplate.Analytics.GetRemoteBoolValue( "bonus_continue_skip_interstitial", false ) )
						FTemplate.Ads.SkipNextInterstitialAd();
				} );
			}

			if( bonusLevelRewardV2ContinueButton )
			{
				bonusLevelRewardV2ContinueButton.onClick.AddListener( () =>
				{
					FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Positive );

					if( bonusLevelRewardGiven )
						return;

					bonusLevelRewardV2ContinueButton.interactable = false;
					if( bonusLevelRewardV2AdButton )
						bonusLevelRewardV2AdButton.interactable = false;

					//FTemplate.Shop.IncrementCoins( BonusLevelRewardAmount );
					//SpawnCollectedCoins( bonusLevelRewardV2Amount.transform.position, 30, BonusLevelRewardAmount, spread: 75f );
					//Hide( UIElementType.BonusLevelRewardMenu, delay: 1.5f );
					//Show( UIElementType.LevelCompletedMenu, delay: 1.5f );

					Hide( UIElementType.BonusLevelRewardMenu );
					Show( UIElementType.LevelCompletedMenu );

					bonusLevelRewardGiven = true;

					if( FTemplate.Analytics.GetRemoteBoolValue( "bonus_continue_skip_interstitial", false ) )
						FTemplate.Ads.SkipNextInterstitialAd();
				} );
			}

			if( bonusLevelRewardV1AdButton )
			{
				bonusLevelRewardV1AdDummyButton = bonusLevelRewardV1AdButton.GetComponent<Button>();
				bonusLevelRewardV1AdButton.PointerDown += ( eventData ) =>
				{
					if( !bonusLevelRewardV1AdDummyButton.interactable )
						return;

					FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Positive );

					if( bonusLevelRewardGiven || !FTemplate.Ads.IsRewardedAdAvailable() )
						return;

					bonusLevelRewardV1AdDummyButton.interactable = false;
					bonusLevelRewardBarStick.enabled = false;

					FTemplate.Ads.ShowRewardedAd( ( reward ) =>
					{
						if( bonusLevelRewardGiven )
							return;

						if( bonusLevelRewardV1ContinueButton )
							bonusLevelRewardV1ContinueButton.interactable = false;

						float rewardStickAngle = bonusLevelRewardBarStick.transform.localEulerAngles.z;
						while( rewardStickAngle > 180f )
							rewardStickAngle -= 360f;
						while( rewardStickAngle < -180f )
							rewardStickAngle += 360f;

						rewardStickAngle = Mathf.Abs( rewardStickAngle );
						int multiplier = 2 + bonusLevelRewardBarStickAngles.Length;
						for( int i = 0; i < bonusLevelRewardBarStickAngles.Length; i++ )
						{
							if( rewardStickAngle <= bonusLevelRewardBarStickAngles[i] )
								break;

							multiplier--;
						}

						bonusLevelRewardV1Amount.SetText( BonusLevelRewardAmount * multiplier );

						FTemplate.Shop.IncrementCoins( BonusLevelRewardAmount * multiplier );
						FTemplate.Ads.SkipNextInterstitialAd(); // Don't show interstitial ad immediately after rewarded ad

						SpawnCollectedCoins( bonusLevelRewardV1Amount.transform.position, 30, BonusLevelRewardAmount * multiplier, spread: 75f );
						PlayCelebrationParticles();

						Hide( UIElementType.BonusLevelRewardMenu, delay: 1.5f );
						Show( UIElementType.LevelCompletedMenu, delay: 1.5f );

						bonusLevelRewardGiven = true;
					}, "rewarded_bonus1" );
				};
			}

			if( bonusLevelRewardV2AdButton )
			{
				bonusLevelRewardV2AdButton.onClick.AddListener( () =>
				{
					FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Positive );

					if( bonusLevelRewardGiven || !FTemplate.Ads.IsRewardedAdAvailable() )
						return;

					FTemplate.Ads.ShowRewardedAd( ( reward ) =>
					{
						if( bonusLevelRewardGiven )
							return;

						if( bonusLevelRewardV2ContinueButton )
							bonusLevelRewardV2ContinueButton.interactable = false;

						bonusLevelRewardV2Amount.SetText( BonusLevelRewardAmount * BonusLevelRewardV2Multiplier );

						FTemplate.Shop.IncrementCoins( BonusLevelRewardAmount * BonusLevelRewardV2Multiplier );
						FTemplate.Ads.SkipNextInterstitialAd(); // Don't show interstitial ad immediately after rewarded ad

						SpawnCollectedCoins( bonusLevelRewardV2Amount.transform.position, 30, BonusLevelRewardAmount * BonusLevelRewardV2Multiplier, spread: 75f );
						PlayCelebrationParticles();

						Hide( UIElementType.BonusLevelRewardMenu, delay: 1.5f );
						Show( UIElementType.LevelCompletedMenu, delay: 1.5f );

						bonusLevelRewardGiven = true;
					}, "rewarded_bonus2" );
				} );
			}

#if USING_URP
			celebrationParticlesRoot.GetComponent<Camera>().GetUniversalAdditionalCameraData().renderType = CameraRenderType.Overlay;
#endif

			DisplayedTotalCoins = -1L;
		}

		private IEnumerator ReEnableTopButtonsCoroutine()
		{
			yield return BetterWaitForSeconds.WaitRealtime( 2f );

			if( topRestartLevelButton )
				topRestartLevelButton.interactable = true;

			if( topSkipLevelButton )
				topSkipLevelButton.interactable = true;
		}

		public void FadeIn( float duration = DEFAULT_FADE_DURATION )
		{
			fadeOverlay.Hide( duration );
		}

		public IEnumerator FadeInCoroutine( float duration = DEFAULT_FADE_DURATION )
		{
			FadeIn();
			yield return BetterWaitForSeconds.WaitRealtime( duration );
		}

		public void FadeOut( float duration = DEFAULT_FADE_DURATION )
		{
			fadeOverlay.Show( duration );
		}

		public IEnumerator FadeOutCoroutine( float duration = DEFAULT_FADE_DURATION )
		{
			FadeOut();
			yield return BetterWaitForSeconds.WaitRealtime( duration + 0.02f );
		}

		public void FadeToScene( int sceneBuildIndex, float duration = DEFAULT_FADE_DURATION )
		{
			StartCoroutine( FadeToSceneCoroutine( sceneBuildIndex, duration ) );
		}

		public void FadeToScene( string sceneName, float duration = DEFAULT_FADE_DURATION )
		{
			StartCoroutine( FadeToSceneCoroutine( sceneName, duration ) );
		}

		public IEnumerator FadeToSceneCoroutine( int sceneBuildIndex, float duration = DEFAULT_FADE_DURATION )
		{
			if( duration < 0f )
				duration = -duration;

			FadeOut( duration );
			yield return BetterWaitForSeconds.WaitRealtime( duration + 0.02f );

			FBehaviour.TriggerLevelClosed();
			SceneManager.LoadScene( sceneBuildIndex );

			FadeIn( duration );
			yield return BetterWaitForSeconds.WaitRealtime( duration );
		}

		public IEnumerator FadeToSceneCoroutine( string sceneName, float duration = DEFAULT_FADE_DURATION )
		{
			if( duration < 0f )
				duration = -duration;

			FadeOut( duration );
			yield return BetterWaitForSeconds.WaitRealtime( duration + 0.02f );

			FBehaviour.TriggerLevelClosed();
			SceneManager.LoadScene( sceneName );

			FadeIn( duration );
			yield return BetterWaitForSeconds.WaitRealtime( duration );
		}

		public void PlayCelebrationParticles()
		{
			if( celebrationParticles )
			{
#if USING_URP
				Camera mainCamera = Camera.main;
				if( mainCamera )
#endif
				{
#if USING_URP
					Camera celebrationParticlesCamera = celebrationParticlesRoot.GetComponent<Camera>();
					UniversalAdditionalCameraData cameraData = mainCamera.GetUniversalAdditionalCameraData();
					if( !cameraData.cameraStack.Contains( celebrationParticlesCamera ) )
						cameraData.cameraStack.Add( celebrationParticlesCamera );
#endif

					DeactivateOnParticlesStopJob job = AnimationSystem<DeactivateOnParticlesStopJob>.NewAnimation();
#if USING_URP
					job.Initialize( celebrationParticlesRoot, celebrationParticles, celebrationParticlesCamera, mainCamera );
#else
					job.Initialize( celebrationParticlesRoot, celebrationParticles );
#endif

					celebrationParticlesRoot.SetActive( true );
					celebrationParticles.Play();
				}
			}
		}

		public void ClearCelebrationParticles()
		{
			if( celebrationParticles )
			{
				celebrationParticles.Stop( true );
				celebrationParticlesRoot.SetActive( false );
			}
		}

		public void Show( UIElementType target, float duration = UI_ELEMENTS_DEFAULT_TOGGLE_DURATION, float delay = 0f, float autoHideInSeconds = 0f )
		{
			if( delay > 0f )
			{
				AnimationSystem<UIElementSetVisibilityJob>.NewAnimation().Initialize( target, true, delay, duration, autoHideInSeconds );
				return;
			}

			UIElement uiElement;
			if( !uiElementsDictionary.TryGetValue( target, out uiElement ) )
				return;

			uiElement.Show( duration );

			switch( target )
			{
				// HUD Elements
				case UIElementType.TopRestartButton:
					topRestartLevelButton.interactable = true;
					break;
				case UIElementType.TopSkipLevelButton:
					topSkipLevelButton.interactable = true;
					break;

				// Menus
				case UIElementType.MainMenu:
					if( startLevelButton )
						startLevelButton.interactable = true;
					if( galleryButton )
						galleryButton.interactable = true;
					if( shopButton )
						shopButton.interactable = true;

					if( settingsButton )
					{
						settingsPanelVisible = false;
						settingsPanel.localScale = Vector3.zero;
					}

					break;

				case UIElementType.ShopMenu:
					FTemplate.Shop.OnShopOpening();
					FTemplate.Analytics.CustomEvent( "open_menu", FTemplate.Gallery ? FTemplate.Gallery.ActiveLevelIndex : 0, new AnalyticsModule.Parameter( "menu", "shop" ) );
					break;

				case UIElementType.GalleryMenu:
					FTemplate.Gallery.OnGalleryOpening();
					FTemplate.Analytics.CustomEvent( "open_menu", FTemplate.Gallery ? FTemplate.Gallery.ActiveLevelIndex : 0, new AnalyticsModule.Parameter( "menu", "gallery" ) );
					break;

				case UIElementType.LevelFailedMenu:
					if( levelFailedRestartButton )
						levelFailedRestartButton.interactable = true;
					if( levelFailedRestartButtonRewarded )
						levelFailedRestartButtonRewarded.interactable = true;
					if( levelFailedContinueButton )
						levelFailedContinueButton.interactable = true;

					if( LevelFailedMenuType == LevelFailedMenu.RestartOnly )
						levelFailedRestartOnlyModeAnim.Play( "LevelFailedPanelAppear", 0, 0f );
					else
					{
						if( topRestartLevelButton )
							topRestartLevelButton.gameObject.SetActive( false );
						if( topSkipLevelButton )
							topSkipLevelButton.gameObject.SetActive( false );

						levelFailedAdvancedCoroutine = StartCoroutine( LevelFailedAdvancedAnimationCoroutine() );
					}

					break;

				case UIElementType.LevelCompletedMenu:
					if( levelCompletedRestartButton )
						levelCompletedRestartButton.interactable = true;
					if( levelCompletedNextLevelButton )
						levelCompletedNextLevelButton.interactable = true;

					if( topRestartLevelButton )
					{
						topRestartLevelButton.interactable = false;
						Hide( UIElementType.TopRestartButton );
					}
					if( topSkipLevelButton )
					{
						topSkipLevelButton.interactable = false;
						Hide( UIElementType.TopSkipLevelButton );
					}

					if( m_levelCompleteMenuType != LevelCompleteMenu.ShowButtons )
						StartCoroutine( ContinueToNextLevelCoroutine() );

					break;

				case UIElementType.BonusLevelRewardMenu:
					if( bonusLevelRewardV1AdDummyButton )
						bonusLevelRewardV1AdDummyButton.interactable = true;
					if( bonusLevelRewardV2AdButton )
						bonusLevelRewardV2AdButton.interactable = true;

					if( bonusLevelRewardV1Amount )
						bonusLevelRewardV1Amount.SetText( BonusLevelRewardAmount );
					if( bonusLevelRewardV2Amount )
						bonusLevelRewardV2Amount.SetText( BonusLevelRewardAmount );

					if( bonusLevelRewardBarStick )
					{
						bonusLevelRewardBarStick.enabled = true;
						bonusLevelRewardBarStick.speed = FTemplate.Analytics.GetRemoteFloatValue( "bonus_stick_speed", 1f );
					}

					bonusLevelRewardGiven = false;

					StartCoroutine( EnableBonusLevelRewardContinueButtonsCoroutine() );
					break;
			}

			if( autoHideInSeconds > 0f )
				Hide( target, duration, autoHideInSeconds );

			if( OnUIElementShown != null )
				OnUIElementShown( target );
		}

		public void Hide( UIElementType target, float duration = UI_ELEMENTS_DEFAULT_TOGGLE_DURATION, float delay = 0f )
		{
			if( delay > 0f )
			{
				AnimationSystem<UIElementSetVisibilityJob>.NewAnimation().Initialize( target, false, delay, duration, 0f );
				return;
			}

			UIElement uiElement;
			if( !uiElementsDictionary.TryGetValue( target, out uiElement ) || !uiElement.IsVisible )
				return;

			uiElement.Hide( duration );

			switch( target )
			{
				// Menus
				case UIElementType.ShopMenu:
					FTemplate.Shop.OnShopClosing();
					break;

				case UIElementType.LevelFailedMenu:
					if( levelFailedAdvancedCoroutine != null )
					{
						StopCoroutine( levelFailedAdvancedCoroutine );
						levelFailedAdvancedCoroutine = null;
					}

					break;

				case UIElementType.Dialog:
					dialogNoButtonAction = null;
					dialogYesButtonAction = null;
					break;
			}
		}

		public bool IsVisible( UIElementType target )
		{
			UIElement uiElement;
			if( uiElementsDictionary.TryGetValue( target, out uiElement ) )
				return uiElement.IsVisible;

			return false;
		}

		public void HideAllHUDElements( float duration = UI_ELEMENTS_DEFAULT_TOGGLE_DURATION )
		{
			for( int i = 0; i < UIElement.UI_HUD_ELEMENTS.Length; i++ )
				Hide( UIElement.UI_HUD_ELEMENTS[i], duration );
		}

		public void HideAllTutorials( float duration = UI_ELEMENTS_DEFAULT_TOGGLE_DURATION )
		{
			for( int i = 0; i < UIElement.UI_TUTORIALS.Length; i++ )
				Hide( UIElement.UI_TUTORIALS[i], duration );
		}

		public void HideAllMenus( float duration = UI_ELEMENTS_DEFAULT_TOGGLE_DURATION )
		{
			for( int i = 0; i < UIElement.UI_MENUS.Length; i++ )
				Hide( UIElement.UI_MENUS[i], duration );
		}

		public void HideAllUIElements( float duration = UI_ELEMENTS_DEFAULT_TOGGLE_DURATION )
		{
			HideAllHUDElements( duration );
			HideAllTutorials( duration );
			HideAllMenus( duration );
		}

		public void SetTotalCoins( long totalCoins, bool animate )
		{
			if( DisplayedTotalCoins != totalCoins )
			{
				DisplayedTotalCoins = totalCoins;

				if( mainMenuCoinsText )
					mainMenuCoinsText.SetText( totalCoins );

				if( totalCoinsText )
				{
					totalCoinsText.SetText( totalCoins );

					if( animate && totalCoinsTextAnim.gameObject.activeSelf )
					{
						totalCoinsTextAnim.DOKill( true );
						totalCoinsTextAnim.DOScale( 1.25f, 0.133f ).SetLoops( 2, LoopType.Yoyo ).SetUpdate( true );
					}
				}
			}
		}

		public void SetProgress( int currentStage, int currentCheckpoint, bool immediately = false )
		{
			if( currentCheckpoint == 0 )
			{
				for( int i = 0; i < progressbarSlots.Length; i++ )
					progressbarSlots[i].sprite = immediately ? ( i < progressbarSlots.Length - 1 ? progressbarInactive : progressbarInactiveBonus ) : progressbarActive;
			}
			else
			{
				for( int i = 0; i < currentCheckpoint; i++ )
					progressbarSlots[i].sprite = progressbarActive;

				for( int i = currentCheckpoint; i < progressbarSlots.Length; i++ )
					progressbarSlots[i].sprite = i < progressbarSlots.Length - 1 ? progressbarInactive : progressbarInactiveBonus;
			}

			if( immediately || currentCheckpoint != 0 )
			{
				currentStageText.SetText( currentStage );
				nextStageText.SetText( currentStage + 1 );
			}
			else
				StartCoroutine( UpdateHUDStageTextsCoroutine( currentStage ) );
		}

		public void ShowDialog( string label, UnityAction yesButtonAction, UnityAction noButtonAction = null, float duration = UI_ELEMENTS_DEFAULT_TOGGLE_DURATION )
		{
			dialogLabel.text = label;

			dialogNoButtonAction = noButtonAction;
			dialogYesButtonAction = yesButtonAction;

			Show( UIElementType.Dialog, duration );
		}

		public void SpawnCollectedCoins( Vector2 screenPos, int spawnedCoins, int gainedCoins, float scaleMultiplier = 1f, float spread = 30f )
		{
			if( spawnedCoins == 0 )
			{
				if( gainedCoins != 0 )
				{
					long targetDisplayedCoin = FTemplate.UI.DisplayedTotalCoins + gainedCoins;
					FTemplate.UI.SetTotalCoins( targetDisplayedCoin >= 0L ? targetDisplayedCoin : 0L, true );
				}

				return;
			}

			int rewardAmountPerCoin = gainedCoins / spawnedCoins;
			int totalRewardedCoins = 0;

			if( !spawnedCoinParent.gameObject.activeSelf )
				spawnedCoinParent.gameObject.SetActive( true );

			Vector3 targetPos = totalCoinsText.transform.position;

			for( int i = 0; i < spawnedCoins; i++ )
			{
				SpawnedCoin spawnedCoin = spawnedCoinsPool.Pop();
				Vector2 coinPos = screenPos;
				if( i > 0 )
					coinPos += Random.insideUnitCircle * spread;

				int rewardAmount = ( i < spawnedCoins - 1 ) ? rewardAmountPerCoin : ( gainedCoins - totalRewardedCoins );
				totalRewardedCoins += rewardAmount;

				spawnedCoin.Animate( coinPos, targetPos, collectedCoinsScaleCurve, Random.Range( 0.7f, 1.2f ) * scaleMultiplier, Random.Range( 0.78f, 1f ), rewardAmount );
			}
		}

		public void PlayNextUnlockAnimation( int unlockProgressCurrent = 0, int unlockProgressTotal = 0 )
		{
			if( nextUnlockCoroutine == null )
				StartCoroutine( PlayNextUnlockAnimationCoroutine( unlockProgressCurrent, unlockProgressTotal ) );
		}

		public IEnumerator PlayNextUnlockAnimationCoroutine( int unlockProgressCurrent = 0, int unlockProgressTotal = 0 )
		{
			if( nextUnlockCoroutine != null )
				yield return nextUnlockCoroutine;
			else
			{
				nextUnlock = FTemplate.Shop.GetNextFreeCustomizationItem( true, ref unlockProgressCurrent, ref unlockProgressTotal );

				if( nextUnlock == null )
					Hide( UIElementType.NextUnlockPanel );
				else
				{
					Show( UIElementType.NextUnlockPanel );
					nextUnlockCoroutine = StartCoroutine( ShowNextUnlockCoroutine( unlockProgressCurrent, unlockProgressTotal ) );

					yield return nextUnlockCoroutine;
				}
			}
		}

		private void OnDialogButtonClicked( bool yesButtonClicked )
		{
			UnityAction action = yesButtonClicked ? dialogYesButtonAction : dialogNoButtonAction;

			// Hide dialog before executing the callback since callback can display another dialog immediately
			Hide( UIElementType.Dialog );

			if( action != null )
				action();

			FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Neutral );
		}

		private IEnumerator ContinueToNextLevelCoroutine()
		{
			if( LevelCompleteMenuType == LevelCompleteMenu.ShowTextThenFadeOut )
				yield return BetterWaitForSeconds.WaitRealtime( 1f );

			if( NextLevelButtonClicked != null )
				NextLevelButtonClicked();
		}

		private IEnumerator LevelFailedAdvancedAnimationCoroutine()
		{
			levelFailedCountdown.fillAmount = 1f;
			levelFailedCountdownOutline.fillAmount = 1f;

			levelFailedAllowSkipModeAnim.Play( "LevelFailedPanelAppearAdvancedVariant", 0, 0f );

			yield return BetterWaitForSeconds.WaitRealtime( levelFailedAllowSkipModeAnim.GetCurrentAnimatorStateInfo( 0 ).length );

			float fillAmount = 1f;
			float fillAmountSpeed = 1f / FTemplate.Analytics.GetRemoteFloatValue( "fail_v2_timer", 5f );
			while( fillAmount > 0f )
			{
				if( ( !levelFailedRestartButtonRewarded || levelFailedRestartButtonRewarded.interactable ) &&
					( !levelFailedContinueButton || levelFailedContinueButton.interactable ) )
				{
					fillAmount = Mathf.Max( 0f, fillAmount - fillAmountSpeed * Time.unscaledDeltaTime );

					levelFailedCountdown.fillAmount = fillAmount;
					levelFailedCountdownOutline.fillAmount = Mathf.Min( 1f, fillAmount + 0.015f );
				}

				yield return null;
			}

			levelFailedAdvancedCoroutine = null;
			levelFailedContinueButton.onClick.Invoke();
		}

		private IEnumerator UpdateHUDStageTextsCoroutine( int currentStage )
		{
			yield return BetterWaitForSeconds.WaitRealtime( 1.3f );

			currentStageText.SetText( currentStage );
			nextStageText.SetText( currentStage + 1 );

			for( int i = 0; i < progressbarSlots.Length; i++ )
				progressbarSlots[i].sprite = i < progressbarSlots.Length - 1 ? progressbarInactive : progressbarInactiveBonus;
		}

		private IEnumerator EnableBonusLevelRewardContinueButtonsCoroutine()
		{
			if( bonusLevelRewardV1ContinueButton )
				bonusLevelRewardV1ContinueButton.interactable = false;
			if( bonusLevelRewardV2ContinueButton )
				bonusLevelRewardV2ContinueButton.interactable = false;

			yield return BetterWaitForSeconds.WaitRealtime( 1.5f );

			if( !bonusLevelRewardGiven )
			{
				if( bonusLevelRewardV1ContinueButton )
					bonusLevelRewardV1ContinueButton.interactable = true;
				if( bonusLevelRewardV2ContinueButton )
					bonusLevelRewardV2ContinueButton.interactable = true;
			}
		}

		private IEnumerator ShowNextUnlockCoroutine( int unlockProgressCurrent, int unlockProgressTotal )
		{
			if( levelCompletedNextLevelButton )
				levelCompletedNextLevelButton.interactable = false;

			nextUnlockProgressText.gameObject.SetActive( true );
			nextUnlockUnlockedAnim.gameObject.SetActive( false );
			nextUnlockEquipButton.gameObject.SetActive( false );
			nextUnlockLockIcon.SetActive( true );

			float unlockProgress = unlockProgressCurrent;
			int unlockProgressNext = Mathf.Min( unlockProgressCurrent + 1, unlockProgressTotal );

			nextUnlockIcon.sprite = nextUnlock.Icon;
			nextUnlockProgress.fillAmount = unlockProgress / unlockProgressTotal;
			nextUnlockProgressText.SetText( (int) ( nextUnlockProgress.fillAmount * 100 ), null, "%" );

			// If the same value is assigned to unlockProgressCurrent and unlockProgressTotal manually,
			// don't show the 100% text since the free item will be unlocked immediately with no progressbar animation
			if( unlockProgress >= unlockProgressTotal )
				nextUnlockProgressText.gameObject.SetActive( false );
			else
				yield return BetterWaitForSeconds.WaitRealtime( 1f );

			float incrementAmount = 1f / 1.653f;
			while( unlockProgress < unlockProgressNext )
			{
				nextUnlockProgress.fillAmount = unlockProgress / unlockProgressTotal;
				nextUnlockProgressText.SetText( (int) ( nextUnlockProgress.fillAmount * 100 ), null, "%" );

				yield return null;
				unlockProgress += incrementAmount * Time.deltaTime;
			}

			nextUnlockProgress.fillAmount = (float) unlockProgressNext / unlockProgressTotal;
			nextUnlockProgressText.SetText( (int) ( nextUnlockProgress.fillAmount * 100 ), null, "%" );

			if( unlockProgressNext >= unlockProgressTotal )
			{
				nextUnlockProgress.fillAmount = 1f;

				nextUnlockProgressText.gameObject.SetActive( false );
				nextUnlockUnlockedAnim.gameObject.SetActive( true );
				nextUnlockUnlockedAnim.Play( "ItemUnlockedText", 0, 0f );

				PlayCelebrationParticles();

				nextUnlockLockIcon.SetActive( false );

				nextUnlockEquipButton.interactable = true;
				nextUnlockEquipButton.gameObject.SetActive( true );
			}

			if( levelCompletedNextLevelButton )
				levelCompletedNextLevelButton.interactable = true;

			nextUnlockCoroutine = null;
		}

		private Canvas FindRootCanvasOf( Component component )
		{
			Canvas result = component.GetComponent<Canvas>();
			Transform parent = component.transform.parent;
			while( parent != null )
			{
				Canvas canvas = parent.GetComponent<Canvas>();
				if( canvas )
					result = canvas;

				parent = parent.parent;
			}

			return result;
		}
	}
}