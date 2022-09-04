using UnityEngine;

namespace FTemplateNamespace
{
	[CreateAssetMenu( fileName = "AdsConfiguration", menuName = "Flamingo/Ads Configuration", order = 111 )]
	public class AdsConfiguration : ScriptableObject
	{
#pragma warning disable 0649
		public string IronSourceAppID;
		public float FailedAdRetryInterval = 10f;
		public float InterstitialAdCooldown = 30f;

		[SerializeField, HideInInspector]
		internal int DpiScaling;
#pragma warning restore 0649
	}
}