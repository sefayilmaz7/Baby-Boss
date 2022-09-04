//#define ELEPHANT_ENABLED
//#define FACEBOOK_ENABLED
//#define FIREBASE_ENABLED
//#define GAMEANALYTICS_ENABLED
//#define GGI_ENABLED
//#define LIONKIT_ENABLED

#if GGI_ENABLED // GGI SDK comes preinstalled with Firebase SDK
#define FIREBASE_ENABLED
#endif

#if ELEPHANT_ENABLED
using ElephantSDK;
#endif
#if FACEBOOK_ENABLED
using Facebook.Unity;
#endif
#if FIREBASE_ENABLED
using Firebase.RemoteConfig;
using Firebase.Extensions;
using System.Threading.Tasks;
#endif
#if GAMEANALYTICS_ENABLED
using GameAnalyticsSDK;
using System.Text;
#endif
#if GGI_ENABLED
using GGI.Analytics.Events;
using GGI.Core;
using System.Reflection;
#endif
#if LIONKIT_ENABLED
using LionStudios;
using LionAnalytics = LionStudios.Analytics;
#endif
using System.Collections.Generic;
using System.Globalization;
using UnityEngine;

namespace FTemplateNamespace
{
	public class AnalyticsModule : MonoBehaviour
	{
		public enum OnlineStatus { Pending = 0, Failure = 1, Success = 2 };

		/// <summary>Returns whether or not remote values are successfully fetched from the server</summary>
		public OnlineStatus RemoteDataStatus { get; private set; }

#if GAMEANALYTICS_ENABLED
		private readonly StringBuilder gameAnalyticsParams = new StringBuilder( 64 );
#endif

#if LIONKIT_ENABLED
		private readonly Dictionary<string, object> lionKitEventParams = new Dictionary<string, object>( 16 );
#endif

		private readonly Dictionary<string, object> remoteData = new Dictionary<string, object>();
		private readonly NumberFormatInfo remoteDataParser = NumberFormatInfo.GetInstance( CultureInfo.InvariantCulture );

		#region Helper Classes
#pragma warning disable 0414
		public struct Parameter
		{
			private enum ValueType { String = 0, Double = 1, Integer = 2 };

			private readonly string name;
			private readonly ValueType valueType;
			private readonly string valueString;
			private readonly double valueDouble;
			private readonly int valueInt;

			public Parameter( string name, string value )
			{
				this.name = name;
				valueType = ValueType.String;
				valueString = value;
				valueDouble = 0.0;
				valueInt = 0;
			}

			public Parameter( string name, double value )
			{
				this.name = name;
				valueType = ValueType.Double;
				valueString = null;
				valueDouble = value;
				valueInt = 0;
			}

			public Parameter( string name, int value )
			{
				this.name = name;
				valueType = ValueType.Integer;
				valueString = null;
				valueDouble = 0.0;
				valueInt = value;
			}

			internal void AddToDictionary( Dictionary<string, object> eventParams )
			{
				switch( valueType )
				{
					case ValueType.String: eventParams[name] = valueString; break;
					case ValueType.Double: eventParams[name] = valueDouble; break;
					case ValueType.Integer: eventParams[name] = valueInt; break;
				}
			}

#if ELEPHANT_ENABLED
			internal void ToElephantParams( Params parameters )
			{
				switch( valueType )
				{
					case ValueType.String: parameters.Set( name, valueString ); break;
					case ValueType.Double: parameters.Set( name, valueDouble ); break;
					case ValueType.Integer: parameters.Set( name, valueInt ); break;
				}
			}
#endif

#if GAMEANALYTICS_ENABLED
			internal void ToGameAnalyticsParams( StringBuilder sb )
			{
				sb.Append( ":" ).Append( name ).Append( "_" );

				switch( valueType )
				{
					case ValueType.String: sb.Append( valueString ); break;
					case ValueType.Double: sb.Append( valueDouble ); break;
					case ValueType.Integer: sb.Append( valueInt ); break;
				}
			}
#endif
		}

		public struct Checkpoint
		{
			internal enum CheckpointState { First = 0, Middle = 1, Last = 2 };

			internal readonly int index;
			internal readonly CheckpointState state;

			private Checkpoint( int index, CheckpointState state )
			{
				this.index = index;
				this.state = state;
			}

