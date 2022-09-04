using System.IO;
using UnityEditor;
using UnityEngine;

namespace FTemplateNamespace
{
	public class ModuleSaveDataEditor : EditorWindow
	{
#pragma warning disable 0649
		[SerializeField]
		private GalleryModule.SaveData gallerySaveData;
		[SerializeField]
		private ShopModule.SaveData shopSaveData;
#pragma warning restore 0649

		private SerializedObject windowSerialized;
		private Vector2 scrollPos;

		[MenuItem( "Flamingo/Edit Save Data", priority = 3 )]
		private static void Init()
		{
			ModuleSaveDataEditor window = GetWindow<ModuleSaveDataEditor>();
			window.titleContent = new GUIContent( "Save Data" );
			window.minSize = new Vector2( 333f, 250f );
			window.Show();

			window.gallerySaveData = GalleryModule.LoadSettingsInternal();
			window.shopSaveData = ShopModule.LoadSettingsInternal();
		}

		private void OnEnable()
		{
			windowSerialized = new SerializedObject( this );
		}

		private void OnGUI()
		{
			scrollPos = EditorGUILayout.BeginScrollView( scrollPos );

			// Draw Gallery save data
			windowSerialized.Update();
			EditorGUILayout.PropertyField( windowSerialized.FindProperty( "gallerySaveData" ), true );
			windowSerialized.ApplyModifiedPropertiesWithoutUndo();

			GUILayout.BeginHorizontal();
			if( GUILayout.Button( "Reset Data" ) )
			{
				File.Delete( GalleryModule.SavePath );
				gallerySaveData = GalleryModule.LoadSettingsInternal();
			}
			if( GUILayout.Button( "Discard Changes" ) )
				gallerySaveData = GalleryModule.LoadSettingsInternal();
			if( GUILayout.Button( "Save Changes" ) )
				GalleryModule.SaveSettingsInternal( gallerySaveData );
			GUILayout.EndHorizontal();

			// Draw separator line
			EditorGUILayout.Space();
			GUILayout.Box( GUIContent.none, GUILayout.Height( 1.5f ), GUILayout.ExpandWidth( true ) );
			EditorGUILayout.Space();

			// Draw Shop save data
			windowSerialized.Update();
			EditorGUILayout.PropertyField( windowSerialized.FindProperty( "shopSaveData" ), true );
			windowSerialized.ApplyModifiedPropertiesWithoutUndo();

			GUILayout.BeginHorizontal();
			if( GUILayout.Button( "Reset Data" ) )
			{
				File.Delete( ShopModule.SavePath );
				shopSaveData = ShopModule.LoadSettingsInternal();
			}
			if( GUILayout.Button( "Discard Changes" ) )
				shopSaveData = ShopModule.LoadSettingsInternal();
			if( GUILayout.Button( "Save Changes" ) )
				ShopModule.SaveSettingsInternal( shopSaveData );
			GUILayout.EndHorizontal();

			EditorGUILayout.EndScrollView();
		}
	}
}