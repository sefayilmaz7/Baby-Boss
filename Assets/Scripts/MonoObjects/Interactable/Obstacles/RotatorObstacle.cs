using System;
using Core;
using DG.Tweening;
using MonoObjects.Interactable.Core;
using UnityEngine;

namespace MonoObjects.Interactable.Obstacles
{
    public class RotatorObstacle : ObstacleBase
    {
        [SerializeField] private Transform rotatingPart;
        [SerializeField] private float rotationDuration;
        [SerializeField] private float rotation = 180f;

        [Header("MovementTween")]
        [SerializeField] private float pushForce;

        [SerializeField] private float moveDuration;


        [Header("ScaleTween")] 
        [SerializeField] private float duration;
        [SerializeField] private float power;
        [SerializeField] private int vibrato;
        [SerializeField, Range(0,90f)] private float randomNess;
        [SerializeField] private bool fadeOut;
        

        
        
        private void Start()
        {
            rotatingPart.DORotate(new Vector3(0, rotation, 0), rotationDuration)
                .SetLoops(-1, LoopType.Incremental)
                .SetEase(Ease.Linear)
                .SetId(rotatingPart.GetInstanceID());
        }

        public override void Interact(Baby baby)
        {
            base.Interact(baby);
            baby.OnObstacleHit();


            DOTween.Kill(baby.Model.GetInstanceID());
            var directionX = Mathf.Sign(baby.Model.InverseTransformDirection(baby.Model.position - transform.position).x);
  
            baby.Model.DOLocalMoveX(directionX * pushForce, moveDuration).SetEase(Ease.OutQuad).SetId(baby.Model.GetInstanceID());
            baby.Model.DOShakeScale(duration, power, vibrato, randomNess, fadeOut).SetId(baby.Model.GetInstanceID());     
            
            
            baby.babyModel.SetBool(AnimationVariables.MirrorHit, !(directionX < 0));
            baby.babyModel.Animate(AnimationVariables.Hit);

        }
    }
}