			public static Checkpoint First( int index ) { return new Checkpoint( index, CheckpointState.First ); }
			public static Checkpoint Middle( int index ) { return new Checkpoint( index, CheckpointState.Middle ); }
			public static Checkpoint Last( int index ) { return new Checkpoint( index, CheckpointState.Last ); }
		}

		public struct Progression
		{
			internal readonly int level;
			internal readonly string levelName;
			internal readonly Checkpoint checkpoint;
			internal readonly bool hasCheckpoint;
			internal readonly int score;
			internal readonly bool hasScore;

			public Progression( int level )
			{
				this.level = level;
				levelName = null;
				checkpoint = new Checkpoint();
				hasCheckpoint = false;
				score = -1;
				hasScore = false;
			}

#if !ELEPHANT_ENABLED
			public Progression( string level ) : this( 0 )
			{
				levelName = level;
			}
#endif

			public Progression( int level, int score ) : this( level )
			{
				this.score = score;
				hasScore = true;
			}

#if !ELEPHANT_ENABLED
			public Progression( string level, int score ) : this( 0, score )
			{
				levelName = level;
			}
#endif

			/// <summary></summary>
			/// <param name="level">Level index</param>
			/// <param name="checkpoint">Checkpoints can be created via Checkpoint.First, Checkpoint.Middle and Checkpoint.Last functions. If checkpoints are not short, use "new Progression(level)" instead (i.e. treat checkpoints as levels). In this case, Level1_Checkpoint1 becomes Level1, L1_C2 becomes Level2, L2_C1 becomes Level3 and so on</param>
			public Progression( int level, Checkpoint checkpoint )
			{
				this.level = level;
				levelName = null;
				this.checkpoint = checkpoint;
				hasCheckpoint = true;
				score = -1;
				hasScore = false;
			}

#if !ELEPHANT_ENABLED
			/// <summary></summary>
			/// <param name="level">Level name</param>
			/// <param name="checkpoint">Checkpoints can be created via Checkpoint.First, Checkpoint.Middle and Checkpoint.Last functions. If checkpoints are not short, use "new Progression(level)" instead (i.e. treat checkpoints as levels). In this case, Level1_Checkpoint1 becomes Level1, L1_C2 becomes Level2, L2_C1 becomes Level3 and so on</param>
			public Progression( string level, Checkpoint checkpoint ) : this( 0, checkpoint )
			{
				levelName = level;
			}
#endif

			/// <summary></summary>
			/// <param name="level">Level index</param>
			/// <param name="checkpoint">Checkpoints can be created via Checkpoint.First, Checkpoint.Middle and Checkpoint.Last functions. If checkpoints are not short, use "new Progression(level)" instead (i.e. treat checkpoints as levels). In this case, Level1_Checkpoint1 becomes Level1, L1_C2 becomes Level2, L2_C1 becomes Level3 and so on</param>
			/// <param name="score">Score value</param>
			public Progression( int level, Checkpoint checkpoint, int score ) : this( level, checkpoint )
			{
				this.score = score;
				hasScore = true;
			}

#if !ELEPHANT_ENABLED
			/// <summary></summary>
			/// <param name="level">Level name</param>
			/// <param name="checkpoint">Checkpoints can be created via Checkpoint.First, Checkpoint.Middle and Checkpoint.Last functions. If checkpoints are not short, use "new Progression(level)" instead (i.e. treat checkpoints as levels). In this case, Level1_Checkpoint1 becomes Level1, L1_C2 becomes Level2, L2_C1 becomes Level3 and so on</param>
			/// <param name="score">Score value</param>
			public Progression( string level, Checkpoint checkpoint, int score ) : this( 0, checkpoint, score )
			{
				levelName = level;
			}
#endif

