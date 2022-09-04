#if UNITY_EDITOR
using UnityEditor;
#endif
using UnityEngine;

public abstract class LevelData : ScriptableObject
{
#pragma warning disable 0649
	[SerializeField]
	private string m_ID;

	[SerializeField]
	private Sprite m_Icon;
#pragma warning restore 0649

	public string ID { get { return m_ID; } }
	public Sprite Icon { get { return m_Icon; } }

#if UNITY_EDITOR
	private void Awake()
	{
		if( string.IsNullOrEmpty( m_ID ) )
			m_ID = System.Guid.NewGuid().ToString();
		else
		{
			string[] customizationItems = AssetDatabase.FindAssets( "t:LevelData" );
			for( int i = 0; i < customizationItems.Length; i++ )
			{
				LevelData level = AssetDatabase.LoadAssetAtPath<LevelData>( AssetDatabase.GUIDToAssetPath( customizationItems[i] ) );
				if( level != this && level.m_ID == m_ID )
				{
					m_ID = System.Guid.NewGuid().ToString();
					return;
				}
			}
		}
	}
#endif

#if UNITY_EDITOR
	[ContextMenu( "Generate Unique ID" )]
	private void GenerateUniqueID()
	{
		Undo.RecordObject( this, "Change ID" );
		m_ID = System.Guid.NewGuid().ToString();
	}

	[ContextMenu( "Generate ID From Name" )]
	private void GenerateIDFromName()
	{
		Undo.RecordObject( this, "Change ID" );
		m_ID = name.ToLowerInvariant();
	}
#endif
}