using UnityEngine;
using UnityEngine.UI;

namespace FTemplateNamespace
{
	public class SpawnedCoin : MonoBehaviour
	{
		public delegate void AnimationFinishedDelegate( SpawnedCoin coin );

#pragma warning disable 0649
		[SerializeField]
		private Image coinIcon;
#pragma warning restore 0649

		private Vector3 startPos;
		private Vector3 destination;

		private AnimationCurve scaleCurve;
		float scaleMultiplier;

		private float t;
		private float timeMultiplier;

		private int rewardAmount;

		public AnimationFinishedDelegate OnAnimationFinished;

		public void Animate( Vector3 startPos, Vector3 destination, AnimationCurve scaleCurve, float scaleMultiplier, float timeMultiplier, int rewardAmount )
		{
			this.startPos = transform.parent.InverseTransformPoint( startPos );
			this.destination = transform.parent.InverseTransformPoint( destination );
			this.scaleCurve = scaleCurve;
			this.scaleMultiplier = scaleMultiplier;
			this.timeMultiplier = timeMultiplier;
			this.rewardAmount = rewardAmount;

			transform.localPosition = startPos;
			transform.localEulerAngles = new Vector3( 0f, 0f, Random.Range( -15f, 15f ) );

			if( CurrencyIconHolder.Icon )
				coinIcon.sprite = CurrencyIconHolder.Icon;

			t = 0f;
			Update();
		}

		private void Update()
		{
			t += Time.unscaledDeltaTime * timeMultiplier;
			if( t >= 1f )
			{
				long targetDisplayedCoin = FTemplate.UI.DisplayedTotalCoins + rewardAmount;
				FTemplate.UI.SetTotalCoins( targetDisplayedCoin >= 0L ? targetDisplayedCoin : 0L, true );

				if( OnAnimationFinished != null )
					OnAnimationFinished( this );
			}
			else
			{
				float scale = scaleCurve.Evaluate( t ) * scaleMultiplier;

				transform.localPosition = Vector3.LerpUnclamped( startPos, destination, t * t );
				transform.localScale = new Vector3( scale, scale, scale );
			}
		}
	}
}