			public static implicit operator Progression( int level )
			{
				return new Progression( level );
			}

#if !ELEPHANT_ENABLED
			public static implicit operator Progression( string level )
			{
				return new Progression( level );
			}
#endif

#if ELEPHANT_ENABLED
			internal void SendElephantCheckpointEvent( string eventType )
			{
				if( !hasCheckpoint )
					return;

				Params parameters = Params.New().Set( "checkpoint", checkpoint.index );
				if( hasScore )
					parameters.Set( "score", score );

				Elephant.Event( eventType, level, parameters );
			}
#endif

#if GAMEANALYTICS_ENABLED
			internal void SendGameAnalyticsEvent( GAProgressionStatus eventType )
			{
				string progression01 = !string.IsNullOrEmpty( levelName ) ? levelName : ( "level_" + level.ToString( "D2" ) );

				if( hasScore )
				{
					if( hasCheckpoint )
						GameAnalytics.NewProgressionEvent( eventType, progression01, "checkpoint_" + checkpoint.index.ToString( "D2" ), score );
					else
						GameAnalytics.NewProgressionEvent( eventType, progression01, score );
				}
				else
				{
					if( hasCheckpoint )
						GameAnalytics.NewProgressionEvent( eventType, progression01, "checkpoint_" + checkpoint.index.ToString( "D2" ) );
					else
						GameAnalytics.NewProgressionEvent( eventType, progression01 );
				}
			}
#endif

#if GGI_ENABLED
			internal void SendGGIEvent( LevelStatus eventType )
			{
				Dictionary<string, object> extraParams = ( hasScore || hasCheckpoint ) ? new Dictionary<string, object>( 2 ) : null;
				if( hasScore )
					extraParams["score"] = score;
				if( hasCheckpoint )
					extraParams["checkpoint"] = checkpoint.index;

				if( !string.IsNullOrEmpty( levelName ) )
					GGIAnalytics.Instance.LogLevelEvent( levelName, eventType, extraParams );
				else
					GGIAnalytics.Instance.LogLevelEvent( level, eventType, extraParams );
			}
#endif

#if LIONKIT_ENABLED
			internal void GetLionKitLevelAndScore( out object level, out object score )
			{
				if( hasScore )
					score = this.score;
				else
					score = null;

				if( hasCheckpoint )
				{
					if( string.IsNullOrEmpty( levelName ) )
						level = string.Concat( this.level.ToString(), "-", checkpoint.index.ToString() );
					else
						level = string.Concat( levelName, "-", checkpoint.index.ToString() );
				}
				else
				{
					if( string.IsNullOrEmpty( levelName ) )
						level = this.level;
					else
						level = levelName;
				}
			}
#endif
		}
#pragma warning restore 0414
		#endregion

		#region SDK Integration Queries
		public bool ElephantSDKEnabled
		{
			get
			{
#if ELEPHANT_ENABLED
				return true;
#else
				return false;
#endif
			}
		}

		public bool FacebookSDKEnabled
		{
			get
			{
#if FACEBOOK_ENABLED
				return true;
#else
				return false;
#endif
			}
		}

		public bool FirebaseSDKEnabled
		{
			get
			{
#if FIREBASE_ENABLED
				return true;
#else
				return false;
#endif
			}
		}

		public bool GameAnalyticsSDKEnabled
		{
			get
			{
#if GAMEANALYTICS_ENABLED
				return true;
#else
				return false;
#endif
			}
		}

		public bool GGISDKEnabled
		{
			get
			{
#if GGI_ENABLED
				return true;
#else
				return false;
#endif
			}
		}

		public bool LionKitSDKEnabled
		{
			get
			{
#if LIONKIT_ENABLED
				return true;
#else
				return false;
#endif
			}
		}
		#endregion

		#region Initialization & Unity Messages
		internal void Initialize()
		{
			RemoteDataStatus = OnlineStatus.Pending;

#if FACEBOOK_ENABLED
			try
			{
				if( !FB.IsInitialized )
					FB.Init( FBInitResult, FBInitTimeHandler );
				else
					FB.ActivateApp();
			}
			catch( System.Exception e )
			{
				Debug.LogException( e );
			}
#endif

#if FIREBASE_ENABLED
			try
			{
				FetchFirebaseRemoteDataAsync();
			}
			catch( System.Exception e )
			{
				Debug.LogException( e );
			}
#endif

#if GAMEANALYTICS_ENABLED
			try
			{
				GameAnalytics.Initialize();
			}
			catch( System.Exception e )
			{
				Debug.LogException( e );
			}
#endif

#if LIONKIT_ENABLED
			try
			{
				LionKit.Initialize();
				AppLovin.WhenInitialized( LionKitRemoteDataFetched );
			}
			catch( System.Exception e )
			{
				Debug.LogException( e );
			}
#endif
		}

#if FACEBOOK_ENABLED
		private void FBInitResult()
		{
			if( FB.IsInitialized )
				FB.ActivateApp();
			else
				Debug.Log( "Failed to Initialize the Facebook SDK" );
		}

