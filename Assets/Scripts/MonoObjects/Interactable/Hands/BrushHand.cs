using Core.Forms.StyleForms;
using MonoObjects.Interactable.Core;
using ScriptableObjects;
using UnityEngine;

namespace MonoObjects.Interactable.Hands
{
    public class BrushHand : HandBase
    {
        [SerializeField] private BrushStyle style;
        
        public override MaterialModifier UpdateMaterialModifier()
        {
            base.UpdateMaterialModifier();
            robotArm.UpdateDisplay(style.GetPalate());

            materialModifier.SetMaterialProperties(style.GetPalate());
            return materialModifier;
        }
        
        public override void GetPalate()
        {
            style.UpdateColorPalate(ColorPalate.CreateInstance(gameColorPalate.GetPalate(bodyPart)));
            materialModifier.SetMaterialProperties(style.GetPalate());
        }
        
        public override void Interact(Baby baby)
        {
            base.Interact(baby);
            baby.GainForm(style);
        }
    }
}