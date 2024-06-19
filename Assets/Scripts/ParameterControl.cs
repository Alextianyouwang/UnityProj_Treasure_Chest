using UnityEngine;
[ExecuteInEditMode]
public class ParameterControl : MonoBehaviour
{
    public GameObject MaskCenter;
    public Material[] AffectedMaterials;
    public float MaskRadius;
    public float MaskFalloff;

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
        }
    }
}
