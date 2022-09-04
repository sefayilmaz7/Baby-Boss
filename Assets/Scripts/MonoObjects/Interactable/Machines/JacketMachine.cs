using System;
using Core.Forms.StyleForms;
using MonoObjects.Interactable.Core;
using ScriptableObjects;
using UnityEngine;

namespace MonoObjects.Interactable.Machines
{
    public class JacketMachine : MachineBase
    {
        [SerializeField] private JacketStyle jacketStyle;

        public override MaterialModifier UpdateMaterialModifier()
        {
            base.UpdateMaterialModifier();   
            robotArm.UpdateDisplay(jacketStyle.GetPalate());

            materialModifier.SetMaterialProperties(jacketStyle.GetPalate());
            return base.UpdateMaterialModifier();

        }
        
        public override void GetPalate()
        {
            jacketStyle.UpdateColorPalate(ColorPalate.CreateInstance(gameColorPalate.GetPalate(bodyPart)));
            materialModifier.SetMaterialProperties(jacketStyle.GetPalate());
        }
        
        public override void Interact(Baby baby)
        {
            base.Interact(baby);
            baby.GainForm(jacketStyle);
        }
    }
}