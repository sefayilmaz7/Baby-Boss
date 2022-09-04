using System;
using Core;
using Core.Forms.StateForms;
using MonoObjects.Interactable.Core;
using UnityEngine;

namespace MonoObjects.Interactable.Gates
{
    
    public class RejuvenateGate : GateBase
    {
        [SerializeField] private CrawlingState crawlingState;
        [SerializeField] private BabyPose babyPose;

        private void Start()
        {
            babyPose?.Animate(AnimationVariables.Crawl);
        }

        public override void Interact(Baby baby)
        {
            baby.GainForm(crawlingState);
            base.Interact(baby);
        }
    }
}