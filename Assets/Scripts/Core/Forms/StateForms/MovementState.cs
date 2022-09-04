using System;
using MonoObjects;
using UnityEngine;

namespace Core.Forms.StateForms
{
    [Serializable]
    public class MovementState : GrowthFormBase
    {

        public override void Add(Baby baby)
        {
            base.Add(baby);
            baby.babyModel.Animate(AnimationVariables.Walk);
            baby.RemoveForm(typeof(CrawlingState));
        }

        public override void Remove(Baby baby)
        {
            base.Remove(baby);

            baby.GainForm(new CrawlingState());
        }
        
        public override Type Type()
        {
            return typeof(MovementState);
        }
        
        public override float GetValue()
        {
            return 10f;
        }
    }
}