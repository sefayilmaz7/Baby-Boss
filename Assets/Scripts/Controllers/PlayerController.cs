using System;
using DG.Tweening;
using Managers;
using TMPro;
using UnityEngine;

namespace Controllers
{
    public class PlayerController : MonoInputListener
    {
        [SerializeField] private BabyManager babyManager;
        [SerializeField] private float speed;
        
        private Vector2 lastPos;

        public override void OnSlide(SlideData data)
        {
            base.OnSlide(data);
            if (data.movement == Vector2.zero)
            {
                lastPos = Vector2.zero;
            }

         
            var currentMovement = -(lastPos - data.movement);
            if (lastPos != data.movement)
            {
                babyManager.Move(currentMovement * speed);
            }
            
            lastPos = data.movement;
        }
    }
}
