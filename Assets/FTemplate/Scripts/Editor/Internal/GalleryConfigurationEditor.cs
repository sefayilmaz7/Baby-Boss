using UnityEditor;
using UnityEditorInternal;
using UnityEngine;

namespace FTemplateNamespace
{
	[CustomEditor( typeof( GalleryConfiguration ) )]
	public class GalleryConfigurationEditor : Editor
	{
		private ReorderableList levelsList;

		private void OnEnable()
		{
			levelsList = new ReorderableList( serializedObject, serializedObject.FindProperty( "m_levels" ), true, true, true, true );
			levelsList.drawHeaderCallback = ( rect ) =>
			{
				rect.xMin += 10f;

				EditorGUI.BeginChangeCheck();
				levelsList.serializedProperty.isExpanded = EditorGUI.Foldout( rect, levelsList.serializedProperty.isExpanded, "Levels: " + levelsList.count, true );
				if( EditorGUI.EndChangeCheck() )
				{
					levelsList.draggable = levelsList.serializedProperty.isExpanded;

					if( Event.current.alt )
					{
						for( int i = levelsList.serializedProperty.arraySize - 1; i >= 0; i-- )
							levelsList.serializedProperty.GetArrayElementAtIndex( i ).isExpanded = levelsList.serializedProperty.isExpanded;
					}
				}
			};
			levelsList.drawElementCallback = ( rect, index, isActive, isFocused ) =>
			{
				if( !levelsList.serializedProperty.isExpanded )
					return;

				rect.xMin += 10f;

				SerializedProperty levelProp = levelsList.serializedProperty.GetArrayElementAtIndex( index );
				EditorGUI.PropertyField( rect, levelProp, new GUIContent( string.Concat( index, ": ", levelProp.displayName ) ), true );
			};
			levelsList.elementHeightCallback = ( index ) => levelsList.serializedProperty.isExpanded ? EditorGUI.GetPropertyHeight( levelsList.serializedProperty.GetArrayElementAtIndex( index ), true ) : 0f;
			levelsList.draggable = levelsList.serializedProperty.isExpanded;
		}

		public override void OnInspectorGUI()
		{
			serializedObject.Update();

			DrawPropertiesExcluding( serializedObject, "m_levels" );
			levelsList.DoLayoutList();

			serializedObject.ApplyModifiedProperties();
		}
	}
}