using System.Collections.Generic;
using UnityEngine;

public abstract class FBehaviour : MonoBehaviour
{
	protected static List<FBehaviour> behaviours = new List<FBehaviour>( 8 );

	protected virtual void OnLevelInitialized() { }
	protected virtual void OnLevelStarted() { }
	protected virtual void OnLevelFinished( bool success ) { }
	protected virtual void OnLevelClosed() { }

	protected virtual void Awake()
	{
		behaviours.Add( this );
	}

	protected virtual void OnDestroy()
	{
		behaviours.Remove( this );
	}

	public static void TriggerLevelInitialized()
	{
		for( int i = 0; i < behaviours.Count; i++ )
			behaviours[i].OnLevelInitialized();
	}

	public static void TriggerLevelStarted()
	{
		for( int i = 0; i < behaviours.Count; i++ )
			behaviours[i].OnLevelStarted();
	}

	public static void TriggerLevelFinished( bool success )
	{
		for( int i = 0; i < behaviours.Count; i++ )
			behaviours[i].OnLevelFinished( success );
	}

	public static void TriggerLevelClosed()
	{
		for( int i = 0; i < behaviours.Count; i++ )
			behaviours[i].OnLevelClosed();
	}
}

public abstract class SingletonBehaviour<T> : FBehaviour where T : SingletonBehaviour<T>
{
	public static T Instance { get; private set; }

	protected override void Awake()
	{
#if UNITY_EDITOR
		if( !UnityEditor.EditorApplication.isPlaying )
			return;
#endif

		if( Instance == null )
		{
			Instance = (T) this;
			base.Awake();
		}
		else if( this != Instance )
			Destroy( this );
	}
}