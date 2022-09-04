using UnityEditor;
using UnityEngine;

namespace FTemplateNamespace
{
	public class CustomBuildWindow : EditorWindow
	{
		private bool buildOpenSceneOnly;
		private bool allLevelsUnlocked, allItemsUnlocked;

		[MenuItem( "Flamingo/Build Game", priority = 0 )]
		private static void Init()
		{
			CustomBuildWindow window = GetWindow<CustomBuildWindow>();
			window.titleContent = new GUIContent( "Build Game" );
			window.minSize = new Vector2( 300f, 200f );
			window.Show();
		}

		private void OnGUI()
		{
			buildOpenSceneOnly = EditorGUILayout.ToggleLeft( "Build Currently Open Scene Only", buildOpenSceneOnly );

			EditorGUILayout.Space();

			allLevelsUnlocked = EditorGUILayout.ToggleLeft( "All Levels Unlocked", allLevelsUnlocked );
			allItemsUnlocked = EditorGUILayout.ToggleLeft( "All Items Unlocked", allItemsUnlocked );

			EditorGUILayout.Space();

			if( GUILayout.Button( "Build" ) )
				MenuItems.BuildPlayer( false, buildOpenSceneOnly, allLevelsUnlocked, allItemsUnlocked );
			if( GUILayout.Button( "Build & Run" ) )
				MenuItems.BuildPlayer( true, buildOpenSceneOnly, allLevelsUnlocked, allItemsUnlocked );
		}
	}
}