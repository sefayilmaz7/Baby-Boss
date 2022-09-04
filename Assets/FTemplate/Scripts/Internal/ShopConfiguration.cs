using UnityEngine;
using UnityEngine.SceneManagement;

namespace FTemplateNamespace
{
	[CreateAssetMenu( fileName = "ShopConfiguration", menuName = "Flamingo/Shop Configuration", order = 111 )]
	public class ShopConfiguration : ScriptableObject
	{
#pragma warning disable 0649
		[System.Serializable]
		public class TabHolder
		{
			public string Category;
			public long RandomUnlockPrice;
			public double RandomUnlockPriceMultiplier = 1.0;
			public Sprite Icon;
			public CustomizationItem DefaultItem;
			public CustomizationItem[] Items;
		}

		[System.Serializable]
		public class RankData
		{
			public string Name;
			public Sprite Icon;
			public int ProgressToNext;
		}

		[SerializeField]
		private TabHolder[] m_tabs;
		public TabHolder[] Tabs { get { return m_tabs; } }

		[SerializeField]
		private float m_shopItemWidth = 150f;
		public float ShopItemWidth { get { return m_shopItemWidth; } }

		[SerializeField]
		private RankData[] m_ranks;
		public RankData[] Ranks { get { return m_ranks; } }

		[SerializeField]
		private Color m_maxRankColor = Color.yellow;
		public Color MaxRankColor { get { return m_maxRankColor; } }

		[SerializeField]
		private int[] freeUnlockIntervals = new int[] { 4, 8, 12 };

		[SerializeField]
		private bool m_autoSaveFreeUnlockProgress = true;
		public bool AutoSaveFreeUnlockProgress { get { return m_autoSaveFreeUnlockProgress; } }

		[SerializeField]
		private string m_shopScene;
		private bool shopSceneValidated = false;
		public string ShopScene
		{
			get
			{
				if( !shopSceneValidated )
				{
					if( !string.IsNullOrEmpty( m_shopScene ) )
					{
						bool shopSceneExistsInBuildSettings = false;
						for( int i = 0; i < SceneManager.sceneCountInBuildSettings; i++ )
						{
							if( System.IO.Path.GetFileNameWithoutExtension( SceneUtility.GetScenePathByBuildIndex( i ) ) == m_shopScene )
							{
								shopSceneExistsInBuildSettings = true;
								break;
							}
						}

						if( !shopSceneExistsInBuildSettings )
						{
							Debug.LogError( "FTemplate.UI has the following 'Shop Scene' but it is not added to the Build Settings: " + m_shopScene );
							m_shopScene = string.Empty;
						}
					}

					shopSceneValidated = true;
				}

				return m_shopScene;
			}
		}

		[SerializeField]
		private string m_videoAdForCoinsAmountRemoteKey = "shop_reward";
		public string VideoAdForCoinsRemoteKey { get { return m_videoAdForCoinsAmountRemoteKey; } }

		[SerializeField]
		private int m_videoAdForCoinsDefaultAmount = 500;
		public int VideoAdForCoinsDefaultAmount { get { return m_videoAdForCoinsDefaultAmount; } }
#pragma warning restore 0649

		public void UpdatePrices( long[] prices )
		{
			for( int i = 0; i < m_tabs.Length; i++ )
			{
				CustomizationItem[] items = m_tabs[i].Items;
				for( int j = 0; j < items.Length && j < prices.Length; j++ )
					items[j].UpdatePrice( prices[j] );
			}
		}

		internal void GetFreeUnlockProgress( int totalFreeUnlockProgress, out int unlockProgressCurrent, out int unlockProgressTotal )
		{
			unlockProgressCurrent = totalFreeUnlockProgress;

			int freeUnlockIntervalIndex = 0;
			while( unlockProgressCurrent >= freeUnlockIntervals[freeUnlockIntervalIndex] )
			{
				unlockProgressCurrent -= freeUnlockIntervals[freeUnlockIntervalIndex];
				if( freeUnlockIntervalIndex < freeUnlockIntervals.Length - 1 )
					freeUnlockIntervalIndex++;
			}

			unlockProgressTotal = freeUnlockIntervals[freeUnlockIntervalIndex];
		}

#if UNITY_EDITOR
		[ContextMenu( "Shuffle Tab Contents" )]
		private void Shuffle()
		{
			UnityEditor.Undo.RecordObject( this, "Shuffle" );

			for( int i = 0; i < m_tabs.Length; i++ )
				m_tabs[i].Items.Shuffle();
		}
#endif
	}
}