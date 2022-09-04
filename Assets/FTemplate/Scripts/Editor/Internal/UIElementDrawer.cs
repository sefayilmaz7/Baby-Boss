using UnityEditor;
using UnityEngine;

namespace FTemplateNamespace
{
	[CustomPropertyDrawer( typeof( UIElement ) )]
	public class TestClassDrawer : PropertyDrawer
	{
		public override void OnGUI( Rect position, SerializedProperty property, GUIContent content )
		{
			EditorGUI.BeginProperty( position, content, property );
			position = EditorGUI.PrefixLabel( position, content );
			EditorGUI.indentLevel = 0;

			bool showAnimations = true;
			SerializedProperty navigationHandlerProp = property.FindPropertyRelative( "m_navigationHandler" );
			if( !navigationHandlerProp.hasMultipleDifferentValues )
			{
				Object navigationHandler = navigationHandlerProp.objectReferenceValue;
				if( !( navigationHandler is Animation ) && !( navigationHandler is Animator ) )
					showAnimations = false;
			}

			float elementWidth = position.width * 0.5f;
			float elementHeight = position.height;
			if( showAnimations )
				elementHeight *= 0.5f;

			Rect posLeft = new Rect( position.x, position.y, elementWidth, elementHeight );
			Rect posRight = new Rect( position.x + elementWidth, position.y, elementWidth, elementHeight );
			EditorGUI.PropertyField( posLeft, property.FindPropertyRelative( "m_type" ), GUIContent.none );
			EditorGUI.PropertyField( posRight, navigationHandlerProp, GUIContent.none );

			if( showAnimations )
			{
				posLeft.y += elementHeight;
				posRight.y += elementHeight;
				EditorGUI.PropertyField( posLeft, property.FindPropertyRelative( "showAnimation" ), GUIContent.none );
				EditorGUI.PropertyField( posRight, property.FindPropertyRelative( "hideAnimation" ), GUIContent.none );
			}

			EditorGUI.EndProperty();
		}

		public override float GetPropertyHeight( SerializedProperty property, GUIContent label )
		{
			SerializedProperty navigationHandlerProp = property.FindPropertyRelative( "m_navigationHandler" );
			if( !navigationHandlerProp.hasMultipleDifferentValues )
			{
				Object navigationHandler = property.FindPropertyRelative( "m_navigationHandler" ).objectReferenceValue;
				if( !( navigationHandler is Animation ) && !( navigationHandler is Animator ) )
					return EditorGUIUtility.singleLineHeight;
			}

			return EditorGUIUtility.singleLineHeight * 2f;
		}
	}
}