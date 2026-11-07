using Il2Cpp;
using UnityEngine;

namespace RunetifyPVZFusionMod
{
    public static class WaterZombieMovement
    {
        public static bool IsWaterOrSubmarine(ZombieType type)
        {
            int t = (int)type;
            if (t == 14 || t == 200 || t == 211 || t == 237 || (t >= 310 && t <= 314)) return true;
            if (t == 71 || t == 234 || t == 235) return true;
            if (t == 19 || t == 27 || t == 59 || t == 61 || t == 113 || t == 214 || t == 249) return true;
            if (t == 11 || t == 12 || t == 13) return true;
            if (t == 17 || t == 20 || t == 51 || t == 76 || t == 202 || t == 216 || t == 218 || t == 239 || t == 240 || t == 262 || (t >= 315 && t <= 317) || (t >= 333 && t <= 335)) return true;
            try {
                if (TypeMgr.WaterZombie(type)) return true;
            } catch {}
            return false;
        }

        public static void CheckAndMove(Zombie zombie)
        {
            if (zombie == null) return;
            if (zombie.WasCollected) return;
            if (zombie.theHealth <= 0 || zombie.beforeDying) return;
            if (zombie.isAttacking) return;
            if (zombie.butterSpeed > 0f || zombie.freezeSpeed > 0f) return;

            if (IsWaterOrSubmarine(zombie.theZombieType))
            {
                if (!zombie.inWater)
                {
                    float speed = zombie.theSpeed;
                    if (speed < 0.05f)
                    {
                        speed = 0.35f;
                        zombie.theOriginSpeed = 0.35f;
                        zombie.theSpeed = 0.35f;
                    }
                    if (zombie.coldSpeed > 0f)
                    {
                        speed *= 0.5f;
                    }
                    float dir = zombie.isMindControlled ? 1.0f : -1.0f;
                    float dx = dir * speed * Time.fixedDeltaTime;
                    zombie.transform.Translate(dx, 0f, 0f);
                }
            }
        }
    }
}