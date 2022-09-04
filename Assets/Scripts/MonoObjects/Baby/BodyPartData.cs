using System;
using System.Collections.Generic;
using Core;
using DG.Tweening;
using ScriptableObjects;
using UnityEngine;

namespace MonoObjects
{
    [Serializable]
    public class BodyPartData
    {
        [HideInInspector]public string name = "";
        public bool togglePivots = true;
        public BodyPart partType;
        public Transform[] pivots;
        public Transform[] OnGain;
        public Transform[] OnLose;
        [ReadOnly] public List<Renderer> meshRenderers;
        
        public void Update()
        {
            name = partType.ToString();

            meshRenderers = new List<Renderer>();

            foreach (var pivot in pivots)
            {
                if (!pivot.TryGetComponent(out Renderer skinnedMeshRenderer))
                    break;
                
                meshRenderers.Add(skinnedMeshRenderer);
            }
        }

        public void LosePart(GenderSetting genderSetting, ColorPalate colorPalate)
        {
            if(togglePivots)
            {
                foreach (var pivot in pivots)
                {
                    pivot.gameObject.SetActive(false);
                }

                foreach (var transform in OnLose)
                {
                    transform.gameObject.SetActive(true);
                }
            }

            if (partType != BodyPart.Hair) return;
            
            
            foreach (var meshRenderer in meshRenderers)
            {
                var propertyBlock = new MaterialPropertyBlock();
                meshRenderer.GetPropertyBlock(propertyBlock,0);
                propertyBlock.SetTexture(PropertyBlockNames.BabyTexture, colorPalate.GetTexture());
                propertyBlock.SetColor(PropertyBlockNames.BabyColor, colorPalate.colors[genderSetting == GenderSetting.Boy ? 0 : 1]);
                meshRenderer.SetPropertyBlock(propertyBlock, 0);
            }

        }

        

        public void GainPart(ColorPalate stylePalate, GameColorPalate gameColorPalate, GenderSetting genderSetting)
        {
            if(togglePivots)
            {
                foreach (var pivot in pivots)
                {
                    pivot.gameObject.SetActive(true);
                }

                foreach (var transform in OnGain)
                {
                    transform.gameObject.SetActive(false);
                }
            }     
            
            if (partType == BodyPart.Brush) return;

            if (partType == BodyPart.Shoes)
            {
                var colorPalate = gameColorPalate.GetPalate(genderSetting);

                foreach (var meshRenderer in meshRenderers)
                {
                    var propertyBlock = new MaterialPropertyBlock();
                    var propertyBlock1 = new MaterialPropertyBlock();
                    
                    meshRenderer.GetPropertyBlock(propertyBlock,1);
                    meshRenderer.GetPropertyBlock(propertyBlock1,0);

                    propertyBlock.SetTexture(PropertyBlockNames.BabyTexture, colorPalate.GetTexture());
                    propertyBlock.SetColor(PropertyBlockNames.BabyColor, colorPalate.GetColor());

                    propertyBlock1.SetTexture(PropertyBlockNames.BabyTexture, stylePalate.GetTexture());
                    propertyBlock1.SetColor(PropertyBlockNames.BabyColor, stylePalate.GetColor());
                    
                    meshRenderer.SetPropertyBlock(propertyBlock, 1);
                    meshRenderer.SetPropertyBlock(propertyBlock1, 0);
                }
                
                return;
            }
            
            
            if (partType == BodyPart.Ribbon)
            {

                foreach (var meshRenderer in meshRenderers)
                {
                    var propertyBlock = new MaterialPropertyBlock();
                    
                    meshRenderer.GetPropertyBlock(propertyBlock,0);

                    propertyBlock.SetTexture(PropertyBlockNames.BabyTexture, stylePalate.GetTexture());
                    propertyBlock.SetColor(PropertyBlockNames.BabyColor, stylePalate.GetColor(genderSetting == GenderSetting.Boy ? 0 : 1));
                    
                    meshRenderer.SetPropertyBlock(propertyBlock, 0);
                }
                
                return;
            }
            

            foreach (var meshRenderer in meshRenderers)
            {
                var propertyBlock = new MaterialPropertyBlock();
                meshRenderer.GetPropertyBlock(propertyBlock,0);
                propertyBlock.SetTexture(PropertyBlockNames.BabyTexture, stylePalate.GetTexture());
                propertyBlock.SetColor(PropertyBlockNames.BabyColor, stylePalate.GetColor());
                meshRenderer.SetPropertyBlock(propertyBlock, 0);
            }
        }
    }
}