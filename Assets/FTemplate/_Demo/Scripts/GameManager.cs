using DG.Tweening;
using MoreMountains.NiceVibrations;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

namespace FTemplateNamespace.Demo
{
	public class GameManager : SingletonBehaviour<GameManager>
	{
		private enum State { MainMenu = 0, Playing = 1, GameOver = 2 };

#pragma warning disable 0649
		[Header( "FTemplate Configurations" )]
		[SerializeField]
		private AdsConfiguration adsConfiguration;

		[SerializeField]
		private GalleryConfiguration galleryConfiguration;

		[SerializeField]
		private ShopConfiguration shopConfiguration;

		[Header( "Other Variables" )]
		[SerializeField]
		private Player playerPrefab;
		public Player Player { get; private set; }

		[SerializeField]
		private AI aiPrefab;
		public AI[] AIs { get; private set; }

		[SerializeField]
		private List<Transform> spawnPoints;

		[SerializeField]
		private TextMeshProUGUI levelIDText;
#pragma warning restore 0649

		private State state = State.MainMenu;
		private bool isBonusLevel;

		public bool IsPlaying { get { return state == State.Playing; } }

		private void Start()
		{
			// Configure FTemplate modules
			FTemplate.Ads.SetConfiguration( adsConfiguration );
			FTemplate.Gallery.SetConfiguration( galleryConfiguration );
			FTemplate.Shop.SetConfiguration( shopConfiguration );

			// Some optimizations
			Application.targetFrameRate = 60;
			Input.simulateMouseWithTouches = false;
			Physics.reuseCollisionCallbacks = true;
			Physics.autoSyncTransforms = false;

			// Show active level's ID for demonstration purposes
			levelIDText.text = FTemplate.Gallery.ActiveLevel.ID;

			// Create player
			Player = Instantiate( playerPrefab );
			PositionCharacter( Player.transform );

			// Create AIs; in this demo, number of AIs increase proportional to the index of the active level
			AIs = new AI[FTemplate.Gallery.ActiveLevelIndex + 1];
			for( int i = 0; i < AIs.Length; i++ )
			{
				AIs[i] = Instantiate( aiPrefab );
				PositionCharacter( AIs[i].transform );
			}

			// Apply customizations to player
			CustomizationGameObject customizationAccessory = FTemplate.Shop.GetActiveCustomization( "accessory" ) as CustomizationGameObject;
			if( customizationAccessory )
				customizationAccessory.Instantiate( Player.transform );

			CustomizationMaterial customizationSkin = FTemplate.Shop.GetActiveCustomization( "skin" ) as CustomizationMaterial;
			if( customizationSkin )
				Player.GetComponent<Renderer>().sharedMaterial = customizationSkin.Material;

			// Send LevelStart event to Analytics
			FTemplate.Analytics.LevelStartedEvent( GetAnalyticsProgression() );

			// Register to UI events
			FTemplate.Gallery.OnGalleryPlayButtonClicked += GalleryPlayButtonClicked;
			FTemplate.UI.StartLevelButtonClicked += StartLevelButtonClicked;
			FTemplate.UI.NextLevelButtonClicked += NextLevelButtonClicked;
			FTemplate.UI.RestartLevelButtonClicked += RestartLevelButtonClicked;
			FTemplate.UI.SkipLevelButtonClicked += SkipLevelButtonClicked;

			// Set UI modes
			FTemplate.UI.LevelCompleteMenuType = UIModule.LevelCompleteMenu.DirectFadeOut;
			FTemplate.UI.LevelFailedMenuType = UIModule.LevelFailedMenu.AllowSkip;
			FTemplate.UI.BonusLevelRewardMenuType = UIModule.BonusLevelRewardMenu.RotatingStick;

			// Update HUD elements
			FTemplate.Gallery.GetCurrentProgress( out int currStage, out int currCheckpoint );
			FTemplate.UI.SetProgress( currStage + 1, currCheckpoint, true );
			FTemplate.UI.SetTotalCoins( FTemplate.Shop.Coins, false );

			// Hide all UI elements immediately (duration: 0f) and then show main menu
			FTemplate.UI.HideAllUIElements( 0f );
			FTemplate.UI.Show( UIElementType.MainMenu );

			// Invoke SingletonBehaviours' OnLevelInitialized function
			TriggerLevelInitialized();
		}

