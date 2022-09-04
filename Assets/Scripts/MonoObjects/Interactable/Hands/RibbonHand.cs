using Core.Forms.StyleForms;
using MonoObjects.Interactable.Core;
using ScriptableObjects;
using UnityEngine;
using UnityEngine.Serialization;

namespace MonoObjects.Interactable.Hands
{
    public class RibbonHand : HandBase
    {
        [FormerlySerializedAs("ribbonStyle")] [SerializeField] private RibbonStyle style;
        
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
            if(genderSetting == baby.babyModel.GenderSetting || genderSetting == GenderSetting.Both)
                baby.GainForm(style);
        }
    }
}