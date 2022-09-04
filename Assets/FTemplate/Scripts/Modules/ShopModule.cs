//#define UNLOCK_ALL_ITEMS

using MoreMountains.NiceVibrations;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;
using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

namespace FTemplateNamespace
{
	public class ShopModule : MonoBehaviour
	{
		public delegate void ShopActiveTabChangedDelegate( ShopConfiguration.TabHolder activeTab );
		public delegate void ShopCustomizationChangedDelegate( List<CustomizationItem> customizations );
		public delegate bool CloseShopHandlerDelegate();

#pragma warning disable 0649
		[System.Serializable]
		internal class SaveData
		{
			public long coins;
			public List<string> unlockedItems = new List<string>();
			public List<string> equippedItems = new List<string>();
			public string nextFreeUnlock;
			public int nextFreeUnlockProgress;
		}

		[SerializeField]
		private ShopTab shopTabPrefab;

		[SerializeField]
		private ShopItem shopItemPrefab;

		[SerializeField]
		private RectTransform background;

		[SerializeField]
		private ScrollRect itemsScrollView;

		[SerializeField]
		private RectTransform tabsHolder;

		[SerializeField]
		private GridLayoutGroup itemsHolder;

		[SerializeField]
		private Button closeButton;

		[SerializeField]
		private Button buyButton;
		private CanvasGroup buyButtonCanvasGroup;

		[SerializeField]
		private Button watchVideoAdButton;

		[SerializeField]
		private Button watchVideoAdForCoinsButton;
		[SerializeField]
		private TextMeshProUGUI watchVideoAdForCoinsButtonText;

		[SerializeField]
		private TextMeshProUGUI coinsText;

		[SerializeField]
		private TextMeshProUGUI buyButtonLabelText;

		[SerializeField]
		private TextMeshProUGUI buyButtonPriceText;

		[SerializeField]
		private RectTransform selectedItemHighlight;

		[SerializeField]
		private Sprite tabActiveSprite;

		[SerializeField]
		private Sprite tabInactiveSprite;

		[SerializeField]
		private Color lockedItemColor;
		internal Color LockedItemColor { get { return lockedItemColor; } }

		[SerializeField]
		private AnimationCurve randomUnlockSwapCurve;

		[Header( "Rank Progress" )]
		[SerializeField]
		private GameObject rankProgressRoot;

		[SerializeField]
		private Image rankIcon;

		[SerializeField]
		private TextMeshProUGUI rankText;

		[SerializeField]
		private SlicedFilledImage nextRankProgress;

		[SerializeField]
		private Animator rankUpAnim;

		[SerializeField]
		private CanvasGroup shopCanvasGroup;
#pragma warning restore 0649

		private bool initialized = false;
		private float itemAspectRatio = 1f;

		private ShopConfiguration configuration;
		public ShopConfiguration Configuration { get { return configuration; } }

		private ShopTab[] shopTabs;

		private bool rewardedAdsEnabled;
		private bool useNormalVideoAdButton, useVideoAdForCoinsButton;
		private int videoAdReward;

		internal string ShopScene { get { return configuration.ShopScene; } }
		internal bool AutoSaveFreeUnlockProgress { get { return configuration.AutoSaveFreeUnlockProgress; } }

		public long Coins { get { return saveData.coins; } }

		private readonly List<ShopItem> shopItems = new List<ShopItem>( 32 );
		private int shopItemCount = 0;

		private int selectedTab;
		private ShopItem selectedItem;
		private bool IsSelectedTabUsingRandomUnlock { get { return configuration.Tabs[selectedTab].RandomUnlockPrice > 0L; } }

		private Coroutine videoAdCheckAvailabilityCoroutine;
		private Coroutine randomUnlockCoroutine;

		private readonly HashSet<string> unlockedItemsSet = new HashSet<string>();

		private int purchasedItemCount, totalPurchasableItemCount;

		private readonly List<CustomizationItem> cachedPlayerCustomizations = new List<CustomizationItem>( 4 );
		private readonly List<CustomizationItem> activePlayerCustomizations = new List<CustomizationItem>( 4 );

		private SaveData saveData;
		internal static string SavePath { get { return Path.Combine( Application.persistentDataPath, "configuration.dat" ); } }

		public ShopActiveTabChangedDelegate OnActiveTabChanged;
		public ShopCustomizationChangedDelegate OnCustomizationChanged;
		public CloseShopHandlerDelegate CloseShopHandler;
		public System.Action IncrementCoinEvent;

