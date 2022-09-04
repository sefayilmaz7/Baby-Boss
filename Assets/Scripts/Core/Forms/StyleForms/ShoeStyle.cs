using System;
using MonoObjects;

namespace Core.Forms.StyleForms
{
    [Serializable]

    public class ShoeStyle : StyleFormBase
    {
        public override void Add(Baby baby)
        {
            base.Add(baby);
            baby.babyModel.GainBodyPart(stylePalate.type, stylePalate);
        }

        public override void Remove(Baby baby)
        {
            base.Remove(baby);
            baby.babyModel.LoseBodyPart(stylePalate.type);
        }
        
        public override Type Type()
        {
            return typeof(ShoeStyle);
        }
        
        public override float GetValue()
        {
            return 10f;
        }
    }
}