		private void FBInitTimeHandler( bool isGameShown )
		{
			Time.timeScale = isGameShown ? 1f : 0f;
		}
#endif

#if FIREBASE_ENABLED
		private Task FetchFirebaseRemoteDataAsync()
		{
			return FirebaseRemoteConfig.FetchAsync( System.TimeSpan.Zero ).ContinueWithOnMainThread( FirebaseRemoteDataFetched );
		}

		private void FirebaseRemoteDataFetched( Task fetchTask )
		{
			if( fetchTask.IsCanceled )
				Debug.Log( "Firebase remote fetch cancelled" );
			else if( fetchTask.IsFaulted )
				Debug.Log( "Firebase remote fetch faulted" );
			else if( fetchTask.IsCompleted )
				Debug.Log( "Firebase remote fetch completed" );

			RemoteDataStatus = OnlineStatus.Failure;

			var info = FirebaseRemoteConfig.Info;
			switch( info.LastFetchStatus )
			{
				case LastFetchStatus.Success:
					Debug.Log( "Firebase remote fetch successfull" );

					FirebaseRemoteConfig.ActivateFetched();
					RemoteDataStatus = OnlineStatus.Success;

					break;
				case LastFetchStatus.Failure:
					switch( info.LastFetchFailureReason )
					{
						case FetchFailureReason.Error:
							Debug.Log( "Firebase remote fetch error failure" );
							break;
						case FetchFailureReason.Throttled:
							Debug.Log( "Firebase remote fetch throttle failure" );
							break;
					}

					break;
				case LastFetchStatus.Pending:
					Debug.Log( "Firebase remote fetch pending" );
					break;
			}

			foreach( string key in FirebaseRemoteConfig.Keys )
				remoteData[key] = FirebaseRemoteConfig.GetValue( key ).StringValue;

#if GGI_ENABLED
			if( GGI.Data.Settings.Instance.DisableAutoInit )
			{
				// Make sure that we don't initialize GGI SDK twice (it might be initialized at some other place by the developer)
				FieldInfo GGIInitCalledField = typeof( GGI.Core.GGI ).GetField( "_initCalled", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance );
				if( GGIInitCalledField == null || !( (bool) GGIInitCalledField.GetValue( GGI.Core.GGI.Instance ) ) )
					GGI.Core.GGI.Instance.Init();
			}
#endif
		}
#endif

#if LIONKIT_ENABLED
		private void LionKitRemoteDataFetched()
		{
			RemoteDataStatus = OnlineStatus.Success;
		}
#endif
		#endregion

		#region Analytics Functions
		/// <summary>Event to track a started level/checkpoint</summary>
		/// <param name="progression">Started level/checkpoint</param>
		public void LevelStartedEvent( Progression progression )
		{
#if ELEPHANT_ENABLED
			if( !progression.hasCheckpoint || progression.checkpoint.state == Checkpoint.CheckpointState.First )
				Elephant.LevelStarted( progression.level, progression.hasScore ? Params.New().Set( "score", progression.score ) : null );

			progression.SendElephantCheckpointEvent( "checkpoint_started" );
#endif

#if GAMEANALYTICS_ENABLED
			progression.SendGameAnalyticsEvent( GAProgressionStatus.Start );
#endif

#if GGI_ENABLED
			progression.SendGGIEvent( LevelStatus.Start );
#endif

#if LIONKIT_ENABLED
			progression.GetLionKitLevelAndScore( out object _level, out object _score );
			LionAnalytics.Events.LevelStarted( _level, _score );
#endif
		}

		/// <summary>Event to track failure on a level/checkpoint</summary>
		/// <param name="progression">Failed level/checkpoint</param>
		public void LevelFailedEvent( Progression progression )
		{
#if ELEPHANT_ENABLED
			progression.SendElephantCheckpointEvent( "checkpoint_failed" );

			if( !progression.hasCheckpoint )
				Elephant.LevelFailed( progression.level, progression.hasScore ? Params.New().Set( "score", progression.score ) : null );
#endif

#if GAMEANALYTICS_ENABLED
			progression.SendGameAnalyticsEvent( GAProgressionStatus.Fail );
#endif

#if GGI_ENABLED
			progression.SendGGIEvent( LevelStatus.Fail );
#endif

#if LIONKIT_ENABLED
			progression.GetLionKitLevelAndScore( out object _level, out object _score );
			LionAnalytics.Events.LevelFailed( _level, _score );
#endif
		}

		/// <summary>Event to track the completion of a level/checkpoint</summary>
		/// <param name="progression">Completed level/checkpoint</param>
		public void LevelCompletedEvent( Progression progression )
		{
			LevelCompletedEventInternal( progression, true );
		}

