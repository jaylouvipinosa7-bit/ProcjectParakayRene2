using MelonLoader;
using UnityEngine;
using Il2Cpp;

[assembly: MelonInfo(typeof(TestMod.MyTestMod),  TestMod, 1.0.0, Author)]
[assembly: MelonGame(LanPiaoPiao, PlantsVsZombiesRH)]

namespace TestMod
{
    public class MyTestMod : MelonMod
    {
        public override void OnInitializeMelon()
        {
            MelonLogger.Msg(TestMod loaded successfully!);
        }
    }
}