		private void OnDisable()
		{
			// Unregister from UI events
			FTemplate.Gallery.OnGalleryPlayButtonClicked -= GalleryPlayButtonClicked;
			FTemplate.UI.StartLevelButtonClicked -= StartLevelButtonClicked;
			FTemplate.UI.NextLevelButtonClicked -= NextLevelButtonClicked;
			FTemplate.UI.RestartLevelButtonClicked -= RestartLevelButtonClicked;
			FTemplate.UI.SkipLevelButtonClicked -= SkipLevelButtonClicked;
		}

		private void Update()
		{
			// When device's back button is pressed, quit the game
			if( Input.GetKeyDown( KeyCode.Escape ) )
			{
				// If a dialog is visible, close the dialog instead
				if( FTemplate.UI.IsVisible( UIElementType.Dialog ) )
					FTemplate.UI.Hide( UIElementType.Dialog );
				else
					Application.Quit();
			}
		}

		private void StartLevel()
		{
			state = State.Playing;
			isBonusLevel = FTemplate.Gallery.PlayingBonusLevel;

			// Activate the characters
			Player.OnLevelStarted();
			for( int i = 0; i < AIs.Length; i++ )
				AIs[i].OnLevelStarted();

			// Hide any visible menus (MainMenu, Gallery and etc.)
			FTemplate.UI.HideAllMenus();

			// Progressbar should be visible during gameplay
			FTemplate.UI.Show( UIElementType.Progressbar );

			// Show swipe tutorial when user plays the first level for the first time
			bool isFirstLevel = FTemplate.Gallery.ActiveLevelIndex == 0;
			bool firstTimePlayingThisLevel = FTemplate.Gallery.GetHighscore( FTemplate.Gallery.ActiveLevel.ID ) < 0;
			if( isFirstLevel && firstTimePlayingThisLevel )
				FTemplate.UI.Show( UIElementType.SwipeTutorial, autoHideInSeconds: 5f );

			// Invoke SingletonBehaviours' OnLevelStarted function
			TriggerLevelStarted();
		}

		private void LevelCompleted( int score )
		{
			if( state == State.GameOver )
				return;

			state = State.GameOver;

#if UNITY_EDITOR
			Debug.Log( "LEVEL COMPLETED: " + Time.timeSinceLevelLoad );
#endif

			// Send LevelComplete event to Analytics
			FTemplate.Analytics.LevelCompletedEvent( GetAnalyticsProgression() );

			// Save gained coins to Shop and score to Gallery
			FTemplate.Shop.IncrementCoins( score );
			FTemplate.Gallery.SubmitScore( FTemplate.Gallery.ActiveLevel.ID, score );

			// Hide all UI elements except progressbar
			FTemplate.UI.HideAllUIElements();
			FTemplate.UI.Show( UIElementType.Progressbar, 0f );

			// Update the progressbar
			FTemplate.Gallery.GetNextProgress( out int nextStage, out int nextCheckpoint );
			FTemplate.UI.SetProgress( nextStage + 1, nextCheckpoint );

			// Play some fancy FX
			FTemplate.UI.PlayCelebrationParticles();

			// Haptic feedback (vibration)
			MMVibrationManager.Haptic( HapticTypes.Success );

			// Invoke SingletonBehaviours' OnLevelFinished function
			TriggerLevelFinished( true );

			// Continue this function in a coroutine
			StartCoroutine( LevelCompletedCoroutine( score ) );
		}

		private void LevelFailed()
		{
			if( state == State.GameOver )
				return;

			state = State.GameOver;

			// Send LevelFail event to Analytics
			FTemplate.Analytics.LevelFailedEvent( GetAnalyticsProgression() );

			// Hide all UI elements and show LevelFailed menu
			FTemplate.UI.HideAllUIElements();
			FTemplate.UI.Show( UIElementType.LevelFailedMenu );

			// Haptic feedback (vibration)
			MMVibrationManager.Haptic( HapticTypes.Failure );

			// Invoke SingletonBehaviours' OnLevelFinished function
			TriggerLevelFinished( false );
		}