		private void Awake()
		{
			buyButtonCanvasGroup = buyButton.gameObject.AddComponent<CanvasGroup>();

			buyButton.onClick.AddListener( () =>
			{
#if UNITY_EDITOR
				if( Input.GetKey( KeyCode.U ) )
					BuyItem( true );
				else
#endif
				if( BuyItem( false ) )
				{
					// In random unlock mode, positive audio is played when the animation is completed
					if( !IsSelectedTabUsingRandomUnlock )
						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Positive );
				}
				else
					FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Negative );

				RefreshBuyButtons();
			} );

			watchVideoAdButton.onClick.AddListener( () =>
			{
				if( !FTemplate.Ads.IsRewardedAdAvailable() )
				{
					watchVideoAdButton.ButtonNotFunctionalFeedback();
					FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Negative );
				}
				else
				{
					if( !IsSelectedTabUsingRandomUnlock )
						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Neutral );

					FTemplate.Ads.ShowRewardedAd( ( reward ) =>
					{
						BuyItem( true );
						RefreshBuyButtons();
					}, "rewarded_shop_purchase" );
				}
			} );

			watchVideoAdForCoinsButton.onClick.AddListener( () =>
			{
				if( !FTemplate.Ads.IsRewardedAdAvailable() )
				{
					watchVideoAdForCoinsButton.ButtonNotFunctionalFeedback();
					FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Negative );
				}
				else
				{
					if( !IsSelectedTabUsingRandomUnlock )
						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Neutral );

					FTemplate.Ads.ShowRewardedAd( ( reward ) =>
					{
						watchVideoAdForCoinsButton.gameObject.SetActive( false );

						IncrementCoins( videoAdReward );
						coinsText.SetText( saveData.coins );

						RefreshBuyButtons();
						OnShopItemClicked( selectedItem );

						FTemplate.Analytics.TransactionEvent( "shop", "coin", FTemplate.Gallery ? FTemplate.Gallery.ActiveLevelIndex : 0, videoAdReward, saveData.coins, "rewarded_ad_coins", null );
					}, "rewarded_shop_coin" );
				}
			} );

			if( closeButton )
			{
				closeButton.onClick.AddListener( () =>
				{
					if( FTemplate.UI.IsVisible( UIElementType.ShopMenu ) )
					{
						ReturnToMainMenu();
						FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Neutral );
					}
				} );
			}

			useNormalVideoAdButton = watchVideoAdButton.gameObject.activeSelf;
			useVideoAdForCoinsButton = watchVideoAdForCoinsButton.gameObject.activeSelf;

			LoadSettings();
		}

		private void Start()
		{
			rewardedAdsEnabled = FTemplate.Ads && FTemplate.Ads.AdsEnabled;
		}

#if UNITY_EDITOR
		private void Update()
		{
			if( Input.GetKeyDown( KeyCode.O ) && FTemplate.UI.IsVisible( UIElementType.ShopMenu ) )
				OnTabClicked( ( selectedTab + 1 ) % shopTabs.Length );
		}
