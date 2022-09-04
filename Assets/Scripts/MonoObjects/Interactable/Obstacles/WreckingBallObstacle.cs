using DG.Tweening;
using MonoObjects.Interactable.Core;
using UnityEngine;

namespace MonoObjects.Interactable.Obstacles
{
    public class WreckingBallObstacle : ObstacleBase
    {
        [SerializeField] private Transform wreckingBall;
        [SerializeField] private float maxAngle;
        [SerializeField] private float duration;
        
        
        

        private void Start()
        {

            var sequence = DOTween.Sequence();
            var firstAngle = (Random.Range(0, 100) % 2 == 0 ? -1 : 1) * maxAngle;
            var endValue = new Vector3(0, 0, firstAngle);
            wreckingBall.rotation = Quaternion.Euler(-endValue);
            sequence.Append(wreckingBall.DORotate(endValue, duration / 2f).SetEase(Ease.InOutCubic));
            sequence.Append(wreckingBall.DORotate(-endValue, duration / 2f).SetEase(Ease.InOutCubic));

            sequence.SetLoops(-1, LoopType.Restart);
            sequence.Play();
        }

        public override void Interact(Baby baby)
        {
            base.Interact(baby);
            baby.OnObstacleHit();
            
            DOTween.Kill(baby.Model.GetInstanceID());
            var directionX = baby.Model.InverseTransformDirection(baby.Model.position - transform.position).x;
            baby.Model.DOLocalMoveX(directionX, 0.3f).SetEase(Ease.OutElastic).SetId(baby.Model.GetInstanceID());
        }
    }
}