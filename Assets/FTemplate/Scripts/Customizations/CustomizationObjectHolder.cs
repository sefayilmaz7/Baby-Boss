using UnityEngine;

[System.Serializable]
public class CustomizationObjectHolder
{
#pragma warning disable 0649
#if UNITY_EDITOR
	public enum Source { UnityObject = 0, Resources = 1 };

	[SerializeField]
	private Source source;
#endif

	[SerializeField]
	private Object unityObject;
	[SerializeField]
	private string resourcesPath;
#pragma warning restore 0649

	public T GetObject<T>() where T : Object
	{
		T result = null;
		if( unityObject )
		{
			result = unityObject as T;
			if( !result )
			{
				if( typeof( Component ).IsAssignableFrom( typeof( T ) ) && unityObject is GameObject )
					result = ( (GameObject) unityObject ).GetComponent<T>();
				else if( typeof( GameObject ).IsAssignableFrom( typeof( T ) ) && unityObject is Component )
					result = ( (Component) unityObject ).gameObject as T;
			}
		}
		else if( !string.IsNullOrEmpty( resourcesPath ) )
			result = Resources.Load<T>( resourcesPath );

		return result;
	}
}