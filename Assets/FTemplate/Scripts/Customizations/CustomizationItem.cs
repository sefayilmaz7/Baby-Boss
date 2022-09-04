#if UNITY_EDITOR
using UnityEditor;
#endif
using UnityEngine;

public abstract class CustomizationItem : ScriptableObject
{
#pragma warning disable 0649
	[SerializeField]
	private string m_ID;

	[SerializeField]
	private long m_Price;

	[SerializeField]
	private Sprite m_Icon;

	[System.NonSerialized]
	internal string m_Category;
#pragma warning restore 0649

	public string ID { get { return m_ID; } }
	public long Price { get { return m_Price; } }
	public Sprite Icon { get { return m_Icon; } }
	public string Category { get { return m_Category; } }

#if UNITY_EDITOR
	private void Awake()
	{
		if( string.IsNullOrEmpty( m_ID ) )
			m_ID = System.Guid.NewGuid().ToString();
		else
		{
			string[] customizationItems = AssetDatabase.FindAssets( "t:CustomizationItem" );
			for( int i = 0; i < customizationItems.Length; i++ )
			{
				CustomizationItem item = AssetDatabase.LoadAssetAtPath<CustomizationItem>( AssetDatabase.GUIDToAssetPath( customizationItems[i] ) );
				if( item != this && item.m_ID == m_ID )
				{
					m_ID = System.Guid.NewGuid().ToString();
					return;
				}
			}
		}
	}
#endif

	public void UpdatePrice( long price )
	{
		m_Price = price;
	}

#if UNITY_EDITOR
	[ContextMenu( "Generate New ID" )]
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