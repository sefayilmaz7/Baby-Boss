using System;
using Core;
using Core.Forms.StateForms;
using Core.Forms.StyleForms;
using MonoObjects.Interactable.Core;
using UnityEngine;

namespace MonoObjects.Interactable.Gates
{
    public class AgeGate : GateBase
    {
        [SerializeField] private MovementState movementState;
        [SerializeField] private BabyPose babyPose;

        private void Start()
        {
            babyPose?.Animate(AnimationVariables.Walk);
        }

        public override void Interact(Baby baby)
        {
            baby.GainForm(movementState);
            baby.RemoveForm(typeof(PacifierStyle));
            base.Interact(baby);
        }
    }
}