		// Called just before switching to a new level
		protected override void OnLevelClosed()
		{
			// Show an interstitial ad
			FTemplate.Ads.ShowInterstitialAd();
		}

		// If game can't start right now, this function should return false
		// When it returns true, any further clicks to the Play button in Main Menu are ignored
		private bool StartLevelButtonClicked()
		{
			StartLevel();
			return true;
		}

		// If the selected level can't be played, this function should return false (note that Gallery calls this function only if the selected level is unlocked)
		// When it returns true, any further clicks to the Play button in Gallery are ignored
		private bool GalleryPlayButtonClicked( GalleryConfiguration.LevelHolder level )
		{
			// Change Gallery's ActiveLevel
			FTemplate.Gallery.SetActiveLevel( level.ID );

			// Fade to the selected level
			LoadActiveLevel();
			return true;
		}

		// If game can't proceed to the next level right now, this function should return false
		// When it returns true, any further clicks to the Continue button in LevelCompleted menu are ignored
		private bool NextLevelButtonClicked()
		{
			// Instruct Gallery to proceed to the next level, i.e. increment the value of ActiveLevel
			FTemplate.Gallery.IncrementActiveLevel();

			// Fade to next level
			LoadActiveLevel();
			return true;
		}

		// If current level can't be restarted right now, this function should return false
		// When it returns true, any further clicks to the Restart buttons in LevelFailed and LevelCompleted menus are ignored
		private bool RestartLevelButtonClicked()
		{
			// Fade to current level
			LoadActiveLevel();
			return true;
		}

		// If game can't proceed to the next level right now, this function should return false
		private bool SkipLevelButtonClicked()
		{
			if( !FTemplate.Ads.IsRewardedAdAvailable() )
				return false;

			// Show a rewarded ad and skip the level if user watches it
			FTemplate.Ads.ShowRewardedAd( ( reward ) =>
			{
				FTemplate.Gallery.IncrementActiveLevel();
				LoadActiveLevel();
			}, "skip_level_button" );

			return true;
		}

		private IEnumerator LevelCompletedCoroutine( int score )
		{
			// Wait for the celebration particles to fade out
			yield return BetterWaitForSeconds.Wait( 2f );

			// Stop the player and zoom the camera to player
			Player.GetComponent<Rigidbody>().isKinematic = true;

			// Zoom camera to the player
			yield return Camera.main.DOOrthoSize( 7.5f, 1f ).WaitForCompletion();

			// If user gained some coins this level, execute "Tap to collect coins" logic and wait for it to finish
			if( score > 0 )
			{
				// Require more clicks in bonus levels
				int requiredClicks = FTemplate.Gallery.PlayingBonusLevel ? 12 : 7;
				int coinsPerClick = Mathf.Max( 1, Mathf.CeilToInt( (float) score / requiredClicks ) );

				FTemplate.UI.Show( UIElementType.TotalCoinsText );
				FTemplate.UI.TapToDoStuffTutorialLabel = "Tap to Collect Coins";

				float clickTutorialShowTime = 0f;
				Camera camera = Camera.main;

				while( score > 0 )
				{
					if( Time.time >= clickTutorialShowTime )
					{
						clickTutorialShowTime = float.PositiveInfinity;
						FTemplate.UI.Show( UIElementType.TapToDoStuffTutorial );
					}

					if( Input.GetMouseButtonDown( 0 ) )
					{
						int coinsToSpawn = Mathf.Min( coinsPerClick, score );
						score -= coinsToSpawn;

						FTemplate.UI.SpawnCollectedCoins( camera.WorldToScreenPoint( Player.transform.position ), coinsToSpawn, coinsToSpawn, 1f, 30f );
						MMVibrationManager.Haptic( HapticTypes.MediumImpact );

						clickTutorialShowTime = Time.time + 1.5f;
						FTemplate.UI.Hide( UIElementType.TapToDoStuffTutorial );

						// At each click, punch scale the player because it looks C00L
						Player.transform.DOKill( true );
						Player.transform.DOPunchScale( Player.transform.localScale * 0.2f, 0.5f );
					}

					yield return null;
				}

				yield return BetterWaitForSeconds.Wait( 1f );
			}

			// Hide HUD elements
			FTemplate.UI.Hide( UIElementType.Progressbar );
			if( !isBonusLevel )
				FTemplate.UI.Hide( UIElementType.TotalCoinsText );

			// Show LevelCompleted menu
			FTemplate.UI.Show( isBonusLevel ? UIElementType.BonusLevelRewardMenu : UIElementType.LevelCompletedMenu );

			// Show "next free unlock" dialog, if there is a pending free unlock
			if( !isBonusLevel && FTemplate.UI.LevelCompleteMenuType == UIModule.LevelCompleteMenu.ShowButtons )
			{
				// Show "next free unlock" dialog, if there is a pending free unlock
				// This dialog is only shown when BonusLevelRewardMenu isn't displayed and LevelCompletedMenu is
				// set to show Restart/Continue buttons (it is the only mode where the LevelCompletedMenu won't
				// fade out automatically)
				FTemplate.UI.PlayNextUnlockAnimation();
			}
		}

