using System;
using System.Collections.Generic;
using System.Linq;
using Core;
using Core.Forms;
using Core.Forms.StateForms;
using DG.Tweening;
using Managers;
using UnityEngine;

namespace MonoObjects
{
    public partial class Baby
    {
        [SerializeField] private float punchScale;
        [SerializeField] private float duration;
        [SerializeField] private int vibrato;
        [SerializeField] private float elasticity;
        [SerializeField] private Ease punchEase;
        
        public void AddNew()
        {
            babyManager.AddNewBaby();
        } 
        
        public void AddToGroup(Baby baby)
        {
            babyManager.AddToGroup(baby);
        }

        public void RemoveFromGroup(bool returnToPool)
        {
            ObjectPoolManager.Instance.GetFromPool<ObstacleHitParticle>().Init(Model);

            babyManager.RemoveFromGroup(this, returnToPool);
        }

        public void OnObstacleHit()
        {
            ObjectPoolManager.Instance.GetFromPool<ObstacleHitParticle>().Init(Model);
            RemoveForm();
        }
        
        public void GainForm(FormBase form)
        {
            if(forms[form.Type()] != null)
                form.CopyFrom(forms[form.Type()]);
            forms[form.Type()] = form;
            form.Add(this);
        }

        private void RemoveForm()
        {
            FormBase formToRemove = null;
            Type type = typeof(CrawlingState);
            foreach (var form in forms.Reverse())
            {
                if (form.Value != null)
                {
                    formToRemove = form.Value;
                    type = form.Value.GetType();
                }
            }

            if (formToRemove == null) return;
            
            formToRemove.Remove(this);
            forms[formToRemove.Type()] = null;
            Debug.Log(formToRemove.ToString());
        }
        
        public void RemoveForm(Type typeToRemove)
        {
            FormBase formToRemove = forms[typeToRemove];

            formToRemove?.Remove(this);
        }

        public void CheckForms()
        {
            if (forms[typeof(MovementState)] != null)
            {
                return;
            }

            RemoveFromGroup(true);
        }


        public void React()
        {
            DOTween.Kill(model.GetInstanceID());
            model.DOPunchScale(Vector3.one * punchScale, duration, vibrato, elasticity)
                .SetEase(punchEase)
                .SetId(model.GetInstanceID()).OnKill((() =>
                {
                    model.localScale = Vector3.one;
                }));
        }
    }
}