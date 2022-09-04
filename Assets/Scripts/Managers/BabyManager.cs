using System.Collections;
using System.Collections.Generic;
using Cinemachine;
using DG.Tweening;
using FluffyUnderware.Curvy;
using FluffyUnderware.Curvy.Controllers;
using MonoObjects;
using UnityEngine;

namespace Managers
{
    public class BabyManager : SingletonBehaviour<BabyManager>
    {
        [SerializeField] private CinemachineVirtualCamera cinemachineVirtualCamera;
        [SerializeField] public RoadGenerator roadGenerator;
        [SerializeField] public Ending ending;
        [SerializeField] private ProgressBar progressBar;
        
        private CinemachineComposer cinemachineComponent;
        private CinemachineTransposer cinemachineTransposer;
        
        // [SerializeField] private SplineController cameraController;
        
        [SerializeField] private float cameraOffset;
        [SerializeField] private CurvySpline currentSpline;
        [SerializeField] private float babyOffset;
        [SerializeField] private float babyMoveSpeed;
        [SerializeField] private float incrementalMultiplier = 1f;

        [SerializeField] private float threshold;

        private float defaultTransposerYOffset;
        private Vector3 currentMovement;
        private List<Baby> currentBabies;
        private float currentPercentage;
        private Coroutine updateCor;
        
        protected void Start()
        {
            cinemachineComponent = cinemachineVirtualCamera.GetCinemachineComponent<CinemachineComposer>();
            cinemachineTransposer = cinemachineVirtualCamera.GetCinemachineComponent<CinemachineTransposer>();
            defaultTransposerYOffset = cinemachineTransposer.m_FollowOffset.y;
            
            currentBabies = new List<Baby>();
            currentBabies.Add(GetRandomBaby());
            currentBabies[0].SetLead(true);
        }
        
        
        private Baby GetRandomBaby()
        {
            if (Random.Range(0, 100) % 2 == 0)
                return ObjectPoolManager.Instance.GetFromPool<BabyBoy>();
            
            
            return ObjectPoolManager.Instance.GetFromPool<BabyGirl>();
        }

        protected override void OnLevelStarted()
        {
            base.OnLevelStarted();
            progressBar.gameObject.SetActive(true);
            updateCor = StartCoroutine(nameof(UpdateCoroutine));
            cinemachineVirtualCamera.Follow = currentBabies[0].Model;
            cinemachineVirtualCamera.LookAt = currentBabies[0].Model;
            currentBabies[0].Initialize(this,currentSpline, 0);
        }

        protected override void OnLevelInitialized()
        {
            base.OnLevelInitialized();
            progressBar.gameObject.SetActive(false);

        }

        private IEnumerator UpdateCoroutine()
        {
            while (true)
            {
                yield return new WaitForFixedUpdate();
                
                for (int i = 0; i < currentBabies.Count-1; i++)
                {
                    var distanceBetween = currentBabies[i].HorizontalDifference(currentBabies[i + 1]);

                    if (distanceBetween.magnitude > threshold)
                    {
                        currentBabies[i + 1].Move(distanceBetween * babyMoveSpeed * Mathf.Max(1f,(i+1) * incrementalMultiplier));
                    }
                }

                if (currentBabies.Count == 0) break;

                var currentBaby = currentBabies[currentBabies.Count / 2];
                roadGenerator.IsTurning(currentBaby.GetAbsolutePos(), out PathDirection side, out float currentTurnValue);
                cinemachineComponent.m_TrackedObjectOffset = cinemachineComponent.m_TrackedObjectOffset.WithX(
                    (side == PathDirection.Forward ? 0 : (side == PathDirection.Left ? -1 : 1)) * currentTurnValue * cameraOffset);
            }
        }

        public void Move(Vector3 movement)
        {
            if (currentBabies.Count == 0) return;
            if (updateCor == null) return;


            currentBabies[0].Move(movement);
            currentMovement = movement;
        }

        public void AddToGroup(Baby baby)
        {
            currentBabies.Add(baby);

            if (currentBabies.Count == 0)
            {
                return;
            }

            var absolutePos = currentBabies[Mathf.Max(0,currentBabies.Count - 2)].GetAbsolutePos() + babyOffset;
            // baby.Model.localPosition = currentBabies[currentBabies.IndexOf(baby)-1].Model.localPosition;
            baby.Initialize(this, currentSpline,
                absolutePos);

            baby.babyModel.SetCycleOffset(currentBabies.Count * 0.1f);

            foreach (var currentBaby in currentBabies)
            {
                currentBaby.React();
            }
            // ReArrangeBabies();
        }

        public void RemoveFromGroup(Baby baby, bool returnToPool)
        {
            currentBabies.Remove(baby);
            if(returnToPool)
                baby.ReturnToPool();

            if (currentBabies.Count == 0)
            {
                cinemachineComponent.m_TrackedObjectOffset = Vector3.zero;
                TriggerLevelFinished(false);
                return;
            }
            
            ReArrangeBabies();
        }

