using System.Collections.Generic;
using MonoObjects;
using UnityEngine;

namespace ScriptableObjects
{
    [CreateAssetMenu(fileName = "GameColorPalate", menuName = "Create Game Color Palate")]
    public class GameColorPalate : ScriptableObject
    {
        public List<ColorPalate> colorPalates;
        public ColorPalate shoesBoy;
        public ColorPalate shoesGirl;

        public BodyPart partToAdd = BodyPart.Body;
        
        [EasyButtons.Button("Add Color Palate")]
        private void AddColorPalate()
        {
            colorPalates.Add(ColorPalate.CreateInstance(partToAdd, new [] {Color.white}));
        }

        public ColorPalate GetPalate(BodyPart bodyPartType)
        {
            ColorPalate colorPalateFound = null;
            foreach (var colorPalate in colorPalates)
            {
                colorPalateFound = colorPalate.type == bodyPartType ? colorPalate : colorPalateFound;
            }
            return colorPalateFound;
        }
        
        public ColorPalate GetPalate(GenderSetting gender)
        {
            
            return gender == GenderSetting.Boy ? shoesBoy : shoesGirl;
        }
    }
}