using System.Collections.Generic;
using UnityEngine;

public enum UIElementType
{
	// NOTE: Make sure that each entry has a unique id

	// HUD elements
	TotalCoinsText = 0,
	Progressbar = 1,
	CalloutText = 18,
	FPSCounter = 20,
	TopRestartButton = 21,
	TopSkipLevelButton = 22,
	TopCurrentLevelText = 23,

	// Tutorials
	SwipeTutorial = 6,
	TapToDoStuffTutorial = 7,

	// Menus
	MainMenu = 8,
	ShopMenu = 9,
	GalleryMenu = 10,
	LevelFailedMenu = 11,
	LevelCompletedMenu = 12,
	BonusLevelRewardMenu = 19,
	NextUnlockPanel = 13,
	Dialog = 17
}

namespace FTemplateNamespace
{
	[System.Serializable]
	internal class UIElement
	{
		#region CONSTANTS
		internal static readonly UIElementType[] UI_HUD_ELEMENTS = new UIElementType[]
		{
			UIElementType.TotalCoinsText,
			UIElementType.Progressbar,
			UIElementType.CalloutText,
			UIElementType.FPSCounter,
			UIElementType.TopRestartButton,
			UIElementType.TopSkipLevelButton,
			UIElementType.TopCurrentLevelText
		};

		internal static readonly UIElementType[] UI_TUTORIALS = new UIElementType[]
		{
			UIElementType.SwipeTutorial,
			UIElementType.TapToDoStuffTutorial
		};

		internal static readonly UIElementType[] UI_MENUS = new UIElementType[]
		{
			UIElementType.MainMenu,
			UIElementType.ShopMenu,
			UIElementType.GalleryMenu,
			UIElementType.LevelFailedMenu,
			UIElementType.LevelCompletedMenu,
			UIElementType.BonusLevelRewardMenu,
			UIElementType.NextUnlockPanel,
			UIElementType.Dialog
		};
		#endregion
		#region ANIMATIONS
		private class GameObjectSetActiveDelayedJob : IAnimationJob
		{
			private GameObject gameObject;
			private bool shouldActivate;
			private float t;

			public void Initialize( GameObject gameObject, bool shouldActivate, float delay )
			{
				this.gameObject = gameObject;
				this.shouldActivate = shouldActivate;
				t = delay;
			}

			public bool Execute( float deltaTime )
			{
				t -= deltaTime;
				if( t > 0f )
					return true;

				gameObject.SetActive( shouldActivate );
				return false;
			}

			public bool CheckAnimatedObject( object animatedObject )
			{
				return ReferenceEquals( gameObject, animatedObject );
			}

			public bool IsValid()
			{
				return gameObject;
			}

			public void Clear()
			{
				gameObject = null;
			}
		}

		private class CanvasGroupSetAlphaJob : IAnimationJob
		{
			private CanvasGroup canvasGroup;
			private float initialAlpha, targetAlpha;
			private float speed;
			private float t;

			public void Initialize( CanvasGroup canvasGroup, float targetAlpha, float duration )
			{
				this.canvasGroup = canvasGroup;
				this.targetAlpha = targetAlpha;
				initialAlpha = canvasGroup.alpha;
				speed = 1f / duration;
				t = 0f;
			}

			public bool Execute( float deltaTime )
			{
				t += deltaTime * speed;
				if( t < 1f )
				{
					canvasGroup.alpha = Mathf.LerpUnclamped( initialAlpha, targetAlpha, t );
					return true;
				}

				canvasGroup.alpha = targetAlpha;
				return false;
			}

			public bool CheckAnimatedObject( object animatedObject )
			{
				return ReferenceEquals( canvasGroup, animatedObject );
			}

			public bool IsValid()
			{
				return canvasGroup;
			}

			public void Clear()
			{
				canvasGroup = null;
			}
		}
		#endregion
		#region HELPER CLASSES
		internal class Comparer : IEqualityComparer<UIElementType>
		{
			public bool Equals( UIElementType x, UIElementType y ) { return x == y; }
			public int GetHashCode( UIElementType obj ) { return (int) obj; }
		}
		#endregion

#pragma warning disable 0649
		[SerializeField]
		private UIElementType m_type;
		public UIElementType Type { get { return m_type; } }

		[SerializeField]
		private Component m_navigationHandler;
		public Component NavigationHandler { get { return m_navigationHandler; } }

		[SerializeField]
		private string showAnimation;
		[SerializeField]
		private string hideAnimation;
#pragma warning restore 0649

		private UIElementCanvas canvasHolder;

		public bool IsVisible { get; private set; }

