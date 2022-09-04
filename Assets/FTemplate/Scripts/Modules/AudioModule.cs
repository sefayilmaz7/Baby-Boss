using DG.Tweening;
using UnityEngine;

namespace FTemplateNamespace
{
	public class AudioModule : MonoBehaviour
	{
		public bool ButtonClickSoundEnabled = true;
		public enum ButtonState { Neutral = 0, Positive = 1, Negative = 2 };

		private const string AUDIO_ENABLED_KEY = "AudioEnabled";

		private class WaitForClipAnimation : IAnimationJob
		{
			private AudioSource audioSource;
			private float delay;
			private float t;

			public void Initialize( AudioSource audioSource )
			{
				this.audioSource = audioSource;
				delay = audioSource.clip.length;
				t = 0f;
			}

			public bool Execute( float deltaTime )
			{
				t += deltaTime;
				if( t < delay )
					return true;

				FTemplate.Audio.audioSources.Push( audioSource );
				return false;
			}

			public bool CheckAnimatedObject( object animatedObject ) { return ReferenceEquals( animatedObject, audioSource ); }
			public bool IsValid() { return audioSource; }
			public void Clear() { audioSource = null; }
		}

#pragma warning disable 0649
		[SerializeField]
		private AudioClip neutralButtonClick;

		[SerializeField]
		private AudioClip positiveButtonClick;

		[SerializeField]
		private AudioClip negativeButtonClick;
#pragma warning restore 0649

		private SimplePool<AudioSource> audioSources;

		private bool? audioEnabled;
		public bool AudioEnabled
		{
			get
			{
				if( !audioEnabled.HasValue )
					audioEnabled = PlayerPrefs.GetInt( AUDIO_ENABLED_KEY, 1 ) == 1;

				return audioEnabled.Value;
			}
			set
			{
				audioEnabled = value;
				AudioListener.volume = value ? 1f : 0f;

				PlayerPrefs.SetInt( AUDIO_ENABLED_KEY, value ? 1 : 0 );
				PlayerPrefs.Save();
			}
		}

		private void Awake()
		{
			audioSources = new SimplePool<AudioSource>( 1, () =>
			{
				AudioSource instance = new GameObject( "ReusableAudioSource" ).AddComponent<AudioSource>();
				instance.playOnAwake = false;
				instance.rolloffMode = AudioRolloffMode.Linear;
				return instance;
			}, null, ( audioSource ) => audioSource.volume = 1f );

			AudioListener.volume = AudioEnabled ? 1f : 0f;
		}

		public void SetVolume( float value, float fadeDuration = 0f )
		{
			if( !AudioEnabled )
				value = 0f;

			if( value == AudioListener.volume )
				return;

			DOTween.Kill( "VolumeFade", false );

			if( fadeDuration <= 0f )
				AudioListener.volume = value;
			else
				DOTween.To( () => AudioListener.volume, ( volume ) => AudioListener.volume = volume, value, fadeDuration ).SetId( "VolumeFade" ).SetEase( Ease.InQuad ).SetUpdate( true );
		}

		public AudioSource Play2DClip( AudioClip clip, bool isLooping, float pitch = 1f )
		{
			if( !clip )
				return null;

			AudioSource audioSource = audioSources.Pop();
			audioSource.clip = clip;
			audioSource.loop = isLooping;
			audioSource.spatialBlend = 0f;
			audioSource.pitch = pitch;
			audioSource.Play();

			if( !isLooping )
				AnimationSystem<WaitForClipAnimation>.NewAnimation().Initialize( audioSource );

			return audioSource;
		}

		public AudioSource Play3DClip( AudioClip clip, Vector3 position, bool isLooping, float pitch = 1f )
		{
			if( !clip )
				return null;

			AudioSource audioSource = audioSources.Pop();
			audioSource.clip = clip;
			audioSource.loop = isLooping;
			audioSource.spatialBlend = 1f;
			audioSource.pitch = pitch;
			audioSource.transform.localPosition = position;
			audioSource.Play();

			if( !isLooping )
				AnimationSystem<WaitForClipAnimation>.NewAnimation().Initialize( audioSource );

			return audioSource;
		}

		public void PlayButtonClickAudio( ButtonState buttonState )
		{
			if (!AudioEnabled || !ButtonClickSoundEnabled)
				return;

			switch( buttonState )
			{
				case ButtonState.Neutral: Play2DClip( neutralButtonClick, false ); break;
				case ButtonState.Positive: Play2DClip( positiveButtonClick, false ); break;
				case ButtonState.Negative: Play2DClip( negativeButtonClick, false ); break;
			}
		}

		public AudioSource FetchAudioSource()
		{
			return audioSources.Pop();
		}

		public void Pool( AudioSource audioSource )
		{
			audioSources.Push( audioSource );
		}
	}
}