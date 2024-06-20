using UnityEngine;
[ExecuteInEditMode]
public class ParameterControl : MonoBehaviour
{
    public GameObject MaskCenter;
    public Material[] AffectedMaterials;
    public float MaskRadius;
    public float MaskFalloff;

    [Range(0f, 1f)]
    public float CrackAmount;

    [Range(0f, 1f)]
    public float IntensityAmount;
    private void Update()
    {
        if (MaskCenter == null)
            return;
        if (AffectedMaterials == null)
            return;

        foreach (Material m in AffectedMaterials) 
        {
            if (m == null)
                continue;
            m.SetVector("_MaskCenter", MaskCenter.transform.position);
            m.SetFloat("_MaskRadius", MaskRadius);
            m.SetFloat("_MaskFalloff", MaskFalloff);
            m.SetFloat("_IntensityMultiplier", IntensityAmount);
            m.SetFloat("_CrackMultiplier", CrackAmount);
        }
    }
}
