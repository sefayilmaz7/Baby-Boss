using System;
using Core;
using EasyButtons;
using Managers;
using ScriptableObjects;
using UnityEngine;

namespace MonoObjects
{
    public class BabyPose : MonoBehaviour
    {
        [SerializeField] private BabyModel babyModel;
        [SerializeField] private Animator animator;
        
        private void Start()
        {
            transform.forward = (-BabyManager.Instance.GetTangent(transform.position));
        }


        [Button("Select")]
        public void Select(ColorPalate palate)
        {
            babyModel.GainBodyPart(palate.type, palate);    
            babyModel.Animate(AnimationVariables.Ending);
        }

        public void Animate(int animation)
        {
            babyModel.Animate(animation);
        }
    }
}