		private void LevelCompletedEventInternal( Progression progression, bool sendLionKitEvent )
		{
#if ELEPHANT_ENABLED
			progression.SendElephantCheckpointEvent( "checkpoint_completed" );

			if( !progression.hasCheckpoint || progression.checkpoint.state == Checkpoint.CheckpointState.Last )
				Elephant.LevelCompleted( progression.level, progression.hasScore ? Params.New().Set( "score", progression.score ) : null );
#endif

#if GAMEANALYTICS_ENABLED
			progression.SendGameAnalyticsEvent( GAProgressionStatus.Complete );
#endif

#if GGI_ENABLED
			progression.SendGGIEvent( LevelStatus.Success );
#endif

#if LIONKIT_ENABLED
			if( sendLionKitEvent )
			{
				progression.GetLionKitLevelAndScore( out object _level, out object _score );
				LionAnalytics.Events.LevelComplete( _level, _score );
			}
#endif
		}

		/// <summary>Event to track a skipped level/checkpoint (e.g. after user watches a rewarded ad)</summary>
		/// <param name="progression">The skipped level/checkpoint</param>
		public void LevelSkippedEvent( Progression progression )
		{
			LevelCompletedEventInternal( progression, false );

#if LIONKIT_ENABLED
			progression.GetLionKitLevelAndScore( out object _level, out object _score );
			LionAnalytics.Events.LevelSkipped( _level, _score );
#endif
		}

		/// <summary>Event to track the completion of a tutorial step</summary>
		/// <param name="step">Which step/stage of the tutorial is completed</param>
		/// <param name="parameters">Additional parameters (optional). GameAnalytics supports at most 4 parameters, with each having a max length of 64 characters</param>
		public void TutorialCompletedEvent( int step, params Parameter[] parameters )
		{
#if ELEPHANT_ENABLED || GAMEANALYTICS_ENABLED || GGI_ENABLED
			CustomEventInternal( "tutorial_completed", 0, parameters.CombineWith( new Parameter( "step", step ) ), false );
#endif

#if LIONKIT_ENABLED
			if( parameters == null || parameters.Length == 0 )
				LionAnalytics.Events.TutorialComplete( step );
			else
				LionAnalytics.Events.TutorialComplete( parameters.FillDictionary( lionKitEventParams, new Parameter( "step", step ) ) );
#endif
		}

		/// <summary>Event to track the completion of a tutorial step</summary>
		/// <param name="step">Which step/stage of the tutorial is completed</param>
		/// <param name="parameters">Additional parameters (optional). GameAnalytics supports at most 4 parameters, with each having a max length of 64 characters</param>
		public void TutorialCompletedEvent( string step, params Parameter[] parameters )
		{
#if ELEPHANT_ENABLED || GAMEANALYTICS_ENABLED || GGI_ENABLED
			CustomEventInternal( "tutorial_completed", 0, parameters.CombineWith( new Parameter( "step", step ) ), false );
#endif

#if LIONKIT_ENABLED
			if( parameters == null || parameters.Length == 0 )
				LionAnalytics.Events.TutorialComplete( step );
			else
				LionAnalytics.Events.TutorialComplete( parameters.FillDictionary( lionKitEventParams, new Parameter( "step", step ) ) );
#endif
		}

		/// <summary>Event to track an in-game money transaction (e.g. purchasing an item from the shop or gaining a bag of coins after watching a rewarded ad)</summary>
		/// <param name="source">Where does this transaction take place, e.g. "shop"</param>
		/// <param name="currencyType">e.g. "coin", "gem"</param>
		/// <param name="level">Current in-game level/scene/progress</param>
		/// <param name="transactionAmount">How much currency is used or gained, MUST BE negative if the currency is used, e.g. "-10"</param>
		/// <param name="finalCurrency">How much currency is left AFTER the transaction</param>
		/// <param name="eventName">Type of the transaction, e.g. "buy_skin"</param>
		/// <param name="unlockedItemID">ID of the purchased item, or null if not available</param>
		public void TransactionEvent( string source, string currencyType, int level, long transactionAmount, long finalCurrency, string eventName, string unlockedItemID )
		{
			TransactionEventInternal( source, currencyType, level, transactionAmount, finalCurrency, eventName, unlockedItemID, true );
		}

