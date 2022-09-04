#define SKIP_SPRITE_ATLAS_PACKABLES_OUTSIDE_FTEMPLATE

using System.Collections.Generic;
using System.Text;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEditor.U2D;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.U2D;

namespace FTemplateNamespace
{
	public class MenuItems
	{
		private const string FTEMPLATE_DIRECTORY = "Assets/FTemplate";
		private const string UI_ATLAS_PATH = FTEMPLATE_DIRECTORY + "/Textures/UIAtlas.spriteatlas";
		private const string FTEMPLATE_PREFAB_PATH = FTEMPLATE_DIRECTORY + "/Resources/FTemplate.prefab";

		private const string DUMMY_BANNER_AD_PATH = FTEMPLATE_DIRECTORY + "/Prefabs/DummyBannerAd.prefab";
		private const string DUMMY_BANNER_AD_PREF = "ShowDummyBanner";

		private static GameObject dummyBannerAd;

		[InitializeOnLoadMethod]
		private static void Initialize()
		{
			if( PlayerPrefs.GetInt( DUMMY_BANNER_AD_PREF ) == 1 )
				ShowDummyBannerAd();

			AssemblyReloadEvents.beforeAssemblyReload -= DestroyDummyBannerAd;
			AssemblyReloadEvents.beforeAssemblyReload += DestroyDummyBannerAd;
		}

		public static void BuildPlayer( bool run, bool buildOpenSceneOnly, bool unlockAllLevels, bool unlockAllItems )
		{
			PlayerSettings.SetStackTraceLogType( LogType.Log, StackTraceLogType.None );
			PlayerSettings.SetStackTraceLogType( LogType.Warning, StackTraceLogType.None );

			string scriptingSymbols = null;
			if( unlockAllLevels || unlockAllItems )
			{
				scriptingSymbols = PlayerSettings.GetScriptingDefineSymbolsForGroup( EditorUserBuildSettings.selectedBuildTargetGroup );
				PlayerSettings.SetScriptingDefineSymbolsForGroup( EditorUserBuildSettings.selectedBuildTargetGroup, scriptingSymbols + ( unlockAllLevels ? ";UNLOCK_ALL_LEVELS" : "" ) + ( unlockAllItems ? ";UNLOCK_ALL_ITEMS" : "" ) );
			}

			// Credit: https://forum.unity.com/threads/functionality-to-turn-off-symbols-zip-generation.685738/page-2#post-5205539
#if UNITY_2018_4_13_OR_NEWER || UNITY_2019_2_11_OR_NEWER || UNITY_2019_3_OR_NEWER
			EditorUserBuildSettings.androidCreateSymbolsZip = false;
#endif

			try
			{
				BuildPlayerOptions options = BuildPlayerWindow.DefaultBuildMethods.GetBuildPlayerOptions( new BuildPlayerOptions() );
				if( run )
					options.options |= BuildOptions.AutoRunPlayer;

				if( buildOpenSceneOnly )
					options.scenes = new string[1] { SceneManager.GetActiveScene().path };

				Debug.Log( "Build Result: " + BuildPipeline.BuildPlayer( options ).summary.result );
			}
			finally
			{
				PlayerSettings.SetStackTraceLogType( LogType.Log, StackTraceLogType.ScriptOnly );
				PlayerSettings.SetStackTraceLogType( LogType.Warning, StackTraceLogType.ScriptOnly );

				if( unlockAllLevels || unlockAllItems )
					PlayerSettings.SetScriptingDefineSymbolsForGroup( EditorUserBuildSettings.selectedBuildTargetGroup, scriptingSymbols );

				AssetDatabase.SaveAssets();
			}
		}

