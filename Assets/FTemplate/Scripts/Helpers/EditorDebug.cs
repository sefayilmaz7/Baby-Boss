using UnityEngine;
using Conditional = System.Diagnostics.ConditionalAttribute;

public static class EditorDebug
{
	[Conditional( "UNITY_EDITOR" )] public static void Log( object message ) { Debug.Log( message ); }
	[Conditional( "UNITY_EDITOR" )] public static void Log( object message, Object context ) { Debug.Log( message, context ); }
	[Conditional( "UNITY_EDITOR" )] public static void Warning( object message ) { Debug.LogWarning( message ); }
	[Conditional( "UNITY_EDITOR" )] public static void Warning( object message, Object context ) { Debug.LogWarning( message, context ); }
	[Conditional( "UNITY_EDITOR" )] public static void Error( object message ) { Debug.LogError( message ); }
	[Conditional( "UNITY_EDITOR" )] public static void Error( object message, Object context ) { Debug.LogError( message, context ); }
	[Conditional( "UNITY_EDITOR" )] public static void Exception( System.Exception exception ) { Debug.LogException( exception ); }
	[Conditional( "UNITY_EDITOR" )] public static void Exception( System.Exception exception, Object context ) { Debug.LogException( exception, context ); }
}