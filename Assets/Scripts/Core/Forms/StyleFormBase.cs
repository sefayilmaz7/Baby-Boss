using System;
using MonoObjects;
using ScriptableObjects;
using UnityEngine;

namespace Core.Forms
{
    [Serializable]
    public class StyleFormBase : FormBase
    {
        [SerializeField] protected ColorPalate stylePalate;
        public override void Add(Baby baby)
        {
            baby.babyModel.GainBodyPart(stylePalate.type, stylePalate);
        }

        public override void Remove(Baby baby)
        { 
            baby.babyModel.LoseBodyPart(stylePalate.type);
        }

        public override void CopyFrom(FormBase formBase)
        {
        }

        public override Type Type()
        {
            Debug.Log("BaseClass");
            return typeof(StyleFormBase);
        }

        public void UpdateColorPalate(ColorPalate colorPalate)
        {
            stylePalate.colors = (Color[]) colorPalate.colors.Clone();
            stylePalate.colorToPick = colorPalate.colorToPick;
            stylePalate.texture = colorPalate.texture;
            stylePalate.type = colorPalate.type;
            stylePalate.name = colorPalate.type.ToString();
        }

        public ColorPalate GetPalate()
        {
            return stylePalate;
        }

        public override float GetValue()
        {
            return 0f;
        }
    }
}