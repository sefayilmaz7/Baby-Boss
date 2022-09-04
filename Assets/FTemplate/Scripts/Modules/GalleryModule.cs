//#define UNLOCK_ALL_LEVELS

using MoreMountains.NiceVibrations;
using System.Collections.Generic;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;

using UnityEngine;
using UnityEngine.UI;

namespace FTemplateNamespace
{
	public class GalleryModule : MonoBehaviour
	{
		public delegate bool PlayButtonClickedDelegate( GalleryConfiguration.LevelHolder level );

#pragma warning disable 0649
		[System.Serializable]
		internal class SaveData
		{
			public List<string> passedLevels = new List<string>();
			public List<int> highscores = new List<int>();

			// Keep track of the index and the ID of the active level; when an update changes the level layout, Gallery tries to 
			// find the level with activeLevelID and sets it active. If activeLevelID no longer exists, activeLevelIndex is used
			public int activeLevelIndex;
			public string activeLevelID;

			public int stage;
			public int checkpoint;
			public int totalPlayedLevelCount;
		}

		[SerializeField]
		private GalleryItem galleryItemPrefab;

		[SerializeField]
		private ScrollRect itemsScrollView;

		[SerializeField]
		private GridLayoutGroup itemsHolder;

		[SerializeField]
		private Button closeButton;

		[SerializeField]
		private Button playButton;

		[SerializeField]
		private RectTransform selectedItemHighlight;

		[SerializeField]
		private Color m_lockedItemColor;
		internal Color LockedItemColor { get { return m_lockedItemColor; } }

		[SerializeField]
		private Color activeItemBackgroundColor;
#pragma warning restore 0649

		private bool initialized = false;
		private float itemAspectRatio = 1f;

		private int completedLevelCount;
		private bool playingRandomLevels;

		private GalleryConfiguration configuration;
		public GalleryConfiguration Configuration { get { return configuration; } }

		private GalleryItem[] galleryItems;
		private GalleryItem selectedItem;

		public int NumberOfLevels { get { return configuration.Levels.Length; } }
		public int ActiveLevelIndex { get { return configuration ? ActiveLevel.Index : 0; } }
		public GalleryConfiguration.LevelHolder ActiveLevel { get { return configuration.Levels[saveData.activeLevelIndex]; } }
		public GalleryConfiguration.LevelHolder this[int index] { get { return configuration.Levels[index]; } }
		public GalleryConfiguration.LevelHolder this[string levelID]
		{
			get
			{
				for( int i = 0; i < configuration.Levels.Length; i++ )
				{
					if( configuration.Levels[i].ID == levelID )
						return configuration.Levels[i];
				}

				return null;
			}
		}

		public int CompletedLevelCount { get { return completedLevelCount; } }
		public int TotalPlayedLevelCount { get { return saveData.totalPlayedLevelCount; } }

		public int CheckpointsPerStage { get { return configuration.CheckpointsPerLevel; } }
		public bool PlayingBonusLevel { get { return configuration.HasBonusLevels && saveData.checkpoint == configuration.CheckpointsPerLevel - 1; } }

		private SaveData saveData;
		internal static string SavePath { get { return Path.Combine( Application.persistentDataPath, "levels.dat" ); } }

		private readonly Dictionary<string, int> levelHighscores = new Dictionary<string, int>( 32 );

		public PlayButtonClickedDelegate OnGalleryPlayButtonClicked;

