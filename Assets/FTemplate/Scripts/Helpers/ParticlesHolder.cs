using UnityEngine;

public class ParticlesHolder : MonoBehaviour
{
#pragma warning disable 0649
	[SerializeField]
	private ParticleSystem[] particles;
#pragma warning restore 0649

	public int Length { get { return particles.Length; } }
	public ParticleSystem this[int index] { get { return particles[index]; } }

	public bool IsPlaying
	{
		get
		{
			for( int i = 0; i < particles.Length; i++ )
			{
				if( particles[i].IsAlive( false ) )
					return true;
			}

			return false;
		}
	}

	public void Play()
	{
		for( int i = 0; i < particles.Length; i++ )
			particles[i].Play( false );
	}

	public void Emit( int count )
	{
		for( int i = 0; i < particles.Length; i++ )
			particles[i].Emit( count );
	}

	public void Stop( bool clearParticles )
	{
		for( int i = 0; i < particles.Length; i++ )
			particles[i].Stop( false, clearParticles ? ParticleSystemStopBehavior.StopEmittingAndClear : ParticleSystemStopBehavior.StopEmitting );
	}

#if UNITY_EDITOR
	private void Reset()
	{
		particles = GetComponentsInChildren<ParticleSystem>( false );
	}
#endif
}