		private void TransactionEventInternal( string source, string currencyType, int level, long transactionAmount, long finalCurrency, string eventName, string unlockedItemID, bool sendLionKitEvent )
		{
#if ELEPHANT_ENABLED
			Elephant.Transaction( currencyType, level, transactionAmount, finalCurrency, eventName );
#endif

#if GAMEANALYTICS_ENABLED
			gameAnalyticsParams.Length = 0;
			gameAnalyticsParams.Append( source ).Append( ":" ).Append( eventName ).Append( ":" ).Append( currencyType );
			if( !string.IsNullOrEmpty( unlockedItemID ) )
				gameAnalyticsParams.Append( ":" ).Append( unlockedItemID );

			GameAnalytics.NewDesignEvent( gameAnalyticsParams.ToString() );
#endif

#if GGI_ENABLED
			GGIAnalytics.Instance.LogMarketEvent( eventName, !string.IsNullOrEmpty( unlockedItemID ) ? unlockedItemID : source, (double) ( transactionAmount >= 0L ? transactionAmount : -transactionAmount ) );
#endif

#if LIONKIT_ENABLED
			if( sendLionKitEvent )
			{
				lionKitEventParams.Clear();
				lionKitEventParams["source"] = source;
				lionKitEventParams["currency_type"] = currencyType;
				lionKitEventParams["level"] = level;
				lionKitEventParams["amount"] = transactionAmount >= 0L ? transactionAmount : -transactionAmount;
				lionKitEventParams["final_currency"] = finalCurrency;
				lionKitEventParams["type"] = eventName;
				if( !string.IsNullOrEmpty( unlockedItemID ) )
					lionKitEventParams["item_id"] = unlockedItemID;

				LionAnalytics.LogEvent( transactionAmount > 0L ? "currency_gain" : "currency_spent", lionKitEventParams );
			}
#endif
		}

		/// <summary>Event to track a purchased upgrade (use TransactionEvent for non-upgrade purchases)</summary>
		/// <param name="upgrade">Type of the upgrade, e.g. "hp_upgrade", "fire_rate"</param>
		/// <param name="upgradeLevel">How many times this upgrade has been purchased</param>
		/// <param name="level">Current in-game level/scene/progress (i.e. NOT upgrade's level)</param>
		/// <param name="currencyType">e.g. "coin", "gem"</param>
		/// <param name="cost">How much currency is used</param>
		/// <param name="finalCurrency">How much currency is left AFTER the purchase</param>
		public void UpgradePurchasedEvent( string upgrade, int upgradeLevel, int level, string currencyType, long cost, long finalCurrency )
		{
#if ELEPHANT_ENABLED || GAMEANALYTICS_ENABLED || GGI_ENABLED
			TransactionEventInternal( "upgrade_purchase", currencyType, level, cost > 0L ? -cost : cost, finalCurrency, string.Concat( upgrade, "_", upgradeLevel ), null, false );
#endif

#if LIONKIT_ENABLED
			LionAnalytics.Events.UpgradePurchase( upgrade, upgradeLevel, (int) ( cost < 0L ? -cost : cost ) );
#endif
		}

		/// <summary>Event to track a free unlocked content (use TransactionEvent or UpgradePurchasedEvent for purchases)</summary>
		/// <param name="content">What is unlocked, e.g. "skin_vader", "weapon_blue_gun"</param>
		/// <param name="numberOfUnlocks">How many times this content has been unlocked (pass -1 if this is a one-time unlock)</param>
		/// <param name="level">Current in-game level/scene/progress</param>
		/// <param name="parameters">Additional parameters (optional). GameAnalytics supports at most 4 parameters, with each having a max length of 64 characters</param>
		public void ContentUnlockedEvent( string content, int numberOfUnlocks, int level, params Parameter[] parameters )
		{
#if ELEPHANT_ENABLED || GAMEANALYTICS_ENABLED || GGI_ENABLED
			if( numberOfUnlocks > 0 )
				CustomEventInternal( "content_unlock", level, parameters.CombineWith( new Parameter( "content", content ), new Parameter( "unlock_count", numberOfUnlocks ) ), false );
			else
				CustomEventInternal( "content_unlock", level, parameters.CombineWith( new Parameter( "content", content ) ), false );
#endif

#if LIONKIT_ENABLED
			if( parameters == null || parameters.Length == 0 )
				LionAnalytics.Events.ContentUnlocked( content, numberOfUnlocks );
			else
			{
				Dictionary<string, object> eventParams = parameters.FillDictionary( lionKitEventParams, new Parameter( "content", content ), new Parameter( "ingame_level", level ) );
				if( numberOfUnlocks > 0 )
					eventParams["unlock_count"] = numberOfUnlocks;

				LionAnalytics.Events.ContentUnlocked( eventParams );
			}
#endif
		}

