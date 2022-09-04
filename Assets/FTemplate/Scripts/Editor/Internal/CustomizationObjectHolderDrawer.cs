using UnityEditor;
using UnityEngine;

namespace FTemplateNamespace
{
	[CustomPropertyDrawer( typeof( CustomizationObjectHolder ) )]
	public class CustomizationObjectHolderDrawer : PropertyDrawer
	{
		public override void OnGUI( Rect position, SerializedProperty property, GUIContent content )
		{
			EditorGUI.BeginProperty( position, content, property );
			position = EditorGUI.PrefixLabel( position, content );
			EditorGUI.indentLevel = 0;

			SerializedProperty sourceProp = property.FindPropertyRelative( "source" );

			// Don't show value field until Source property has the same value for all inspected properties
			if( sourceProp.hasMultipleDifferentValues )
				EditorGUI.PropertyField( position, sourceProp, GUIContent.none );
			else
			{
				CustomizationObjectHolder.Source source = (CustomizationObjectHolder.Source) sourceProp.enumValueIndex;
				SerializedProperty unityObjectProp = property.FindPropertyRelative( "unityObject" );

				float elementWidth = position.width * 0.5f;
				Rect posLeft = new Rect( position.x, position.y, elementWidth, position.height );
				Rect posRight = new Rect( position.x + elementWidth, position.y, elementWidth, position.height );

				EditorGUI.PropertyField( posLeft, sourceProp, GUIContent.none );

				switch( source )
				{
					case CustomizationObjectHolder.Source.UnityObject: EditorGUI.PropertyField( posRight, unityObjectProp, GUIContent.none ); break;
					case CustomizationObjectHolder.Source.Resources:
						SerializedProperty resourcesPathProp = property.FindPropertyRelative( "resourcesPath" );
						EditorGUI.PropertyField( posRight, resourcesPathProp, GUIContent.none );

						// When Resources Path is set, make sure that Unity Object's value is null so that we don't load that Unity Object to memory by mistake
						if( resourcesPathProp.hasMultipleDifferentValues || !string.IsNullOrEmpty( resourcesPathProp.stringValue ) )
							unityObjectProp.objectReferenceValue = null;

						break;
				}
			}

			EditorGUI.EndProperty();
		}
	}
}