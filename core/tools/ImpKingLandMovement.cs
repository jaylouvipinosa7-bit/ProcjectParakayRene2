using MelonLoader;
using HarmonyLib;
using Il2Cpp;
using UnityEngine;

[assembly: MelonInfo(typeof(ImpKingLandMovement.Mod), "ImpKingLandMovement", "1.0.0", "RENEarn")]
[assembly: MelonGame("LanPiaoPiao", "PlantsVsZombiesRH")]

namespace ImpKingLandMovement
{
    public class Mod : MelonMod
    {
        public override void OnInitializeMelon()
        {
            MelonLogger.Msg("ImpKingLandMovement Mod loaded! UltimateImpKing (234) land movement active.");
        }
    }

    [HarmonyPatch(typeof(Zombie), "FixedUpdate")]
    public static class Patch_Zombie_FixedUpdate
    {
        [HarmonyPostfix]
        public static void Postfix(Zombie __instance)
        {
            if (__instance == null || __instance.WasCollected) return;
            
            if (__instance.theZombieType == ZombieType.UltimateImpKing)
            {
                if (__instance.isAttacking || __instance.beforeDying || __instance.theHealth <= 0)
                {
                    return;
                }

                if (__instance.butterSpeed > 0f || __instance.freezeSpeed > 0f)
                {
                    return;
                }

                float speed = 0.35f;
                if (__instance.coldSpeed > 0f)
                {
                    speed *= 0.5f;
                }

                float dir = __instance.isMindControlled ? 1.0f : -1.0f;
                Vector3 pos = __instance.transform.position;
                pos.x += dir * speed * Time.fixedDeltaTime;
                __instance.transform.position = pos;
            }
        }
    }
}