		/// <summary>Custom event that doesn't fit into other categories</summary>
		/// <param name="eventName">What is this event</param>
		/// <param name="level">Current in-game level/scene/progress</param>
		/// <param name="parameters">Additional parameters (optional). GameAnalytics supports at most 4 parameters, with each having a max length of 64 characters</param>
		public void CustomEvent( string eventName, int level, params Parameter[] parameters )
		{
			CustomEventInternal( eventName, level, parameters, true );
		}

		private void CustomEventInternal( string eventName, int level, Parameter[] parameters, bool sendLionKitEvent )
		{
#if ELEPHANT_ENABLED
			if( parameters == null || parameters.Length == 0 )
				Elephant.Event( eventName, level );
			else
			{
				Params _parameters = Params.New();
				for( int i = 0; i < parameters.Length; i++ )
					parameters[i].ToElephantParams( _parameters );

				Elephant.Event( eventName, level, _parameters );
			}
#endif

#if GAMEANALYTICS_ENABLED
			if( parameters == null || parameters.Length == 0 )
				GameAnalytics.NewDesignEvent( eventName );
			else
			{
				gameAnalyticsParams.Length = 0;
				gameAnalyticsParams.Append( eventName );
				for( int i = 0; i < parameters.Length; i++ )
					parameters[i].ToGameAnalyticsParams( gameAnalyticsParams );

				GameAnalytics.NewDesignEvent( gameAnalyticsParams.ToString() );
			}
#endif

#if GGI_ENABLED
			if( parameters == null || parameters.Length == 0 )
				GGIAnalytics.Instance.LogGenericEvent( eventName );
			else
				GGIAnalytics.Instance.LogGenericEventWithParams( eventName, parameters.FillDictionary( new Dictionary<string, object>( parameters.Length ) ) );
#endif

#if LIONKIT_ENABLED
			if( sendLionKitEvent )
			{
				if( parameters == null || parameters.Length == 0 )
					LionAnalytics.LogEvent( eventName );
				else
					LionAnalytics.LogEvent( eventName, parameters.FillDictionary( lionKitEventParams, new Parameter( "level", level ) ) );
			}
#endif
		}
		#endregion

		#region A/B Functions (Remote Values)
		/// <summary>Fetches a remote string value from the server</summary>
		/// <param name="key">Key of the value</param>
		/// <param name="defaultValue">Default value that will be returned when there is no network connection or the key doesn't exist on server</param>
		public string GetRemoteStringValue( string key, string defaultValue )
		{
#if LIONKIT_ENABLED
			if( RemoteDataStatus == OnlineStatus.Success && !remoteData.ContainsKey( key ) )
				remoteData[key] = MaxSdk.VariableService.GetString( key, defaultValue );
#endif

			if( remoteData.TryGetValue( key, out object value ) && value != null )
				return value.ToString();

			return defaultValue;
		}

		/// <summary>Fetches a remote integer value from the server</summary>
		/// <param name="key">Key of the value</param>
		/// <param name="defaultValue">Default value that will be returned when there is no network connection or the key doesn't exist on server</param>
		public int GetRemoteIntValue( string key, int defaultValue )
		{
#if LIONKIT_ENABLED
			if( RemoteDataStatus == OnlineStatus.Success && !remoteData.ContainsKey( key ) )
			{
				string remoteValue = MaxSdk.VariableService.GetString( key );
				if( !string.IsNullOrEmpty( remoteValue ) )
					remoteData[key] = remoteValue;
				else
					remoteData[key] = defaultValue;
			}
#endif

			if( remoteData.TryGetValue( key, out object value ) && value != null )
			{
				if( value is int )
					return (int) value;
				else if( value is float )
					return Mathf.RoundToInt( (float) value );
				else if( int.TryParse( value.ToString(), NumberStyles.Integer, remoteDataParser, out int _value ) )
					return _value;
				else if( float.TryParse( value.ToString(), NumberStyles.Float, remoteDataParser, out float _value2 ) )
					return Mathf.RoundToInt( _value2 );
			}

			return defaultValue;
		}

