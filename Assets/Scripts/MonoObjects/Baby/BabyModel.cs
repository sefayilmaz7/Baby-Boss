using System;
using System.Collections.Generic;
using Core;
using DG.Tweening;
using EasyButtons;
using ScriptableObjects;
using UnityEngine;
using UnityEngine.Rendering;

namespace MonoObjects
{
    [Serializable]
    public enum BodyPart
    {
        Body,
        UnderWare,
        Shoes,
        Pants,
        Shirt,
        Jacket,
        Tie,
        Ribbon,
        Hair,
        Pacifier,
        Brush
    }

    public enum GenderSetting
    {
        Both,
        Boy,
        Girl
    }
    public class BabyModel : MonoBehaviour
    {
        [SerializeField] private GameColorPalate gameColorPalate;
        [SerializeField] private BodyPartData[] bodyPartsData;
        [SerializeField] private GenderSetting genderSetting;
        [SerializeField] private Animator animator;
        [SerializeField] private RobotPivots[] robotPivots;
        
        public GenderSetting GenderSetting => genderSetting;


        public void GainBodyPart(BodyPart partType, ColorPalate stylePalate)
        {
            foreach (var bodyPartData in bodyPartsData)
            {
                if(bodyPartData.partType == partType)
                {
                    bodyPartData.GainPart(stylePalate, gameColorPalate, genderSetting);
                }
            }
        }
        
        public void LoseBodyPart(BodyPart partType)
        {
            foreach (var bodyPartData in bodyPartsData)
            {
                if(bodyPartData.partType == partType)
                {
                    bodyPartData.LosePart(genderSetting, gameColorPalate.GetPalate(partType));
                }
            } 
        }

        [Button("Update")]
        public void UpdateBody()
        {
            foreach (var bodyPartData in bodyPartsData)
            {
                bodyPartData.Update();
                InitBodyPart(bodyPartData);
            }
        }

        private void Start()
        {
            foreach (var bodyPartData in bodyPartsData)
            {
                InitBodyPart(bodyPartData);
            }
        }

        private void InitBodyPart(BodyPartData bodyPartData)
        {
            if (gameColorPalate == null) return;

            if (bodyPartData.partType == BodyPart.UnderWare)
            {
                foreach (var meshRenderer in bodyPartData.meshRenderers)
                {
                    var propertyBlock = new MaterialPropertyBlock();
                    meshRenderer.GetPropertyBlock(propertyBlock);
                    var colorPalate = gameColorPalate.GetPalate(BodyPart.UnderWare);
                    propertyBlock.SetTexture(PropertyBlockNames.BabyTexture, colorPalate.GetTexture());
                    propertyBlock.SetColor(PropertyBlockNames.BabyColor, colorPalate.GetColor());
                    meshRenderer.SetPropertyBlock(propertyBlock);
                }
            }

            if (bodyPartData.partType == BodyPart.Body)
            {
                foreach (var meshRenderer in bodyPartData.meshRenderers)
                {
                    var propertyBlock = new MaterialPropertyBlock();
                    meshRenderer.GetPropertyBlock(propertyBlock);
                    var colorPalate = gameColorPalate.GetPalate(BodyPart.Body);
                    propertyBlock.SetTexture(PropertyBlockNames.BabyTexture, colorPalate.GetTexture());
                    meshRenderer.SetPropertyBlock(propertyBlock);
                }
            }
            
            if (bodyPartData.partType == BodyPart.Hair)
            {
                foreach (var meshRenderer in bodyPartData.meshRenderers)
                {
                    var colorPalate = gameColorPalate.GetPalate(BodyPart.Hair);
                    var propertyBlock = new MaterialPropertyBlock();
                    meshRenderer.GetPropertyBlock(propertyBlock);
                    propertyBlock.SetTexture(PropertyBlockNames.BabyTexture, colorPalate.GetTexture());
                    propertyBlock.SetColor(PropertyBlockNames.BabyColor, colorPalate.colors[Mathf.Max(0,(int)genderSetting - 1)]);
                    meshRenderer.SetPropertyBlock(propertyBlock);
                }
            }
            
            if (bodyPartData.partType == BodyPart.Ribbon)
            {
                foreach (var meshRenderer in bodyPartData.meshRenderers)
                {
                    var colorPalate = gameColorPalate.GetPalate(BodyPart.Ribbon);
                    var propertyBlock = new MaterialPropertyBlock();
                    meshRenderer.GetPropertyBlock(propertyBlock);
                    propertyBlock.SetTexture(PropertyBlockNames.BabyTexture, colorPalate.GetTexture());
                    propertyBlock.SetColor(PropertyBlockNames.BabyColor, colorPalate.colors[Mathf.Max(0,(int)genderSetting - 1)]);
                    meshRenderer.SetPropertyBlock(propertyBlock);
                }
            }
            
            if (bodyPartData.partType == BodyPart.Shoes)
            {
                var colorPalate = gameColorPalate.GetPalate(genderSetting);

                foreach (var meshRenderer in bodyPartData.meshRenderers)
                {
                    var propertyBlock = new MaterialPropertyBlock();
                    var propertyBlock1 = new MaterialPropertyBlock();
                    colorPalate = gameColorPalate.GetPalate(BodyPart.Shoes);
                    
                    meshRenderer.GetPropertyBlock(propertyBlock,0);
                    meshRenderer.GetPropertyBlock(propertyBlock1,1);

                    propertyBlock1.SetTexture(PropertyBlockNames.BabyTexture, colorPalate.GetTexture());
                    propertyBlock1.SetColor(PropertyBlockNames.BabyColor, colorPalate.GetColor());

                    propertyBlock.SetTexture(PropertyBlockNames.BabyTexture, colorPalate.GetTexture());
                    propertyBlock.SetColor(PropertyBlockNames.BabyColor, colorPalate.GetColor());
                    
                    meshRenderer.SetPropertyBlock(propertyBlock, 0);
                    meshRenderer.SetPropertyBlock(propertyBlock1, 1);
                }
            }

        }


        private int lastHash = 0;
        public void Animate(int animationHash)
        {
            if(lastHash != 0)
                animator.ResetTrigger(lastHash);
            animator.SetTrigger(animationHash);
            lastHash = animationHash;
        }

        public void SetBool(int variableName,bool value)
        {
            animator.SetBool(variableName, value);
        }
        
        public void SetCycleOffset(float value)
        {
            animator.SetFloat("CycleOffset", value);
        }

        public Transform GetPartTransform(BodyPart part)
        {
            var pivot = robotPivots[0];
            foreach (var robotPivot in robotPivots)
            {
                if (robotPivot.partType == part)
                {
                    pivot = robotPivot;
                }
            }

            Animate(pivot.partPivot);
            return pivot.partPivot[0];
        }
        
        private void Animate(Transform[] pivots)
        {
            if (pivots.Length == 0) return;
            DOTween.Kill(pivots[0].GetInstanceID());

            Debug.Log(pivots.Length);
            foreach (var pivot in pivots)
            {
                pivot.DOPunchScale(Vector3.one * 0.8f, 0.4f, 3, 0f)
                    .SetEase(Ease.InOutElastic)
                    .SetId(pivots[0].GetInstanceID()).OnKill((() =>
                    {
                        pivot.localScale = Vector3.one;
                    })).SetDelay(0.4f);
            }
        }
    }

    [Serializable]
    public struct RobotPivots
    {
        public BodyPart partType;
        public Transform[] partPivot;
    }
}