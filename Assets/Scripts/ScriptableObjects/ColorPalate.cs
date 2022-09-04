using System;
using FluffyUnderware.DevTools;
using MonoObjects;
using UnityEngine;

namespace ScriptableObjects
{
    [Serializable]
    public class ColorPalate
    {
        [HideInInspector] public string name = "";
        [SerializeField]public BodyPart type = BodyPart.Body;
        [SerializeField]public Color[] colors;
        [SerializeField]public Texture2D texture;
        [RangeEx(0, "COLORSIZE")]
        [SerializeField]public int colorToPick;

        private int COLORSIZE => colors.Length - 1;
        
        public Color GetColor()
        {
            return colors[colorToPick];
        }

        public Color GetColor(int index)
        {
            return colors[index];
        }
        public Texture2D GetTexture()
        {
            return texture != null ? texture : Texture2D.whiteTexture;
        }
        
        private ColorPalate(BodyPart type, Color[] colors)
        {
            name = type + " Palate";
            this.colors = colors;
            this.type = type;
            
        }
        
        private ColorPalate(BodyPart type, Color[] colors, Texture2D texture, int colorPalateColorToPick)
        {
            name = type + " Palate";
            this.colors = (Color[]) colors.Clone();
            this.type = type;
            this.texture = texture;
            colorToPick = colorPalateColorToPick;
        }

        public static ColorPalate CreateInstance(BodyPart type, Color[] colors)
        {
            return new ColorPalate(type, colors);
        }
        
        public static ColorPalate CreateInstance(ColorPalate colorPalate)
        {
            return new ColorPalate(colorPalate.type, colorPalate.colors, colorPalate.texture, colorPalate.colorToPick);
        }
    }
}