using UnityEngine;
[ExecuteInEditMode]
public class SetBufferMatProperty : MonoBehaviour
{
    public Material Material;

    private void LateUpdate()
    {
        Material.SetVector("_EffectCenter", transform.position);
    }
}