		[MenuItem( "Flamingo/Generate FTemplate Atlas", priority = 9 )]
		private static void GenerateFTemplateAtlas()
		{
			SpriteAtlas atlas = AssetDatabase.LoadAssetAtPath<SpriteAtlas>( UI_ATLAS_PATH );
			if( !atlas )
			{
				Debug.LogError( "Atlas not found at: " + UI_ATLAS_PATH );
				return;
			}

#if SKIP_SPRITE_ATLAS_PACKABLES_OUTSIDE_FTEMPLATE
			List<string> skippedPackables = new List<string>( 16 );
#endif

			List<Object> newPackables = new List<Object>( 64 );
			string[] dependencies = AssetDatabase.GetDependencies( FTEMPLATE_PREFAB_PATH );
			for( int i = 0; i < dependencies.Length; i++ )
			{
				if( !dependencies[i].StartsWith( "Assets/" ) )
					continue;
				if( dependencies[i].Contains( "/Unpacked/" ) )
					continue;

				if( AssetDatabase.LoadAssetAtPath<Sprite>( dependencies[i] ) )
				{
#if SKIP_SPRITE_ATLAS_PACKABLES_OUTSIDE_FTEMPLATE
					if( dependencies[i].StartsWith( FTEMPLATE_DIRECTORY ) )
#endif
						newPackables.Add( AssetDatabase.LoadMainAssetAtPath( dependencies[i] ) );
#if SKIP_SPRITE_ATLAS_PACKABLES_OUTSIDE_FTEMPLATE
					else
						skippedPackables.Add( dependencies[i] );
#endif
				}
			}

			newPackables.Sort( ( s1, s2 ) => s1.name.CompareTo( s2.name ) );

			Undo.RecordObject( atlas, "Change Packables" );
			atlas.Remove( atlas.GetPackables() );
			atlas.Add( newPackables.ToArray() );

			Debug.Log( "Added " + newPackables.Count + " sprites to " + UI_ATLAS_PATH, atlas );

#if SKIP_SPRITE_ATLAS_PACKABLES_OUTSIDE_FTEMPLATE
			if( skippedPackables.Count > 0 )
			{
				StringBuilder sb = new StringBuilder( 500 );
				sb.Append( "Skipped " ).Append( skippedPackables.Count ).Append( " sprites since they are not located inside " ).Append( FTEMPLATE_DIRECTORY ).Append( ":" );
				sb.AppendLine().AppendLine();
				for( int i = 0; i < skippedPackables.Count; i++ )
					sb.AppendLine( skippedPackables[i] );

				Debug.Log( sb.ToString() );
			}
#endif
		}

		[MenuItem( "Flamingo/Show Dummy Banner Ad", priority = 20 )]
		private static void ShowDummyBannerAd()
		{
			if( dummyBannerAd )
				return;

			dummyBannerAd = Object.Instantiate( AssetDatabase.LoadAssetAtPath<GameObject>( DUMMY_BANNER_AD_PATH ) );

			// If we don't set each child Object's hideFlags, Unity complains about not being able to Destroy RectTransform while switching scenes
			foreach( Transform transform in dummyBannerAd.GetComponentsInChildren<Transform>() )
				transform.gameObject.hideFlags = HideFlags.HideAndDontSave;

			PlayerPrefs.SetInt( DUMMY_BANNER_AD_PREF, 1 );
			PlayerPrefs.Save();

			// If we don't select the Main Camera after showing the dummy banner ad, the banner ad isn't displayed on screen immediately for some reason
			Object selection = Selection.activeObject;
			Selection.activeObject = Camera.main;

			int selectionRestoreDelay = 2;
			EditorApplication.CallbackFunction selectionRestore = null;
			selectionRestore = () =>
			{
				// When selectionRestoreDelay is 1, SceneView will show Main Camera and this will prompt the banner ad to show up immediately
				// When selectionRestoreDelay is 0, we will restore the selection
				if( --selectionRestoreDelay == 0 )
				{
					EditorApplication.update -= selectionRestore;

					Selection.activeObject = selection;
					UnityEditorInternal.InternalEditorUtility.RepaintAllViews();
				}
			};
			EditorApplication.update += selectionRestore;
		}

		[MenuItem( "Flamingo/Hide Dummy Banner Ad", priority = 20 )]
		private static void HideDummyBannerAd()
		{
			DestroyDummyBannerAd();

			PlayerPrefs.SetInt( DUMMY_BANNER_AD_PREF, 0 );
			PlayerPrefs.Save();
		}

		private static void DestroyDummyBannerAd()
		{
			if( dummyBannerAd )
			{
				Object.DestroyImmediate( dummyBannerAd );
				dummyBannerAd = null;

				// Necessary to refresh Game view
				UnityEditorInternal.InternalEditorUtility.RepaintAllViews();
			}
		}

		[MenuItem( "Flamingo/Show Dummy Banner Ad", validate = true )]
		private static bool ShowDummyBannerAdValidate()
		{
			return !dummyBannerAd;
		}

		[MenuItem( "Flamingo/Hide Dummy Banner Ad", validate = true )]
		private static bool HideDummyBannerAdValidate()
		{
			return dummyBannerAd;
		}

		[MenuItem( "CONTEXT/Renderer/Clone Material", priority = 8 )]
		private static void CloneMaterial( MenuCommand command )
		{
			Renderer renderer = (Renderer) command.context;
			if( AssetDatabase.Contains( renderer ) )
				Debug.LogError( "Can't clone an asset's material!" );
			else
			{
				Material[] materials = renderer.sharedMaterials;
				for( int i = 0; i < materials.Length; i++ )
					materials[i] = new Material( materials[i] );

				Undo.RecordObject( renderer, "Clone Material" );
				renderer.sharedMaterials = materials;
			}
		}

		[MenuItem( "Flamingo/Reset All PlayerPrefs", priority = 500 )]
		private static void ResetPlayerPrefs()
		{
			int showDummyBanner = PlayerPrefs.GetInt( DUMMY_BANNER_AD_PREF );

			PlayerPrefs.DeleteAll();
			PlayerPrefs.SetInt( DUMMY_BANNER_AD_PREF, showDummyBanner );
			PlayerPrefs.Save();
		}
	}
}