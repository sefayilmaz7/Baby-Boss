using System;
using Core.Forms;
using DG.Tweening;
using EasyButtons;
using ScriptableObjects;
using TMPro;
using UnityEngine;

namespace MonoObjects.Interactable.Core
{
    public class GateBase : Interactable
    {
        // [SerializeField] private GameColorPalate gameColorPalate;
        // [SerializeField] private TextMeshProUGUI gateInfo;
        // [SerializeField] private string gateText;

        public override void Interact(Baby baby)
        {
            baby.React();
            if (!baby.isLead) return;

            baby.canMove = true;
            baby.babyManager.GateCameraStart();
        }

        public override void InteractionOver(Baby baby)
        {
            base.InteractionOver(baby);
            if (!baby.isLead) return;
            
            baby.canMove = false;
            baby.babyManager.GateCameraEnd();
        }
    }
}