using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace FTemplateNamespace
{
	public interface IAnimationJob
	{
		bool Execute( float deltaTime ); // Should return true while the animation is running, false when the animation is finished
		bool CheckAnimatedObject( object animatedObject ); // Should return true if the animation is animating the "animatedObject"
		bool IsValid(); // Should return true if the animated object is still alive
		void Clear(); // Should clear any object references here
	}

	public interface IAnimationSystem
	{
		void Execute( float deltaTime );
		void Clear( bool invalidAnimationsOnly, bool completeAnimations );
	}

	public class AnimationSystem<T> : IAnimationSystem where T : class, IAnimationJob, new()
	{
		private const int DEFAULT_INITIAL_CAPACITY = 4;

		private static AnimationSystem<T> instance;

		private readonly List<T> animations;
		private readonly List<T> animationsPool;
		private float animationSpeed;

		private AnimationSystem( int initialCapacity, float animationSpeed = 1f )
		{
			if( initialCapacity < 0 )
				initialCapacity = 0;

			animations = new List<T>( initialCapacity );
			animationsPool = new List<T>( initialCapacity );
			this.animationSpeed = animationSpeed;

			PopulatePool( initialCapacity );
			FTemplate.Animation.RegisterAnimationSystem( this );
		}

		// Optional: Set the initial pool size and 'deltaTime' multiplier of the AnimationSystem
		public static void Initialize( int initialCapacity, float animationSpeed = 1f )
		{
			if( initialCapacity < 0 )
				initialCapacity = 0;

			if( instance == null )
				instance = new AnimationSystem<T>( initialCapacity, animationSpeed );
			else
			{
				instance.PopulatePool( initialCapacity );
				instance.animationSpeed = animationSpeed;
			}
		}

		// Create a new animation and return it
		public static T NewAnimation()
		{
			if( instance == null )
				instance = new AnimationSystem<T>( DEFAULT_INITIAL_CAPACITY );

			return instance.NewAnimationInternal();
		}

		// Stop any animations that are animating "animatedObject"
		public static void StopAnimation( object animatedObject, bool completeAnimations = true )
		{
			if( instance != null )
				instance.StopAnimationInternal( animatedObject, completeAnimations );
		}

		// Stop all running animations
		public static void StopAllAnimations( bool completeAnimations = true )
		{
			if( instance != null )
				instance.Clear( false, completeAnimations );
		}

		// Stop processing this animation system and release all of its resources
		public static void Kill()
		{
			FTemplate.Animation.UnregisterAnimationSystem( instance );
			instance = null;
		}

		public void Execute( float deltaTime )
		{
			deltaTime *= animationSpeed;

			for( int i = animations.Count - 1; i >= 0; i-- )
			{
				if( !animations[i].Execute( deltaTime ) )
					RemoveAnimationAt( i, false );
			}
		}

		private T NewAnimationInternal()
		{
			T animation;
			if( animationsPool.Count > 0 )
			{
				int lastPooledIndex = animationsPool.Count - 1;
				animation = animationsPool[lastPooledIndex];
				animationsPool.RemoveAt( lastPooledIndex );
			}
			else
				animation = new T();

			animations.Add( animation );
			return animation;
		}

		private void StopAnimationInternal( object animatedObject, bool completeAnimations )
		{
			for( int i = animations.Count - 1; i >= 0; i-- )
			{
				if( animations[i].CheckAnimatedObject( animatedObject ) )
					RemoveAnimationAt( i, completeAnimations );
			}
		}

		private void RemoveAnimationAt( int index, bool completeAnimation )
		{
			if( completeAnimation && animations[index].IsValid() )
				animations[index].Execute( float.PositiveInfinity );

			animations[index].Clear();
			animationsPool.Add( animations[index] );

			// Replace the finished animation with the last animation
			int lastAnimationIndex = animations.Count - 1;
			animations[index] = animations[lastAnimationIndex];
			animations.RemoveAt( lastAnimationIndex );
		}

		private void PopulatePool( int capacity )
		{
			for( int i = capacity - animationsPool.Count; i > 0; i-- )
				animationsPool.Add( new T() );
		}

		// Pool all running animations
		public void Clear( bool invalidAnimationsOnly, bool completeAnimations = true )
		{
			if( invalidAnimationsOnly )
			{
				for( int i = animations.Count - 1; i >= 0; i-- )
				{
					if( !animations[i].IsValid() )
						RemoveAnimationAt( i, completeAnimations );
				}
			}
			else
			{
				for( int i = animations.Count - 1; i >= 0; i-- )
				{
					if( completeAnimations && animations[i].IsValid() )
						animations[i].Execute( float.PositiveInfinity );

					animations[i].Clear();
					animationsPool.Add( animations[i] );
				}

				animations.Clear();
			}
		}
	}

	internal class AnimationModule : MonoBehaviour
	{
		private const bool POOL_INVALID_ANIMATIONS_ON_SCENE_CHANGE = true;

		private readonly List<IAnimationSystem> animationSystems = new List<IAnimationSystem>( 8 );

		private void OnEnable()
		{
			if( POOL_INVALID_ANIMATIONS_ON_SCENE_CHANGE )
				SceneManager.activeSceneChanged += Clear;
		}

		private void OnDisable()
		{
			if( POOL_INVALID_ANIMATIONS_ON_SCENE_CHANGE )
				SceneManager.activeSceneChanged -= Clear;
		}

		private void Update()
		{
			float deltaTime = Time.unscaledDeltaTime;
			if( deltaTime <= 0f )
				return;

			for( int i = animationSystems.Count - 1; i >= 0; i-- )
				animationSystems[i].Execute( deltaTime );
		}

		// Stop all running animations
		internal void Clear( bool invalidAnimationsOnly = false )
		{
			for( int i = animationSystems.Count - 1; i >= 0; i-- )
				animationSystems[i].Clear( invalidAnimationsOnly, true );
		}

		// Stop all invalid animations when active Scene changes
		private void Clear( Scene s1, Scene s2 )
		{
			Clear( true );
		}

		internal void RegisterAnimationSystem( IAnimationSystem animationSystem )
		{
			if( animationSystem != null )
				animationSystems.Add( animationSystem );
		}

		internal void UnregisterAnimationSystem( IAnimationSystem animationSystem )
		{
			if( animationSystem != null )
				animationSystems.Remove( animationSystem );
		}
	}
}