using UnityEngine;

namespace FTemplateNamespace
{
	[CreateAssetMenu( fileName = "GalleryConfiguration", menuName = "Flamingo/Gallery Configuration", order = 111 )]
	public class GalleryConfiguration : ScriptableObject
	{
#pragma warning disable 0649
		[System.Serializable]
		public class LevelHolder
		{
			public string ID;
			public Sprite Icon;

			[System.NonSerialized]
			public int Index;

			public LevelHolder( string id, Sprite icon, int index )
			{
				ID = id;
				Icon = icon;
				Index = index;
			}
		}

		[SerializeField]
		private LevelHolder[] m_levels;
		public LevelHolder[] Levels { get { return m_levels; } }

		public int CheckpointsPerLevel;
		public bool HasBonusLevels;
#pragma warning restore 0649

		public static GalleryConfiguration CreateFrom( string[] levelIDs, Sprite[] levelIcons )
		{
			GalleryConfiguration result = CreateInstance<GalleryConfiguration>();
			result.m_levels = new LevelHolder[levelIDs.Length];
			for( int i = 0; i < levelIDs.Length; i++ )
				result.m_levels[i] = new LevelHolder( levelIDs[i], levelIcons[i], i );

			return result;
		}
	}
}