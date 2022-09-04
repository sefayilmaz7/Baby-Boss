using System;
using System.Collections.Generic;
using Core;
using EasyButtons;
using ScriptableObjects;
using UnityEngine;
using UnityEngine.UI;

namespace MonoObjects
{
    public class MaterialModifier : MonoBehaviour
    {
        [SerializeField] private ModifyData[] modifyData;
        
        private void Awake()
        {
            UpdateMesh();
        }

        [Button("UpdateMesh")]
        public void UpdateMesh()
        {
            foreach (var data in modifyData)
            {
                foreach (var meshRenderer in data.MeshRenderers)
                {
                    var propertyBlock = new MaterialPropertyBlock();
                    meshRenderer.GetPropertyBlock(propertyBlock, data.materialIndex);
                    propertyBlock.SetTexture(PropertyBlockNames.BabyTexture, data.ColorPalate.GetTexture());
                    propertyBlock.SetColor(PropertyBlockNames.BabyColor, data.ColorPalate.GetColor());
                    meshRenderer.SetPropertyBlock(propertyBlock, data.materialIndex);
                }

                foreach (var image in data.images)
                {
                    image.color = data.ColorPalate.GetColor();
                }
            }

        }

        public void SetMaterialProperties(ColorPalate colorPalate)
        {
            if (modifyData.Length == 0)
            {
                return;
            }
            
            modifyData[0].ColorPalate.colors = (Color[]) colorPalate.colors.Clone();
            modifyData[0].ColorPalate.colorToPick = colorPalate.colorToPick;
            modifyData[0].ColorPalate.texture = colorPalate.texture;
            modifyData[0].ColorPalate.type = colorPalate.type;
            modifyData[0].ColorPalate.name = colorPalate.type.ToString();

            UpdateMesh();
        }

        public ColorPalate GetMaterialProperties()
        {
            return modifyData[0].ColorPalate;
        }
    }

    [Serializable]
    public class ModifyData
    {
        public Renderer[] MeshRenderers;
        public Image[] images;
        public int materialIndex = 0;
        public ColorPalate ColorPalate;
    }
}