		private void Awake()
		{
			playButton.onClick.AddListener( () =>
			{
				bool adminMode = false;
#if UNLOCK_ALL_LEVELS
				adminMode = true;
#elif UNITY_EDITOR
				if( Input.GetKey( KeyCode.U ) )
					adminMode = true;
#endif

				if( !adminMode && ( selectedItem == null || !selectedItem.IsUnlocked ) )
				{
					playButton.ButtonNotFunctionalFeedback();
					MMVibrationManager.Haptic( HapticTypes.Warning );
					FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Negative );
				}
				else if( OnGalleryPlayButtonClicked != null )
				{
					if( OnGalleryPlayButtonClicked( selectedItem.Level ) )
					{
						playButton.interactable = false;

						if( closeButton )
							closeButton.interactable = false;

						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Positive );
					}
					else
					{
						playButton.ButtonNotFunctionalFeedback();
						MMVibrationManager.Haptic( HapticTypes.Warning );
						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Negative );
					}
				}
			} );

			if( closeButton )
			{
				closeButton.onClick.AddListener( () =>
				{
					if( FTemplate.UI.IsVisible( UIElementType.GalleryMenu ) )
					{
						FTemplate.UI.Hide( UIElementType.GalleryMenu );
						FTemplate.UI.Show( UIElementType.MainMenu, delay: Mathf.Abs( UIModule.UI_ELEMENTS_DEFAULT_TOGGLE_DURATION ) );
						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Neutral );
					}
				} );
			}

			LoadSettings();
		}

		public void SetConfiguration( GalleryConfiguration configuration )
		{
			if( !configuration || this.configuration == configuration )
				return;

			if( galleryItems != null )
			{
				for( int i = 0; i < galleryItems.Length; i++ )
					Destroy( galleryItems[i].gameObject );
			}

			initialized = false;
			this.configuration = configuration;

			if( configuration.Levels.Length > 0 )
			{
				for( int i = 0; i < configuration.Levels.Length; i++ )
					configuration.Levels[i].Index = i;

				Sprite icon = configuration.Levels[0].Icon;
				if( icon )
				{
					Rect rect = icon.rect;
					itemAspectRatio = rect.height / rect.width;
				}
			}

			if( galleryItems == null || galleryItems.Length != configuration.Levels.Length )
				galleryItems = new GalleryItem[configuration.Levels.Length];

			SetActiveLevel( saveData.activeLevelID );

			completedLevelCount = 0;
			for( int i = 0; i < configuration.Levels.Length; i++ )
			{
				if( saveData.passedLevels.Contains( configuration.Levels[i].ID ) )
					completedLevelCount++;
			}

			playingRandomLevels = completedLevelCount >= configuration.Levels.Length;
		}

		public void SetActiveLevel( string levelID )
		{
			if( configuration == null )
				return;

			GalleryConfiguration.LevelHolder level = this[levelID];
			if( level == null )
				level = configuration.Levels[Mathf.Clamp( saveData.activeLevelIndex, 0, configuration.Levels.Length - 1 )];

			saveData.activeLevelIndex = level.Index;
			saveData.activeLevelID = level.ID;

			int targetCheckpoint = level.Index % Mathf.Max( 1, configuration.CheckpointsPerLevel );
			bool isBonusLevel = configuration.HasBonusLevels && targetCheckpoint == configuration.CheckpointsPerLevel - 1;
			if( isBonusLevel || !playingRandomLevels )
				saveData.checkpoint = targetCheckpoint;

			SaveSettings();
		}

		public void IncrementActiveLevel()
		{
			// Increment checkpoint and stage, if necessary
			saveData.checkpoint = ( saveData.checkpoint + 1 ) % Mathf.Max( 1, configuration.CheckpointsPerLevel );
			if( saveData.checkpoint == 0 )
				saveData.stage++;

			int nextLevel;
			if( !playingRandomLevels )
				nextLevel = ( saveData.activeLevelIndex + 1 ) % configuration.Levels.Length;
			else
			{
				do
				{
					if( !configuration.HasBonusLevels )
						nextLevel = Random.Range( 0, configuration.Levels.Length );
					else if( saveData.checkpoint == configuration.CheckpointsPerLevel - 1 )
					{
						// Next level should be a bonus level
						nextLevel = Random.Range( 0, configuration.Levels.Length / configuration.CheckpointsPerLevel ) * configuration.CheckpointsPerLevel + configuration.CheckpointsPerLevel - 1;
					}
					else
					{
						// Next level should not be a bonus level
						nextLevel = Random.Range( 0, configuration.Levels.Length / configuration.CheckpointsPerLevel ) * configuration.CheckpointsPerLevel + Random.Range( 0, configuration.CheckpointsPerLevel - 1 );
					}
				} while( nextLevel == saveData.activeLevelIndex );
			}

			saveData.activeLevelIndex = nextLevel;
			saveData.activeLevelID = configuration.Levels[nextLevel].ID;
			saveData.totalPlayedLevelCount++;

			SaveSettings();
		}

		public void GetCurrentProgress( out int stage, out int checkpoint )
		{
			stage = saveData.stage;
			checkpoint = saveData.checkpoint;
		}

		public void GetCurrentProgress( out int level )
		{
			level = saveData.stage * configuration.CheckpointsPerLevel + saveData.checkpoint;
		}

		public void GetNextProgress( out int stage, out int checkpoint )
		{
			if( saveData.checkpoint + 1 < configuration.CheckpointsPerLevel )
			{
				stage = saveData.stage;
				checkpoint = saveData.checkpoint + 1;
			}
			else
			{
				stage = saveData.stage + 1;
				checkpoint = 0;
			}
		}

		public void GetNextProgress( out int level )
		{
			level = saveData.stage * configuration.CheckpointsPerLevel + saveData.checkpoint + 1;
		}

		public int GetHighscore( string levelID )
		{
			int index = saveData.passedLevels.IndexOf( levelID );
			return index >= 0 ? saveData.highscores[index] : -1;
		}

		public void SubmitScore( string levelID, int score )
		{
			bool changedHighscore = false;
			int levelIndex = saveData.passedLevels.IndexOf( levelID );
			if( levelIndex < 0 )
			{
				saveData.passedLevels.Add( levelID );
				saveData.highscores.Add( score );
				changedHighscore = true;

				if( ++completedLevelCount >= configuration.Levels.Length )
					playingRandomLevels = true;
			}
			else if( saveData.highscores[levelIndex] < score )
			{
				saveData.highscores[levelIndex] = score;
				changedHighscore = true;
			}

			if( changedHighscore )
			{
				levelHighscores[levelID] = score;

				if( initialized )
				{
					GalleryConfiguration.LevelHolder[] levels = configuration.Levels;
					for( int i = 0; i < levels.Length; i++ )
					{
						if( levels[i].ID == levelID )
						{
							levelIndex = i;
							break;
						}
					}

					galleryItems[levelIndex].Initialize( levels[levelIndex], score );
					if( levelIndex < levels.Length - 1 && !galleryItems[levelIndex + 1].IsUnlocked )
						galleryItems[levelIndex + 1].Initialize( levels[levelIndex + 1], 0 );
				}

				SaveSettings();
			}
		}

		public void UnlockAllLevels()
		{
			saveData.passedLevels.Clear();
			saveData.highscores.Clear();

			for( int i = 0; i < configuration.Levels.Length; i++ )
			{
				saveData.passedLevels.Add( configuration.Levels[i].ID );
				saveData.highscores.Add( 100 );
			}

			SaveSettings();
		}

		internal void OnGalleryOpening()
		{
			if( !configuration )
			{
				Debug.LogError( "Call SetConfiguration before displaying the Gallery!" );

				FTemplate.UI.Hide( UIElementType.GalleryMenu, 0f );
				FTemplate.UI.Show( UIElementType.MainMenu, 0f );

				return;
			}

			GalleryConfiguration.LevelHolder[] levels = configuration.Levels;

			if( !initialized )
			{
				initialized = true;

				float cellWidth = 100f;
				itemsHolder.cellSize = new Vector2( cellWidth, cellWidth * itemAspectRatio );
				selectedItemHighlight.sizeDelta = new Vector2( cellWidth, cellWidth * itemAspectRatio );

				bool prevLevelUnlocked = true;
				for( int i = 0; i < levels.Length; i++ )
				{
					int highscore;
					bool thisLevelUnlocked = levelHighscores.TryGetValue( levels[i].ID, out highscore );
					if( !thisLevelUnlocked )
						highscore = prevLevelUnlocked ? 0 : -1;

					GalleryItem galleryItem = Instantiate( galleryItemPrefab, itemsHolder.transform, false );
					galleryItem.GetComponent<Button>().onClick.AddListener( () =>
					{
						OnGalleryItemClicked( galleryItem );
						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Neutral );
					} );
					galleryItem.Initialize( levels[i], highscore );
					galleryItems[i] = galleryItem;

#if UNLOCK_ALL_LEVELS
					prevLevelUnlocked = true;
#else
					prevLevelUnlocked = thisLevelUnlocked;
#endif
				}

				itemsScrollView.verticalNormalizedPosition = 1f;
			}

			playButton.interactable = true;

			if( closeButton )
				closeButton.interactable = true;

			for( int i = 0; i < levels.Length; i++ )
				galleryItems[i].Background.color = saveData.activeLevelIndex == i ? activeItemBackgroundColor : Color.white;

			OnGalleryItemClicked( galleryItems[saveData.activeLevelIndex] );
		}

		private void OnGalleryItemClicked( GalleryItem item )
		{
			if( item == null )
			{
				selectedItem = null;
				selectedItemHighlight.gameObject.SetActive( false );

				//playButton.interactable = false;
			}
			else
			{
				selectedItem = item;

				selectedItemHighlight.gameObject.SetActive( true );
				selectedItemHighlight.localPosition = item.transform.localPosition;
				selectedItemHighlight.transform.SetAsLastSibling();

				//#if UNITY_EDITOR
				//if( Input.GetKey( KeyCode.U ) )
				//	playButton.interactable = true;
				//else
				//#endif
				//	playButton.interactable = item.IsUnlocked;
			}
		}

		private void SaveSettings()
		{
			SaveSettingsInternal( saveData );
		}

		private void LoadSettings()
		{
			saveData = LoadSettingsInternal();

			for( int i = 0; i < saveData.highscores.Count; i++ )
				levelHighscores[saveData.passedLevels[i]] = saveData.highscores[i];
		}

		internal static void SaveSettingsInternal( SaveData saveData )
		{
			BinaryFormatter formatter = new BinaryFormatter();
			try
			{
				using( FileStream fs = new FileStream( SavePath, FileMode.Create ) )
					formatter.Serialize( fs, saveData );
			}
			catch( System.Exception e )
			{
				Debug.LogException( e );
			}
		}

		internal static SaveData LoadSettingsInternal()
		{
			string savePath = SavePath;
			if( File.Exists( savePath ) )
			{
				BinaryFormatter formatter = new BinaryFormatter();
				try
				{
					using( FileStream fs = new FileStream( savePath, FileMode.Open, FileAccess.Read ) )
						return (SaveData) formatter.Deserialize( fs );
				}
				catch( System.Exception e )
				{
					Debug.LogException( e );
				}
			}

			return new SaveData();
		}

		public void ResetSettings()
		{
			File.Delete( SavePath );
			LoadSettings();
		}
	}
}