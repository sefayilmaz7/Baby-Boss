using System;
using MonoObjects;
using UnityEngine;

namespace Core.Forms.StateForms
{
    [Serializable]
    public class CrawlingState : GrowthFormBase
    {
        public override void Add(Baby baby)
        {
            base.Add(baby);
            baby.babyModel.Animate(AnimationVariables.Crawl);
        }

        public override void Remove(Baby baby)
        {
            base.Remove(baby);
            baby.CheckForms();    
        }
        public override Type Type()
        {
            return typeof(CrawlingState);
        }
    }
}