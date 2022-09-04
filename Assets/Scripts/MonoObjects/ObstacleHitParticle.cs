using System;
using Core;
using UnityEngine;

namespace MonoObjects
{
    public class ObstacleHitParticle : MonoPooled
    {
        [SerializeField] private ParticleSystem particleSystem;

        private float _timeToComplete;

        private void Awake()
        {
            _timeToComplete = particleSystem.main.duration;
        }

        public void Init(Transform parent)
        {
            transform.position = parent.position;
            particleSystem.Play();
            Invoke(nameof(ReturnToPool), _timeToComplete);
        }
    }
}