		public void Initialize( UIElementCanvas canvas )
		{
			canvasHolder = canvas;

			// Hide all UIElements at startup
			IsVisible = true;
			Hide( 0f );
		}

		public void Show( float duration )
		{
			if( IsVisible )
				return;

			IsVisible = true;

			AnimationSystem<GameObjectSetActiveDelayedJob>.StopAnimation( m_navigationHandler.gameObject, false );
			m_navigationHandler.gameObject.SetActive( true );

			if( canvasHolder != null )
			{
				AnimationSystem<GameObjectSetActiveDelayedJob>.StopAnimation( canvasHolder.Canvas.gameObject, false );
				canvasHolder.Canvas.gameObject.SetActive( true );
			}

			if( m_navigationHandler is CanvasGroup )
				HandleCanvasGroup( 1f, duration );
			else if( showAnimation.Length > 0 )
			{
				if( m_navigationHandler is Animation )
					HandleAnimation( showAnimation, duration );
				else if( m_navigationHandler is Animator )
					HandleAnimator( showAnimation, duration );
			}
		}

		public void Hide( float duration )
		{
			if( !IsVisible )
				return;

			IsVisible = false;

			float disableTime = 0f;
			if( duration == 0f )
				m_navigationHandler.gameObject.SetActive( false );
			else
			{
				if( m_navigationHandler is CanvasGroup )
					disableTime = HandleCanvasGroup( 0f, duration );
				else if( hideAnimation.Length > 0 )
				{
					if( m_navigationHandler is Animation )
						disableTime = HandleAnimation( hideAnimation, duration );
					else if( m_navigationHandler is Animator )
						disableTime = HandleAnimator( hideAnimation, duration );
				}

				if( disableTime <= 0f )
					m_navigationHandler.gameObject.SetActive( false );
				else
					AnimationSystem<GameObjectSetActiveDelayedJob>.NewAnimation().Initialize( m_navigationHandler.gameObject, false, disableTime );
			}

			if( canvasHolder != null )
			{
				bool shouldDeactivateCanvas = true;
				for( int i = 0; i < canvasHolder.UIElements.Length; i++ )
				{
					if( canvasHolder.UIElements[i].IsVisible )
					{
						shouldDeactivateCanvas = false;
						break;
					}
				}

				if( shouldDeactivateCanvas )
				{
					if( disableTime <= 0f )
						canvasHolder.Canvas.gameObject.SetActive( false );
					else
						AnimationSystem<GameObjectSetActiveDelayedJob>.NewAnimation().Initialize( canvasHolder.Canvas.gameObject, false, disableTime );
				}
			}
		}

		private float HandleCanvasGroup( float targetAlpha, float duration )
		{
			AnimationSystem<CanvasGroupSetAlphaJob>.StopAnimation( (CanvasGroup) m_navigationHandler, false );

			if( duration == 0f )
				( (CanvasGroup) m_navigationHandler ).alpha = targetAlpha;
			else
			{
				if( duration < 0f )
					duration = -duration;

				( (CanvasGroup) m_navigationHandler ).alpha = 1f - targetAlpha;
				AnimationSystem<CanvasGroupSetAlphaJob>.NewAnimation().Initialize( (CanvasGroup) m_navigationHandler, targetAlpha, duration );
			}

			( (CanvasGroup) m_navigationHandler ).blocksRaycasts = targetAlpha > 0f;

			return duration;
		}

		private float HandleAnimation( string animation, float duration )
		{
			( (Animation) m_navigationHandler ).Play( animation );

			AnimationState animState = ( (Animation) m_navigationHandler )[animation];
			animState.speed = duration <= 0f ? 1f : animState.length / duration;
			if( duration == 0f )
				animState.normalizedTime = 1f;

			return duration >= 0f ? duration : animState.length;
		}

		private float HandleAnimator( string animation, float duration )
		{
			( (Animator) m_navigationHandler ).Play( animation, 0, duration == 0f ? 1f : 0f );
			( (Animator) m_navigationHandler ).Update( 0f ); // Necessary for GetCurrentAnimatorStateInfo to return the correct state

			AnimatorStateInfo animState = ( (Animator) m_navigationHandler ).GetCurrentAnimatorStateInfo( 0 );
			( (Animator) m_navigationHandler ).speed = duration <= 0f ? 1f : animState.length / duration;

			return duration >= 0f ? duration : animState.length;
		}
	}

	internal class UIElementCanvas
	{
		public readonly Canvas Canvas;
		public readonly UIElement[] UIElements;

		public UIElementCanvas( Canvas canvas, UIElement[] uiElements )
		{
			Canvas = canvas;
			UIElements = uiElements;
		}
	}
}