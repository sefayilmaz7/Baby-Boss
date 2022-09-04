using System;
using System.Collections.Generic;
using Core;
using Core.Forms.StateForms;
using Core.Forms.StyleForms;
using DG.Tweening;
using FluffyUnderware.Curvy;
using FluffyUnderware.Curvy.Controllers;
using Managers;
using UnityEngine;
using UnityEngine.Events;

namespace MonoObjects
{
    public partial class Baby : MonoPooled
    {
        [SerializeField, ReadOnly] private GenderSetting genderSetting;
        
        [SerializeField] private SplineController splineController;
        
        public SplineController SplineController => splineController;
        [SerializeField] public BabyManager babyManager;
        [SerializeField] private Transform model;
        [SerializeField] private Rigidbody rigidBody;
        [SerializeField] private Rigidbody parentRigidBody;
        [SerializeField] public BabyModel babyModel;
        
        public Transform Model => model;
        [SerializeField] private float speed;
        
        [SerializeField] public BabyCollision babyCollision;
        public bool isLead;
        public bool canMove;
        private float RoadSize = 2;
        public Dictionary<Type, FormBase> forms;
        private CurvySpline Spline;

        public void Initialize(BabyManager manager, CurvySpline spline, float babyOffset)
        {
            forms = new Dictionary<Type, FormBase>()
            {
                {typeof(PacifierStyle), null},
                {typeof(RibbonStyle), null},
                {typeof(PantsStyle), null},
                {typeof(ShirtStyle), null},
                {typeof(JacketStyle), null},
                {typeof(ShoeStyle), null},
                {typeof(TieStyle), null},
                {typeof(HairStyle), null},
                {typeof(MovementState), null},
                {typeof(CrawlingState), new CrawlingState()},
            };
            forms[typeof(CrawlingState)].Add(this);
            
            
            Spline = spline;
            babyManager = manager;
            UpdateBabyPositionInGroup(babyOffset);
            splineController.Spline = spline;
            splineController.PositionMode = CurvyPositionMode.WorldUnits;
            splineController.Position = babyOffset;
            splineController.Speed = speed;
            splineController.OnEndReached.AddListenerOnce(OnEndReached);
            babyCollision.UpdateGroupInfo(true);
            babyCollision.SetActive(true);
        }

        private void OnEndReached(CurvySplineMoveEventArgs e)
        {
            splineController.Speed = 0;
            splineController.enabled = false;
            babyManager.EndReached(this);
        }

        public override MonoPooled Init()
        {
            babyCollision.SetActive(false);
            return base.Init();
        }

        public float GetFormValue()
        {
            var value = 0f;
            foreach (var form in forms)
            {
                if (form.Value != null)
                {
                    value +=form.Value.GetValue();
                }
            }

            return value;
        }

        private void LateUpdate()
        {
            if (isOnBridge) return;

            var abs = Mathf.Abs(model.localPosition.x);
            babyModel.SetBool(AnimationVariables.MirrorWalk, !(Mathf.Sign(model.localPosition.x) < 0));
            babyModel.SetBool(AnimationVariables.Caution, ((RoadSize - abs) < 0.3f));
        }

        public void Move(Vector3 currentMovement)
        {
            // movement = currentMovement;
            if (canMove) return;
            
            var movementVector = (currentMovement.WithY(0).WithZ(0)) * Time.fixedDeltaTime;
            model.Translate(movementVector, Space.Self);
            if (Mathf.Abs(model.localPosition.x) >= RoadSize)
            {
                model.localPosition = model.localPosition.WithX(Mathf.Sign(model.localPosition.x) * RoadSize);
            }
        }

        public bool isOnBridge;
        
        public void SetLead(bool value)
        {
            isLead = value;
        }

        public override void ReturnToPool()
        {
            base.ReturnToPool();
            babyCollision.UpdateGroupInfo(false);
            DOTween.Kill(model.GetInstanceID());
            model.localScale = Vector3.one;
            model.rotation = Quaternion.identity;
        }

        public void UpdateBabyPositionInGroup(float position)
        {
            splineController.AbsolutePosition = position;
        }

        public float GetAbsolutePos()
        {
            return splineController.AbsolutePosition;
        }

        public Vector3 HorizontalDifference(Baby baby)
        {
            // var horizontalDifference = ((LocalHorizontal - baby.LocalHorizontal));
            var horizontalDifference = model.localPosition - baby.Model.localPosition;
            return horizontalDifference;
        }
    }
}
