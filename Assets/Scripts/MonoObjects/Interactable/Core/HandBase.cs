using System;
using Core.Forms;
using EasyButtons;
using ScriptableObjects;
using UnityEngine;

namespace MonoObjects.Interactable.Core
{
    public class HandBase : Interactable
    {
        [SerializeField] protected GenderSetting genderSetting;
        [SerializeField] protected GameColorPalate gameColorPalate;
        [SerializeField] protected BodyPart bodyPart = BodyPart.Body;
        [SerializeField] protected MaterialModifier materialModifier;
        [SerializeField] protected RobotArm robotArm;


        private void Start()
        {
            UpdateMaterialModifier();
        }

        public override void Interact(Baby baby)
        {
            var targetPivot = baby.babyModel.GetPartTransform(bodyPart);

            robotArm.MoveArm(targetPivot);
            baby.React();
        }

        [Button("UpdateMaterialModifier")]
        public virtual MaterialModifier UpdateMaterialModifier()
        {
            return materialModifier;
        }

        [Button("GetPalate")]
        public virtual void GetPalate()
        {
        }
    }
}