		/// <summary>Fetches a remote float value from the server</summary>
		/// <param name="key">Key of the value</param>
		/// <param name="defaultValue">Default value that will be returned when there is no network connection or the key doesn't exist on server</param>
		public float GetRemoteFloatValue( string key, float defaultValue )
		{
#if LIONKIT_ENABLED
			if( RemoteDataStatus == OnlineStatus.Success && !remoteData.ContainsKey( key ) )
			{
				string remoteValue = MaxSdk.VariableService.GetString( key );
				if( !string.IsNullOrEmpty( remoteValue ) )
					remoteData[key] = remoteValue;
				else
					remoteData[key] = defaultValue;
			}
#endif

			if( remoteData.TryGetValue( key, out object value ) && value != null )
			{
				if( value is int )
					return (int) value;
				else if( value is float )
					return (float) value;
				else if( float.TryParse( value.ToString(), NumberStyles.Float, remoteDataParser, out float _value ) )
					return _value;
			}

			return defaultValue;
		}

		/// <summary>Fetches a remote boolean value from the server</summary>
		/// <param name="key">Key of the value</param>
		/// <param name="defaultValue">Default value that will be returned when there is no network connection or the key doesn't exist on server</param>
		public bool GetRemoteBoolValue( string key, bool defaultValue )
		{
#if LIONKIT_ENABLED
			if( RemoteDataStatus == OnlineStatus.Success && !remoteData.ContainsKey( key ) )
				remoteData[key] = MaxSdk.VariableService.GetBoolean( key, defaultValue );
#endif

			if( remoteData.TryGetValue( key, out object value ) && value != null )
			{
				if( value is bool )
					return (bool) value;
				else if( value is int )
					return (int) value != 0;
				else if( value is float )
					return (float) value != 0f;
				else
				{
					string _value = value.ToString();
					return _value.Equals( "true", System.StringComparison.OrdinalIgnoreCase ) || _value == "1";
				}
			}
			else
				return defaultValue;
		}
		#endregion
	}

	#region Extension Functions
	internal static class AnalyticsModuleExtensions
	{
		public static Dictionary<string, object> FillDictionary( this AnalyticsModule.Parameter[] parameters, Dictionary<string, object> dictionary )
		{
			dictionary.Clear();

			for( int i = 0; i < parameters.Length; i++ )
				parameters[i].AddToDictionary( dictionary );

			return dictionary;
		}

		public static Dictionary<string, object> FillDictionary( this AnalyticsModule.Parameter[] parameters, Dictionary<string, object> dictionary, AnalyticsModule.Parameter additionalParameter )
		{
			dictionary.Clear();

			additionalParameter.AddToDictionary( dictionary );
			for( int i = 0; i < parameters.Length; i++ )
				parameters[i].AddToDictionary( dictionary );

			return dictionary;
		}

		public static Dictionary<string, object> FillDictionary( this AnalyticsModule.Parameter[] parameters, Dictionary<string, object> dictionary, AnalyticsModule.Parameter additionalParameter1, AnalyticsModule.Parameter additionalParameter2 )
		{
			dictionary.Clear();

			additionalParameter1.AddToDictionary( dictionary );
			additionalParameter2.AddToDictionary( dictionary );

			for( int i = 0; i < parameters.Length; i++ )
				parameters[i].AddToDictionary( dictionary );

			return dictionary;
		}

		public static AnalyticsModule.Parameter[] CombineWith( this AnalyticsModule.Parameter[] parameters, AnalyticsModule.Parameter parameter )
		{
			AnalyticsModule.Parameter[] result = new AnalyticsModule.Parameter[parameters == null ? 1 : parameters.Length + 1];
			if( parameters != null )
			{
				for( int i = 0; i < parameters.Length; i++ )
					result[i] = parameters[i];
			}

			result[result.Length - 1] = parameter;
			return result;
		}

		public static AnalyticsModule.Parameter[] CombineWith( this AnalyticsModule.Parameter[] parameters, AnalyticsModule.Parameter parameter1, AnalyticsModule.Parameter parameter2 )
		{
			AnalyticsModule.Parameter[] result = new AnalyticsModule.Parameter[parameters == null ? 2 : parameters.Length + 2];
			if( parameters != null )
			{
				for( int i = 0; i < parameters.Length; i++ )
					result[i] = parameters[i];
			}

			result[result.Length - 2] = parameter1;
			result[result.Length - 1] = parameter2;

			return result;
		}
	}
	#endregion
}