        private void ReArrangeBabies()
        {
            var firstBabyPosition = currentBabies[0].GetAbsolutePos();
            var index = 0;
            foreach (var baby in currentBabies)
            {
                baby.UpdateBabyPositionInGroup((index * babyOffset) + firstBabyPosition);
                
                baby.SetLead(index == 0);
                index++;
            }
            
            
            cinemachineVirtualCamera.Follow = currentBabies[0].Model;
            cinemachineVirtualCamera.LookAt = currentBabies[0].Model;
        }

        public void EvaluateBabyUpgrades()
        {
            var formValues = 0f;
            foreach (var baby in currentBabies)
            {
                formValues += baby.GetFormValue();
            }

            currentPercentage = (formValues / Mathf.Max(1, currentBabies.Count))/100f;
            
            progressBar.UpdateProgress(currentPercentage);
        }
        
        public void AddNewBaby()
        {
            AddToGroup(UnityEngine.Random.Range(0, 100) % 2 == 0
                ? (Baby) ObjectPoolManager.Instance.GetFromPool<BabyBoy>()
                : ObjectPoolManager.Instance.GetFromPool<BabyGirl>());
        }

        public void EndReached(Baby baby)
        {
            if(updateCor != null)
            {
                StopCoroutine(updateCor);
                updateCor = null;
                ending.InitPositions(currentBabies.Count);
                FTemplate.Shop.IncrementCoins((long)(currentPercentage * 10) + (currentBabies.Count * 20) , true);
            }
            ending.GetBabyPosition(baby, currentBabies.IndexOf(baby));

            if (currentBabies.IndexOf(baby) == 0)
            {
                cinemachineVirtualCamera.Follow = ending.pivot;
                cinemachineVirtualCamera.LookAt = ending.pivot;
                cinemachineTransposer.m_FollowOffset = cinemachineTransposer.m_FollowOffset.AddZ(-3);
                cinemachineComponent.m_TrackedObjectOffset =
                    cinemachineComponent.m_TrackedObjectOffset.AddZ(-1).WithX(ending.GetMagnitude(0));
                    
                EndCamera();
            }
            // baby.babyModel.SetCycleOffset();
            
        }

        private void EndCamera()
        {
            var sequence = DOTween.Sequence();
            var pointTimer = 0f;
            sequence.Append(
                DOTween.To(() => cinemachineComponent.m_TrackedObjectOffset.x,
                    value => cinemachineComponent.m_TrackedObjectOffset = cinemachineComponent.m_TrackedObjectOffset.WithX(value),
                    -ending.GetMagnitude(currentBabies.Count-1), 1f * (currentBabies.Count / 2f)).SetDelay(0.4f));

            StartCoroutine(nameof(PercentageCor));
            sequence.Append(
                DOTween.To(() => cinemachineComponent.m_TrackedObjectOffset.x,
                    value => cinemachineComponent.m_TrackedObjectOffset =
                        cinemachineComponent.m_TrackedObjectOffset.WithX(value),
                    0f, 1f * (currentBabies.Count / 2f)));

            ending.Finish();
        }

        public IEnumerator PercentageCor()
        {
            var lastIntPercentage = (int)(currentPercentage * 100);

            while (lastIntPercentage > 0)
            {
                lastIntPercentage = Mathf.Max(0, lastIntPercentage - 5);
                AddPoint(5, Camera.main.transform.position);
                progressBar.UpdateProgress(lastIntPercentage/100f);
                yield return BetterWaitForSeconds.Wait(0.3f);
            }
        }

        public void GateCameraStart()
        {
            DOTween.Kill(cinemachineTransposer.GetInstanceID());
            DOTween.To(() => cinemachineTransposer.m_FollowOffset.y,
                value => cinemachineTransposer.m_FollowOffset = cinemachineTransposer.m_FollowOffset.WithY(value),
                0.6f, 1f).SetId(cinemachineTransposer.GetInstanceID());
        }

        public void GateCameraEnd()
        {
            DOTween.Kill(cinemachineTransposer.GetInstanceID());
            DOTween.To(() => cinemachineTransposer.m_FollowOffset.y,
            value => cinemachineTransposer.m_FollowOffset = cinemachineTransposer.m_FollowOffset.WithY(value),
            defaultTransposerYOffset, 1f).SetId(cinemachineTransposer.GetInstanceID()).SetDelay(0.5f);
        }

        public void AddPoint(int amount, Vector3 position)
        {
            var screenPosition = (Vector2) Camera.main.WorldToScreenPoint(position);
            FTemplate.UI.SpawnCollectedCoins(screenPosition, 1, amount);
        }

        public Vector3 GetTangent(Vector3 transformPosition)
        {
            return currentSpline.GetTangent(currentSpline.GetNearestPointTF(transformPosition));
        }
    }
}