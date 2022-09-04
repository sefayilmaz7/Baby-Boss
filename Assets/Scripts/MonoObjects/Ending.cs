using System;
using System.Collections.Generic;
using Core;
using DG.Tweening;
using DG.Tweening.Core;
using EasyButtons;
using Managers;
using UnityEngine;

namespace MonoObjects
{
    public class Ending : MonoBehaviour
    {
        [SerializeField] public Transform pivot;
        [SerializeField] private List<Vector3> positions;
        [SerializeField] private float period;
        [SerializeField] private float amplitude;
        private List<Baby> babies;
        private bool initialized = false;

        private void Start()
        {
            BabyManager.Instance.ending = this;
        }

        [Button("Init")]
        public void InitPositions(int babyCount)
        {
            babies = new List<Baby>();
            positions = new List<Vector3>();
            for (int i = -babyCount / 2; i < babyCount / 2 + (babyCount % 2 == 0 ? 0 : 1); i++)
            {
                var z = -Mathf.Abs(Mathf.Sin(i * period) * amplitude);

                positions.Add(new Vector3(i, 0, z));
            }

            initialized = true;
        }

        public Vector3 GetBabyPosition(Baby baby, int index)
        {
            babies.Add(baby);
            var pivotPosition = pivot.position + positions[index];

            baby.Model.DOMove(pivotPosition, 1f).OnComplete(() =>
            {
                baby.babyModel.Animate(AnimationVariables.Ending);
            }).OnStart((() =>
            {
                baby.babyManager.AddPoint(20, baby.Model.position);
            }));
            var lookVector = (pivotPosition - baby.Model.position).normalized;
            baby.Model.DOLookAt(lookVector, 0.8f).OnComplete(() =>
            {
                baby.Model.DOLookAt(pivot.position.AddZ(-3f), 0.3f);
            });
            
            return pivotPosition;

        }

        private float Remap(float value, float from1, float to1, float from2, float to2)
        {
            return (value - from1) / (to1 - from1) * (to2 - from2) + from2;
        }

        public float GetMagnitude(int index)
        {
            return positions[index].magnitude;
        }

        public void Finish()
        {
            var lastTween = babies[0].Model.DOLocalMoveX(babies[0].Model.localPosition.x, 0f);
            int index = 0;
            Debug.Log(babies.Count);
            foreach (var baby in babies)
            {
                lastTween = baby.Model.DOMove(transform.position, 2f).OnStart(() =>
                {
                    baby.Model.DOLookAt(transform.position, 0.2f);
                    baby.babyModel.Animate(AnimationVariables.Walk);
                }).SetDelay((index + 1) * 0.45f);

                index++;
            }

            lastTween.OnStart(() => { GameManager.Instance.CompleteLevel(); });
        }
    }
}