#endif

		public void SetConfiguration( ShopConfiguration configuration )
		{
			if( !configuration || this.configuration == configuration )
				return;

			activePlayerCustomizations.Clear();

			purchasedItemCount = 0;
			totalPurchasableItemCount = 0;

			if( shopTabs != null )
			{
				for( int i = 0; i < shopTabs.Length; i++ )
					Destroy( shopTabs[i].gameObject );
			}

			ShopConfiguration.TabHolder[] tabs = configuration.Tabs;
			this.configuration = configuration;
			if( shopTabs == null || shopTabs.Length != tabs.Length )
				shopTabs = new ShopTab[tabs.Length];

			float tabAnchorX = 0f;
			float tabAnchorXIncrementAmount = 1f / tabs.Length;
			for( int i = 0; i < tabs.Length; i++ )
			{
				// Initialize CustomizationItems' categories
				tabs[i].DefaultItem.m_Category = tabs[i].Category;

				for( int j = 0; j < tabs[i].Items.Length; j++ )
					tabs[i].Items[j].m_Category = tabs[i].Category;

				// Create tab
				int index = i;
				shopTabs[i] = Instantiate( shopTabPrefab, tabsHolder, false );
				shopTabs[i].Icon.sprite = tabs[i].Icon;
				shopTabs[i].Button.onClick.AddListener( () =>
				{
					OnTabClicked( index );
					FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Neutral );
				} );

				RectTransform tabTransform = (RectTransform) shopTabs[i].transform;
				tabTransform.SetAsFirstSibling();
				tabTransform.anchorMin = new Vector2( tabAnchorX, tabTransform.anchorMin.y );
				tabAnchorX += tabAnchorXIncrementAmount;
				tabTransform.anchorMax = new Vector2( tabAnchorX, tabTransform.anchorMax.y );

				// Handle equipped items
				CustomizationItem[] items = tabs[i].Items;
				bool foundEquippedItem = false;
				for( int j = 0; j < items.Length; j++ )
				{
					if( saveData.equippedItems.IndexOf( items[j].ID ) >= 0 )
					{
						activePlayerCustomizations.Add( items[j] );

						foundEquippedItem = true;
						break;
					}
				}

				totalPurchasableItemCount += items.Length;
				for( int j = 0; j < items.Length; j++ )
				{
					if( unlockedItemsSet.Contains( items[j].ID ) )
						purchasedItemCount++;
				}

				if( !foundEquippedItem )
					activePlayerCustomizations.Add( tabs[i].DefaultItem );

				if( !unlockedItemsSet.Contains( tabs[i].DefaultItem.ID ) )
				{
					saveData.unlockedItems.Add( tabs[i].DefaultItem.ID );
					unlockedItemsSet.Add( tabs[i].DefaultItem.ID );
				}

				if( items.Length > 0 )
				{
					Sprite icon = items[0].Icon;
					if( icon )
					{
						Rect rect = icon.rect;
						itemAspectRatio = rect.height / rect.width;
					}
				}
			}
		}

		internal void OnShopOpening()
		{
			if( !configuration )
			{
				Debug.LogError( "Call SetConfiguration before displaying the Shop!" );
				ReturnToMainMenu();

				return;
			}

			coinsText.SetText( saveData.coins );

			cachedPlayerCustomizations.Clear();
			for( int i = 0; i < activePlayerCustomizations.Count; i++ )
				cachedPlayerCustomizations.Add( activePlayerCustomizations[i] );

			if( !initialized )
			{
				initialized = true;

				float cellWidth = configuration.ShopItemWidth;
				itemsHolder.cellSize = new Vector2( cellWidth, cellWidth * itemAspectRatio );
				selectedItemHighlight.sizeDelta = new Vector2( cellWidth, cellWidth * itemAspectRatio );

				videoAdReward = FTemplate.Analytics.GetRemoteIntValue( configuration.VideoAdForCoinsRemoteKey, configuration.VideoAdForCoinsDefaultAmount );
				watchVideoAdForCoinsButtonText.SetText( videoAdReward, "+", null );

				if( configuration.Ranks.Length > 0 )
				{
					rankProgressRoot.SetActive( true );
					UpdateRank( true );
				}
				else
					rankProgressRoot.SetActive( false );
			}
			else
				watchVideoAdForCoinsButton.gameObject.SetActive( rewardedAdsEnabled && useVideoAdForCoinsButton );

			if( rewardedAdsEnabled )
				videoAdCheckAvailabilityCoroutine = StartCoroutine( CheckForRewardedAdAvailabilityCoroutine() );

			OnTabClicked( selectedTab );
		}

		internal void OnShopClosing()
		{
			if( randomUnlockCoroutine != null )
			{
				StopCoroutine( randomUnlockCoroutine );
				randomUnlockCoroutine = null;
			}

			if( videoAdCheckAvailabilityCoroutine != null )
			{
				StopCoroutine( videoAdCheckAvailabilityCoroutine );
				videoAdCheckAvailabilityCoroutine = null;
			}

			bool previewingLockedItems = false;
			for( int i = activePlayerCustomizations.Count - 1; i >= 0; i-- )
			{
				if( !IsCustomizationUnlocked( activePlayerCustomizations[i] ) )
				{
					int replacementIndex = -1;
					for( int j = 0; j < cachedPlayerCustomizations.Count; j++ )
					{
						if( activePlayerCustomizations[i].Category == cachedPlayerCustomizations[j].Category )
						{
							replacementIndex = j;
							break;
						}
					}

					if( replacementIndex >= 0 )
						activePlayerCustomizations[i] = cachedPlayerCustomizations[replacementIndex];
					else
						activePlayerCustomizations.RemoveAt( i );

					previewingLockedItems = true;
				}
			}

			saveData.equippedItems.Clear();
			for( int i = 0; i < activePlayerCustomizations.Count; i++ )
				saveData.equippedItems.Add( activePlayerCustomizations[i].ID );

			if( previewingLockedItems )
				RefreshCustomization();

			SaveSettings();
		}

		private void ReturnToMainMenu()
		{
			if( CloseShopHandler == null || !CloseShopHandler() )
			{
				if( !configuration || !string.IsNullOrEmpty( configuration.ShopScene ) && SceneManager.GetActiveScene().name == configuration.ShopScene )
				{
					FTemplate.UI.Hide( UIElementType.ShopMenu, UIModule.DEFAULT_FADE_DURATION );
					FTemplate.UI.FadeToScene( FTemplate.UI.ShopPrecedingSceneIndex );
				}
				else
				{
					FTemplate.UI.Hide( UIElementType.ShopMenu );
					FTemplate.UI.Show( UIElementType.MainMenu, delay: Mathf.Abs( UIModule.UI_ELEMENTS_DEFAULT_TOGGLE_DURATION ) );
				}
			}
		}

		private void OnTabClicked( int index )
		{
			if( randomUnlockCoroutine != null )
				return;

			bool activeTabChanged = selectedTab != index;
			selectedTab = index;

			if( activeTabChanged && OnActiveTabChanged != null )
				OnActiveTabChanged( configuration.Tabs[selectedTab] );

			for( int i = 0; i < shopTabs.Length; i++ )
			{
				if( i == index )
				{
					shopTabs[i].Background.sprite = tabActiveSprite;
					shopTabs[i].transform.SetSiblingIndex( background.GetSiblingIndex() + 1 );
				}
				else
				{
					shopTabs[i].Background.sprite = tabInactiveSprite;
					shopTabs[i].transform.SetSiblingIndex( Mathf.Max( 0, background.GetSiblingIndex() - 1 ) );
				}
			}

			OnShopItemClicked( null );

			CustomizationItem[] items = configuration.Tabs[index].Items;
			shopItemCount = items.Length + 1; // +1: Default item

			for( int i = shopItems.Count; i < shopItemCount; i++ )
			{
				ShopItem shopItem = Instantiate( shopItemPrefab, itemsHolder.transform, false );
				shopItem.GetComponent<Button>().onClick.AddListener( () =>
				{
					OnShopItemClicked( shopItem );
					FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Neutral );
				} );

				shopItems.Add( shopItem );
			}

			for( int i = shopItemCount; i < shopItems.Count; i++ )
				shopItems[i].gameObject.SetActive( false );

			ShopItem activeShopItem = null;
			for( int i = 0; i < shopItemCount; i++ )
			{
				CustomizationItem customizationItem = ( i == 0 ) ? configuration.Tabs[index].DefaultItem : items[i - 1];

				shopItems[i].gameObject.SetActive( true );
				shopItems[i].Initialize( customizationItem, IsCustomizationUnlocked( customizationItem ), !IsSelectedTabUsingRandomUnlock );

				if( activePlayerCustomizations.IndexOf( customizationItem ) >= 0 )
					activeShopItem = shopItems[i];
			}

			if( activeShopItem != null )
			{
				LayoutRebuilder.ForceRebuildLayoutImmediate( (RectTransform) itemsHolder.transform );
				OnShopItemClicked( activeShopItem );
			}

			buyButtonLabelText.text = IsSelectedTabUsingRandomUnlock ? "RANDOM UNLOCK" : "BUY";
			RefreshBuyButtons();

			itemsScrollView.verticalNormalizedPosition = 1f;
		}

		private void OnShopItemClicked( ShopItem item )
		{
			if( randomUnlockCoroutine != null )
				return;

			if( !item )
			{
				selectedItem = null;

				if( !IsSelectedTabUsingRandomUnlock )
				{
					buyButton.gameObject.SetActive( false );
					watchVideoAdButton.gameObject.SetActive( false );
				}

				selectedItemHighlight.gameObject.SetActive( false );
			}
			else
			{
				selectedItem = item;

				if( !IsSelectedTabUsingRandomUnlock )
				{
					buyButton.gameObject.SetActive( !item.IsUnlocked );
					watchVideoAdButton.gameObject.SetActive( !item.IsUnlocked && rewardedAdsEnabled && useNormalVideoAdButton );

					if( !item.IsUnlocked )
						SetBuyButtonPrice( item.CustomizationItem.Price );
				}

				selectedItemHighlight.gameObject.SetActive( true );
				selectedItemHighlight.localPosition = item.transform.localPosition;
				selectedItemHighlight.transform.SetAsLastSibling();

				CustomizationItem customizationItem = selectedItem.CustomizationItem;
				for( int i = activePlayerCustomizations.Count - 1; i >= 0; i-- )
				{
					if( activePlayerCustomizations[i].Category == customizationItem.Category )
						activePlayerCustomizations.RemoveAt( i );
				}

				activePlayerCustomizations.Add( customizationItem );
				RefreshCustomization();
			}
		}

		private bool BuyItem( bool viaVideoAd )
		{
			if( randomUnlockCoroutine != null )
				return true;

			CustomizationItem itemToUnlock;
			if( IsSelectedTabUsingRandomUnlock )
			{
				itemToUnlock = GetRandomUnlockItem();
				if( !itemToUnlock )
					return true;
			}
			else
			{
				if( !selectedItem )
					return false;

				itemToUnlock = selectedItem.CustomizationItem;

				if( IsCustomizationUnlocked( itemToUnlock ) )
					return true;
			}

			long price = viaVideoAd ? 0L : ( IsSelectedTabUsingRandomUnlock ? CalculateRandomUnlockPrice() : itemToUnlock.Price );
			if( !viaVideoAd && saveData.coins < price )
			{
				buyButton.ButtonNotFunctionalFeedback();
				MMVibrationManager.Haptic( HapticTypes.Warning );

				return false;
			}

			if( !viaVideoAd )
			{
				saveData.coins -= price;
				coinsText.SetText( saveData.coins );
			}

			UnlockCustomizationItem( itemToUnlock );

			if( IsSelectedTabUsingRandomUnlock )
				randomUnlockCoroutine = StartCoroutine( UnlockRandomItemCoroutine( itemToUnlock ) );
			else
			{
				// In random unlock mode, item will be equipped when the animation finishes
				EquipCustomizationItem( itemToUnlock, false );

				selectedItem.Initialize( itemToUnlock, true, !IsSelectedTabUsingRandomUnlock );
				OnShopItemClicked( selectedItem );

				MMVibrationManager.Haptic( HapticTypes.Success );
			}

			if( configuration.Ranks.Length > 0 && purchasedItemCount < totalPurchasableItemCount )
			{
				GetRankProgress( out int rankIndex, out int rankProgress );
				purchasedItemCount++;

				if( rankIndex < configuration.Ranks.Length )
					StartCoroutine( RankUpCoroutine( rankProgress, configuration.Ranks[rankIndex].ProgressToNext ) );
			}

			string eventName = ( viaVideoAd ? "rewarded_ad_" : "buy_" ) + itemToUnlock.Category;
			FTemplate.Analytics.TransactionEvent( "shop", "coin", FTemplate.Gallery ? FTemplate.Gallery.ActiveLevelIndex : 0, -price, saveData.coins, eventName, itemToUnlock.name );

			return true;
		}

		public void IncrementCoins( long amount, bool saveChanges = true )
		{
			if( amount != 0L )
			{
				saveData.coins += amount;
				if( saveData.coins < 0L )
					saveData.coins = 0L;

				if( saveChanges )
					SaveSettings();

				IncrementCoinEvent?.Invoke();
			}
		}

		internal void RefreshCustomization()
		{
			if( OnCustomizationChanged != null )
				OnCustomizationChanged( activePlayerCustomizations );
		}

		public ShopConfiguration.TabHolder GetActiveTab()
		{
			return configuration.Tabs[selectedTab];
		}

		public void SetActiveTab( int tabIndex )
		{
			if( configuration )
				OnTabClicked( tabIndex % shopTabs.Length );
		}

		public List<CustomizationItem> GetActiveCustomizations()
		{
			return activePlayerCustomizations;
		}

		public CustomizationItem GetActiveCustomization( string category )
		{
			for( int i = 0; i < activePlayerCustomizations.Count; i++ )
			{
				if( activePlayerCustomizations[i].Category == category )
					return activePlayerCustomizations[i];
			}

			return null;
		}

		public List<CustomizationItem> GetAllCustomizations( string category )
		{
			List<CustomizationItem> result = new List<CustomizationItem>();
			for( int i = 0; i < configuration.Tabs.Length; i++ )
			{
				if( configuration.Tabs[i].Category == category )
				{
					result.Add( configuration.Tabs[i].DefaultItem );
					result.AddRange( configuration.Tabs[i].Items );
				}
			}

			return result;
		}

		public CustomizationItem GetCustomizationByID( string id )
		{
			ShopConfiguration.TabHolder[] tabs = configuration.Tabs;
			for( int i = 0; i < tabs.Length; i++ )
			{
				CustomizationItem[] items = tabs[i].Items;
				for( int j = 0; j < items.Length; j++ )
				{
					if( items[j].ID == id )
						return items[j];
				}
			}

			return null;
		}

		private CustomizationItem GetRandomUnlockItem()
		{
			CustomizationItem[] items = configuration.Tabs[selectedTab].Items;

			List<CustomizationItem> lockedItems = new List<CustomizationItem>( items.Length );
			List<float> lockedItemChances = new List<float>( items.Length );
			float lockedItemsTotalChance = 0;
			for( int i = 0; i < items.Length; i++ )
			{
				if( !IsCustomizationUnlocked( items[i] ) )
				{
					lockedItems.Add( items[i] );
					lockedItemChances.Add( 1f / items[i].Price );
					lockedItemsTotalChance += lockedItemChances[lockedItemChances.Count - 1];
				}
			}

			if( lockedItems.Count == 0 )
				return null;

			float randomChance = Random.Range( 0f, lockedItemsTotalChance );
			for( int i = 0; i < lockedItems.Count; i++ )
			{
				if( randomChance <= lockedItemChances[i] )
					return lockedItems[i];

				randomChance -= lockedItemChances[i];
			}

			return lockedItems[lockedItems.Count - 1];
		}

		private IEnumerator UnlockRandomItemCoroutine( CustomizationItem unlockedItem )
		{
			List<ShopItem> lockedItems = new List<ShopItem>( configuration.Tabs[selectedTab].Items.Length );
			ShopItem targetItem = null;
			int targetItemOffset = 0;
			for( int i = 0; i < shopItems.Count; i++ )
			{
				if( shopItems[i].gameObject.activeSelf )
				{
					if( shopItems[i].CustomizationItem == unlockedItem )
					{
						targetItem = shopItems[i];
						lockedItems.Add( targetItem );
						targetItemOffset = lockedItems.Count;
					}
					else if( !shopItems[i].IsUnlocked )
						lockedItems.Add( shopItems[i] );
				}
			}

			float scrollViewHeight = -1f / ( (RectTransform) itemsHolder.transform ).rect.height;
			if( targetItem && lockedItems.Count > 1 ) // Don't play the animation for the last locked item
			{
				selectedItemHighlight.gameObject.SetActive( true );
				selectedItemHighlight.transform.SetAsLastSibling();

				int numberOfSwaps = 0;
				while( numberOfSwaps < 15 )
					numberOfSwaps += lockedItems.Count;

				numberOfSwaps += targetItemOffset;

				for( int i = 0; i < numberOfSwaps; i++ )
				{
					selectedItemHighlight.localPosition = lockedItems[i % lockedItems.Count].transform.localPosition;
					FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Neutral );
					MMVibrationManager.Haptic( HapticTypes.Selection );

					if( !RectTransformUtility.RectangleContainsScreenPoint( (RectTransform) itemsScrollView.transform, selectedItemHighlight.position ) )
						itemsScrollView.verticalNormalizedPosition = 1f - Mathf.Clamp01( selectedItemHighlight.localPosition.y * scrollViewHeight );

					yield return BetterWaitForSeconds.Wait( Mathf.Lerp( 0.1f, 0.5f, randomUnlockSwapCurve.Evaluate( (float) i / numberOfSwaps ) ) );
				}
			}

			randomUnlockCoroutine = null;

			EquipCustomizationItem( unlockedItem, false );

			if( targetItem )
			{
				targetItem.Initialize( unlockedItem, true, !IsSelectedTabUsingRandomUnlock );
				OnShopItemClicked( targetItem );

				//itemsScrollView.verticalNormalizedPosition = 1f - Mathf.Clamp01( targetItem.transform.localPosition.y * scrollViewHeight );
			}

			MMVibrationManager.Haptic( HapticTypes.Success );
			FTemplate.Audio.PlayButtonClickAudio( AudioModule.ButtonState.Positive );
			FTemplate.UI.PlayCelebrationParticles();
		}

		internal CustomizationItem GetNextFreeCustomizationItem( bool shouldProgress, ref int unlockProgressCurrent, ref int unlockProgressTotal )
		{
			// If an unlockProgressTotal is passed manually, use it instead of using shop's Free Unlock Intervals
			if( unlockProgressTotal <= 0 )
				configuration.GetFreeUnlockProgress( saveData.nextFreeUnlockProgress, out unlockProgressCurrent, out unlockProgressTotal );

			bool shouldSaveSettings = shouldProgress;
			CustomizationItem result = null;
			if( !string.IsNullOrEmpty( saveData.nextFreeUnlock ) && !IsCustomizationUnlocked( saveData.nextFreeUnlock ) )
				result = GetCustomizationByID( saveData.nextFreeUnlock );

			if( !result )
			{
				bool processedRandomTabIndex = false;
				int randomTabIndex = Random.Range( 0, shopTabs.Length );
				for( int i = randomTabIndex; !processedRandomTabIndex || i != randomTabIndex; i = ( i + 1 ) % shopTabs.Length )
				{
					CustomizationItem[] items = configuration.Tabs[i].Items;
					int cheapestLockedItemIndex = -1;
					for( int j = 0; j < items.Length; j++ )
					{
						if( !IsCustomizationUnlocked( items[j] ) )
						{
							if( cheapestLockedItemIndex < 0 || items[cheapestLockedItemIndex].Price > items[j].Price ||
								( items[cheapestLockedItemIndex].Price == items[j].Price && Random.value < 0.5f ) )
							{
								cheapestLockedItemIndex = j;
							}
						}
					}

					if( cheapestLockedItemIndex >= 0 )
					{
						saveData.nextFreeUnlock = items[cheapestLockedItemIndex].ID;
						shouldSaveSettings = true;

						result = items[cheapestLockedItemIndex];
						break;
					}

					processedRandomTabIndex = true;
				}
			}

			if( result )
			{
				if( shouldProgress )
				{
					saveData.nextFreeUnlockProgress++;

					if( unlockProgressCurrent + 1 >= unlockProgressTotal )
					{
						UnlockCustomizationItem( result, AutoSaveFreeUnlockProgress );
						FTemplate.Analytics.ContentUnlockedEvent( string.Concat( result.Category, "_", result.name ), -1, FTemplate.Gallery ? FTemplate.Gallery.ActiveLevelIndex : 0 );
					}
					else if( AutoSaveFreeUnlockProgress )
						SaveSettings();
				}
				else if( shouldSaveSettings && AutoSaveFreeUnlockProgress )
					SaveSettings();
			}

			return result;
		}

		public void UnlockCustomizationItem( CustomizationItem customizationItem, bool saveSettings = true )
		{
			if( !IsCustomizationUnlocked( customizationItem ) )
			{
				saveData.unlockedItems.Add( customizationItem.ID );
				unlockedItemsSet.Add( customizationItem.ID );

				if( saveSettings )
					SaveSettings();
			}
		}

		public void UnlockAllCustomizationItems()
		{
			saveData.unlockedItems.Clear();

			for( int i = 0; i < configuration.Tabs.Length; i++ )
			{
				CustomizationItem[] items = configuration.Tabs[i].Items;
				for( int j = 0; j < items.Length; j++ )
					saveData.unlockedItems.Add( items[j].ID );
			}

			unlockedItemsSet.Clear();
			unlockedItemsSet.UnionWith( saveData.unlockedItems );

			SaveSettings();
		}

		internal void EquipCustomizationItem( CustomizationItem customizationItem, bool saveChanges )
		{
			// Adding to cache makes sure that the unlocked item is now the new default equipped item while browsing the shop
			for( int i = cachedPlayerCustomizations.Count - 1; i >= 0; i-- )
			{
				if( cachedPlayerCustomizations[i].Category == customizationItem.Category )
					cachedPlayerCustomizations.RemoveAt( i );
			}

			cachedPlayerCustomizations.Add( customizationItem );

			for( int i = activePlayerCustomizations.Count - 1; i >= 0; i-- )
			{
				if( activePlayerCustomizations[i].Category == customizationItem.Category )
					activePlayerCustomizations.RemoveAt( i );
			}

			activePlayerCustomizations.Add( customizationItem );

			if( saveChanges )
			{
				saveData.equippedItems.Clear();
				for( int i = 0; i < activePlayerCustomizations.Count; i++ )
					saveData.equippedItems.Add( activePlayerCustomizations[i].ID );

				SaveSettings();
			}
		}

		public bool IsCustomizationUnlocked( CustomizationItem customizationItem )
		{
			return customizationItem.Price <= 0L || IsCustomizationUnlocked( customizationItem.ID );
		}

		private bool IsCustomizationUnlocked( string customizationItemID )
		{
#if UNLOCK_ALL_ITEMS
			return true;
#else
			return unlockedItemsSet.Contains( customizationItemID );
#endif
		}

		private bool AreAllCustomizationsUnlocked( int tabIndex )
		{
			CustomizationItem[] items = configuration.Tabs[tabIndex].Items;
			for( int i = 0; i < items.Length; i++ )
			{
				if( !IsCustomizationUnlocked( items[i] ) )
					return false;
			}

			return true;
		}

		private long CalculateRandomUnlockPrice()
		{
			double priceMultiplier = configuration.Tabs[selectedTab].RandomUnlockPriceMultiplier;
			double price = configuration.Tabs[selectedTab].RandomUnlockPrice;

			CustomizationItem[] items = configuration.Tabs[selectedTab].Items;
			for( int i = 0; i < items.Length; i++ )
			{
				if( items[i].Price > 0L && IsCustomizationUnlocked( items[i] ) )
					price *= priceMultiplier;
			}

			return (long) price;
		}

		private void RefreshBuyButtons()
		{
			if( IsSelectedTabUsingRandomUnlock )
			{
				bool hasLockedItems = !AreAllCustomizationsUnlocked( selectedTab );

				buyButton.gameObject.SetActive( hasLockedItems );
				watchVideoAdButton.gameObject.SetActive( hasLockedItems && rewardedAdsEnabled && useNormalVideoAdButton );

				if( hasLockedItems )
					SetBuyButtonPrice( CalculateRandomUnlockPrice() );
			}
		}

		private void SetBuyButtonPrice( long price )
		{
			buyButtonPriceText.SetText( price );
			buyButton.interactable = saveData.coins >= price;
			buyButtonCanvasGroup.alpha = buyButton.interactable ? 1f : 0.75f;
		}

		private IEnumerator CheckForRewardedAdAvailabilityCoroutine()
		{
			while( true )
			{
				bool videoAdAvailable = FTemplate.Ads.IsRewardedAdAvailable();
				if( watchVideoAdButton.interactable != videoAdAvailable )
				{
					watchVideoAdButton.interactable = videoAdAvailable;
					watchVideoAdForCoinsButton.interactable = videoAdAvailable;
				}

				yield return BetterWaitForSeconds.Wait( 0.5f );
			}
		}

		private IEnumerator RankUpCoroutine( int progressCurrent, int progressTotal )
		{
			shopCanvasGroup.blocksRaycasts = false;
			shopCanvasGroup.interactable = false;

			rankText.gameObject.SetActive( true );
			rankUpAnim.gameObject.SetActive( false );

			float unlockProgress = progressCurrent;
			int unlockProgressNext = Mathf.Min( progressCurrent + 1, progressTotal );

			nextRankProgress.fillAmount = unlockProgress / progressTotal;

			float incrementAmount = 1f / 0.653f;
			while( unlockProgress < unlockProgressNext )
			{
				nextRankProgress.fillAmount = unlockProgress / progressTotal;

				yield return null;
				unlockProgress += incrementAmount * Time.deltaTime;
			}

			nextRankProgress.fillAmount = (float) unlockProgressNext / progressTotal;

			if( unlockProgressNext >= progressTotal )
			{
				nextRankProgress.fillAmount = 1f;

				rankText.gameObject.SetActive( false );
				rankUpAnim.gameObject.SetActive( true );
				rankUpAnim.Play( "ShopRankUpText", 0, 0f );

				UpdateRank( false );

				FTemplate.UI.PlayCelebrationParticles();

				yield return BetterWaitForSeconds.WaitRealtime( 1f );

				rankText.gameObject.SetActive( true );
				rankUpAnim.gameObject.SetActive( false );

				if( purchasedItemCount < totalPurchasableItemCount )
					nextRankProgress.fillAmount = 0f;
			}

			shopCanvasGroup.blocksRaycasts = true;
			shopCanvasGroup.interactable = true;
		}

		private void UpdateRank( bool updateRankProgressbar )
		{
			GetRankProgress( out int rankIndex, out int rankProgress );

			ShopConfiguration.RankData rank = configuration.Ranks[Mathf.Clamp( rankIndex, 0, configuration.Ranks.Length - 1 )];
			rankIcon.sprite = rank.Icon;
			rankText.text = rank.Name;

			if( purchasedItemCount >= totalPurchasableItemCount )
				nextRankProgress.color = configuration.MaxRankColor;

			if( updateRankProgressbar )
				nextRankProgress.fillAmount = ( purchasedItemCount >= totalPurchasableItemCount ) ? 1f : ( rankProgress / (float) rank.ProgressToNext );
		}

		private void GetRankProgress( out int rankIndex, out int rankProgress )
		{
			for( rankIndex = 0, rankProgress = purchasedItemCount; rankIndex < configuration.Ranks.Length; rankIndex++ )
			{
				if( configuration.Ranks[rankIndex].ProgressToNext > rankProgress )
					break;

				rankProgress -= configuration.Ranks[rankIndex].ProgressToNext;
			}
		}

		public void SaveSettings()
		{
			SaveSettingsInternal( saveData );
		}

		private void LoadSettings()
		{
			saveData = LoadSettingsInternal();
			unlockedItemsSet.UnionWith( saveData.unlockedItems );
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