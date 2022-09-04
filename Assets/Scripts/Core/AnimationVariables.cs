using UnityEngine;

namespace Core
{
    public static class AnimationVariables
    {
        public static readonly int Crawl = Animator.StringToHash("Crawl");
        public static readonly int Walk = Animator.StringToHash("Walk");
        public static readonly int CycleOffset = Animator.StringToHash("CycleOffset");
        public static readonly int Idle = Animator.StringToHash("Idle");
        public static readonly int Hit = Animator.StringToHash("Hit");
        public static readonly int Fall = Animator.StringToHash("Fall");
        public static readonly int Ending = Animator.StringToHash("EndPose");
        public static readonly int Caution = Animator.StringToHash("Caution");
        public static readonly int MirrorHit = Animator.StringToHash("MirrorHit");
        public static readonly int MirrorWalk = Animator.StringToHash("MirrorWalk");
        public static float CurrentCycleOffset = Mathf.Repeat(GetCycleOffset(), 1f);
        private static float lastCycleOffset;
        private static float cycleOffset = 0.07f;

        private static float GetCycleOffset()
        {
            lastCycleOffset += cycleOffset;
            Debug.Log(lastCycleOffset);
            return lastCycleOffset;
        }
    }
}