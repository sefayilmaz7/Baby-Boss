using System.Collections;
using DG.Tweening;
using ScriptableObjects;
using UnityEngine;

namespace MonoObjects.Interactable
{
    public class RobotArm : MonoBehaviour
    {
        [SerializeField] private Transform controller;
        [SerializeField] private BabyPose babyPose;
        
        [SerializeField] private float speed;
        [SerializeField] private float timeToComplete = 0.6f;
        
        [SerializeField] private Vector3 defaultPosition;
        [SerializeField] private Quaternion defaultRotation;
        private Transform currentTarget;
        private Vector3 GetTargetPos => currentTarget.position;
        private Coroutine moveCor;
        private void Awake()
        {
            defaultPosition = controller.position;
            defaultRotation = controller.rotation;
        }

        public void MoveArm(Transform targetPivot)
        {
            // DOTween.Kill(GetInstanceID());
            // var sequence = DOTween.Sequence().SetId(GetInstanceID());
            // currentTarget = targetPivot;
            // sequence.Append(controller.DOMove(GetTargetPos, 0.3f));
            // sequence.Append(controller.DOMove(defaultPosition, 0.6f));

            if (moveCor != null)
            {
                StopCoroutine(moveCor);
                moveCor = null;
            }
            
            moveCor = StartCoroutine(nameof(MoveTo), targetPivot);
        }

        private IEnumerator MoveTo(Transform target)
        {
            var timePassed = 0f;
            var distance = Vector3.Distance(target.position, controller.position);
            while (distance > 0.1f && timePassed < timeToComplete)
            {
                controller.position = Vector3.Lerp(controller.position, target.position, speed * 2f * Time.fixedDeltaTime);
                var controllerDirection = (target.position - controller.position).normalized;
                controller.rotation = Quaternion.Lerp(controller.rotation, Quaternion.LookRotation(-controllerDirection), speed * 2f * Time.fixedDeltaTime);
                yield return new WaitForFixedUpdate();
                distance = Vector3.Distance(target.position, controller.position);
                timePassed += Time.fixedDeltaTime;
                if (distance < 0.3f)
                {
                    break;
                }
            }

            timePassed = 0;
            distance = Vector3.Distance(defaultPosition, controller.position);
            while (distance > 0.1f)
            {
                controller.position = Vector3.Lerp(controller.position, defaultPosition, speed * Time.fixedDeltaTime);
                controller.rotation = Quaternion.Lerp(controller.rotation, defaultRotation, speed * 2f * Time.fixedDeltaTime);
                yield return new WaitForFixedUpdate();
                distance = Vector3.Distance(defaultPosition, controller.position);
                timePassed += Time.fixedDeltaTime;
            }
        }

        public void UpdateDisplay(ColorPalate colorPalate)
        {
            babyPose.Select(colorPalate);
        }
    }
}