		private void PositionCharacter( Transform character )
		{
			int spawnPointIndex = Random.Range( 0, spawnPoints.Count );
			character.transform.position = spawnPoints[spawnPointIndex].position;
			character.transform.eulerAngles = new Vector3( 0f, Random.Range( 0f, 360f ), 0f );
			spawnPoints.RemoveAtFast( spawnPointIndex );
		}

		public void CharacterDied( Character character )
		{
			if( character == Player )
			{
				for( int i = 0; i < AIs.Length; i++ )
					AIs[i].enabled = false;

				LevelFailed();
			}
			else
			{
				for( int i = 0; i < AIs.Length; i++ )
				{
					if( AIs[i].enabled )
						return;
				}

				LevelCompleted( Mathf.Max( 100 - (int) Time.timeSinceLevelLoad, 1 ) );
			}
		}

		private AnalyticsModule.Progression GetAnalyticsProgression()
		{
			// a. Recommended method for long checkpoints, each checkpoint is treated as a separate level (recommended for Elephant SDK)
			FTemplate.Gallery.GetCurrentProgress( out int currLevel );
			return new AnalyticsModule.Progression( currLevel );

			// b. Alternative method for short checkpoints (~15-20s)
			//FTemplate.Gallery.GetCurrentProgress( out int currStage, out int currCheckpoint );
			//AnalyticsModule.Checkpoint checkpoint;
			//if( currCheckpoint == 0 )
			//	checkpoint = AnalyticsModule.Checkpoint.First( currCheckpoint );
			//else if( currCheckpoint == FTemplate.Gallery.CheckpointsPerStage - 1 )
			//	checkpoint = AnalyticsModule.Checkpoint.Last( currCheckpoint );
			//else
			//	checkpoint = AnalyticsModule.Checkpoint.Middle( currCheckpoint );

			//return new AnalyticsModule.Progression( currStage, checkpoint );
		}

		public static void LoadActiveLevel()
		{
			// Here, there are two options:
			// - If each level is played in a different scene, determine the scene to load by looking at level.Index and/or level.ID
			// - If each level is played in the same scene, simply load that scene (the example below)
			GalleryConfiguration.LevelHolder level = FTemplate.Gallery.ActiveLevel;
			FTemplate.UI.FadeToScene( "GameplayScene" ); // Or, for immediate scene switch: SceneManager.LoadScene( "GameplayScene" );

			// == NOTE ==
			// Here, FadeToScene automatically calls FBehaviour.TriggerLevelClosed to invoke SingletonBehaviours' OnLevelClosed function
			// Since FTemplate also listens to OnLevelClosed, it is recommended to
			// a) either use FadeToScene to switch scenes
			// b) or, invoke FBehaviour.TriggerLevelClosed manually before the scene changes
		}
	}
}